GLS Regression - organizing multiple series and potential models
================
Ann Nakamura

-   <a href="#1-use-case" id="toc-1-use-case">1 Use Case</a>
    -   <a href="#11-fakecohort1" id="toc-11-fakecohort1">1.1 FakeCohort1</a>
-   <a href="#2-organize-data" id="toc-2-organize-data">2 Organize data</a>
-   <a href="#3-data-preparation" id="toc-3-data-preparation">3 Data
    Preparation</a>
    -   <a href="#31-ols-run-assumptions-check-and-outlier-detection"
        id="toc-31-ols-run-assumptions-check-and-outlier-detection">3.1 OLS run:
        assumptions check and outlier detection</a>
-   <a href="#4-ols-vs-gls-model-comparisons"
    id="toc-4-ols-vs-gls-model-comparisons">4 OLS vs GLS Model
    Comparisons</a>
    -   <a href="#41-side-by-side-model-comparisons-and-anova-table"
        id="toc-41-side-by-side-model-comparisons-and-anova-table">4.1
        Side-by-side model comparisons and ANOVA table</a>
-   <a href="#5-summary-table" id="toc-5-summary-table">5 Summary Table</a>
-   <a href="#6-software-acknowledgements-most-recent-updates"
    id="toc-6-software-acknowledgements-most-recent-updates">6 Software
    acknowledgements (Most recent updates)</a>

<H1>

Formatting for scalability with minimal manual intervention

</H1>

# 1 Use Case

When a number of time series and models need to be looked at, the
following code uses list processing and functions applied to lists to
enable processing of a number of series and models for OLS and GLS
models and reduce the lines of code (goal \< 500 lines, with comments).
Tables with model characteristics are coerced into data frames and
formatted using the **gt** package. Packages **performance** and
**modelsummary**, and **patchwork** are used to quickly format tables
and diagnostic plots.

This demo uses the `gls()` function from the **nlme** package to compare
an OLS model with models that can account for non-independence of
observations (when what happens next in a time series is very much like
what happened before).

## 1.1 FakeCohort1

Examples use fake data, created using random group and variable
assignment. `FakeCohort1` contains a unique identifier (ID), a group
membership (GRP1–GRP4), a program membership (PGM1–PGM3), some
demographics (age), dates (MO,YR,dt), and a couple of numeric variables
(ind1 and ind2).

``` r
db1 <- read.table("https://raw.githubusercontent.com/AMNakamura/miscellanea/master/datasets/FakeCohort1.txt",sep="|",header=T) 
```

# 2 Organize data

The following creates a vector for each series and creates lists of time
sereies aggregates and plots. Use the **patchwork** package’s
`wrap_plots()` function and `&` operator to print out all of the plots
and modify all of the themes at once.

``` r
library(tidyverse) ## Attach ggplot2, tidyr, stringr, and other commonly used packages 

series <- list()
plots  <- list()

glst <- sort(unique(as.character(db1[,2])))

# Simplified reporting of p-values for tables later
pstars <- function(prob){
     ifelse(prob < 0.001, "***",
     ifelse(prob < 0.01,"**",
     ifelse(prob < 0.05,"*","")))
}


for (g in glst){
  
i  <- as.numeric(gsub("[[:alpha:]]", "", g))  

# Make a time series for each glst element and store it in the series list.

series[[i]] <- subset(db1, GRP == g) %>%
               arrange(dt) %>%
               group_by(dt) %>%
               summarize(age.mu  = mean(age),
                         pctF    = round(mean(ifelse(GNDR=="F",1,0)),2),
                         pctP1   = round(mean(ifelse(PGM == "PGM1",1,0)),2),
                         ind1    = mean(ind1),
                         ind2    = mean(ind2)) %>%
               mutate_at(c("age.mu"), ~(scale(.,center=TRUE,scale=TRUE) %>% as.vector))  # center and scale 
   
# Make a plot for each of the above time series and store them in the plots list. 

plots[[i]] <- ggplot(data = series[[i]], aes(x=as.Date(dt),y=ind2)) +
                geom_point(color=i) +
                geom_line( aes(group=1), linetype = i) +
                scale_x_date(date_labels = "%m/%y", date_breaks ="18 months") +
                labs(title = glue::glue("ind2 by month for {g}"),
                     x=" ")
}

library(patchwork)

wrap_plots(plots) & theme_minimal()
```

![](GLS_Scaled0/unnamed-chunk-2-1.png)<!-- -->

# 3 Data Preparation

Testing the effects of **age, gender distribution, and program
participation** on **ind2** (sample), the following fits a multiple
linear regression model with autocorrelated errors and seasonal terms.
Data aren’t transformed beyond differencing.

First, decompose the `ind2` time series. Pick one for processing.

``` r
library(forecast)

Grp <- series[[2]] %>%
  mutate(dt = as.Date(dt)) %>%
  dplyr::select(ind2,age.mu,pctF,pctP1,dt)

# Decompose `ind2` into trend, autocorrelation, seasonal, and residual components.
tind2 <- ts(Grp[,1], frequency = 12, start = c(2008,1))
tcomp1 <- decompose(tind2)
tcomp.p1 <- forecast::autoplot(tcomp1,main="Decomposition \nBefore Differencing") # Use autoplot to create a ggplot object for patchwork
```

After applying the `ndiffs()` function from the **forecast** package to
all columns at once to calculate the number of differences needed to
make each series stationary, test for cointegration using the
Engle-Granger(or EG) test. If the first column is the response and the
last column is the date, the following performs a cointegration test on
all columns compared to the response. Use list processing to apply the
cointegration tests and the **gt** package to format the output.

``` r
nd <- as.data.frame(sapply(Grp,ndiffs)) # Named numeric vector

library(aTSA) # for a quick cointegration test
library(gt) # pretty tables

plst <- names(Grp)[2:length(names(Grp))-1]

coint <- list()

for (i in plst){
  c <- which(plst == i)
  coint[[c]] <- coint.test(unlist(Grp[,1]), unlist(Grp[,c]), d = 1, output = F) %>%
                as.data.frame() %>%
                mutate(vname = i,
                       EG    = round(EG,2)) %>%
                dplyr::select(vname,lag, EG, p.value)
}

z<- bind_rows(coint) %>%
    group_by(vname, lag) %>%
    gt() %>%
    tab_header(
      title = md(glue::glue("Cointegration Tests <br> Ind2 ~ Predictors")),
       subtitle = "Fake Cohort Data") %>%
    tab_footnote(
      footnote = "Completely random data. ",
      locations = cells_title(groups="title")) 

invisible(gtsave(z,"coint.png"))

coint_png <- png::readPNG('coint.png', native=TRUE)
```

Apply non-seasonal difference to detrend, if needed, and print out
graphs.

``` r
GrpD <- as.data.frame(lapply(Grp, diff, lag=1))  # Takes the difference of response and dependents

GrpD$t <- as.numeric(as.character(rownames(GrpD))) # Create a time variable for graphing

tindD <- ts(GrpD[,1], frequency = 12, start = c(2008,2))  # Differenced time series for the response.

tcomp2 <- decompose(tindD)

tcomp.p2 <- forecast::autoplot(tcomp2, main="Decomposition \nAfter Differencing") 

wrap_plots(tcomp.p1,tcomp.p2) + coint_png
```

<img src="GLS_Scaled0/unnamed-chunk-5-1.png" style="display: block; margin: auto;" />

The following example uses fourier series, instead of dummies, to
account for seasonality and to reduce the number of regression terms
added to the model.

``` r
# Helper function to find the number of fourier terms (k) that give the best fit for tind2, courtesy https://robjhyndman.com/hyndsight/forecasting-weekly-data/. 

bestfit <- list(aicc=Inf)
for(i in 1:4)
{
  fit <- auto.arima(tindD, xreg=fourier(tindD, K=i), seasonal=FALSE)
  if(fit$aicc < bestfit$aicc)
    bestfit <- fit
  else break;
  bestK <- i
 }

fterms <- fourier(tindD, K=1) # Create the seasonal terms 

GrpD <- cbind(GrpD, fterms) # Add to the data frame

colnames(GrpD)[7:8] <- c("S1","C1") # Rename 
```

## 3.1 OLS run: assumptions check and outlier detection

Examine the performance of the OLS regression model. Use diagnostic
plots to identify outliers and influential observations. Remove outliers
and re-run.

``` r
library(modelsummary)

# For convenience, use the **performance** package to quickly obtain a series of standard model diagnostic charts.  

library(performance) # Functions for measuring overdispersion, autocorrelation, and other diagnostics
library(see) # to visualize diagnostics
library(ggplot2) #reload later version

mod.lm <- lm(ind2 ~ age.mu + pctF + pctP1 + S1 + C1 , data=GrpD)

library(performance)
ols.chk1 <- check_model(mod.lm,verbose=FALSE)

GrpDo <- GrpD[3:71,]  # Removes observation # 1, an outlier and influential observation

mod.lm <- lm(ind2 ~ age.mu + pctF + pctP1 + S1 + C1 , data=GrpDo)


check_model(mod.lm,verbose=FALSE)
```

<img src="GLS_Scaled0/unnamed-chunk-7-1.png" style="display: block; margin: auto;" />

The following checks for independence of residuals.

``` r
# Check residuals 
p.res <- qplot(x=as.numeric(GrpDo$t), y=residuals(mod.lm)) + 
     geom_hline(yintercept=0,lty=2, color='red') +
  xlab("time")

p.acf  <- invisible(autoplot(acf(residuals(mod.lm))))
```

``` r
p.pacf <- invisible(autoplot(pacf(residuals(mod.lm))))
```

``` r
# Durbin-Watson test. 
library(lmtest)
dw <- dwtest(mod.lm, alternative="two.sided")
```

``` r
p.res/wrap_plots(p.acf,p.pacf) + plot_annotation(
  title = "Residuals check, autocorrelation, partial autocorrelation",
  caption = paste0("Durbin-Watson test: p =", round(dw$p.value,4))) & theme_minimal()
```

![](GLS_Scaled0/autocor_patch-1.png)<!-- -->

# 4 OLS vs GLS Model Comparisons

## 4.1 Side-by-side model comparisons and ANOVA table

``` r
library(nlme)

# NULL (OLS)
mod.gls0 <- gls(ind2 ~ age.mu + pctF + pctP1 + S1 + C1 ,
                data=GrpDo, 
                correlation = NULL, method="ML")    # Null model.
# MA(1)
mod.gls1 <- gls(ind2 ~ age.mu + pctF + pctP1 + S1 + C1 , data=GrpDo, 
                      correlation = corARMA(q=1), method="ML")
# Note, for ANOVA model comparisons, models have to be fit using the same estimation method. 

models <- list(mod.gls0, mod.gls1)

modelsummary(models, output="gt", 
  fmt = 2,
  estimate="{estimate} ({std.error}){stars}",
  statistic = NULL)  %>%
  tab_header(
    title = md(glue::glue("GLS models <br> Ind2 ~ Predictors")),
     subtitle = "Fake Cohort Data") %>%
  tab_footnote(
    footnote = "Linear models regressing ind2 on age, percent identifying as female, percent 'program 1'. Completely random data. ",
    locations = cells_title(groups="title")) %>%
  tab_footnote(
    footnote = " + p ~ .1, * p <=.05, ** p<=.01, *** p<=0.001",
    locations =  cells_title(groups="title")) %>%
   cols_label(
    `Model 1` = "OLS",
    `Model 2`= "MA(1)"
  )
```

<div id="wcrigjbgfe" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#wcrigjbgfe .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#wcrigjbgfe .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#wcrigjbgfe .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#wcrigjbgfe .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#wcrigjbgfe .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#wcrigjbgfe .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#wcrigjbgfe .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#wcrigjbgfe .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#wcrigjbgfe .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#wcrigjbgfe .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#wcrigjbgfe .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#wcrigjbgfe .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#wcrigjbgfe .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#wcrigjbgfe .gt_from_md > :first-child {
  margin-top: 0;
}

#wcrigjbgfe .gt_from_md > :last-child {
  margin-bottom: 0;
}

#wcrigjbgfe .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#wcrigjbgfe .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#wcrigjbgfe .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#wcrigjbgfe .gt_row_group_first td {
  border-top-width: 2px;
}

#wcrigjbgfe .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#wcrigjbgfe .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#wcrigjbgfe .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#wcrigjbgfe .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#wcrigjbgfe .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#wcrigjbgfe .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#wcrigjbgfe .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#wcrigjbgfe .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#wcrigjbgfe .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#wcrigjbgfe .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#wcrigjbgfe .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#wcrigjbgfe .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#wcrigjbgfe .gt_left {
  text-align: left;
}

#wcrigjbgfe .gt_center {
  text-align: center;
}

#wcrigjbgfe .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#wcrigjbgfe .gt_font_normal {
  font-weight: normal;
}

#wcrigjbgfe .gt_font_bold {
  font-weight: bold;
}

#wcrigjbgfe .gt_font_italic {
  font-style: italic;
}

#wcrigjbgfe .gt_super {
  font-size: 65%;
}

#wcrigjbgfe .gt_two_val_uncert {
  display: inline-block;
  line-height: 1em;
  text-align: right;
  font-size: 60%;
  vertical-align: -0.25em;
  margin-left: 0.1em;
}

#wcrigjbgfe .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#wcrigjbgfe .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#wcrigjbgfe .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#wcrigjbgfe .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#wcrigjbgfe .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="3" class="gt_heading gt_title gt_font_normal" style>GLS models <br> Ind2 ~ Predictors<sup class="gt_footnote_marks">1,2</sup></th>
    </tr>
    <tr>
      <th colspan="3" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Fake Cohort Data</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1"> </th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">OLS</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">MA(1)</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">(Intercept)</td>
<td class="gt_row gt_center">0.05 (0.17)</td>
<td class="gt_row gt_center">0.04 (0.06)</td></tr>
    <tr><td class="gt_row gt_left">age.mu</td>
<td class="gt_row gt_center">0.06 (0.33)</td>
<td class="gt_row gt_center">0.01 (0.27)</td></tr>
    <tr><td class="gt_row gt_left">pctF</td>
<td class="gt_row gt_center">2.72 (4.46)</td>
<td class="gt_row gt_center">-0.68 (3.38)</td></tr>
    <tr><td class="gt_row gt_left">pctP1</td>
<td class="gt_row gt_center">-13.81 (7.60)+</td>
<td class="gt_row gt_center">-17.06 (6.54)*</td></tr>
    <tr><td class="gt_row gt_left">S1</td>
<td class="gt_row gt_center">-0.06 (0.24)</td>
<td class="gt_row gt_center">-0.11 (0.11)</td></tr>
    <tr><td class="gt_row gt_left" style="border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #000000;">C1</td>
<td class="gt_row gt_center" style="border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #000000;">-0.17 (0.24)</td>
<td class="gt_row gt_center" style="border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #000000;">-0.11 (0.12)</td></tr>
    <tr><td class="gt_row gt_left">Num.Obs.</td>
<td class="gt_row gt_center">69</td>
<td class="gt_row gt_center">69</td></tr>
    <tr><td class="gt_row gt_left">R2</td>
<td class="gt_row gt_center">0.060</td>
<td class="gt_row gt_center">0.038</td></tr>
    <tr><td class="gt_row gt_left">AIC</td>
<td class="gt_row gt_center">246.7</td>
<td class="gt_row gt_center">225.8</td></tr>
    <tr><td class="gt_row gt_left">BIC</td>
<td class="gt_row gt_center">262.4</td>
<td class="gt_row gt_center">243.7</td></tr>
    <tr><td class="gt_row gt_left">RMSE</td>
<td class="gt_row gt_center">1.31</td>
<td class="gt_row gt_center">1.32</td></tr>
  </tbody>
  
  <tfoot class="gt_footnotes">
    <tr>
      <td class="gt_footnote" colspan="3"><sup class="gt_footnote_marks">1</sup> Linear models regressing ind2 on age, percent identifying as female, percent 'program 1'. Completely random data. </td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="3"><sup class="gt_footnote_marks">2</sup>  + p ~ .1, * p &lt;=.05, ** p&lt;=.01, *** p&lt;=0.001</td>
    </tr>
  </tfoot>
</table>
</div>

The following runs an anova() test to see if the more complex model(s)
is/are better than the simpler model(s). Use lists, as needed, flatten
list into a data frame, apply helper functions (e.g., `pstars()`) and
organize using **gt** tab headers, footers, footnotes, etc.

``` r
a1 <- anova(mod.gls0, mod.gls1) 

models <- list(a1)
names(models) <- c("MA1 vs NULL")

options(scipen=999)

models.df <- as.data.frame(do.call(rbind, lapply(models, as.data.frame))) %>%
  mutate(model=rownames(.),
         `p-value` = pstars(`p-value`)) %>%
  dplyr::select(model, df, BIC, logLik, L.Ratio, `p-value`) %>%
  gt() %>%
  tab_header(
    title = md(glue::glue("AVOVA Result <br> GLS models with AR/MA/ARMA terms")),
     subtitle = "Fake Cohort Data") %>%
  tab_footnote(
    footnote = "Linear models regressing ind2 on age, percent identifying as female, percent 'program 1'. Completely random data. ",
    locations = cells_title(groups="title")) %>%
  tab_footnote(
    footnote = " + p ~ .1, * p <=.05, ** p<=.01, *** p<=0.001",
    locations =  cells_title(groups="title"))

models.df
```

<div id="xtalqyqpgt" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#xtalqyqpgt .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#xtalqyqpgt .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#xtalqyqpgt .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#xtalqyqpgt .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#xtalqyqpgt .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xtalqyqpgt .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#xtalqyqpgt .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#xtalqyqpgt .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#xtalqyqpgt .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#xtalqyqpgt .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#xtalqyqpgt .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#xtalqyqpgt .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#xtalqyqpgt .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#xtalqyqpgt .gt_from_md > :first-child {
  margin-top: 0;
}

#xtalqyqpgt .gt_from_md > :last-child {
  margin-bottom: 0;
}

#xtalqyqpgt .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#xtalqyqpgt .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#xtalqyqpgt .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#xtalqyqpgt .gt_row_group_first td {
  border-top-width: 2px;
}

#xtalqyqpgt .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#xtalqyqpgt .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#xtalqyqpgt .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#xtalqyqpgt .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xtalqyqpgt .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#xtalqyqpgt .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#xtalqyqpgt .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#xtalqyqpgt .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xtalqyqpgt .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#xtalqyqpgt .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#xtalqyqpgt .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#xtalqyqpgt .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#xtalqyqpgt .gt_left {
  text-align: left;
}

#xtalqyqpgt .gt_center {
  text-align: center;
}

#xtalqyqpgt .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#xtalqyqpgt .gt_font_normal {
  font-weight: normal;
}

#xtalqyqpgt .gt_font_bold {
  font-weight: bold;
}

#xtalqyqpgt .gt_font_italic {
  font-style: italic;
}

#xtalqyqpgt .gt_super {
  font-size: 65%;
}

#xtalqyqpgt .gt_two_val_uncert {
  display: inline-block;
  line-height: 1em;
  text-align: right;
  font-size: 60%;
  vertical-align: -0.25em;
  margin-left: 0.1em;
}

#xtalqyqpgt .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#xtalqyqpgt .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#xtalqyqpgt .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#xtalqyqpgt .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#xtalqyqpgt .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="6" class="gt_heading gt_title gt_font_normal" style>AVOVA Result <br> GLS models with AR/MA/ARMA terms<sup class="gt_footnote_marks">1,2</sup></th>
    </tr>
    <tr>
      <th colspan="6" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Fake Cohort Data</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">model</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">df</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">BIC</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">logLik</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">L.Ratio</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">p-value</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">MA1 vs NULL.mod.gls0</td>
<td class="gt_row gt_right">7</td>
<td class="gt_row gt_right">262.3661</td>
<td class="gt_row gt_right">-116.3637</td>
<td class="gt_row gt_right">NA</td>
<td class="gt_row gt_left">NA</td></tr>
    <tr><td class="gt_row gt_left">MA1 vs NULL.mod.gls1</td>
<td class="gt_row gt_right">8</td>
<td class="gt_row gt_right">243.6629</td>
<td class="gt_row gt_right">-104.8950</td>
<td class="gt_row gt_right">22.9373</td>
<td class="gt_row gt_left">***</td></tr>
  </tbody>
  
  <tfoot class="gt_footnotes">
    <tr>
      <td class="gt_footnote" colspan="6"><sup class="gt_footnote_marks">1</sup> Linear models regressing ind2 on age, percent identifying as female, percent 'program 1'. Completely random data. </td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="6"><sup class="gt_footnote_marks">2</sup>  + p ~ .1, * p &lt;=.05, ** p&lt;=.01, *** p&lt;=0.001</td>
    </tr>
  </tfoot>
</table>
</div>

<br>

# 5 Summary Table

``` r
modelsummary(mod.gls1, output="gt", 
  fmt = 2,
  estimate="{estimate} ({std.error}){stars}",
  statistic = NULL)  %>%
  tab_header(
    title = md(glue::glue("GLS Model <br> 1st Order Moving Average")),
     subtitle = "Fake Cohort Data") %>%
  tab_footnote(
    footnote = "Linear model regressing ind2 on age, percent identifying as female, percent 'program 1'. Completely random, made-up data. ",
    locations = cells_title(groups="title")) %>%
  tab_footnote(
    footnote = " + p ~ .1, * p <=.05, ** p<=.01, *** p<=0.001",
    locations =  cells_title(groups="title"))
```

<div id="upqsdgosiq" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#upqsdgosiq .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#upqsdgosiq .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#upqsdgosiq .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#upqsdgosiq .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#upqsdgosiq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#upqsdgosiq .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#upqsdgosiq .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#upqsdgosiq .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#upqsdgosiq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#upqsdgosiq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#upqsdgosiq .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#upqsdgosiq .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#upqsdgosiq .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#upqsdgosiq .gt_from_md > :first-child {
  margin-top: 0;
}

#upqsdgosiq .gt_from_md > :last-child {
  margin-bottom: 0;
}

#upqsdgosiq .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#upqsdgosiq .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#upqsdgosiq .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#upqsdgosiq .gt_row_group_first td {
  border-top-width: 2px;
}

#upqsdgosiq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#upqsdgosiq .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#upqsdgosiq .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#upqsdgosiq .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#upqsdgosiq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#upqsdgosiq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#upqsdgosiq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#upqsdgosiq .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#upqsdgosiq .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#upqsdgosiq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#upqsdgosiq .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#upqsdgosiq .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#upqsdgosiq .gt_left {
  text-align: left;
}

#upqsdgosiq .gt_center {
  text-align: center;
}

#upqsdgosiq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#upqsdgosiq .gt_font_normal {
  font-weight: normal;
}

#upqsdgosiq .gt_font_bold {
  font-weight: bold;
}

#upqsdgosiq .gt_font_italic {
  font-style: italic;
}

#upqsdgosiq .gt_super {
  font-size: 65%;
}

#upqsdgosiq .gt_two_val_uncert {
  display: inline-block;
  line-height: 1em;
  text-align: right;
  font-size: 60%;
  vertical-align: -0.25em;
  margin-left: 0.1em;
}

#upqsdgosiq .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#upqsdgosiq .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#upqsdgosiq .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#upqsdgosiq .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#upqsdgosiq .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  <thead class="gt_header">
    <tr>
      <th colspan="2" class="gt_heading gt_title gt_font_normal" style>GLS Model <br> 1st Order Moving Average<sup class="gt_footnote_marks">1,2</sup></th>
    </tr>
    <tr>
      <th colspan="2" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Fake Cohort Data</th>
    </tr>
  </thead>
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1"> </th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Model 1</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">(Intercept)</td>
<td class="gt_row gt_center">0.04 (0.06)</td></tr>
    <tr><td class="gt_row gt_left">age.mu</td>
<td class="gt_row gt_center">0.01 (0.27)</td></tr>
    <tr><td class="gt_row gt_left">pctF</td>
<td class="gt_row gt_center">-0.68 (3.38)</td></tr>
    <tr><td class="gt_row gt_left">pctP1</td>
<td class="gt_row gt_center">-17.06 (6.54)*</td></tr>
    <tr><td class="gt_row gt_left">S1</td>
<td class="gt_row gt_center">-0.11 (0.11)</td></tr>
    <tr><td class="gt_row gt_left" style="border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #000000;">C1</td>
<td class="gt_row gt_center" style="border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #000000;">-0.11 (0.12)</td></tr>
    <tr><td class="gt_row gt_left">Num.Obs.</td>
<td class="gt_row gt_center">69</td></tr>
    <tr><td class="gt_row gt_left">R2</td>
<td class="gt_row gt_center">0.038</td></tr>
    <tr><td class="gt_row gt_left">AIC</td>
<td class="gt_row gt_center">225.8</td></tr>
    <tr><td class="gt_row gt_left">BIC</td>
<td class="gt_row gt_center">243.7</td></tr>
    <tr><td class="gt_row gt_left">RMSE</td>
<td class="gt_row gt_center">1.32</td></tr>
  </tbody>
  
  <tfoot class="gt_footnotes">
    <tr>
      <td class="gt_footnote" colspan="2"><sup class="gt_footnote_marks">1</sup> Linear model regressing ind2 on age, percent identifying as female, percent 'program 1'. Completely random, made-up data. </td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="2"><sup class="gt_footnote_marks">2</sup>  + p ~ .1, * p &lt;=.05, ** p&lt;=.01, *** p&lt;=0.001</td>
    </tr>
  </tfoot>
</table>
</div>

# 6 Software acknowledgements (Most recent updates)

Thomas Lin Pedersen (2020). patchwork: The Composer of Plots. R package
version 1.1.1. <https://CRAN.R-project.org/package=patchwork>

Wickham et al., (2019). Welcome to the tidyverse. Journal of Open Source
Software, 4(43), 1686, <https://doi.org/10.21105/joss.01686>

Pinheiro J, Bates D, DebRoy S, Sarkar D, R Core Team (2021). *nlme:
Linear and Nonlinear Mixed Effects Models*. R package version 3.1-153,
\<URL: <a href="https://CRAN.R-project.org/package=nlme\"
class="uri">https://CRAN.R-project.org/package=nlme\</a>\>.

Hyndman R, Athanasopoulos G, Bergmeir C, Caceres G, Chhay L, O’Hara-Wild
M, Petropoulos F, Razbash S, Wang E, Yasmeen F (2022). *forecast:
Forecasting functions for time series and linear models*. R package
version 8.17.0, \<URL: <a href="https://pkg.robjhyndman.com/forecast/\"
class="uri">https://pkg.robjhyndman.com/forecast/\</a>\>.

Hyndman RJ, Khandakar Y (2008). “Automatic time series forecasting: the
forecast package for R.” *Journal of Statistical Software*, *26*(3),
1-22. doi: 10.18637/jss.v027.i03 (URL:
<https://doi.org/10.18637/jss.v027.i03>).

Debin Qiu (2015). aTSA: Alternative Time Series Analysis. R package
version 3.1.2. <https://CRAN.R-project.org/package=aTSA>

Richard Iannone, Joe Cheng and Barret Schloerke (2022). gt: Easily
Create Presentation-Ready Display Tables. R package version 0.6.0.
<https://CRAN.R-project.org/package=gt>

Achim Zeileis, Torsten Hothorn (2002). Diagnostic Checking in Regression
Relationships. R News 2(3), 7-10. URL
<https://CRAN.R-project.org/doc/Rnews/>

Thomas Lin Pedersen (2020). patchwork: The Composer of Plots. R package
version 1.1.1. <https://CRAN.R-project.org/package=patchwork>

Arel-Bundock V (2022). “modelsummary: Data and Model Summaries in R.”
*Journal of Statistical Software*, *103*(1), 1-23. doi:
10.18637/jss.v103.i01 (URL: <https://doi.org/10.18637/jss.v103.i01>).

Lüdecke et al., (2021). see: An R Package for Visualizing Statistical
Models. Journal of Open Source Software, 6(64), 3393.
<https://doi.org/10.21105/joss.03393>

H. Wickham. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag
New York, 2016.
