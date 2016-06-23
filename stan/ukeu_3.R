st <- read.table("stan/ukeu_3.csv", header=TRUE, sep=",")

par_me <- colMeans(st[7:ncol(st)])
par_sd <- apply(st[7:ncol(st)], 2, sd)

par(las=1, mar=c(5,4,1,1))

g_mu <- par_me["grand_mu"]
g_sig <- par_me["grand_sigma"]

curve(dnorm(x, g_mu, g_sig), -17, 17, 501)
curve(dnorm(x, g_mu + par_me["kappa_teleph"], g_sig), n=501, add=TRUE)
grid()
abline(v=c(-1, 1), lty="dotted")

p_leave <- pnorm(-1, g_mu, g_sig)
p_remain <- 1 - pnorm(1, g_mu, g_sig)
p_undec <- 1 - p_leave - p_remain
print(round(100 * c(p_leave, p_undec, p_remain), 1))
