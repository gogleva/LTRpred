#' @title Plot the width distribution of putative LTR transposons
#' @description Visualize the correlation between LTR transposon age
#' (measured in LTR similarity) and the width of the corresponding LTR retrotransposon (the complete sequence) or the width of the left LTR element.
#' @param data the \code{\link{data.frame}} generated by \code{\link[LTRpred]{LTRpred}}.
#' @param element.type which width shall be visualized. Full retrotransposon width or only LTR element width: 
#' choose \code{element.type = "full_retrotransposon"} or \code{element.type = "ltr_element"}. 
#' In case \code{element.type = "ltr_element"} is chosen then the width of the left LTR element is 
#' used to visualize width vs. seq. similarity between the LTRs.
#' @param plot.type type of visualization: either \code{plot.type = "boxplot"} or \code{plot.type = "violin"}.
#' @param similarity.bin resolution of similarity binning. E.g. binning 98\%-100\% into 0.5\% intervals would be \code{similarity.bin = 0.5}. 
#' @param min.sim minimum similarity between LTRs that can shall be considered for visualization.
#' @param quality.filter shall false positives be filtered out as much as possible or not. See Description for details.
#' @param n.orfs minimum number of ORFs detected in the putative LTR transposon.
#' @param xlab label of x-axis.
#' @param ylab label of y-axis.
#' @param main title label.
#' @param legend.title title of legend.
#' @param y.ticks number of ticks at the y-axis. Default is \code{y.ticks = 10}.
#' @author Hajk-Georg Drost
#' @details This function visualizes the correlation between LTR transposon age
#' (measured in LTR similarity) and the width of the corresponding LTR retrotransposon (the complete sequence) or the width of the left LTR element. Using this visualization approach, different classes of LTR retrotransposons can be detected due to their width and age correlation.
#' 
#' @examples 
#' \dontrun{
#' # run LTRpred for A. thaliana
#' Ath.Pred <- LTRpred(genome.file = "TAIR10_chr_all.fas",
#'                     trnas       = "plantRNA_Arabidopsis.fsa",
#'                     hmms        = "hmm_*")
#'                     
#' # visualize the collelation between LTR transposon age and width
#' # of predicted  A. thaliana LTR retrotransposons
#' plot_ltrwidth_individual(Ath.Pred, plot.type = "violin")
#' 
#' # visualize the collelation between LTR retrotransposon age and width
#' # of predicted  A. thaliana LTR element
#' plot_ltrwidth_individual(Ath.Pred, element.type = "full_retrotransposon")
#' }
#' @export

plot_ltrwidth_individual <- function(data,
                         element.type   = "full_retrotransposon",
                         plot.type      = "boxplot", 
                         similarity.bin = 2, 
                         min.sim        = 70,
                         quality.filter = FALSE,
                         n.orfs         = 0,
                         xlab           = "LTR % Similarity",
                         ylab           = "LTR Retrotransposon length in bp",
                         main           = "",
                         legend.title   = "Similarity between LTRs",
                         y.ticks        = 10){
    
    if (!is.element(plot.type, c("boxplot","violin")))
        stop("Please choose either type = 'boxplot' or type = 'violin'.", call. = FALSE)
    
    if (!is.element(element.type, c("full_retrotransposon", "ltr_element")))
      stop("Please choose either element.type = 'full_retrotransposon' or element.type = 'ltr_element'.", call. = FALSE)
  
    similarity <- width <- lLTR_length <- ltr_similarity <- NULL
  
    if (quality.filter)
        data <- LTRpred::quality.filter(data, sim = min.sim, n.orfs = n.orfs)
    if (!quality.filter) {
        message("No quality filter has been applied.")
    }
    
    if (!is.null(similarity.bin) & !is.null(min.sim)) {
        
        data <- dplyr::filter(data, ltr_similarity >= min.sim)
        data <- dplyr::mutate(data,
                              similarity = cut(
                                  ltr_similarity,
                                  rev(seq(100, min.sim, -similarity.bin)),
                                  include.lowest = TRUE,
                                  right          = TRUE
                              ))
    }
    
    #max.width <- max(data$ltr.retrotransposon[ , "ltr_similarity"])
    if (element.type == "full_retrotransposon") {
        res <-
            ggplot2::ggplot(data, ggplot2::aes(x = similarity, y = width))
    }
    
    if (element.type == "ltr_element") {
        res <-
            ggplot2::ggplot(data, ggplot2::aes(x = similarity , y = lLTR_length))
    }
    
    if (plot.type == "boxplot") {
        res <-
            res + ggplot2::geom_boxplot(ggplot2::aes(colour = similarity), size = 1.5) +
            ggplot2::geom_point(ggplot2::aes(colour = similarity)) +
            ggplot2::geom_jitter(ggplot2::aes(colour = similarity), position = ggplot2::position_jitter(0.3))
    }
    
    if (plot.type == "violin") {
        res <-
            res + ggplot2::geom_violin(ggplot2::aes(colour = similarity), size = 1.5) +
            ggplot2::geom_point(ggplot2::aes(colour = similarity)) +
            ggplot2::geom_jitter(ggplot2::aes(colour = similarity), position = ggplot2::position_jitter(0.3))
    }
    
    res <-
        res + ggplot2::labs(x = xlab, y = ylab, title = main) +
        ggplot2::scale_fill_discrete(name = legend.title) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
            title            = ggplot2::element_text(size = 18, face = "bold"),
            legend.title     = ggplot2::element_text(size = 18, face = "bold"),
            legend.text      = ggplot2::element_text(size = 18, face = "bold"),
            axis.title       = ggplot2::element_text(size = 18, face = "bold"),
            axis.text.y      = ggplot2::element_text(size = 18, face = "bold"),
            axis.text.x      = ggplot2::element_text(size = 18, face = "bold"),
            panel.background = ggplot2::element_blank(),
            strip.text.x     = ggplot2::element_text(
                size           = 18,
                colour         = "black",
                face           = "bold"
            ),
            panel.grid.major = ggplot2::element_line(color = "gray50", size = 0.5),
            panel.grid.major.x = ggplot2::element_blank()
        ) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(
            angle = 90,
            vjust = 1,
            hjust = 1
        )) +
        ggplot2::scale_y_continuous(breaks = scales::pretty_breaks(n = y.ticks))
    
    return(res)
}


