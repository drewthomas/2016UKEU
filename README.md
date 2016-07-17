2016 UK-in-EU referendum statistical models
===========================================

On the night of [the UK's referendum to leave or remain in the EU](https://en.wikipedia.org/wiki/United_Kingdom_European_Union_membership_referendum,_2016), I made a few last-minute statistical models of [the results of polls taken in 2016 about the referendum](https://en.wikipedia.org/wiki/Opinion_polling_for_the_United_Kingdom_European_Union_membership_referendum#2016).

## Definition of the final model

I used the polls which put respondents into three categories: those who intended to vote to remain (R), those who intended to vote to leave (L), and the undecided.
Because those categories form a 3-point ordinal scale, I decided that a potential voter's preference could be represented as a single number, with positive values representing a preference for R, negative values representing a preference for L, and values close to 0 representing indecision. The distribution of preferences among the electorate could then be represented as a Gaussian distribution with mean &mu; and standard deviation &sigma;<sub>0</sub> (the choice of distribution was arbitrary &mdash; it'd be interesting to experiment with other distributions and see how that changed things), where values between &#8722;1 and +1 represented the undecided, values below &#8722;1 those voting L, and values above +1 those voting R.

Changes in opinion could manifest as changes in &mu; or in &sigma;<sub>0</sub>.
Not having time to make a more complex model that could accommodate both, I assumed &sigma;<sub>0</sub> was a constant, and just slapped a lognormal prior on it: &sigma;<sub>0</sub> ~ ln **N**(ln 2.5, 1).
My model therefore had to represent factors influencing opinion, and changes in opinion over time, as changes in &mu; alone.

To link the underlying Gaussian distribution and its &mu; and &sigma;<sub>0</sub> to the observed poll results, the model converted each poll's reported percentages into approximate counts, by multiplying the three percentages (for L, for R, and undecided) by the poll's sample size *N*.
Hence each poll was represented by three approximate counts: *N*<sub>L</sub>, the number of respondents supporting L; *N*<sub>R</sub>, the number of respondents supporting R; and *N*<sub>U</sub> the number undecided.
The model then assumed these three counts came from a multinomial distribution with number of trials *N*<sub>L</sub> + *N*<sub>R</sub> + *N*<sub>U</sub>, and probabilities

> *p*<sub>L</sub> &equiv; &Phi;((&#8722;&mu; &#8722; 1) / &sigma;<sub>0</sub>),    
> *p*<sub>R</sub> &equiv; &Phi;((&mu; &#8722; 1) / &sigma;<sub>0</sub>), and    
> 1 &#8722; *p*<sub>L</sub> &#8722; *p*<sub>R</sub>

respectively.
This allowed for sampling error and the differing sizes of the polls' samples.

The model represented the &mu; obtaining for a specific poll as

> &mu; = &mu;<sub>0</sub> + &kappa;<sub>pollster</sub> + &beta;*t* + &delta;<sub>*t*</sub> + &kappa;<sub>tel</sub>**1**<sub>tel</sub>

where

* &mu;<sub>0</sub> is a constant, a grand mean representing the overall level of pro-L sentiment;
* &kappa;<sub>pollster</sub> is a pollster-level fixed effect, representing the systematic difference between each pollster's results and the overall average;
* *t* is the number of days after January 8, 2016 when the midpoint of the poll's survey period occurred (*t* ranged from 1, for a poll with a midpoint on January 9, to 165, for a poll with a midpoint on June 21);
* &beta; a linear trend over time towards or away from L over time;
* &delta;<sub>*t*</sub> a date fixed effect (i.e. the time-dependent residual left over after allowing for the linear trend over time);
* &kappa;<sub>tel</sub> the systematic difference in &mu; between telephone polls and online polls;
* and **1**<sub>tel</sub> representing whether or not the poll was a telephone poll (1 if so, 0 otherwise).

In other words, the coefficient
&kappa;<sub>pollster</sub> captured variation among pollsters;
&beta; captured straight-line variation over time;
&delta;<sub>*t*</sub> captured day-to-day variation superimposed on the straight-line trend;
and &kappa;<sub>tel</sub> captured the variation across modes of polling (telephone vs. Internet).

Most of these parameters were constants, to which I attached simple priors:

* &mu;<sub>0</sub> ~ **N**(0, 1)
* &kappa;<sub>pollster</sub> ~ **N**(0, 2)
* &kappa;<sub>tel</sub> ~ **N**(0, 2)
* &beta; ~ **N**(0, 0.1)

I originally considered having the &delta;<sub>*t*</sub> parameters be i.i.d. with a Gaussian prior as well, but decided this didn't make much sense, because I expected public opinion on day *t*+1 to be much the same as opinion on day *t*.
A random walk model for these day-to-day variations therefore made more sense, so I instead defined

> &delta;<sub>1</sub> &equiv; &epsilon;<sub>1</sub>,    
> with &delta;<sub>*t*</sub> &equiv; &delta;<sub>*t*-1</sub> + &epsilon;<sub>*t*</sub> for *t* &gt; 1,    
> &epsilon;<sub>*t*</sub> ~ **N**(0, &sigma;<sub>&epsilon;</sub>), and    
> &sigma;<sub>&epsilon;</sub> ~ ln **N**(ln 0.4, 1)

In short, I assumed that in addition to the linear trend represented by &beta;, &mu; was pushed up or down by a new random i.i.d. Gaussian shock each day, with a typical magnitude &sigma;<sub>&epsilon;</sub> estimated by the model.
The effect of these shocks was cumulative, so the day-specific effect &delta;<sub>*t*</sub> was simply the sum of the preceding shocks.

Once Stan estimated &mu;<sub>0</sub>, &sigma;<sub>0</sub>, &kappa;<sub>pollster</sub>, &kappa;<sub>tel</sub>, &beta;, &epsilon;<sub>*t*</sub> for all *t*, and &sigma;<sub>&epsilon;</sub>, I could extract predictions or retrodictions of the L vs. R vs. undecided shares by calculating a &mu; estimate from the parameter estimates, then applying the above formulae for *p*<sub>L</sub> and *p*<sub>R</sub>.

## Model results

My Stan run gave the following moments of the posterior distributions of the most important parameters.
Notice the tendency towards leptokurticity for most of the posteriors.

| parameter                                               | mean | SD   | kurtosis |
|---------------------------------------------------------|------|------|----------|
| &mu;<sub>0</sub>                                        | 0.25 | 0.46 | 3.14 |
| &sigma;<sub>0</sub>                                     | 5.53 | 0.03 | 3.01 |
| &kappa;<sub>1</sub>, &hellip;, &kappa;<sub>15</sub>     | &#8722;0.6 to +0.4 | 0.44 to 0.50 | 2.99 to 3.13 |
| &kappa;<sub>tel</sub>                                   | 0.42 | 0.08 | 2.94 |
| &beta;                                                  | &#8722;0.003 | 0.007 | 3.83 |
| &sigma;<sub>&epsilon;</sub>                             | 0.08 | 0.02 | 3.33 |
| &delta;<sub>165</sub> = &Sigma; &epsilon;<sub>*t*</sub> | &#8722;0.04 | 1.08 | 3.86 |

Most of the parameter estimates are statistically insignificant, in that their means are comparable in size to their standard deviations.
Specifically, &mu;<sub>0</sub>, the pollster effects, &beta;, and the day effect &delta;<sub>165</sub> of the latest poll, considered alone, are each statistically insignificant.
But this fact is potentially misleading because it doesn't allow for correlation in the parameter estimates.
For example, the &delta;<sub>165</sub> estimates strongly anticorrelate with the &beta; estimates (*r* = &#8722;0.986), and this means that the *combined* effect of the two parameters is in fact statistically significant: the combined effect 165&beta; + &delta;<sub>165</sub> has mean &#8722;0.59 and standard deviation 0.19.

An estimate of &mu; on referendum day itself is &mu;<sub>0</sub> + 167&beta; + &delta;<sub>165</sub>, since the day of the referendum, June 27, corresponds to *t* = 167.
The model can't directly estimate &delta;<sub>167</sub>, because day 167 falls outside the bounds of the data, so &delta;<sub>165</sub> serves as a best estimate of &delta;<sub>167</sub> (since the expected value of &delta;<sub>167</sub> minus &delta;<sub>165</sub> is zero, the model assuming that &delta;<sub>t</sub>'s random walk has no drift).
From Stan's parameter estimates, the referendum-day &mu; has a posterior distribution with mean &#8722;0.339 and SD 0.454, suggesting a probable advantage for L over R.

This conclusion is supported by running an R script to estimate vote shares from that &mu; (and &sigma;<sub>0</sub>); it implies a referendum result of 52.8% for L, and 47.2% for R, with a standard error of 3.8% attaching to either percentage.
This seems impressively close to the actual referendum result of 51.9% L and 48.1% R, but that's mostly luck; by ignoring the &kappa;<sub>pollster</sub> and &kappa;<sub>tel</sub> parameters this estimate implicitly assumes that the best way to predict/retrodict the referendum result is to assume the online polls had no systematic sampling bias and that, on average, the pollsters had no systematic bias either.

I in fact guessed (apparently wrongly) that the telephone polls had more representative samples than the online polls, and reckoned that splitting the difference 2:1 in favour of the telephone polls was a reasonable guess.
That implied adding two thirds of &kappa;<sub>tel</sub> to the referendum-day &mu; estimate, and hence a referendum result of 50.5% L, 49.5% R.
Although that result is still qualitatively correct (L did in fact win), it underestimates L's lead by 2.8 percentage points, though that underestimation is minor enough to be explicable as statistical noise.

## Potential model improvements

Because I was trying to predict the referendum's result before it was released, I didn't have time to try out potential improvements to the model:

* experimenting with non-Gaussian distributions for the latent variable representing the electorate's preference distribution
* allowing &sigma;<sub>0</sub> to rise over time, which would have accounted for the [apparent decrease](https://en.wikipedia.org/wiki/File:UK_EU_referendum_polling.svg) in undecided respondents in surveys during 2016
* putting a hyper-prior on the standard deviation of &kappa;<sub>pollster</sub>, rather than just assuming a standard deviation of 2; this would allow for the fact that the final estimates of &kappa;<sub>pollster</sub> clearly have a standard deviation much less than 2
* modelling the obvious-in-retrospect non-independence of the random shock variables &epsilon;<sub>*t*</sub>
* modelling the obvious-in-retrospect non-Gaussianness of the random shock variables &epsilon;<sub>*t*</sub> (based on their kurtosis, a *t* distribution with ~ 13 d.o.f. might be more suitable)
