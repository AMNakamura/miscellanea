Make Fake Survey Data 1
================
Ann Nakamura
orig: 7/15/2017. updates: 8/2/2021

# Make some fake survey data

The following code makes use of [MLRun’s demo-stocks
“reviews”](https://github.com/mlrun/demo-stocks) dataset for sentiment
analysis, topic modeling, and other analyses of text, adding some
additional columns with random rating panels.

``` r
GRPS  <- c("Business Operations","Technical and Scientific")


# Obtain some comment fields from the "reviews" list. Divide into five separate columns that can be used as dummy free responses (four L's plus one overall comment). 

# Load file
raw <- read.csv(file = 'https://raw.githubusercontent.com/mlrun/demo-stocks/master/data/reviews.csv',nrows=500)

# Split and recreate
lst  <- list()

for(i in 1:5){
  n1 <- (i-1)*100 + 1
  n2 <- (i)*100  
  print(paste(n1,n2,sep="-"))
  lst[[i]] <- raw[n1:n2,c(3)]  
}
```

    ## [1] "1-100"
    ## [1] "101-200"
    ## [1] "201-300"
    ## [1] "301-400"
    ## [1] "401-500"

``` r
raw.new <- do.call(cbind, lst)

# Add some additional columns, convert from matrix to data frame

suppressMessages(library(dplyr))


df <- as.data.frame(raw.new)
df$ID <- seq(1:nrow(df)) 

df <- df %>%
  mutate(grp = sample(GRPS,  nrow(df),replace=TRUE),
         YrStarted   = sample(2010:2017, nrow(df), replace=TRUE)) 

# Add eight new columns with random ratings
for(i in 1:8) {                                   
  tmp <- sample(1:8, nrow(df), replace = TRUE)    # tmp column
  df[ , ncol(df) + 1] <- tmp                    # Append to the end
  colnames(df)[ncol(df)] <- paste0("Q16_", i)     # Increment name
}

# Add another eight new columns with random ratings
for(i in 1:8) {                                   
  tmp <- sample(1:8, nrow(df), replace = TRUE)    # tmp column
  df[ , ncol(df) + 1] <- tmp                    # Append to the end
  colnames(df)[ncol(df)] <- paste0("Q18_", i)     # Increment name
}

# Introduce some missing values in selected fields. 

df[,c(1:5,8:24)] <- apply (df[,c(1:5,8:24)], 2, function(x) {x[sample( c(1:nrow(df)), floor(nrow(df)/25))] <- NA; x} )
```

# Data Checks

The following prints out quick data profiles to serve as sanity checks
before using the fake data for any actual testing.

``` r
suppressMessages(library(inspectdf))
suppressMessages(library(tidyverse))


inspect_types(df) %>% show_plot()
```

![](MakeAFakeSurvey1_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

``` r
inspect_na(df) %>% show_plot()
```

![](MakeAFakeSurvey1_files/figure-gfm/unnamed-chunk-2-2.png)<!-- -->

# Customizing labels

Customize as needed to mimic data extracted from sources like SPSS or
the Qualtrics API, where data will be labeled already. For Qualtrics,
the labels will match the survey question text.

The sample below applies labels used for a 4L’s retrospective and
identically labeled panels for an Importance-Satisfaction matrix.

``` r
suppressMessages(library(Hmisc))

var.labels = 
  c(V1 = "I really liked", 
    V2 = "I've learned", 
    V3 = "This could have been better",
    V4 = "I would have really liked", 
    V5 = "Thinking back to your experiences in the last six months, do you have any general comments?",
    YrStarted = "What year did you join the project", 
    
    Q16_1="Component1",
    Q16_2="Component2",
    Q16_3="Component3",
    Q16_4="Component4",
    Q16_5="Component5",
    Q16_6="Component6",
    Q16_7="Component7",
    Q16_8="Component8",
    
    Q18_1="Component1",
    Q18_2="Component2",
    Q18_3="Component3",
    Q18_4="Component4",
    Q18_5="Component5",
    Q18_6="Component6",
    Q18_7="Component7",
    Q18_8="Component8")

label(df) = as.list(var.labels[match(names(df),names(var.labels))])
```

    ## Output file written: C:\Users\Kevin\Documents\RProjects\RGitHub\r\DataOps\MkSrvy1DfSummary.html

![](MakeAFakeSurvey1_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-R-summarytools" class="csl-entry">

Comtois, Dominic. 2022. *Summarytools: Tools to Quickly and Neatly
Summarize Data*. <https://github.com/dcomtois/summarytools>.

</div>

<div id="ref-R-Hmisc" class="csl-entry">

Harrell, Frank E, Jr. 2022. *Hmisc: Harrell Miscellaneous*.
<https://hbiostat.org/R/Hmisc/>.

</div>

<div id="ref-R-inspectdf" class="csl-entry">

Rushworth, Alastair. 2021. *Inspectdf: Inspection, Comparison and
Visualisation of Data Frames*.
<https://alastairrushworth.github.io/inspectdf/>.

</div>

<div id="ref-R-tidyverse" class="csl-entry">

Wickham, Hadley. 2021. *Tidyverse: Easily Install and Load the
Tidyverse*. <https://CRAN.R-project.org/package=tidyverse>.

</div>

<div id="ref-tidyverse2019" class="csl-entry">

Wickham, Hadley, Mara Averick, Jennifer Bryan, Winston Chang, Lucy
D’Agostino McGowan, Romain François, Garrett Grolemund, et al. 2019.
“Welcome to the <span class="nocase">tidyverse</span>.” *Journal of Open
Source Software* 4 (43): 1686. <https://doi.org/10.21105/joss.01686>.

</div>

<div id="ref-R-dplyr" class="csl-entry">

Wickham, Hadley, Romain François, Lionel Henry, and Kirill Müller. 2022.
*Dplyr: A Grammar of Data Manipulation*.
<https://CRAN.R-project.org/package=dplyr>.

</div>

</div>
