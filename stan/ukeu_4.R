# Read in the Stan model-fitting results, then the poll results, then the
# enumerated list of pollsters.
st <- read.table("stan/ukeu_4.csv", header=TRUE, sep=",",
                 colClasses="numeric")
po_unadj <- read.table("results.dat", header=TRUE)
po_unadj$DATE <- as.Date(po_unadj$DATE)
pols <- read.table("pollsters.dat", header=TRUE)

# Graft pollster ID numbers onto the unadjusted poll results. There's
# probably a nice way to do this with `merge` but this way takes less thought.
po_unadj$PSTER <- NA
for (i in 1:nrow(po_unadj)) {
	po_unadj$PSTER[i] <- pols$ID[pols$POLLSTER == po_unadj$POLLSTER[i]]
}

# Define a time variable as the number of days since the first poll, plus 1.
po_unadj$T <- as.integer(1 + po_unadj$DATE - min(po_unadj$DATE))

# Compute the mean of the parameter estimates.
par_me <- colMeans(st[7:ncol(st)])

# Pick out the mean of `grand_mu` and `grand_sigma` as particularly important.
g_mu <- par_me["grand_mu"]
g_sig <- par_me["grand_sigma"]

# Roll up the daily shocks estimated by the model into day effects by
# taking a rolling sum of the random shocks.
epsilons <- par_me[grepl("^epsilon\\.", names(par_me))]
day_delta <- cumsum(epsilons)

# Compute the implied leave vs. undecided vs. remain percentages from the
# latent mean and standard deviation of public opinion.
compute_lru_prop <- function(mu, sig)
{
	p_leave <- pnorm(-1, mu, sig)
	p_remain <- 1 - pnorm(1, mu, sig)
	return(c(p_leave, 1 - p_leave - p_remain, p_remain))
}

# Fix up R's crummy default graphics settings.
par(las=1, mar=c(5,4,1,1))

# Plot (adjusted or unadjusted) poll results.
plo_po <- function(po, on_plot_label="")
{
	plot(po$DATE, 100.0 * po$REM / (po$REM + po$LEA),
	     pch=po$PSTER, col="red", cex=sqrt(po$N / 1e3),
	     ylim=range(35.8, 64.2),
	     xlab="mid-date of poll",
	     ylab="head-to-head %age (i.e. setting aside the undecided)")
	abline(h=seq(35, 65, 5), col="#0000005f", lty="dotted")
	points(po$DATE, 100.0 * po$LEA / (po$REM + po$LEA),
	       pch=po$PSTER, col="blue", cex=sqrt(po$N / 1e3))
	text(as.Date("2016-03-31"), 35.5, on_plot_label, cex=1.2)
	legend(as.Date("2016-05-29"), 64, c("remain", "leave"),
	       col=c("red", "blue"), pch=1)
}

# Plot the unadjusted poll results.
plo_po(po_unadj, "unadjusted")

# Adjust poll results with a list of mu offsets.
adjust_po <- function(mu_offset)
{
	po_adj <- po_unadj
	for (i in 1:nrow(po_unadj)) {
		mu <- g_mu + mu_offset[i]
		offset <- compute_lru_prop(mu, g_sig) - compute_lru_prop(g_mu, g_sig)
		po_adj$LEA[i] <- po_adj$LEA[i] - (100.0 * offset[1])
		po_adj$UND[i] <- po_adj$UND[i] - (100.0 * offset[2])
		po_adj$REM[i] <- po_adj$REM[i] - (100.0 * offset[3])
	}
	return(po_adj)
}

# Plot the poll results adjusted, crudely, for a telephone vs. Web effect.
po_adj_1 <- adjust_po(c(0, par_me["kappa_tel"])
                      [1 + (po_unadj$POLLTYPE == "Telephone")])
plo_po(po_adj_1, "adjusted for medium (phone effect vs. Web)")

# Plot the poll results adjusted, crudely, for a telephone effect, and
# individual pollster effects.
po_adj_2 <- adjust_po(c(0, par_me["kappa_tel"])
                      [1 + (po_unadj$POLLTYPE == "Telephone")]
                      + par_me[paste0("kappa_pollster.", po_unadj$PSTER)])
plo_po(po_adj_2, "adjusted for medium & pollster")

# Plot the poll results adjusted, crudely, for a telephone effect,
# individual pollster effects, and a linear time trend.
po_adj_3 <- adjust_po(c(0, par_me["kappa_tel"])
                      [1 + (po_unadj$POLLTYPE == "Telephone")]
                      + par_me[paste0("kappa_pollster.", po_unadj$PSTER)]
                      + (par_me["beta"] * po_unadj$T))
plo_po(po_adj_3, "adjusted for medium, pollster, and time trend")

# Plot the poll results adjusted, crudely, for a telephone effect,
# individual pollster effects, a linear time trend, and day effects.
po_adj_4 <- adjust_po(c(0, par_me["kappa_tel"])
                      [1 + (po_unadj$POLLTYPE == "Telephone")]
                      + par_me[paste0("kappa_pollster.", po_unadj$PSTER)]
					  + (par_me["beta"] * po_unadj$T)
                      + (day_delta[po_unadj$T]))
plo_po(po_adj_4, "adjusted for medium, pollster, trend, and day effects")

# Plot the poll results adjusted, crudely, for individual pollster effects,
# a linear time trend, and day effects, weighting the results two thirds
# of the way towards the telephone-derived results.
po_adj_5 <- adjust_po(c(-2 * par_me["kappa_tel"] / 3,
                        1 * par_me["kappa_tel"] / 3)
                      [1 + (po_unadj$POLLTYPE == "Telephone")]
                      + par_me[paste0("kappa_pollster.", po_unadj$PSTER)]
					  + (par_me["beta"] * po_unadj$T)
                      + (day_delta[po_unadj$T]))
plo_po(po_adj_5, "adjusted for pollster, trend, and day, weighted towards phone polls")

# Generate a basic estimate of the head-to-head leave-vs.-remain result.
# (Note the lack of a telephone effect increment here; this calculation
# effectively adjusts the telephone polls to bring them into line with
# the online polls.)
props <- compute_lru_prop(g_mu + (167 * par_me["beta"]) + day_delta[165],
                          g_sig)
cat("p_leave, p_undec, p_remain:", props, "\n")
cat("Basic just-average-everything estimate of referendum result:\n",
    "leave", round(100 * props[1] / (props[1] + props[3]), 1), "%,",
    "remain", round(100 * props[3] / (props[1] + props[3]), 1), "%\n")

# Overlay two stripcharts to illustrate the estimated pollster effects.
pollster_effects <- pols
pollster_effects$REM <- NA
pollster_effects$LEA <- NA
basic_estimates <- compute_lru_prop(g_mu, g_sig)
for (i in pollster_effects$ID) {
	mu <- g_mu + (167 * par_me["beta"]) + day_delta[165] +
	      par_me[paste0("kappa_pollster.", i)]
	pollster_effects$REM[i] <- compute_lru_prop(mu, g_sig)[3]
	pollster_effects$LEA[i] <- compute_lru_prop(mu, g_sig)[1]
}
pollster_effects$DEC <- pollster_effects$REM + pollster_effects$LEA
pollster_effects$REM <- 100.0 * pollster_effects$REM / pollster_effects$DEC
pollster_effects$LEA <- 100.0 * pollster_effects$LEA / pollster_effects$DEC
pollster_effects <- pollster_effects[, c("ID", "POLLSTER", "REM", "LEA")]
stripchart(REM ~ POLLSTER, pollster_effects, xlim=c(42, 58), col="red",
           xlab="average %age on ref. day by pollster (adjusted for medium)")
grid()
stripchart(LEA ~ POLLSTER, pollster_effects, add=TRUE, col="blue")
abline(v=100.0 * props[3] / (props[1] + props[3]), lty="dashed", col="red")
abline(v=100.0 * props[1] / (props[1] + props[3]), lty="dashed", col="blue")
text(45.8, 7, "remain mean\nover all pollsters", col="red", cex=3/4)
text(54.2, 7, "leave mean\nover all pollsters", col="blue", cex=3/4)

# Plot the random walk superimposed on the trend (a.k.a. the day effects),
# and the shocks which produce the walk (the `epsilons`).
plot(min(po_unadj$DATE) - 1 + 1:length(day_delta), day_delta,
     type="l",
     xlab="date", ylab="(pro-remain) day effect or random daily shock")
abline(h=seq(-0.4, 0.3, 0.1), lty="dotted", col="#0000005f")
points(min(po_unadj$DATE) - 1 + 1:length(day_delta), epsilons, cex=2/3)
legend(as.Date("2016-02-01"), -0.3,
       c("random daily shocks", "day effect (cumulative sum of shocks)"),
       pch=c(1, NA), lty=c(NA, "solid"), pt.cex=c(2/3, NA))
abline(v=as.Date("2016-06-16"), col="#00000099", lty="dashed")
text(as.Date("2016-06-04"), 0.17, "Jo Cox\nassassinated", cex=3/4)

# Make my own preferred estimate of the head-to-head L-vs.-R result
# (i.e. weigh the results more towards the telephone poll results, 'cause I
# suspect their samples are more representative).
my_mu <- g_mu + (167 * par_me["beta"]) + day_delta[165] +
         (2 * par_me["kappa_tel"] / 3)
props <- compute_lru_prop(my_mu, g_sig)
cat("My guess at the referendum result:\n",
    "leave", round(100 * props[1] / (props[1] + props[3]), 1), "%,",
    "remain", round(100 * props[3] / (props[1] + props[3]), 1), "%\n")

# Generate a new single estimate of the head-to-head L-vs.-R result by
# sampling a row from the Stan MCMC results.
sample_leave_remain_results <- function(N=nrow(st))
{
	samples <- data.frame(LEA=rep(NA, N), REM=rep(NA, N))
	row_nos <- sample(1:nrow(st), N, replace=TRUE)
	for (i in 1:N) {
		ro <- st[row_nos[i],]
		mu <- ro["grand_mu"]
		sig <- ro["grand_sigma"]
		k_tel <- ro["kappa_tel"]
		bet <- ro["beta"]
		epsilon_row <- ro[grepl("^epsilon\\.", names(st))]
		final_dd <- sum(epsilon_row)
		props <- compute_lru_prop(unlist(mu + (167 * bet) + final_dd +
		                                 (2 * k_tel / 3)),
		                          unlist(sig))
		samples$LEA[i] <- round(100 * props[1] / (props[1] + props[3]), 1)
		samples$REM[i] <- round(100 * props[3] / (props[1] + props[3]), 1)
	}
	return(samples)
}

# Estimate the standard error of the head-to-head prediction/retrodiction
# through resampling.
cat("Resampling to estimate standard errors...\n")
#sampled_LR <- sample_leave_remain_results(1000)
sampled_LR <- sample_leave_remain_results(2000)
LR_ses <- apply(sampled_LR, 2, sd)
cat("Standard error on those percentages:", round(LR_ses[1], 1), "%\n")

# Plot a kernel-density estimate of the random daily shock distribution.
plot(density(epsilons),
     main="kernel-density estimate of random-daily-shock distribution")
cat("Shapiro-Wilk normality test p-value applied to epsilons:",
    shapiro.test(epsilons)$p.value, "\n")
grid()

# Plot the model's retrodictions of the proportion undecided, using the
# estimated grand mean, trend, and day effects.
daily_und <- rep(NA, 167)
for (i in 1:length(daily_und)) {
	daily_und[i] <- compute_lru_prop(g_mu + (i * par_me["beta"]) +
	                                 day_delta[min(i, 165)], g_sig)[2]
	daily_und[i] <- 100.0 * daily_und[i]
}
plot(min(po_unadj$DATE) - 1 + 1:167, daily_und, type="b", cex=3/4,
     xlim=range(po_unadj$DATE),
     xlab="date", ylab="%age undecided estimated by model")
grid()
abline(v=as.Date("2016-06-16"), col="#00000099", lty="dashed")
text(as.Date("2016-06-07"), 14.338, "Jo Cox\nassassinated", cex=3/5)

# Plot the model's retrodictions of the head-to-head leave vs. remain
# percentages, using the estimated grand mean, trend, and day effects.
daily_est <- data.frame(LEA=rep(NA, 167), REM=rep(NA, 167))
for (i in 1:nrow(daily_est)) {
	props <- compute_lru_prop(g_mu + (i * par_me["beta"]) +
	                          day_delta[min(i, 165)], g_sig)
    daily_est$LEA[i] <- 100 * props[1] / (props[1] + props[3])
    daily_est$REM[i] <- 100 * props[3] / (props[1] + props[3])
}
plot(min(po_unadj$DATE) - 1 + 1:167, daily_est$LEA, type="b", col="blue",
     xlim=range(po_unadj$DATE), ylim=c(35.8, 64.2),
     xlab="date", ylab="head-to-head %age estimated by model", cex=3/4)
grid()
points(min(po_unadj$DATE) - 1 + 1:167, daily_est$REM, type="b", col="red",
       cex=3/4)
abline(v=as.Date("2016-06-16"), col="#00000099", lty="dashed")
text(as.Date("2016-06-04"), 37.5, "Jo Cox\nassassinated", cex=3/4)
abline(h=51.89, lty="dotted", col="blue")
text(as.Date("2016-02-01"), 52.4, col="blue", cex=4/5, "final leave %age")
abline(h=48.11, lty="dotted", col="red")
text(as.Date("2016-02-01"), 47.6, col="red", cex=4/5, "final remain %age")

# Show the mean and SD of the telephone effect, in percentage points, on
# the remain percentage.
props_no_tel <- compute_lru_prop(g_mu, g_sig)
props_tel <- compute_lru_prop(g_mu + par_me["kappa_tel"], g_sig)
tel_effec <- props_tel[3] / (props_tel[1] + props_tel[3])
tel_effec <- tel_effec -
             (props_no_tel[3] / (props_no_tel[1] + props_no_tel[3]))
cat("Mean telephone effect: remain", round(100.0 * tel_effec, 1), "% higher\n")
