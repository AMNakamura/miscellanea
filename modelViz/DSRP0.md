Creating a Distinctions, Systems, Relationships, and Perspectives (DSRP)
Model in R
================
Ann Nakamura

-   <a href="#1-distinctions-d" id="toc-1-distinctions-d">1 Distinctions
    (D)</a>
-   <a href="#2-systems-s" id="toc-2-systems-s">2 Systems (S)</a>
-   <a href="#3-relationships-r" id="toc-3-relationships-r">3 Relationships
    (R)</a>
-   <a href="#4-perspectives-p" id="toc-4-perspectives-p">4 Perspectives
    (P)</a>

Distinctions, Systems, Relationships, and Perspectives (DSRP) is a
mathematical theory and way of approaching messy problems (see [Cabrera
Research](https://www.cabreraresearch.org/)) and DSRP models can be very
helpful in better understanding and describing new ideas or initiatives;
issues or policies; or other concepts. Some free diagram-making
software, like [plectica.com](https://www.plectica.com/) or
[daggity.net](https://www.plectica.com/) can make sophisticated models,
but may not have the image resolution to add fine details render large
canvases.

The code below uses **DiagrammeR** and **rsvg** packages to create a
simple DSRP model that can be printed in high resolution for free.

``` r
library(DiagrammeR)
library(DiagrammeRsvg)  # for conversion to svg
library(rsvg)
```

# 1 Distinctions (D)

Let ‘it’ be the thing we want to describe. What is ‘it’ and what is ‘it’
not? The code below creates two clusters, one for ‘What It Is’ and one
for ‘What It Is Not’.

``` r
d<- DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = TB]  
 label = 'Distinctions'

subgraph cluster1 {

label = 'What It Is'


a [label='\u2608', shape=none, fontsize=25,fontcolor='darkgreen' ]

}
subgraph cluster2 {
label = 'What It Is Not'

b [label='\u2603', shape=none, fontsize=25, fontcolor='blue' ]

}

}

")

tmp = DiagrammeRsvg::export_svg(d)
tmp = charToRaw(tmp) # flatten
rsvg::rsvg_png(tmp, "D.png",width=1000) 
```

<center>
<H1 style="color:grey;">

DSRP

</H1>

<img src="D.png" style="width:70.0%" />

</center>

# 2 Systems (S)

For this example, a system is simply something that can be broken down
into parts, with different inputs and outputs. The code below fills the
clusters with two tables containing HTML table versions of [record-based
nodes](http://www.graphviz.org/doc/info/shapes.html), one with ‘Work
Done’ and one with ‘System’ parts. Note the use of HTML tags. The PORT
name is added to the node description with an identifier that indicates
where to attach an edge.

The solution to attaching the ports to nodes in **DiagrammeR** come
courtesy of StackOverflow [Question
13369992](https://stackoverflow.com/questions/13369992/graphviz-how-can-i-create-edges-between-html-table-cells).

``` r
s <- DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = TB]  

label = 'Distinctions and Systems'

subgraph cluster1 {

label = 'What It Is'


a [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0' >
                           <TR><TD>Work Done  </TD></TR>
                           <TR><TD PORT='11'>activity 1</TD></TR>
                           <TR><TD PORT='12'>activity 2</TD></TR>
                           <TR><TD PORT='13'>activity 3</TD></TR>
                           <TR><TD PORT='14'>activity 4</TD></TR>
              </TABLE>> pos = '0,0!',
         shape=none, fontsize=10 ]
         
b [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>System  </TD></TR>
                           <TR><TD PORT='21'>part 1</TD></TR>
                           <TR><TD PORT='22'>part 2</TD></TR>
                           <TR><TD PORT='23'>part 3</TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10 ]
}
subgraph cluster2 {
label = 'What It Is Not'
        c [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>Work Done  </TD></TR>
                           <TR><TD PORT='31'>activity 1</TD></TR>
                           <TR><TD PORT='32'>activity 2</TD></TR>
                           <TR><TD PORT='33'>activity 3</TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10 ]
         
d [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>System  </TD></TR>
                           <TR><TD PORT='41'>part 1</TD></TR>
                           <TR><TD PORT='42'>part 2</TD></TR>
                           <TR><TD PORT='43'>part 3</TD></TR>
                           <TR><TD PORT='44'>part 4</TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none, fontsize=10 ]
}

}

")

tmp = DiagrammeRsvg::export_svg(s)
tmp = charToRaw(tmp) # flatten
rsvg::rsvg_png(tmp, "DS.png",width=1200) 
```

<center>
<H1 style="color:grey;">

DSRP

</H1>

![](DS.png)

</center>

# 3 Relationships (R)

The following adds some hypothetical relationships using edges to
connect nodes. Note the use of ports e.g., (`b:21 -> a:11`) to connect
edges to nodes. Edge attributes appear in square brackets `[]`. The
following updates the graph object, setting `compound` to `TRUE` to
allow edges between clusters.

``` r
r <- DiagrammeR::grViz(
diagram = "digraph {
           graph[layout = dot, rankdir = TB]  
           newrank=true;
           compound=true;
           
label = 'Distinctions and Systems'



subgraph cluster1 {

label = 'What It Is'

a [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>Work Done  </TD></TR>
                           <TR><TD PORT='11'>activity 1</TD></TR>
                           <TR><TD PORT='12'>activity 2</TD></TR>
                           <TR><TD PORT='13'>activity 3</TD></TR>
                           <TR><TD PORT='14'>activity 4</TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none,
         fontsize=10]
         
b [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>System  </TD></TR>
                           <TR><TD PORT='21'>part 1</TD></TR>
                           <TR><TD PORT='22'>part 2</TD></TR>
                           <TR><TD PORT='23'>part 3</TD></TR>
                           
              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10]
         
{rank = same; a b }

}
subgraph cluster2 {
label = 'What It Is Not'

        c [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>Work Done  </TD></TR>
                           <TR><TD PORT='31'>activity 1</TD></TR>
                           <TR><TD PORT='32'>activity 2</TD></TR>
                           <TR><TD PORT='33'>activity 3</TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10]
         
        d [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>System  </TD></TR>
                           <TR><TD PORT='41'>part 1</TD></TR>
                           <TR><TD PORT='42'>part 2</TD></TR>
                           <TR><TD PORT='43'>part 3</TD></TR>
                           <TR><TD PORT='44'>part 4</TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10]
         
{rank = same; c d }   
}
{ rank=same; a; b; c; d;}

    b:21 -> a:11 [dir=back]
    b:22 -> a:13 [dir=back]
    b:22 -> a:14 [dir=back]
    
    c:31 -> d:44 [dir=forward]
    c:31 -> d:41 [dir=forward]
    
    a:12 -> c:33 [dir=both,style=dashed]
    a:11 -> c:32 [dir=back, style=dashed]
    
  }

")


tmp = DiagrammeRsvg::export_svg(r)
tmp = charToRaw(tmp) # flatten
rsvg::rsvg_png(tmp, "DSR.png",width=1000) 
```

<center>
<H1 style="color:grey;">

DSRP

</H1>

![](DSR.png)

</center>

# 4 Perspectives (P)

The next code chunk adds another cluster containing the Seinfeld
foursome (Kramer, George, Elaine, and Jerry) to show how perspectives
can be added visually.

The phrase, `minlen =1` is the minimum rank distance between head and
tail, and positions the nodes close together.

The phrase,
`Jerry -> b [lhead=cluster0, ltail=cluster0,minlen =2, color=none ]`
sets the cluster on top, above the other clusters..

The following is a comically hackish way to tie perspectives to system
parts. I have copy-pasted Unicode symbols from [Vertex42.com’s Excel
Tips site](https://www.vertex42.com/ExcelTips/unicode-symbols.html)
directly into the html tags for each activity node below. A sample
tooltip is provided to illustrate the tooltip feature (if rendering in
HTML).

``` r
DiagrammeR::grViz(
  diagram = "digraph {
           graph[layout = dot]  
           newrank=true;
           compound=true; 
           
label = 'Distinctions, Systems, and Relationships'

subgraph cluster0 {
node [style=filled, shape=box, width=1];
label = 'Perspectives'

Jerry  [color=red]
Elaine [color=green]
George [color=purple]
Kramer [color=yellow, tooltip='These are my everyday balloons.']

Jerry-> Elaine -> George -> Kramer [color=none]
{ rank=same; Jerry; Elaine; George; Kramer;}
}


subgraph cluster1 {

label = 'What It Is'

a [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>Work Done</TD></TR>
                           <TR><TD PORT='11'>activity 1🟠🟡</TD></TR>
                           <TR><TD PORT='12'>activity 2🟢 </TD></TR>
                           <TR><TD PORT='13'>activity 3🟠🟢🟣</TD></TR>
                           <TR><TD PORT='14'>activity 4🟠 </TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10]
         
b [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>System</TD></TR>
                           <TR><TD PORT='21'>part 1🟡</TD></TR>
                           <TR><TD PORT='22'>part 2🟢</TD></TR>
                           <TR><TD PORT='23'>part 3🟣</TD></TR>
                           
              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10]
         
{rank = same; a b }

}


subgraph cluster2 {
label = 'What It Is Not'

        c [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>Work Done</TD></TR>
                           <TR><TD PORT='31'>activity 1🟠 </TD></TR>
                           <TR><TD PORT='32'>activity 2🟠🟣 </TD></TR>
                           <TR><TD PORT='33'>activity 3🟢 </TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none , fontsize=10]
         
        d [label=<<TABLE BORDER='0' CELLBORDER='1' CELLSPACING='0'>
                           <TR><TD>System</TD></TR>
                           <TR><TD PORT='41'>part 1🟠 </TD></TR>
                           <TR><TD PORT='42'>part 2🟣</TD></TR>
                           <TR><TD PORT='43'>part 3🟢 </TD></TR>
                           <TR><TD PORT='44'>part 4🟣 </TD></TR>

              </TABLE>> pos = '0,0!',
         shape=none, fontsize=10 ]
         
{rank = same; c d }   
}


{ rank=same; a; b; c; d;}

 
    
    b:21 -> a:11 [dir=back]
    b:22 -> a:13 [dir=back]
    b:22 -> a:14 [dir=back]
    
    c:31 -> d:44 [dir=forward]
    c:31 -> d:41 [dir=forward]
    
    
    Jerry -> b [lhead=cluster0, ltail=cluster0,minlen =2, color=none ]

    a:12 -> c:33 [dir=both,style=dashed]
    a:11 -> c:32 [dir=back, style=dashed]
  
 
 
  }

")
```

<center>
<H1 style="color:grey;">

DSRP

</H1>

![](DSRP.png)

</center>
