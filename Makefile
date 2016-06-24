STANPRINT=~/others\'\ programs/cmdstan-2.8.0/bin/print

stan/data.R: process_raw_WP_table.py WP_2016.dat
	rm -f results.dat stan/data.R
	./process_raw_WP_table.py
	cat stan/data.R

# (Before making this target, one must compile the model by running
#   ~/cmdstan-2.8.0$ make [path to ukeu_4.stan]
# to produce the `stan/ukeu_4` sampler program.)
stan/ukeu_4.csv: stan/ukeu_4 stan/data.R
	stan/ukeu_4 sample num_samples=4000 \
		data file=stan/data.R output file=stan/ukeu_4.csv
#	${STANPRINT} stan/ukeu_4.csv

# (Before making this target, one must compile the model by running
#   ~/cmdstan-2.8.0$ make [path to ukeu_3.stan]
# to produce the `stan/ukeu_3` sampler program.)
stan/ukeu_3.csv: stan/ukeu_3 stan/data.R
	stan/ukeu_3 sample num_samples=2000 \
		data file=stan/data.R output file=stan/ukeu_3.csv

# (Before making this target, one must compile the model by running
#   ~/cmdstan-2.8.0$ make [path to ukeu_2.stan]
# to produce the `stan/ukeu_2` sampler program.)
stan/ukeu_2.csv: stan/ukeu_2 stan/data.R
	stan/ukeu_2 sample num_samples=2000 \
		data file=stan/data.R output file=stan/ukeu_2.csv

# (Before making this target, one must compile the model by running
#   ~/cmdstan-2.8.0$ make [path to ukeu_1.stan]
# to produce the `stan/ukeu_1` sampler program.)
stan/ukeu_1.csv: stan/ukeu_1 stan/data.R
	stan/ukeu_1 sample num_samples=2000 \
		data file=stan/data.R output file=stan/ukeu_1.csv

Rplots.pdf: stan/ukeu_4.R stan/ukeu_4.csv
	R -q --vanilla < stan/ukeu_4.R
