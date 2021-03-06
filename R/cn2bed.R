#' @title Write copy number estimation results to BED file format.
#' @description Format copy number estimation output to BED file format.
#' @param cn.pred \code{data.frame} object returned by \code{\link{ltr.cn}} (if \code{type = "solo"}).
#' @param type type of copy number estimation: \code{\link{ltr.cn}} (if \code{type = "solo"}).
#' @param filename name of the output file (will be extended by "*.csv").
#' @param sep column separator.
#' @param output path in which the output file shall be stored.
#' @author Hajk-Georg Drost
#' @seealso \code{\link{ltr.cn}}, \code{\link{LTRpred}}
#' @export

cn2bed <- function(cn.pred, 
                   type = "solo", 
                   filename = "copy_number_est", 
                   sep = "\t", 
                   output = NULL) {
    
    if (!is.element(type, c("solo", "te")))
        stop("Please choose either 'solo' or 'te' as type.")
    query_id <- subject_id <- s_start <- s_end <- strand <- bit_score <- chromosome <- start <- end <- ID <- bit_score <- strand <- NULL
    
    cn.pred <- dplyr::mutate(
        cn.pred,
        chromosome = subject_id,
        ID = query_id,
        start = s_start,
        end = s_end
    )
    
    if (type == "solo") {
        if (is.null(output))
            utils::write.table(
                dplyr::select(
                    cn.pred,
                    chromosome,
                    start,
                    end,
                    ID,
                    bit_score,
                    strand
                ),
                file = paste0(filename, ".bed"),
                sep = sep,
                row.names = FALSE,
                col.names = FALSE
            )
        
        if (!is.null(output))
            utils::write.table(
                dplyr::select(
                    cn.pred,
                    chromosome,
                    start,
                    end,
                    ID,
                    bit_score,
                    strand
                ),
                file = file.path(output, paste0(filename, ".bed")),
                sep = sep,
                row.names = FALSE,
                col.names = FALSE
            )
    }
}
