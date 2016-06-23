st <- read.table("stan/ukeu_2.csv", header=TRUE, sep=",")

par_me <- colMeans(st[7:ncol(st)])
par_sd <- apply(st[7:ncol(st)], 2, sd)
