#' @title Core Microbiota
#' @description Filter the phyloseq object to include only prevalent taxa.
#' @param x \code{\link{phyloseq-class}} object
#' @param detection Detection threshold (non-negative real)
#' @param prevalence Prevalence threshold (in [0, 100])
#' @param method Either "standard" or "bootstrap". The standard methods selects
#' the taxa that exceed the given detection and prevalence threshold.
#' The bootstrap method is more robust an described in Salonen et al. (2012).
#' Note that the results may depend on the random seed unless a sufficiently
#' large bootstrap sample size is used.
#' @param Nsample Only needed for method "bootstrap". Bootstrap sample size, default is the same size as data.
#' @param bs.iter Only needed for method "bootstrap". Bootstrap iterations.
#' @param I.max Only needed for method "bootstrap". Upper limit for intensity threshold. Later addition. Set to NULL (default) to replicate Salonen et al.
#' @param ... Arguments to pass.
#' @return Filtered phyloseq object including only prevalent taxa
#' @references
#' The core microbiota bootstrap method implemented with this function:
#' Salonen A, Salojarvi J, Lahti L, de Vos WM. The adult intestinal
#' core microbiota is determined by analysis depth and health
#' status. Clinical Microbiology and Infection 18(S4):16-20, 2012
#'   To cite the microbiome R package, see citation('microbiome') 
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
#' @export
#' @aliases filter_prevalent
#' @examples
#'   data(peerj32)
#'   core(peerj32$phyloseq, 200, 20)
core <- function (x, detection, prevalence, method = "standard", Nsample = NULL, bs.iter = 1000, I.max = NULL) {

  # TODO: add optional renormalization such that the core member
  # abundances would sum up to 100 ?
  taxa <- core_members(x, detection, prevalence, method, Nsample = Nsample, bs.iter = bs.iter, I.max = I.max)
  prune_taxa(taxa, x)

}



#' @title Core Taxa
#' @description Determine members of the core microbiota with given abundance
#' and prevalences
#' @inheritParams core
#' @return Vector of core members
#' @details For phyloseq object, lists taxa that are more prevalent with the
#'   given detection. For matrix, lists columns that satisfy
#'   these criteria.
#' @examples
#'   data(dietswap)
#'   a <- core_members(dietswap, 1, 95)
#' @aliases prevalent_taxa
#' @references 
#'   A Salonen et al. The adult intestinal core microbiota is determined by 
#'   analysis depth and health status. Clinical Microbiology and Infection 
#'   18(S4):16 20, 2012. 
#'   To cite the microbiome R package, see citation('microbiome') 
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
core_members <- function(x, detection = 1, prevalence = 95, method = "standard", Nsample = NULL, bs.iter = 1000, I.max = NULL)  {

  Core <- NULL

  if (class(x) == "phyloseq") {
    x <- abundances(x)
  }

  if (method == "standard") {
    taxa <- names(which(prevalence(x, detection) > prevalence))
  } else if (method == "bootstrap") {
    # Core bootstrap analysis
    cb <- core_bootstrap(x, Nsample = Nsample,
       	  		    prevalence = prevalence,
                            bs.iter = bs.iter, 
		   	    detection = detection,
			    I.max = I.max)
    # Pick the taxa that have been identified in the robust core
    taxa <- as.character(subset(cb, Core == 1)$Name)
  }

  taxa

}


#' @title Bootstrap Analysis of the Core Microbiota
#' @description Bootstrap analysis of the core microbiota.
#' @param x OTUxSample data matrix
#' @param Nsample bootstrap sample size, default is the same size as data
#' @param prevalence Lower limit for number of samples where microbe needs 
#'   	    to exceed the intensity threshold for a 'present' call. 
#' @param bs.iter bootstrap iterations
#' @param detection Lower limit for intensity threshold
#' @param I.max Upper limit for intensity threshold. Later addition.
#'              set to NULL (default) to replicate Salonen et al.
#' @return data frame with microbes and their frequency of presence in 
#'   	     the core
#' @examples
#'   data(peerj32)
#'   # In practice, use bs.iter = 1000 or more
#'   bs <- core_bootstrap(peerj32$phyloseq, bs.iter = 5)
#' @references 
#' The core microbiota bootstrap method implemented with this function:
#' Salonen A, Salojarvi J, Lahti L, de Vos WM. The adult intestinal
#' core microbiota is determined by analysis depth and health
#' status. Clinical Microbiology and Infection 18(S4):16-20, 2012
#' To cite this R package, see citation("microbiome")  
#' @author Contact: Jarkko Salojarvi \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
core_bootstrap <- function(x,
	                   Nsample = NULL,
	                   prevalence = 2,
	                   bs.iter = 1000, 
		      	   detection = 1.8,
			   I.max = NULL){

   # In this function prevalence refers to counts
   # wheras the main function uses percentages
   # Let us convert percentages to counts for compatibility
   prevalencen <- round((prevalence/100) * ncol(x))

   # Rename the input variable
   # (must be x in the argument list to follow standard conventions!)
   D <- x
   if (is.null(Nsample)) {Nsample <- ncol(D)}

   boot <- replicate(bs.iter, sample(ncol(D), Nsample, replace = TRUE), 
   	   		    simplify = FALSE)

   # choose intensity such that there is at least one bacteria 
   # fulfilling prevalence criterion
     boot.which <- lapply(boot, function(x){ 
       Prev = round(runif(1, prevalencen, length(x)));
       if (is.null(I.max))
          I.max = max(apply(D[,x], 1, 
                      function(xx) quantile(xx, probs = (1 - Prev/length(x)))));
       I.max = max(detection, I.max); # Ensure I.max > detection, otherwise Insty gives NA's / LL 13.8.2012
       Insty = runif(1, detection, I.max);
       return(core.which(D[,x], Insty, Prev))
    })
   

   boot.prob <- rowSums(as.data.frame(boot.which))/bs.iter

   df <- data.frame(Name = rownames(D), Frequency = boot.prob)
   df <- df[order(df$Frequency,decreasing = TRUE),]

   mm <- bootstrap_microbecount(D,Nsample = Nsample,
         		 	minprev = prevalencen, 
      	 			bs.iter = bs.iter,
				detection = detection,
				I.max = I.max)

   df$Core <- as.numeric(sapply(1:nrow(df), function(x) x <= mm))

   message("Bootstrapped median core size: ", mm)

   return(df)

}



#' @title Bootstrap Microbe Count Data
#' @description Auxiliary function for bootstrap_microbes.
#' @param D data
#' @param Nsample sample size
#' @param minprev minimum prevalence
#' @param bs.iter bootstrap sample size
#' @param detection intensity threshold
#' @param I.max max intensity threshold
#' @return median microbe count in bootstrapped cores
#' @examples
#'   \dontrun{
#'     library(microbiome)
#'     data(peerj32)
#'     tmp <- bootstrap_microbecount(t(peerj32$microbes), bs.iter = 5)
#'  }
#' @references 
#' The core microbiota bootstrap method implemented with this function:
#' Salonen A, Salojarvi J, Lahti L, de Vos WM. The adult intestinal
#' core microbiota is determined by analysis depth and health
#' status. Clinical Microbiology and Infection 18(S4):16-20, 2012
#' To cite this R package, see citation("microbiome") 
#' @author Contact: Jarkko Salojarvi \email{microbiome-admin@@googlegroups.com}
#' @keywords internal
bootstrap_microbecount <- function(D, Nsample = NULL,
		       	  	      minprev = 1, 
		       	  	      bs.iter = 1000,
				      detection = 1.8, 
				      I.max = NULL){

  if (is.null(Nsample)) {Nsample <- ncol(D)}

   # Select the bootstrap samples for each bootstrap iteration
   # (each element is a list of sample indices; and there are bs.iter elements)
   boot <- replicate(bs.iter,
   	             sample(ncol(D), Nsample, replace = TRUE),
   	   	     simplify = FALSE)

   # Choose intensity such that there is at least one bacteria 
   # fulfilling prevalence criterion
   if (Nsample > 1) {
     boot.which <- lapply(boot,function(x){ 
        if (is.null(I.max)) {
          I.max = max(apply(D[,x], 1, min))
	}
        I.max = max(detection, I.max); 
        Insty = runif(1, detection, I.max)
        sum(rowSums(D[,x]>Insty) > minprev)
     })
   } else {
     boot.which <- lapply(boot,function(x){ 
        if (is.null(I.max)) {
           I.max = max(D[,x])
	}
        I.max = max(detection, I.max); 
        Insty = runif(1,detection,I.max)
        return(sum(D[,x] > Insty))
     })
   }

   boot.prob <- as.matrix(as.data.frame(boot.which, check.names = FALSE))
   t1 <- quantile(boot.prob, probs = c(0.05, 0.5, 0.95))
   return(t1[2])
}

#' @title Core which
#' @description Auxiliary function 
#' @param data phylotypes vs. samples data matrix
#' @param intTr intTr
#' @param prevalenceTr prevalenceTr
#' @return Number of OTUs.
#' @keywords internal
core.which <- function(data, intTr, prevalenceTr) {
    d.bin <- data >= intTr
    prevalences <- rowSums(d.bin)
    nOTUs <- as.numeric(prevalences >= prevalenceTr)
    nOTUs
}








