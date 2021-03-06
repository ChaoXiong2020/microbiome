#' @title Diversity Index
#' @description Various community diversity indices.
#' @param index Diversity index. See details for options.
#' @param zeroes Include zero counts in the diversity estimation.
#' @inheritParams global
#' @return A vector of diversity indices
#' @export
#' @examples
#'   data(dietswap)
#'   d <- diversities(dietswap, "shannon")
#'   # d <- diversities(dietswap, "all")
#'
#' @details
#' By default, returns all diversity indices. The available diversity indices include the following:
#'  \itemize{
#'    \item{inverse_simpson}{Inverse  Simpson diversity: $1/lambda$ where $lambda = sum(p^2)$ and $p$ are relative abundances.}
#'    \item{gini_simpson}{Gini-Simpson diversity $1 - lambda$. This is also called Gibbs–Martin, or Blau index in sociology, psychology and management studies.}
#'    \item{shannon}{Shannon diversity ie entropy}
#'    \item{fisher}{Fisher alpha; as implemented in the \pkg{vegan} package}
#'    \item{coverage}{Number of species needed to cover 50\% of the ecosystem. For other quantiles, apply the function coverage directly.}
#'
#'  }
#'   
#' @references
#'
#'  Beisel J-N. et al. A Comparative Analysis of Diversity Index Sensitivity. Internal Rev. Hydrobiol. 88(1):3-15, 2003. URL: \url{https://portais.ufg.br/up/202/o/2003-comparative_evennes_index.pdf}
#' 
#'  Bulla L. An  index  of  diversity  and  its  associated  diversity  measure.  Oikos 70:167--171, 1994
#'
#'  Magurran AE, McGill BJ, eds (2011) Biological Diversity: Frontiers in Measurement and Assessment (Oxford Univ Press, Oxford), Vol 12.
#'  Smith B and Wilson JB. A Consumer's Guide to Diversity Indices. Oikos 76(1):70-82, 1996.
#'
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @seealso dominance, richness, evenness, rarity, global
#' @keywords utilities
diversities <- function(x, index = "all", zeroes = TRUE) {

  # Only include accepted indices	 
  accepted <- c("inverse_simpson", "gini_simpson", "shannon", "fisher", "coverage")

  # Return all indices
  if (index == "all") {
    index <- accepted
  }

  index <- intersect(index, accepted)
  if (length(index) == 0) {
    return(NULL)
  }

  if (length(index) > 1) {
    tab <- NULL
    for (idx in index) {
      tab <- cbind(tab, diversities(x, index = idx, zeroes = TRUE))
    }
    colnames(tab) <- index
    return(as.data.frame(tab))
  }

  # Pick data
  otu <- abundances(x)

  if (index == "inverse_simpson") {
    ev <- apply(otu, 2, function (x) {inverse_simpson(x, zeroes = zeroes)})
  } else if (index == "gini_simpson") {
    ev <- apply(otu, 2, function (x) {gini_simpson(x, zeroes = zeroes)})    
  } else if (index == "shannon") {
    ev <- apply(otu, 2, function (x) {shannon(x)})
  } else if (index == "fisher") {
    ev <- fisher.alpha(otu, MARGIN = 2)
  } else if (index == "coverage") {
    ev <- unname(coverage(otu))
  }
    
  names(ev) <- colnames(otu)

  ev

}



# x: Species count vector
inverse_simpson <- function (x, zeroes = TRUE) {

  # Simpson index
  lambda <- simpson_index(x, zeroes = zeroes)

  # Inverse Simpson diversity
  (1/lambda)
  
}

# x: Species count vector
gini_simpson <- function (x, zeroes = TRUE) {

  # Simpson index
  lambda <- simpson_index(x, zeroes = zeroes)

  # Gini-Simpson diversity
  1 - lambda
  
}

simpson_index <- function (x, zeroes = TRUE) {

  if (!zeroes) {
    x[x > 0]
  }

  # Relative abundances
  p <- x/sum(x)

  # Simpson index
  lambda <- sum(p^2)

  lambda
  
}



# x: Species count vector
shannon <- function (x) {

  # Ignore zeroes
  x <- x[x > 0]
  
  # Species richness (number of species)
  S <- length(x)

  # Relative abundances
  p <- x/sum(x)

  # Shannon index
  (-sum(p * log(p)))

}


#' @title Estimate Global Indices 
#' @description Estimate global indicators of the ecoystem state (richness, diversity, and other indicators).
#' @inheritParams global
#' @return A data.frame of samples x global indicators
#' @details This function returns the indices with the default choices for detection, prevalence and other parameters for simplicity and standardization. See the individual functions for more options. This function extends the functionality of the phyloseq::estimate_richness function.
#' @export
#' @seealso rarity, core_abundance, dominance, low_abundance, dominance, gini, phyloseq::estimate_richness
#' @references See citation('microbiome') 
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
diversity <- function(x) {

  .Deprecated(new = "global", msg = "The microbiome::diversity function has been replaced with the microbiome::global function and will be removed in the next release.")	  
  global(x)

}

