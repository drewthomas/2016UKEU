data {
	int<lower=1> poll_count;
	int<lower=1> t[poll_count];
	int<lower=1> n[poll_count];
	int<lower=1> pollsters;
	int<lower=1> pollster[poll_count];
	int<lower=0,upper=1> teleph[poll_count];
	real<lower=0,upper=1> rema[poll_count];
	real<lower=0,upper=1> leav[poll_count];
	real<lower=0,upper=1> unde[poll_count];
}

transformed data {
	int<lower=0> n_est[poll_count, 3];

	/* For each poll, convert the leave/undecided/remain percentages
	   into estimated counts of people in each category. This is necessary
	   to employ a multinomial distribution in the model proper. */
	for (i in 1:poll_count) {
		/* Circumvent Stan's refusal to coerce `real`s to `int`s, even when
		   it's just for the purpose of transforming data and wouldn't
		   introduce discontinuities in the likelihood function. Sigh. */
		n_est[i][1] <- 1;
		while (n_est[i][1] < leav[i] * n[i]) {
			n_est[i][1] <- n_est[i][1] + 1;
		}
		n_est[i][2] <- 1;
		while (n_est[i][2] < unde[i] * n[i]) {
			n_est[i][2] <- n_est[i][2] + 1;
		}
		n_est[i][3] <- 1;
		while (n_est[i][3] < rema[i] * n[i]) {
			n_est[i][3] <- n_est[i][3] + 1;
		}
	}

}

parameters {

	/* grand mean of latent public-opinion distribution */
	real grand_mu;

	/* standard deviation of latent public-opinion distribution */
	real<lower=0> grand_sigma;

	/* pollster effects on apparent mean of latent PO distribution */
	vector[pollsters] kappa_pollster;

	/* telephone-poll effect (vs. Web polls) */
	real kappa_tel;

	/* standard deviation of epsilons (random daily shocks) */
	real<lower=0> sigma_epsilon;

	/* the random daily shocks which sum to make idiosyncratic day effects */
	vector[max(t)] epsilon;

	/* linear time trend (per day) effect on mean of latent PO distribution */
	real beta;
}

model {

	vector[3] inferred_proportions;
	vector[max(t)] delta;  // overall date effect from accumulated shocks
	real mu;

	/* Define the priors for each parameter. */
	grand_mu ~ normal(0, 1);
	grand_sigma ~ lognormal(log(2.5), 1);
	kappa_pollster ~ normal(0, 2);
	kappa_tel ~ normal(0, 2);
	sigma_epsilon ~ lognormal(log(0.4), 1);
	epsilon ~ normal(0, sigma_epsilon);
	beta ~ normal(0, 0.1);

	/* Compute the idiosyncratic day effects `delta` as the cumulative
	   sum of the random daily shocks in `epsilon`. */
	delta[1] <- epsilon[1];
	for (i in 2:max(t)) {
		delta[i] <- delta[i-1] + epsilon[i];
	}

	/* Fit the model to each poll's results in turn. */
	for (i in 1:poll_count) {
		mu <- grand_mu + kappa_pollster[pollster[i]] + delta[t[i]]
		      + (beta * t[i]);
		if (teleph[i]) {
			mu <- mu + kappa_tel;
		}
		inferred_proportions[1] <- Phi((-mu - 1) / grand_sigma);
		inferred_proportions[3] <- Phi((mu - 1) / grand_sigma);
		inferred_proportions[2] <- 1.0 - inferred_proportions[1] -
		                           inferred_proportions[3];
		n_est[i] ~ multinomial(inferred_proportions);
	}

}
