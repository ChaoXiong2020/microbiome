# https://support.rstudio.com/hc/en-us/articles/200486518-Customizing-Package-Build-Options
/home/lei/bin/R CMD BATCH document.R
/home/lei/bin/R CMD build ../../ --no-build-vignettes #--no-examples
/home/lei/bin/R CMD check microbiome_0.99.93.tar.gz --no-build-vignettes #--no-examples
/home/lei/bin/R CMD INSTALL microbiome_0.99.93.tar.gz 
