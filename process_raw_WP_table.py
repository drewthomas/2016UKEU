#!/usr/bin/env python

from datetime import datetime
from pprint import pprint

def process_WP_table(file_path, year=2016, nice_results_path="results.dat", stan_results_path="stan/data.R", pollster_path="pollsters.dat"):

	f = open(file_path, "rb")
	raw_lines = [ line.strip() for line in f.readlines() ]
	f.close()

	results = [ ]

	for row in [ line.replace(" \t", "\t").split("\t") for line in raw_lines ]:

		if len(row) < 6:
			# This isn't a poll result, just an extraneous row of text.
			continue

		dates, rema, leav, unde, lead, n, pollster, pt = row[:8]

		if unde == "N/A":
			# Throw out polls that don't quantify the undecideds!
			continue

		# Clean up the relevant fields.
		dates = dates.replace("\xe2\x80\x93", "-").replace("June", "Jun")
		rema = int(rema.replace("%", ""))
		leav = int(leav.replace("%", ""))
		unde = int(unde.replace("%", ""))
		n = int(n.replace(",", ""))
		pollster = filter(lambda c: c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ/",
		                  pollster)

		# Quite a few polls have percentages that don't sum to 100%. Small
		# differences from 100% can be explained by rounding, but large ones
		# can't. Throw out polls that don't have percentage sums near 100%.
		if (rema + leav + unde < 98) or (rema + leav + unde > 102):
			print("Throwing out poll with percentages summing to " +
			      str(rema + leav + unde) + "%")
			print(dates, rema, leav, unde, n, pollster, pt)

		# Process the `dates` string into a start date and end date.
		if "-" in dates:
			if len(dates.split()) > 2:
				# The start and end date lie in different months.
				began, ended = dates.split("-")
				began = datetime.strptime(str(year) + " " + began, "%Y %d %b")
				ended = datetime.strptime(str(year) + " " + ended, "%Y %d %b")
			else:
				began = datetime.strptime("{} {} {}".format(str(year),
				                                            dates.split("-")[0],
				                                            dates.split()[1]),
			                          "%Y %d %b")
				
				ended = str(year) + " " + dates.split("-")[1]
				ended = datetime.strptime(ended, "%Y %d %b")
		else:
			began = datetime.strptime(str(year) + " " + dates, "%Y %d %b")
			ended = began
		began = began.date()
		ended = ended.date()

		# Deduce the middle of the period over which the poll was conducted.
		# (If there are an even number of days between `began` & `ended`,
		# take the middle day closer to the start, on the assumption that
		# pollsters tend to gather most of their sample towards the start of
		# the poll's period.)
		mid_date = began + ((ended - began) / 2)

		results.append((mid_date, rema, leav, unde, n, pollster, pt))

	nice_results = open(nice_results_path, "ab")
	nice_results.write("DATE\tREM\tLEA\tUND\tN\tPOLLSTER\tPOLLTYPE\n")
	for result in results:
		nice_results.write("\t".join(map(str, result)) + "\n")
	nice_results.close()

	def dates_as_ints(dates):
		return map(lambda da: 1 + (da - min(dates)).days,
		           [ da for da in dates ])

	def ints_as_stan_var(var_name, ints):
		return var_name + " <- c(" + ", ".join(map(str, ints)) + ")\n"

	stan_results = open(stan_results_path, "ab")

	stan_results.write("poll_count <- " + str(len(results)) + "\n")
	stan_results.write(ints_as_stan_var("t", dates_as_ints([ result[0]
	                                                         for result
	                                                         in results ])))
	for idx, field_name in enumerate(("rema", "leav", "unde"), 1):
		stan_results.write(ints_as_stan_var(field_name,
		                                    [ result[idx] / 100.0 for result
		                                      in results ] ))

	stan_results.write(ints_as_stan_var("n",
		                                [ result[4] for result in results ] ))

	pollsters = list(set([ result[5] for result in results ]))
	stan_results.write("pollsters <- " + str(len(pollsters)) + "\n")
	stan_results.write(ints_as_stan_var("pollster",
	                                    [ 1 + pollsters.index(result[5])
	                                      for result in results ]))

	stan_results.write(ints_as_stan_var("teleph",
	                                    [ int(result[6] == "Telephone")
	                                      for result in results ]))

	stan_results.close()

	pollster_f = open(pollster_path, "wb")
	pollster_f.write("ID\tPOLLSTER\n")
	for pollster_idx, pollster in enumerate(pollsters, 1):
		pollster_f.write(str(pollster_idx) + "\t\"" + pollster + "\"\n")
	pollster_f.close()

	#pprint(broken_up)

process_WP_table("WP_2016.dat")
