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
	simplex[3] theta[poll_count];
	real total;

	# Might as well make each poll's observed results into a simplex to
	# prevent blow-ups when they don't sum quite to 100%.
	for (i in 1:poll_count) {
		total <- rema[i] + leav[i] + unde[i];
		theta[i][1] <- rema[i] / total;
		theta[i][2] <- leav[i] / total;
		theta[i][3] <- unde[i] / total;
	}
}

parameters {
	vector<lower=0>[3] alpha;
	vector<lower=0>[3] beta_teleph;
	vector<lower=0>[3] beta_pollster[pollsters];
}

model {

	alpha ~ lognormal(log(1000), 2);
	beta_teleph ~ lognormal(log(1), 0.3);
	for (i in 1:pollsters) {
		beta_pollster[i] ~ lognormal(log(1), 0.2);
	}

	for (i in 1:poll_count) {
		if (teleph[i]) {
			theta[i] ~ dirichlet(beta_pollster[pollster[i]]
			                     .* beta_teleph .* alpha);
		} else {
			theta[i] ~ dirichlet(beta_pollster[pollster[i]]
			                     .* alpha);
		}
	}

}
