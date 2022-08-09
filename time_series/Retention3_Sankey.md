Measuring and Visualizing Retention
================
Ann Nakamura
2/4/2019

-   [1 Use Case](#1-use-case)
-   [2 Member Retention from Year to
    Year](#2-member-retention-from-year-to-year)
    -   [2.1 Data preparation](#21-data-preparation)
    -   [2.2 Add node information](#22-add-node-information)
    -   [2.3 Create the edge list](#23-create-the-edge-list)
-   [3 Graphs](#3-graphs)
    -   [3.1 Network Flow](#31-network-flow)
    -   [3.2 Sankey Diagram for Year to Year
        Changes](#32-sankey-diagram-for-year-to-year-changes)
    -   [3.3 Network Graphs to Visualize Movement Between
        Groups](#33-network-graphs-to-visualize-movement-between-groups)
-   [4 Packages](#4-packages)
-   [5 References](#5-references)

<h1 style="color: #154c79">

Using Network Diagrams

</h1>

# 1 Use Case

Create a quick visualization, using network diagrams and alluvial plots
to examine growth and retention for group members who enter and exit at
random points in time. Uses a [Fake
cohort](https://raw.githubusercontent.com/AMNakamura/miscellanea/master/datasets/FakeCohort1.txt)
for demonstration purposes.

``` r
library(tidyverse)   # adding variables, other data manipulation
library(lubridate)

db1 <- read.table("https://raw.githubusercontent.com/AMNakamura/miscellanea/master/datasets/FakeCohort1.txt",sep="|",header=T) %>% 
  group_by(ID,YR,MO,GRP) %>%
  summarise(IND = sum(ind1)) %>%
  dplyr::select(ID,YR,MO,GRP,IND) %>%
  mutate(dt = as.Date(paste(YR,MO,"01",sep="-"))) # set to first of the month for simplicity
```

# 2 Member Retention from Year to Year

The next step collapses the data frame on member ID and Year and creates
lists of nodes and edges.

## 2.1 Data preparation

Create an aggregate dataframe to use in the creation of nodes (vertices)
and edges. Use a sample for “Group 2”.

``` r
df <- subset(db1,GRP == "GRP2") %>% 
  ungroup() %>%
  dplyr::filter(IND > 0) %>%
  group_by(ID,YR) %>%
  summarize(IND=mean(IND)) %>%
  ungroup() 
```

## 2.2 Add node information

Add statistics or other information to describe the nodes (e.g., year).
These can be used to define visual elements (e.g., size and color).

``` r
node.stats <- df %>%
  group_by(YR) %>%
  summarize(member.ttl = n_distinct(ID),
            ind.mu     = mean(IND),
            ind.med    = median(IND)) %>%
  rename(V = YR)

NodeCols <- unique(node.stats$V)

last.per <- max(node.stats$V)

nodeInfo <- as.data.frame(NodeCols,stringsAsFactors = FALSE) %>%
  rename(V = NodeCols) %>%
  left_join(.,node.stats,by="V")
```

## 2.3 Create the edge list

The following performs a self-join to create an edge list, with all
pairwise year combinations. Singletons are allowed, but not for the last
period. Edges are restricted to sequential pairs.

``` r
# Perform a self-join to create an edge list, with all pairwise combinations of year.
# Allow singletons for all but the last period, but remove non-sequential pairs.

e0 <- df %>% select(ID, YR,IND) %>%
  inner_join(., select(., ID,YR,IND), by = "ID") %>%
  rename(FROM = YR.x, TO = YR.y, INIT=IND.x) %>%
  group_by(ID) %>%
  mutate(rows = n()) %>%
  filter((rows == 1 & FROM == TO)| TO-FROM ==1 ) %>%
  filter(FROM != last.per) %>%
  unique %>%
  arrange(ID, FROM,TO) %>%
  dplyr::select(ID,FROM,TO,INIT)

# Aggregate

e1 <- e0 %>%
  group_by(FROM,TO) %>%
  summarize(VALUE=n()) %>% # members
  ungroup() %>%
  select(FROM,TO,VALUE) %>%
  as.data.frame()
```

# 3 Graphs

## 3.1 Network Flow

The following uses the **networkD3** and **igraph** packages to create a
directed graph and simple network object. The node size reflects the
number of cohort members.

``` r
library(networkD3)
library(igraph)

g    <- graph_from_data_frame(e1,directed=TRUE,vertices = nodeInfo)
g_d3 <- igraph_to_networkD3(g)


plot(g, vertex.size = node.stats$member.ttl/5, main = "Cohort Flow from Year to Year")
```
<img src="Retention3_Sankey_files/flowplot-1.png" style="display: block; margin: auto;" />

## 3.2 Sankey Diagram for Year to Year Changes

A Sankey diagram describes the flow from one set of attributes (e.g., a
phase, cohort, class, development iteration) to another.

-   Vertical bars show the relative size of the cohort.
-   Light grey connectors show the relative size of cohort members
    moving from one year to another.
-   Grey circles show the relative number of members who only
    participated for a single year.

``` r
sankeyNetwork(g_d3$links, Nodes=g_d3$nodes,
              Source = "source", Target="target",
              Value = "value",NodeID = "name",
              fontSize=28,
              sinksRight = FALSE,
              nodeWidth = 20, nodePadding = 20,
              units ="members")
```

<img src="Retention3_Sankey_files/snky-1.png" style="display: block; margin: auto;" />

## 3.3 Network Graphs to Visualize Movement Between Groups

``` r
df <- subset(db1) %>% 
  ungroup() %>%
  group_by(ID,GRP) %>%
  summarize(IND     = mean(IND)) %>%
  ungroup()

# Node Info (V for vertex)

node.stats <- df %>%
  group_by(GRP) %>%
  summarize(member.ttl = n_distinct(ID),
            ind.mu     = mean(IND),
            ind.med    = median(IND)) %>%
  rename(V = GRP)

NodeCols <- unique(node.stats$V)

last.per <- max(node.stats$V)

nodeInfo <- as.data.frame(NodeCols,stringsAsFactors = FALSE) %>%
  rename(V = NodeCols) %>%
  left_join(.,node.stats,by="V")

# Edge List prep

e0 <- df %>% select(ID, GRP,IND) %>%
  inner_join(., select(., ID,GRP,IND), by = "ID") %>%
  rename(FROM = GRP.x, TO = GRP.y, INIT=IND.x) %>%
  group_by(ID) %>%
  mutate(rows = n()) %>%
  filter(rows == 1 & FROM == TO|FROM != TO ) %>%
  unique %>%
  arrange(ID, FROM,TO) %>%
  dplyr::select(ID,FROM,TO,INIT)

# Aggregate

e1 <- e0 %>%
  group_by(FROM,TO) %>%
  summarize(VALUE=n()) %>% # members
  ungroup() %>%
  select(FROM,TO,VALUE) %>%
  as.data.frame()
```

-   The size of the nodes describes the relative value of `ind` for the
    group (e.g., `ind` could reflect costs or other inputs or outputs).
-   The thickness of the connecting lines reflects the number of members
    moving from one group to the other.

``` r
g    <- graph_from_data_frame(e1,directed=TRUE,vertices = nodeInfo)

d <- as_adjacency_matrix(g) 

network <- graph_from_adjacency_matrix(d , mode='directed', diag=F )


# IBM Design Colorblind safe

clrs <- c("#648fff", "#785ef0", "#dc267f", "#fe6100" )

plot(network, layout=layout_components, 
     edge.width = E(g)$VALUE/50,
     vertex.size = nodeInfo$ind.med/20,
     vertex.color = clrs,
     edge.label = E(g)$VALUE,
     edge.curved = .5,
     main = "Flow of Members Between Groups\n Node size reflects median values for `ind`")
```

<img src="Retention3_Sankey_files/network-1.png" style="display: block; margin: auto;" />

### 3.3.1 Alluvial Charts

The following charts the flow between groups over all cohort years.

``` r
# Extract the data and coerce it into alluvial form.

df <- db1 %>%
  group_by(ID,YR) %>%
  summarize(GRP = last(GRP)) %>%
  ungroup() %>%
  group_by(ID) %>%
  mutate(Exit.YR = last(YR) + 1,
         Enter.Yr = first(YR) - 1) %>%
  ungroup()

df.enter <- df %>% select(ID,Enter.Yr) %>%
  mutate(GRP = "Enter") %>%
  rename(YR = Enter.Yr)

df.exit <- df %>% select(ID,Exit.YR) %>% 
  mutate(GRP = "Exit") %>%
  rename(YR = Exit.YR)


df.new <- rbind.data.frame(df[,1:3],df.enter,df.exit) 

df.plot <- df.new %>%
  mutate(YR = as.character(YR),
         YR = factor(YR, levels=c(sort(unique(df.new$YR)))),
         GRP = factor(GRP, levels = c("Enter","GRP1","GRP2","GRP3","GRP4","Exit")) ) %>%
  unique()

clrs <- c("#ffffff","#648fff", "#785ef0", "#dc267f", "#fe6100","#808080" )

library(ggalluvial)

ggplot(df.plot,
       aes(x = YR, stratum = GRP, alluvium = ID,
           fill = GRP, label = GRP,)) +
  scale_fill_manual(values=clrs) +
  geom_flow(stat = "flow", lode.guidance = "frontback",
            color = "darkgray") +
  geom_stratum() +
  ggtitle("Growth and Attrition by Year and Group Cohort") +
  theme(legend.position = "bottom",
        legend.title=element_blank()) +
  theme_minimal()
```
<img src="Retention3_Sankey_files/alluvial-1.png" style="display: block; margin: auto;" />

# 4 Packages

Wickham et al., (2019). Welcome to the tidyverse. Journal of Open Source
Software, 4(43), 1686, <https://doi.org/10.21105/joss.01686>

Garrett Grolemund, Hadley Wickham (2011). Dates and Times Made Easy with
lubridate. Journal of Statistical Software, 40(3), 1-25. URL:
<https://www.jstatsoft.org/v40/i03/>.

Csardi G, Nepusz T: The igraph software package for complex network
research, InterJournal, Complex Systems 1695. 2006. <https://igraph.org>

J.J. Allaire, Christopher Gandrud, Kenton Russell and CJ Yetman (2017).
networkD3: D3 JavaScript Network Graphs from R. R package version 0.4.
<https://CRAN.R-project.org/package=networkD3>

Brunson JC (2017). “ggalluvial: Layered Grammar for Alluvial Plots.”
*Journal of Open Source Software*, *5*(49), 2017. doi:
10.21105/joss.02017 (URL: <https://doi.org/10.21105/joss.02017>).

# 5 References
