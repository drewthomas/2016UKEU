STANPRINT=~/others\'\ programs/cmdstan-2.8.0/bin/print

stan/data.R: process_raw_WP_table.py WP_2016.dat
	rm -f results.dat stan/data.R
	./process_raw_WP_table.py
	cat stan/data.R

# (Before making this target, one must compile the model by running
#   ~/cmdstan-2.8.0$ make [path to ukeu_2.stan]
# to produce the `stan/ukeu_2` sampler program.)
stan/ukeu_2.csv: stan/ukeu_2 stan/data.R
	stan/ukeu_2 sample num_samples=2000 \
		data file=stan/data.R output file=stan/ukeu_2.csv
#	${STANPRINT} stan/ukeu_2.csv

# (Before making this target, one must compile the model by running
#   ~/cmdstan-2.8.0$ make [path to ukeu_1.stan]
# to produce the `stan/ukeu_1` sampler program.)
stan/ukeu_1.csv: stan/ukeu_1 stan/data.R
	stan/ukeu_1 sample num_samples=2000 \
		data file=stan/data.R output file=stan/ukeu_1.csv
#	${STANPRINT} stan/ukeu_1.csv
