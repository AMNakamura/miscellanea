---
title: "List Processing - Demo"
author: "Ann"
date: "7/27/2022"
output: html_document
---

# Using lists in R

## FakeCohort1

Examples use fake data, created using random group and variable assignment. `FakeCohort1` contains a unique identifier (ID), a group membership (GRP1--GRP4), a program membership (PGM1--PGM3), some demographics (age), dates (MO,YR,dt), and a couple of numeric variables (ind1 and ind2). The data can be used for time-series analysis or other purposes. 


```{r, message=FALSE, warning=FALSE, comment=NA}

setwd("~/Misc")
library(pins)
board <- board_rsconnect(auth="envvar") 

```

## A brief introduction to 'objects'

R is a 'functional programming language', which means it uses functions (e.g., sum()) that can be used and reused. 
R also supports 'object oriented programming' (OOP), where 'objects' bring together data and attributes about the data. For example, when you create a regression model (e.g., `mod <- lm(data=df, y~x)`), the model object (e.g., `mod`) contains the original values, the predicted values, residuals, model terms (i.e., the formula), regression coefficients, and other information -- all in one. 

Everything in R is actually an object. 

## Lists

Lists are special R objects that act like containers. Lists can contain a collection of objects, like data frames, plots, images, vectors, or even other lists. These objects don't have to be the same. A list can contain a data frame, a plot, and a number (scalar), for example.  

Creating a list is simple. Typing `mylist <= list()` creates an empty list object called `mylist`. 



```{r, message=FALSE, warning=FALSE, comment=NA}

mylist <- list("Red",                                # Character value (hair color)
               c("Green","Blue"),                    # Character vector with two columns (eye color)
               seq(1:7),                             # Sequence of 7 integers (days of the week)
               TRUE,                                 # Logical value
               5,                                    # Numeric value
               list("1999 Jeep Wrangler","1969 Mustang","1967 Kharman Ghia"))       # List of cars

```

## Accessing members of a list 

There are two ways to access list members or 'elements', by using single brackets [] or double brackets [[]]. Use double brackets [[]] if you only want one element. Use single brackets [] if you want a list returned. 

List members can be accessed by the index of the element (the location in the list) or by the name.

### Accessing by index

```{r, message=FALSE, warning=FALSE, comment=NA}

Hair1 <- mylist[1]         # List of 1 (list containing one character value)
Hair2 <- mylist[[1]]       # The character value ("Red")


car1 <- mylist[6]          # List of of 1 (a list containing 1 element: a list with 3 values)
car2 <- mylist[[6]]        # List of 3 (a list containing 3 elements: three lists with one value each )
car3 <- mylist[[6]][1]     # List of 1 (a list containing 1 element: a character value of "Toyota")
car4 <- mylist[[6]][[1]]   # A character value

```

### Accessing by name 


```{r, message=FALSE, warning=FALSE, comment=NA}

names(mylist) <- c("Hair Color", "Eye Color", "days", "TrueFalse", "A number", "Cars I want")

mylist["Cars I want"]
mylist[["Cars I want"]][[3]]

```
# Using lists to boost efficiency

## Applying a function to a list

The function, `lapply` stands for 'list apply'. Use it to apply a function to each list element and get a list returned. 

The function, `sapply` stands for 'simplified list apply'. Use it to get a vector returned. 

Use `lapply` or `sapply`, depending on how you want to use the results. They both operate similarly to a loop (e.g., for each element in the array, do the following).

```{r, message=FALSE, warning=FALSE, comment=NA}

lapply(mylist, length)
sapply(mylist, length)

```

## FOR loop example

### Start by filling a list with objects

```{r, message=FALSE, warning=FALSE, comment=NA}

# Find a useful way to identify the elements. 

df$GRPid <- as.numeric(gsub("[[:alpha:]]", "", df$GRP)) # Remove the letters and just leave the number

library(tidyverse) # Attach ggplot, tidyr, stringr, and other commonly used packages

glst <- sort(unique(df$GRP))

series <- list()
plots   <- list()

for (g in glst){
  
i  <- as.numeric(gsub("[[:alpha:]]", "", g))  

series[[i]] <- subset(df, GRP == g) %>%
               arrange(YR) %>%
               group_by(YR) %>%
               summarize(age.med = median(age),
                  ind1    = mean(ind1),
                  ind2    = mean(ind2))

plots[[i]] <- ggplot(data = series[[i]], aes(x=YR,y=ind2)) +
                geom_point(color=i) +
                geom_line( aes(group=1), linetype = i) +
                labs(title = glue::glue("ind2 by year for {g}"))
}

```


```{r, message=FALSE, warning=FALSE, comment=NA}

series

```

```{r, message=FALSE, warning=FALSE, fig.align='center', comment=NA}

plots

```

# Getting started with pins


```{r,eval=FALSE}

# To use RStudio Connect board, first authenticate. Add the CONNECT_API_KEY and CONNECT_SERVER to the .Renviron file
# usethis::edit_r_environ()
# Add the key and server name as environmental variables.
# CONNECT_API_KEY=xxx
# CONNECT_SERVER=url

# Creating a pin

library(pins)
# authenticate and define the board. `board` is a variable used in the pin() command later. 
# auth = "envvar" uses environment variables CONNECT_API_KEY and CONNECT_SERVER.
board <- board_rsconnect(auth="envvar") 

df <- read.csv('MyDataPath', header=TRUE, sep='|')

# Do some manipulation, if wanted.
write.csv(df,"FakeCohort1.csv", row.names = FALSE)

pin("FakeCohort1.csv",    description = "Fake cohort for testing purposes")

```
