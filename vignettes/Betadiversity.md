<!--
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteIndexEntry{microbiome tutorial - variability}
  %\usepackage[utf8]{inputenc}
  %\VignetteEncoding{UTF-8}  
-->
Beta diversity (microbiome heterogeneity)
-----------------------------------------

Load example data

    library(microbiome)
    data(peerj32)
    pseq <- peerj32$phyloseq

### Quantification of group heterogeneity / spread

Calculate beta diversities within the LGG (probiotic) and Placebo
groups. The beta diversity is here calculated as the dissimilarity of
each sample from the group mean. See the function help for details on
beta diversity measures.

    b.pla <- betadiversity(subset_samples(pseq, group == "Placebo"))
    b.lgg <- betadiversity(subset_samples(pseq, group == "LGG"))

Compare the heterogeneity within each group. The LGG group tends to have
smaller values, indicating that the samples are more similar to the
group mean, and hence the overall heterogeneity (or spread) of the LGG
group is smaller.

Or in other words, the inter-individual homogeneity within the LGG group
is greater; this homogeneity measure, or *inter-individual stability*
has been used for group-wise comparisons for instance in [Salonen et al.
ISME J
2014](http://www.nature.com/ismej/journal/v8/n11/full/ismej201463a.html).
Other beta diversity measures could be used as well but they are not
currently implemented.

    boxplot(list(LGG = b.lgg, Placebo = b.pla))

![](Betadiversity_files/figure-markdown_strict/heterogeneity-example2bbb-1.png)

### Intra-individual heterogeneity

Beta diversity is often quantified also within subjects over time.
[Salonen et al. ISME J
2014](http://www.nature.com/ismej/journal/v8/n11/full/ismej201463a.html))
used this to quantify intra-individual stability (ie homogeneity)
between time points.

Calculate the beta diversity between the two time points within each
subject, and compare the beta diversities between the two groups.

    betas <- list()
    groups <- as.character(unique(meta(pseq)$group))
    for (g in groups) {
      df <- meta(subset_samples(pseq, group == g))
      beta <- c()

      for (subj in df$subject) {
        # Pick the samples for this subject
        dfs <- subset(df, subject == subj)
        # Check that the subject has two time points
        if (nrow(dfs) == 2) {
          s <- as.character(dfs$sample)
          beta[[subj]] <- betadiversity(abundances(pseq)[, s])
        }
      }
      betas[[g]] <- beta
    }

    boxplot(betas)

![](Betadiversity_files/figure-markdown_strict/homogeneity-example2c-1.png)

### Beta diversity within individual over time

Calculate change in beta diversity (community dissimilarity) over time
within a single individual

    data(atlas1006)
    pseq <- atlas1006

    # Identify subject with the longest time series (most time points)
    s <- names(which.max(sapply(split(meta(pseq)$time, meta(pseq)$subject), function (x) {length(unique(x))})))

    # Pick the metadata for this subject and sort the
    # samples by time
    df <- meta(subset_samples(pseq, subject == s)) %>% arrange(time)

    # Calculate the beta diversity between each time point and
    # the baseline (first) time point
    beta <- c(0, 0) # Baseline similarity
    s0 <- subset(df, time == 0)$sample
    for (tp in df$time[-1]) {
      # Pick the samples for this subject
      # If the same time point has more than one sample,
      # pick one at random
      st <- sample(subset(df, time == tp)$sample, 1)
      b <- betadiversity(abundances(pseq)[, c(s0, st)])
      beta <- rbind(beta, c(tp, b))
    }
    colnames(beta) <- c("time", "beta")
    beta <- as.data.frame(beta)

    p <- ggplot(beta, aes(x = time, y = beta)) +
           geom_point() + geom_line()
    print(p)       

![](Betadiversity_files/figure-markdown_strict/homogeneity-example2d-1.png)