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
	real grand_mu;
	real<lower=0> grand_sigma;
	vector[pollsters] kappa_pollster;
	real kappa_teleph;
}

model {

	vector[3] inferred_proportions;
	real mu;

	grand_mu ~ normal(0, 1);
	grand_sigma ~ lognormal(log(2.5), 1);
	kappa_pollster ~ normal(0, 2);
	kappa_teleph ~ normal(0, 2);

	for (i in 1:poll_count) {
		mu <- grand_mu + kappa_pollster[pollster[i]];
		if (teleph[i]) {
			mu <- mu + kappa_teleph;
		}
		inferred_proportions[1] <- Phi((-mu - 1) / grand_sigma);
		inferred_proportions[3] <- Phi((mu - 1) / grand_sigma);
		inferred_proportions[2] <- 1.0 - inferred_proportions[1] -
		                           inferred_proportions[3];
		n_est[i] ~ multinomial(inferred_proportions);
	}

}
