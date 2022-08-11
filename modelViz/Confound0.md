Conceptual Model Visualization
================
A Nakamura
(update 5/15/2022 to add vtree)

-   <a href="#use-case" id="toc-use-case">Use Case</a>
-   <a href="#graphviz" id="toc-graphviz">GraphViz</a>
-   <a href="#dot-graph-specifications"
    id="toc-dot-graph-specifications">DOT graph specifications</a>
    -   <a href="#basic-graph" id="toc-basic-graph">Basic graph</a>
    -   <a href="#adding-attributes" id="toc-adding-attributes">Adding
        Attributes</a>
-   <a href="#graphing-types-of-potential-bias"
    id="toc-graphing-types-of-potential-bias">Graphing types of potential
    bias</a>
    -   <a href="#confounding" id="toc-confounding">Confounding</a>
    -   <a href="#mediation" id="toc-mediation">Mediation</a>
    -   <a href="#moderation" id="toc-moderation">Moderation</a>
    -   <a href="#collider" id="toc-collider">Collider</a>
-   <a href="#package-acknowledgements"
    id="toc-package-acknowledgements">Package Acknowledgements</a>

# Use Case

Prepare simple visual diagrams that can describe the relationship
between a predictor and an outcome, while also exploring how this
relationship might be distorted by other factors.

In the simplest case, let `x` be the predictor and `y` be the outcome.
What other factors are involved in this relationship? Which variables
should we condition on when looking at the x –\> y relationship?

Causal diagrams (e.g., Directed Acyclic Diagram (DAG)) help identify the
following sources of bias and which variables should be conditioned on
when looking at the `x` -\> `y` relationship.

# GraphViz

This program uses **DiagrammeR**’s `grViz()` function. `grViz()` makes
diagrams using free Graph Visualization Software(GraphViz) software
tools created by [AT&T Labs
Research](https://en.wikipedia.org/wiki/AT%26T_Labs) and `viz.js`. All
graphs are created using [DOT
language](https://www.graphviz.org/doc/info/lang.html). The
[GraphViz](https://www.graphviz.org/doc/info/shapes.html) site provides
access to source code, layout engines, attribute formats, and other
documentation that can be used to help communicate relationships.

# DOT graph specifications

The DOT language defines structure and attributes of the graph object
(e.g., dependencies, labels, shapes, colors and line types). Like other
network diagrams, it uses the concept of nodes and edges. In the example
below:

-   graph: Describes the graph layout (DOT) and the direction (rank
    direction = left to right (LR))
-   x: represents a node.
-   y: represents another node
-   x -\> y: represents the dependency of y on x

## Basic graph

``` r
library(DiagrammeR)
library(vtree)

grVizToPNG(DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = LR]
           x
           y
           x -> y
}"), height=150, filename="g1.png")
```

<center>
![](g1.png)
</center>

## Adding Attributes

Attributes can be added to nodes (single variable declarations) and
edges (variable dependency specifications) within square brackets `[]`
Line breaks can be inserted by indicating a newline (`\n`). The example
below describes a hypothetical relationship between system documentation
and system data quality, with some attributes to illustrate the DOT
grammar.

``` r
grVizToPNG(DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = LR]
           x[label = 'x\n(documentation)', shape= folder, color='darkgreen',  style = filled, fillcolor='lightblue']
           y[label = 'y\n(data quality)',   shape= cylinder,color='darkgrey']
           w[label = 'some other \n unmeasured factor', color='lightgrey']
           x -> y [color = 'blue', arrowhead = curve]
}"),height=400,filename="g2.png")
```

<center>
[](g2.png)
</center>

# Graphing types of potential bias

## Confounding

`z` is associated with both `x` and `y`. Consider shoe size as a
predictor of reading ability among children [excellent example
here](https://ams005-spring17-02.courses.soe.ucsc.edu/system/files/attachments/Correlation.pdf).
Age distorts this relationship. Children with larger feet tend to read
at a higher level, but if you control for age (e.g, by measuring the
association between shoe size and reading level for children of the same
age), kids with bigger feet don’t read any better than kids with smaller
feet. Shoe size is not a reliable predictor of reading reading ability
because after controlling for age, the effect of shoe size on reading
level disappears.

If you don’t control for a confounder, you’re likely to over or
under-report the strength of the impact of x on y.

``` r
grVizToPNG(DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = TB]  

subgraph cluster1 {
label = 'Relationship'
           z
           x
           y
           z -> x
           z -> y
}

subgraph cluster2 {
label = 'Example'
           age [label = 'age \u231B']
           shoe[label = 'Shoe size \U1F463']
           reading[label='reading level \U1F56E ']
           age -> shoe
           age -> reading
}

}

"),height=400,filename="g3.png")
```

<center>
[](g3.png)
</center>

## Mediation

`Z` is on the causal pathway between `x` and `y`. For example, a [2018
study](https://www.internationaljournalofwellbeing.org/index.php/ijow/article/view/621)
looking at the psychological benefits of natural environments proposed
that nature’s impact on happiness depends a lot on whether the person
experiencing nature can savor the experience by being in the present
moment, intentionally focusing on the experience, practice gratitude, or
sharing the experience with others. Saying that visiting a garden, for
example, doesn’t predict emotional wellbeing because the effect drops or
disappears when you control for savoring, would be incorrect; there is a
relationship between nature and wellbeing. The mediator, savoring, helps
explain *why* that relationship exists.

In this example, deciding to visit a park (predictor) prompts savoring
behavior (mediator) in some, which causes relaxation or other positive
reaction (response).

``` r
grVizToPNG(DiagrammeR::grViz(
diagram = "digraph D {
           graph[layout = dot, rankdir = TB]  

subgraph cluster0 {
label = 'Relationship'
           z
           x
           y
           z -> x -> y
}

subgraph cluster1 {
label = 'Example'
           park
           savor
           happiness
           park -> savor -> happiness
           
           subgraph {
           node [shape = none]
      
           p [label= '\u26F1', fontsize=20]
           s [label= '\u2619', fontsize=20]
           h [label= '\U1F60A', fontsize=20]
           p -> s -> h [color='white']
}
}

}

"),filename="g4.png")
```

<center>
[](g4.png)
</center>

## Moderation

`z--> (x --> y)`, where `z`, if present, changes the relationship
between `x` and `y`. For example, political satire often helps audiences
make sense of political information. In a 2021, a [study looking at how
satirical news impacts
learning](https://journals.sagepub.com/doi/full/10.1177/00936502211032100)
describe the moderating effect of political perspective on learning via
satire. Not surprisingly, the amount of information processed is likely
stronger among audience members whose political positions align closest
with the satirist. The total effect of satire on learning, therefore
depends on the distribution of political orientations among the audience
and controlling for moderation, if possible, could help avoid
misreporting (e.g., results for the study group could be very different
from results from a broader population or different timeframe).

Hacky visualization, using an invisible node, below.

``` r
grVizToPNG(DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = TB] 
           newrank=true

subgraph cluster2 {
label = 'Relationship'

           emid2 [label='', shape=none, height=0, width=0]
           x -> emid2 [arrowhead = none]
           z -> emid2
           emid2 -> y 
           
{rank=same;x,y,emid2}
}

subgraph cluster1 {
label = 'Example'

           emid1[label='', shape=none, height=0, width=0]
           learning
           satire -> emid1
           perspective -> emid1 [arrowhead = none]
           emid1 -> learning 
           
{rank=same;satire,learning,emid1}
}

}

"),height=400,filename="g5.png")
```

<center>
[](g5.png)
</center>

## Collider

`x --> Z <-- y`. `z` is a common effect (collider) of both `x` and `y`.
Selection bias may be the most common example of conditioning on an
intermediate factor as colliders can be tough to detect. One of the more
famous examples in epidemiology is (Yerushalmy’s 1964
study)\[<https://www.sciencedirect.com/science/article/abs/pii/0002937864905095>\]
that smoking potentially protective among babies with low birthweight
(LBWT). Later analysess, by Yerushalmy and others, proposed that the
initial, paradoxical finding was likely due to selection (AKA collider)
bias. Among LBWT babies of smoking moms, smoking is a likely cause of
LBWT. Among LBWT babies of non-smoking moms, smoking is ruled out as a
cause for LBWT, which suggests the non-smoking moms in the study likely
had other causes of LBWT, like a birth defect, which carries a much
higher risk of mortality. Controlling for LBWT in the study design
created an unfair comparison between the smoking (lower risk) and
non-smoking (higher risk) groups.If he could have controlled for birth
defects, the protective effects of smoking on survival likely would have
disappeared. Controlling statistically creates a spurious dependence
between x and y.

For a great description of colliders and graphical approaches to finding
them, see [Saunder’s “back door” diagram
method](https://biostat.app.vumc.org/wiki/pub/Main/ContinuingEdu/CTSaunders_CausalDiagrams.pdf).

An approach to graphing the “Smoking-Birthweight Paradox” in DiagrammeR
appears below.

``` r
grVizToPNG(DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = TB]
center=true;

subgraph cluster1 {
label='Relationship'
           z [shape=doubleoctagon]
           z -> y
           w -> z
           x -> z
           x -> y
           w -> y
}

 subgraph cluster2 {
 
 label='Example'
           lbwt [shape=doubleoctagon]
           lbwt -> mortality
           birthdefect -> lbwt
           smoking -> lbwt
           smoking ->mortality
           birthdefect -> mortality
 }

}

"),filename="g6.png")
```

<center>
[](g6.png)
</center>

# Package Acknowledgements

Iannone R (2022). *DiagrammeR: Graph/Network Visualization*. R package
version 1.0.9, <https://CRAN.R-project.org/package=DiagrammeR>.

Barrowman N (2021) *vtree: Display Information About Nested Subsets of a
Data Frame*. R package version 5.4.6,
<https://CRAN.R-project.org/package=vtree>.
