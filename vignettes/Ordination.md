---
title: "Ordination analysis"
bibliography: 
- bibliography.bib
- references.bib
output: 
  prettydoc::html_pretty:
    theme: cayman
    highlight: github
---
<!--
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteIndexEntry{microbiome tutorial - ordination}
  %\usepackage[utf8]{inputenc}
  %\VignetteEncoding{UTF-8}  
-->


## Ordination examples

Full examples for standard ordination techniques applied to phyloseq data, based on the [phyloseq ordination tutorial](http://joey711.github.io/phyloseq/plot_ordination-examples.html). For handy wrappers for some common ordination tasks in microbiome analysis, see [landscaping examples](Landscaping.html)


Load example data:


```r
library(microbiome)
library(phyloseq)
library(ggplot2)
data(dietswap)
pseq <- dietswap

# Convert to compositional data
pseq.rel <- microbiome::transform(pseq, "compositional")

# Pick core taxa with with the given prevalence and detection limits
pseq.core <- core(pseq.rel, detection = .1/100, prevalence = 90/100)

# Use relative abundances for the core
pseq.core <- microbiome::transform(pseq.core, "compositional")
```


### Sample ordination

Project the samples with the given method and dissimilarity measure. 


```r
# Ordinate the data
set.seed(4235421)
# proj <- get_ordination(pseq, "MDS", "bray")
ord <- ordinate(pseq, "MDS", "bray")
```


```r
# "quiet" is here used to suppress intermediate output
quiet(p <- plot_ordination(pseq, ord, type = "taxa", color = "Phylum", title = "Taxa ordination"))
print(p)
```

![plot of chunk ordination-pca-ordination21](figure/ordination-pca-ordination21-1.png)

Grouping per phyla could be done with:


```r
p + facet_wrap(~Phylum, 5)
```


### Multidimensional scaling (MDS / PCoA)


```r
plot_ordination(pseq, ord, color = "nationality") +
                geom_point(size = 5)
```

<img src="figure/ordination-ordinate23-1.png" title="plot of chunk ordination-ordinate23" alt="plot of chunk ordination-ordinate23" width="200px" />


### Canonical correspondence analysis (CCA)


```r
# With samples
pseq.cca <- ordinate(pseq, "CCA")
p <- plot_ordination(pseq, pseq.cca,
       type = "samples", color = "nationality")
p <- p + geom_point(size = 4)
print(p)

# With taxa:
p <- plot_ordination(pseq, pseq.cca,
       type = "taxa", color = "Phylum")
p <- p + geom_point(size = 4)
print(p)
```

<img src="figure/ordination-ordinate24a-1.png" title="plot of chunk ordination-ordinate24a" alt="plot of chunk ordination-ordinate24a" width="400px" /><img src="figure/ordination-ordinate24a-2.png" title="plot of chunk ordination-ordinate24a" alt="plot of chunk ordination-ordinate24a" width="400px" />


### Split plot


```r
plot_ordination(pseq, pseq.cca,
		      type = "split", shape = "nationality", 
    		      color = "Phylum", label = "nationality")
```

![plot of chunk ordination-ordinate25](figure/ordination-ordinate25-1.png)



### RDA

See a separate page on [RDA](RDA.html).


