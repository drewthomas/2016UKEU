/* A "hello world" kind of model, lifted from my first attempt to fit the
   2015 general-election polling data. This just tries to estimate one
   underlying percentage for each of the 3 polling outcomes:
   remain, leave, or undecided. */

data {
	int<lower=1> poll_count;
	int<lower=1> t[poll_count];
	int<lower=1> pollster[poll_count];
	int<lower=1> n[poll_count];
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
}

model {
	for (i in 1:poll_count) {
		theta[i] ~ dirichlet(alpha);
	}
}
