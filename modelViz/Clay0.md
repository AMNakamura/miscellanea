Path Exploration - Clay Compression
================
A. Nakamura

-   <a href="#1-purpose" id="toc-1-purpose">1 Purpose</a>
-   <a href="#2-data-prep" id="toc-2-data-prep">2 Data Prep</a>
-   <a href="#3-data-exploration" id="toc-3-data-exploration">3 Data
    exploration</a>
    -   <a href="#31-create-the-palette" id="toc-31-create-the-palette">3.1
        Create the palette</a>
    -   <a href="#32-quick-eyeball-checks-on-missingness"
        id="toc-32-quick-eyeball-checks-on-missingness">3.2 Quick eyeball checks
        on missingness</a>
    -   <a href="#33-pairwise-correlations"
        id="toc-33-pairwise-correlations">3.3 Pairwise correlations</a>
    -   <a href="#34-variable-spread-and-distribution-checks"
        id="toc-34-variable-spread-and-distribution-checks">3.4 Variable spread
        and distribution checks</a>
    -   <a href="#35-choose-the-estimation-method"
        id="toc-35-choose-the-estimation-method">3.5 Choose the estimation
        method</a>
    -   <a href="#36-measure-some-possible-relationships-between-variables"
        id="toc-36-measure-some-possible-relationships-between-variables">3.6
        Measure some possible relationships between variables</a>
    -   <a href="#37-explore-relationships-with-a-path-diagram"
        id="toc-37-explore-relationships-with-a-path-diagram">3.7 Explore
        relationships with a path diagram</a>
-   <a href="#4-references" id="toc-4-references">4 References</a>
-   <a href="#5-software-acknowledgements"
    id="toc-5-software-acknowledgements">5 Software acknowledgements</a>

# 1 Purpose

Explore materials data from Löfman and Korkiala-Tantuu’s [partial
multivariate database of Finnish clay
soils](https://www.tandfonline.com/doi/suppl/10.1080/17499518.2020.1864410?scroll=top),
generously provided among supplemental materials with their study of
transformation models to measure compressibility of Finnish clays. I
don’t source clay from Finland for my ceramic work, but I am generally
interested in clay properties and sharing code.

# 2 Data Prep

Load the data and add some meaningful variable names.

``` r
getwd()
```

    ## [1] "C:/Users/Kevin/Documents/RProjects/RGitHub/rtemp/analytics_staging/analytics-staging"

``` r
library(readxl)
library(tidyverse)

db0 <- read_excel("~/RProjects/RGitHub/DATA/Table_S1_FI_CLAY_14_856_noheader.xlsx") 
db0$soil <- recode(db0$soil.type, Sa = "clay", liSa = "fat clay", laSa = "lean clay", 
                   saSi = "clayey silt", ljSa = "organic clay", ljSi = "organic silt", 
                   saLj = "clayey gyttja", Lj = "gyttja", Si = "silt")
db0 <- db0 %>% dplyr::select(-No.)


db0 <- db0 %>%
  mutate(soil = as.factor(ifelse(soil %in% c("clay", "fat clay", "lean clay", 
                   "clayey silt", "organic clay", "organic silt", 
                   "clayey gyttja", "gyttja", "silt"), soil,'other')))
```

# 3 Data exploration

Key variables include:

-   soil type: Type of soil (e.g., clay, silt)
-   compression: Compression index, predictor of the compressibility of
    soil
-   void.ratio: Ratio of void (empty space) to solids. Related to
    pourosity.
-   plastic.limit: Moisture content at which soil begins to crumble.
-   liquid.limit: Moisture content where the soil begins to act as a
    liquid
-   swelling.index: Amount expected to swell, vs. dry volume, at full
    saturation.
-   water.content: Difference between moist soil and soil at oven-dry
    weight.
-   unit.weight: Weight divided by volume
-   undrained.strength: Amount of shear stress (pushing and pulling in
    different directions) the soil can sustain.
-   insitu.stress: Stress level of soil at rest - before excavation, for
    example.
-   pre.pressure: pre-consolidation pressure, the most vertical stress
    the soil has sustained previously. Helps figure out expected
    settlement of embankments.
-   ocr: overconsolidation ratio (OCR), the ratio of the most stress
    ever experienced to the present stress (e.g., before and after being
    weighted down by a structure).

## 3.1 Create the palette

For visualizing data with with many potential variables, it helps me to
pick a palette generator ahead of time, one that can increase and
decrease in size without changing the general look and feel too much.

Using the \*\*R Graphics Devices\*, the `hcl()` and `colorRampPalette()`
functions can create the palette members and a function to generate a
palette of any size.

-   `hcl()` creates a vector of colors from vector triplets describing
    hue (the color), chroma (amount of grey), and luminance (amount of
    white).
-   `colorRampPalette()` creates a function that returns a vector of
    colors to create new color palettes. The parameter, passed to
    `ramp1()` will create a new palette in the same color scheme with
    the given number of values. This is helpful for creating large,
    colorblind-friendly palettes. e

``` r
# hcl() takes a triplet(hue, chroma, intensity)

# First two columns: dark to light red. Same hue and saturation, with two increasing values for luminance. 
ramp1 = colorRampPalette(c(hcl(0,100,  # h= 0  (red),  chroma = 100 (lots of grey)
                           c(10,100)), # luminance (how much white to add): 10 and 100 
                           
# Next two columns: light to dark blue. Same hue and saturation, with two decreasing values for luminance. 
                           hcl(245,50, # h = 245 (bluish), chroma = 50 (a little grey)
                           c(50,10)))  # luminance (how much white to add): 50 and 10 
                           )
```

## 3.2 Quick eyeball checks on missingness

Get a sense of missing variables before proceeding. Only columns
containing at least 90% non-missing values will be used for exploration.
Note that you can use the `+` operator add graph components to enhance
the output from the `inspect_*()` function.

``` r
suppressMessages(library(inspectdf))

# Create a palette-generating function

inspect_na(db0) %>% show_plot() +
  labs(title="Percent Missing, Original Dataset",
       caption = "Data from Löfman and Korkiala-Tantuu, 'Partial multivariate database of Finnish clay soils'") + 
 theme_minimal() + 
 theme(axis.text.x=element_text(angle=90,hjust=1)) + # override the default angle in theme_minimal.
  scale_fill_manual(values=ramp1(33)) 
```

<img src="Clay0_files/figure-gfm/plotna-1.png" style="display: block; margin: auto;" />

``` r
z <- inspect_na(db0) %>%
dplyr::filter(pcnt < 10)

vars <- z$col_name

db1 <- db0[vars] %>%
  dplyr::select(-c(Point,soil.type,Reference,Site,depth.upper, depth.lower,test))

inspect_types(db1) %>% show_plot()+
  labs(title="Variable Types, Restricted Dataset",
       caption = "Data from Löfman and Korkiala-Tantuu, \n'Partial multivariate database of Finnish clay soils'\nRestricted to columns with less than 10% missing values.") + 
 
scale_fill_manual(values=ramp1(3)) 
```

<img src="Clay0_files/figure-gfm/inspectTypes-1.png" style="display: block; margin: auto;" />

## 3.3 Pairwise correlations

Visually inspect pairwise correlations using the **gclus** package.
Create the correlation matrix, set the colors to the custom palette
created earlier, and reorder the variables so that those most similar
are adjacent.

``` r
library(gclus) # clustering graphics


db1 <- db1[complete.cases(db1), ]  # remove any rows where one or more columns are missing

db.n <- db1 %>%
 select_if(., is.numeric)   # Numerics

db.f <- db1 %>%
  select_if(.,is.factor)    # Character (factor)

# Correlation (absolute)
corr <- abs(cor(db.n)) 

colors <- dmat.color(corr, colors=ramp1(64))
order <-  order.single(corr)

names(db.n)
```

    ## [1] "unit.weight"   "ocr"           "depth.avg"     "insitu.stress"
    ## [5] "pre.pressure"  "void.ratio"    "water.content" "compression"

``` r
cpairs(db.n,                    # Data frame with numerics
       order,                   # Sort order 
       panel.colors = colors,   # Matrix of panel colors, based on the correlation values
       border.color = "grey70", # Border color
       gap = 0.45,              # Distance between subplots
       main = "Ordered variables colored by correlation", # Main title
       show.points = TRUE,      # If FALSE, removes all the points
       pch = 21,                # pch plotting symbol (circle)
       bg = rainbow(6)[db1$soil], # Colors by group
       cex.labels=1,
       oma=c(.5,1,1.5,15))   
  legend("topright", fill = unique(db.f$soil), legend = c( levels(db.f$soil)),cex=.7,inset = c(-.01,.01),box.col='white')
```

<img src="Clay0_files/figure-gfm/corgraph-1.png" style="display: block; margin: auto;" />

## 3.4 Variable spread and distribution checks

Take a look at the distributions. Plot histograms to see the
distribution patterns for the various columns, then run a quick check
for multivariate normality to see what approach makes the most sense for
fitting the CFA model later (for maximum likelihood estimation, data
need to be multivariate normal).

``` r
library(patchwork) # to neaten up graph layouts

plot.hist <- function(var){
  
  col.name <- db.n %>% dplyr::select(!!enquo(var)) %>%
    rename(v = 1)
  
  ggplot(db.n,aes(x = !!enquo(var))) +
    geom_histogram(aes(y =..density..),
                   colour = "black", 
                   fill = "white" ) +
labs(title= deparse(substitute(var))) +
 theme_minimal()
  
}

p1 <- plot.hist(unit.weight)
p2 <- plot.hist(ocr)
p3 <- plot.hist(depth.avg) 
p4 <- plot.hist(insitu.stress) 
p5 <- plot.hist(pre.pressure) 
p6 <- plot.hist(void.ratio) 
p7 <- plot.hist(water.content) 
p8 <- plot.hist(compression) 

p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8 +
  plot_layout(ncol=3)
```

<img src="Clay0_files/figure-gfm/histos-1.png" style="display: block; margin: auto;" />

``` r
## Compression is right skewed. Try a square root transformation to
## get a more normal distribution.   

db.n$compression.sqrt <- sqrt(db.n$compression)
p9 <- plot.hist(compression.sqrt)  

p8 + p9
```

<img src="Clay0_files/figure-gfm/histos-2.png" style="display: block; margin: auto;" />

``` r
db.t <- db.n %>% dplyr::select(-compression)
```

``` r
library(semTools) # For the mardiaSkew function

mardiaSkew(db.t[,1:7], use = "everything")
```

    ##        b1d        chi         df          p 
    ##   127.1129 15507.7745    84.0000     0.0000

``` r
mardiaKurtosis(db.t, use = "everything")
```

    ##      b2d        z        p 
    ## 273.8086 207.2711   0.0000

## 3.5 Choose the estimation method

If the data were normally distributed, the CFA model could be fit using
maximum likelihood (ML) estimation. Since anything beyond the previous
transformation feels like data torture, use one of the alternate
estimation methods available in the **lavaan** package.

-   MLR (robust ML): for non-normal data
-   WLSMV (robust weighted least squares): for categorical responses

``` r
library(lavaan)   # Latent variable analysis.
library(semPlot)  # Path diagrams
library(OpenMx)   # Extended structural equation models
library(GGally)   # For graphing
```

## 3.6 Measure some possible relationships between variables

Fit a CFA model, using lavaan model syntax, which can be expressed (as
below) as a system of formulas (or system of nested relationships) among
variables with the response on the left, predictors on the right, and a
tilde (`~`) in between. See [this
tutorial](https://lavaan.ugent.be/tutorial/syntax1.html) for an
accessible description of the syntax for latent variables (`=~`),
intercepts (`~`), and variance/covariance (`~~`) relationships. Models
need to be enclosed in singe quotes.

The `cfa()` function will create a lavaan object representing the fitted
CFA model, assuming some theoretical and potentially comically overly
simplified relationships between compression, water content, unit
weight, and in-situ stress.

``` r
model1 = 'compression.sqrt ~ unit.weight + insitu.stress + pre.pressure + void.ratio + water.content 
void.ratio ~ water.content + unit.weight
insitu.stress ~ pre.pressure'

fit1 = lavaan::cfa(model1, data = db.t, estimator = "MLR")

s <- summary(fit1, fit.measures = TRUE, standardized = TRUE, rsquare = TRUE)
```

## 3.7 Explore relationships with a path diagram

To explore the structural component of the model, create a path diagram,
which will show how the predictors and response are related. Display the
model as an unweighted network.

-   Rectangles = observed variables
-   Ellipses = latent variables
-   Curves with beginning and ending arrows =
    correlations/variance/covariance
-   Straight lines with one arrow: paths linking the predicting to
    predicted.

Add labels using `nodeLabels` and `sizeMan` parameters in the
`lavaan::semPaths()` function to improve readability. Using `std` for
the `what` parameter will display standardized parameter estimates
(i.e., unit change, in standard deviations, of the response associated
with one standard deviation change of the predictor). The **semtools**
package helps customize CFA and other SEM plots (e.g., dropping
nodes,bending or straightening curves, and adding significance values).

``` r
library(semptools)

path1 <- semPaths(fit1, 'std', layout = 'tree2', 
                  sizeMan=10,nCharNodes = 0, nCharEdges = 0,
                  color = c('lightblue','white','white','white','white','white'))
```

<img src="Clay0_files/figure-gfm/paths-1.png" style="display: block; margin: auto;" />

``` r
path1.1 <- change_node_label(path1,
                           c(compression.sqrt = "\u221A \nCompress",
                             unit.weight = "Unit \nWeight",
                             pre.pressure = "Pre-\nConsol\nPressure",
                             water.content = "Water \nContent",
                             void.ratio = "Void \nRatio",
                             insitu.stress = "In-situ \nStress"),
                           label.cex = 1.1) 
```

# 4 References

Transformation models for the compressibility properties of Finnish
clays using a multivariate database. Taylor & Francis. Löfman, Monica
Susanne; Korkiala-Tanttu, Leena Katariina.

# 5 Software acknowledgements

#### 5.0.0.1 Updated to reflect the latest versions as of 8/2022.

Hadley Wickham and Jennifer Bryan (2022). readxl: Read Excel Files. R
package version 1.4.0. <https://CRAN.R-project.org/package=readxl>

Wickham et al., (2019). Welcome to the tidyverse. Journal of Open Source
Software, 4(43), 1686, <https://doi.org/10.21105/joss.01686>

Alastair Rushworth (2021). inspectdf: Inspection, Comparison and
Visualisation of Data Frames. R package version 0.0.11.
<https://CRAN.R-project.org/package=inspectd>

Catherine Hurley (2019). gclus: Clustering Graphics. R package version
1.3.2. <https://CRAN.R-project.org/package=gclus>

Thomas Lin Pedersen (2020). patchwork: The Composer of Plots. R package
version 1.1.1. <https://CRAN.R-project.org/package=patchwork>

Thomas D. Fletcher (2022). QuantPsyc: Quantitative Psychology Tools. R
package version 1.6. <https://CRAN.R-project.org/package=QuantPsyc>

Jorgensen, T. D., Pornprasertmanit, S., Schoemann, A. M., & Rosseel, Y.
(2022). semTools: Useful tools for structural equation modeling. R
package version 0.5-6. Retrieved from
<https://CRAN.R-project.org/package=semTools>

Yves Rosseel (2012). lavaan: An R Package for Structural Equation
Modeling. Journal of Statistical Software, 48(2), 1-36.
<https://doi.org/10.18637/jss.v048.i02>

Sacha Epskamp (2022). semPlot: Path Diagrams and Visual Analysis of
Various SEM Packages’ Output. R package version 1.1.6.
<https://CRAN.R-project.org/package=semPlot>

Michael C. Neale, Michael D. Hunter, Joshua N. Pritikin, Mahsa Zahery,
Timothy R. Brick Robert M. Kirkpatrick, Ryne Estabrook, Timothy C.
Bates, Hermine H. Maes, Steven M. Boker. (2016). OpenMx 2.0: Extended
structural equation and statistical modeling. Psychometrika, 81(2),
535-549. <doi:10.1007/s11336-014-9435-8>

Pritikin, J. N., Hunter, M. D., & Boker, S. M. (2015). Modular
open-source software for Item Factor Analysis. Educational and
Psychological Measurement, 75(3), 458-474

Hunter, M. D. (2018). State space modeling in an open source, modular,
structural equation modeling environment. Structural Equation Modeling,
25(2), 307-324. doi: 10.1080/10705511.2017.1369354

Steven M. Boker

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Michael C. Neale

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Hermine H. Maes

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Michael J. Wilde

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Michael Spiegel

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Timothy R. Brick

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Ryne Estabrook

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Timothy C. Bates

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Paras Mehta

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Timo von Oertzen

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Ross J. Gore

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Michael D. Hunter

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Daniel C. Hackett

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Julian Karch

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Andreas M. Brandmaier

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Joshua N. Pritikin <jpritikin@pobox.com>

![aut, cre](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut%2C%20cre "aut, cre")

, Mahsa Zahery

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Robert M. Kirkpatrick

![aut](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;aut "aut")

, Yang Wang

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Ben Goodrich <goodrich.ben@gmail.com>

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Charles Driver <driver@mpib-berlin.mpg.de>

![ctb](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;ctb "ctb")

, Massachusetts Institute of Technology

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, S. G. Johnson

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Association for Computing Machinery

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Dieter Kraft

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Stefan Wilhelm

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Sarah Medland

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Carl F. Falk

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Matt Keller

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Manjunath B G

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, The Regents of the University of California

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Lester Ingber

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Wong Shao Voon

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Juan Palacios

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Jiang Yang

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

, Gael Guennebaud

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

and Jitse Niesen

![cph](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;cph "cph")

. (2022) OpenMx 2.20.6 User Guide.

Barret Schloerke, Di Cook, Joseph Larmarange, Francois Briatte, Moritz
Marbach, Edwin Thoen, Amos Elberg and Jason Crowley (2021). GGally:
Extension to ‘ggplot2’. R package version 2.1.2.
<https://CRAN.R-project.org/package=GGally>

Shu Fai Cheung and Mark Hok Chio Lai (2021). semptools: Customizing
Structural Equation Modelling Plots. R package version 0.2.9.3.
<https://CRAN.R-project.org/package=semptools>
