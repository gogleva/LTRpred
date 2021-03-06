#' @title Perform Meta-Analyses with LTRpred
#' @description Run \code{\link{LTRpred}} on several genomes (sequentially) that are stored in a given folder.
#' @param genome.folder path to the folder storing all unmasked genomes for which \code{\link{LTRpred}}
#' based \code{de novo} LTR retrotransposon prediction shall be performed.
#' @param result.folder folder in which \code{LTRpred} results shall be stored.
#' @param sim similarity threshold for defining LTR similarity.
#' @param cut.range range to bin similarity values (e.g.(98,100])).
#' @param quality.filter shall false positives be filtered out as much as possible or not. 
#' See \code{Description} for details.
#' @param n.orfs minimum number of Open Reading Frames that must be found between the LTRs (if \code{quality.filter = TRUE}). See \code{Details} for further information on quality control. 
#' @param file.name name of the \code{*._SimilarityMatrix.csv} and \code{*.GenomeInfo.csv} file generated by this function.
#' @param LTRpred.meta.folder meta-folder storing already pre-cumputed \code{\link{LTRpred}} generated files.
#' @param \dots all parameters of \code{\link{LTRpred}}.
#' @author Hajk-Georg Drost
#' @details 
#' This function provides a crawler to run \code{\link{LTRpred}} sequencially
#' on any number of genomes stored within the same folder.
#' The result will be saved on in the \code{result.folder} and can be analysed with the
#' \code{\link{meta.apply}} function.
#' 
#' \strong{Quality Control}
#' 
#' \itemize{
#' \item \code{ltr.similarity}: Minimum similarity between LTRs. All TEs not matching this
#'  criteria are discarded.
#'  \item \code{n.orfs}: minimum number of Open Reading Frames that must be found between the
#'   LTRs. All TEs not matching this criteria are discarded.
#'  \item \code{PBS or Protein Match}: elements must either have a predicted Primer Binding
#'  Site or a protein match of at least one protein (Gag, Pol, Rve, ...) between their LTRs. All TEs not matching this criteria are discarded.
#'  \item The relative number of N's (= nucleotide not known) in TE <= 0.1. The relative number of N's is computed as follows: absolute number of N's in TE / width of TE.
#' }
#' 
#' @return 
#' \itemize{
#' \item a file \code{*_SimilarityMatrix.csv} is generated and stored in the working directory. It contains the following columns:
#'  \itemize{
#'  \item \code{organism} : name of the species.
#'  \item binned similarity columns.
#'  }
#' \item a file \code{*_GenomeInfo.csv} is generated and stored in the working directory.
#' It contains the following columns:
#'  \itemize{
#'  \item \code{organism} : name of the species.
#'  \item \code{nLTRs} : absolute number of de novo predicted LTR retrotransposons.
#'  \item \code{totalMass} : total length of all de novo predicted LTR retrotransposons combined.
#'  \item \code{prop} : totalMass / genome.size.
#'  \item \code{norm.LTRs} : absolute number of de novo predicted LTR retrotransposons divided by genome size in mega bp.
#'  \item \code{genome.size} : in mega bp.
#'  \item \code{genome.quality} : absolute number of N's in genome / total nucleotides in genome.
#'   }
#' }
#' 
#' @examples 
#' \dontrun{
#' # perform a meta analysis on multiple genomes
#' # stored in a genomes folder
#' LTRpred.meta(genome.folder = "Genomes/",
#'              result.folder = "LTRpredResults"
#'              trnas         = "plantRNA_Arabidopsis.fsa",
#'              hmms          = "hmm_*")
#' }
#' @export
   
LTRpred.meta <- function(genome.folder       = NULL, 
                         result.folder       = NULL,
                         sim                 = 70,
                         cut.range           = 2,
                         quality.filter      = TRUE,
                         n.orfs              = 1,
                         file.name           = NULL,
                         LTRpred.meta.folder = NULL, 
                         ...){
  
  
    if (length(rev(seq(100, sim, -cut.range))) == 1L)
        stop("Please specify a 'cut.range' value that is compatible with the 'sim' threshold. ",
             "The input 'cut.range = ",cut.range,"', whereas the similarity bin is between: [",sim,",100].", call. = FALSE)
    
    if (!is.null(genome.folder) &&
        is.null(result.folder) &&
        !is.null(LTRpred.meta.folder)) {
        if (!file.exists(genome.folder))
            stop("The folder ' ", genome.folder, " ' could not be found.")
        
        ltr_similarity <- similarity <- PBS_start <- protein_domain <- orfs <- width <- TE_N_abs <- NULL
        
        message("\n")
        message("Starting LTRpred meta analysis on the following files: ")
        genomes <- list.files(genome.folder)
        genomes <- genomes[!stringr::str_detect(genomes, "doc_")]
        genomes <- genomes[!stringr::str_detect(genomes, "md5cheksum")]
        
        message("\n")
        message(paste(list.files(LTRpred.meta.folder), collapse = ", "))
        message("\n")
        if (quality.filter)
            message(
                "Apply filters: [ similarity >= ",
                sim,
                "% ] ; [ PBS or Protein Match ] ; [ #ORFs >= ",
                n.orfs,
                "] ; [rel #N's in TE <= 0.1]"
            )
        
        if (!quality.filter)
            message("No quality filter was applied...")
        
        message("\n")

        
        result.files <- list.files(LTRpred.meta.folder)
        folders0 <-
            result.files[stringr::str_detect(result.files, "ltrpred")]
        
        genomes.chopped <-
            sapply(genomes, function(x)
                unlist(stringr::str_split(x, "[.]"))[1])
        
        ltrpred.folder.files.chopped <-
            sapply(folders0, function(x)
                unlist(stringr::str_replace(x, "_ltrpred", "")))
        
        available.genomes <-
            match(ltrpred.folder.files.chopped, genomes.chopped)
        
        genomes <- genomes[available.genomes]
        
        if (length(folders0) != length(genomes))
            stop (
                "Please make sure that the number of your genome files matches with your LTRpred folders."
            )
        
        if (length(folders0) < 1) {
            stop ("No folders to be processed...")
        }
        
        SimMatrix <- vector("list", length(folders0))
        nLTRs <- vector("numeric", length(folders0))
        nLTRs.normalized <- vector("numeric", length(folders0))
        gs <- vector("numeric", length(folders0))
        total.LTR.mass <- vector("numeric", length(folders0))
        LTR.prop <- vector("numeric", length(folders0))
        genome.quality <- vector("numeric", length(folders0))
        
        cat("Processing file:")
        cat("\n")
        for (i in 1:length(folders0)) {
            choppedFolder <- unlist(stringr::str_split(folders0[i], "_"))
            print(file.path(
                LTRpred.meta.folder,
                folders0[i],
                paste0(
                    paste0(choppedFolder[-length(choppedFolder)], collapse = "_"),
                    "_LTRpred_DataSheet.csv"
                )
            ))
            cat("\n")

            if (!file.exists(file.path(
                LTRpred.meta.folder,
                folders0[i],
                paste0(
                    paste0(choppedFolder[-length(choppedFolder)], collapse = "_"),
                    "_LTRpred_DataSheet.csv"
                )
            ))) {
                print(paste0(
                    "Skip :",
                    file.path(
                        LTRpred.meta.folder,
                        folders0[i],
                        paste0(
                            paste0(choppedFolder[-length(choppedFolder)], collapse = "_"),
                            "_LTRpred_DataSheet.csv"
                        )
                    ),
                    " -> folder was empty!"
                ))
                cat("\n")
            } else {
                pred <- read.ltrpred(file.path(
                    LTRpred.meta.folder,
                    folders0[i],
                    paste0(
                        paste0(choppedFolder[-length(choppedFolder)], collapse = "_"),
                        "_LTRpred_DataSheet.csv"
                    )
                ))
                
                if (quality.filter) {
                    # try to reduce false positives by filtering for PBS and ORFs and rel #N's in TE <= 0.1
                    pred <- quality.filter(pred, sim = sim, n.orfs = n.orfs)
                }
                
                if (!quality.filter) {
                    # keep all predicted LTR transposons including false positives
                    pred <- dplyr::filter(pred, ltr_similarity >= sim)
                    message("No quality filter has been applied. Threshold: sim = ",sim,"%.")
                }
                
                #dplyr::group_by(pred,similarity)
              
                binned.similarities <- cut(
                    pred$ltr_similarity,
                    rev(seq(100, sim, -cut.range)),
                    include.lowest = TRUE,
                    right = TRUE
                )
                
                # implement error handling here or a more dynamic approach
                # to handle different bin ranges in different organisms 
                # sim.mass.summary <- dplyr::summarize(dplyr::group_by(pred,similarity), mass = sum(width) / 1000000)
                #                  
                # SimMatrix[i] <- list(sim.mass.summary)
                # 
                
                SimMatrix[i] <- list(table(factor(
                  binned.similarities,
                  levels = levels(binned.similarities)
                )))
                
                # count the number of predicted LTR transposons
                nLTRs[i] <- length(unique(pred$ID))
                # determine the total length of all LTR transposons in Mega base pairs
                total.LTR.mass[i] <- sum(pred$width) / 1000000
                # determine the genome size
                genome.size <-
                    Biostrings::readDNAStringSet(file.path(genome.folder, genomes[i]))
                # compute genome size in Mega base pairs
                gs[i] <- sum(as.numeric(genome.size@ranges@width)) / 1000000
                
                # compute normalized LTR count: LTR count / genome size in Mbp
                nLTRs.normalized[i] <-
                    as.numeric(length(unique(pred$ID)) / gs[i])
                # compute the proportion of LTR retrotransposons with the entire genome
                LTR.prop[i] <- total.LTR.mass[i] / gs[i]
                
                # compute relative frequency of N's in genome: abs N / genome length
                genome.quality[i] <- sum(as.numeric(Biostrings::vcountPattern("N", genome.size))) / sum(as.numeric(genome.size@ranges@width))
            }
        }
        
        names(nLTRs) <- folders0
        names(nLTRs.normalized) <- folders0
        names(gs) <- folders0
        
        GenomeInfo <- data.frame(
            organism    = genomes.chopped[available.genomes],
            nLTRs       = nLTRs,
            totalMass   = total.LTR.mass,
            prop        = LTR.prop,
            norm.nLTRs  = nLTRs.normalized,
            genome.size = gs,
            genome.quality = genome.quality
        )
        
        SimMatrix <- do.call(rbind, SimMatrix)
        SimMatrix <- data.frame(organism = genomes.chopped[available.genomes], SimMatrix)
        
        if (!is.null(file.name)) {
            # store results in working directory
            utils::write.table(
                SimMatrix,
                paste0(file.name, "_SimilarityMatrix.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
            
            utils::write.table(
                GenomeInfo,
                paste0(file.name, "_GenomeInfo.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
        }
        
        if (is.null(file.name)) {
            # store results in working directory
            utils::write.table(
                SimMatrix,
                paste0(
                    basename(LTRpred.meta.folder),
                    "_SimilarityMatrix.csv"
                ),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
            
            utils::write.table(
                GenomeInfo,
                paste0(basename(LTRpred.meta.folder), "_GenomeInfo.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
        }
        
        cat("Finished meta analysis!")
        
    } else {
        if (!file.exists(genome.folder))
            stop ("The folder ' ", genome.folder, " ' could not be found.")
        
        cat("\n")
        cat("Starting LTRpred meta analysis on the following genomes: ")
        genomes <- list.files(genome.folder)
        genomes <- genomes[!stringr::str_detect(genomes, "doc_")]
        genomes <- genomes[!stringr::str_detect(genomes, "md5cheksum")]
        
        cat("\n")
        cat("\n")
        cat(paste(genomes, collapse = ", "))
        cat("\n")
        cat("\n")
        cat("\n")
        if (quality.filter)
            cat(
                "Apply filters: [ similarity >= ",
                sim,
                "% ] ; [ PBS or Protein Match ] ; [ #ORFs >= ",
                n.orfs,
                "] ; [rel #N's in TE <= 0.1]"
            )
        
        if (!quality.filter)
            cat("No quality filter was applied...")
        
        cat("\n")

        genome.names.chopped <-
            sapply(genomes, function(x)
                unlist(stringr::str_split(x, "[.]"))[1])
        
        # run meta analysis for all species sequencially
        for (i in 1:length(genomes)) {
            LTRpred(genome.file = file.path(genome.folder, genomes[i]), ...)
        }
        
        if (!is.null(result.folder)) {
            # store results in result folder -> default: working directory
            file.move(
                from = paste0(genome.names.chopped, "_ltrpred"),
                to   = file.path(
                    result.folder,
                    paste0(genome.names.chopped, "_ltrpred")
                )
            )
        }
        
        if (!is.null(result.folder))
          result.files <- list.files(result.folder)
        
        if (is.null(result.folder))
          result.files <- list.files(getwd())
        
        folders0 <-
            result.files[stringr::str_detect(result.files, "ltrpred")]
        SimMatrix <- vector("list", length(folders0))
        nLTRs <- vector("numeric", length(folders0))
        nLTRs.normalized <- vector("numeric", length(folders0))
        gs <- vector("numeric", length(folders0))
        total.LTR.mass <- vector("numeric", length(folders0))
        LTR.prop <- vector("numeric", length(folders0))
        genome.quality <- vector("numeric", length(folders0))
    
        
        for (i in 1:length(folders0)) {
            choppedFolder <- unlist(stringr::str_split(folders0[i], "_"))
            pred <- read.ltrpred(file.path(
                result.folder,
                folders0[i],
                paste0(
                    paste0(choppedFolder[-length(choppedFolder)], collapse = "_"),
                    "_LTRpred_DataSheet.csv"
                )
            ))
            
            if (quality.filter) {
                # try to reduce false positives by filtering for PBS and ORFs and rel #N's in TE <= 0.1
                pred <- dplyr::filter(pred,
                                      ltr_similarity >= sim, (TE_N_abs / width) <= 0.1,
                                      (!is.na(PBS_start)) |
                                          (!is.na(protein_domain)),
                                      orfs >= n.orfs)
            }
            
            if (!quality.filter) {
                # keep all predicted LTR transposons including false positives
                pred <- dplyr::filter(pred, ltr_similarity >= sim)
            }
            
            binned.similarities <- cut(
                pred$ltr_similarity,
                rev(seq(100, sim, -cut.range)),
                include.lowest = TRUE,
                right = TRUE
            )
            
            # implement error handling here or a more dynamic approach
            # to handle different bin ranges in different organisms 
            # sim.mass.summary <- dplyr::summarize(dplyr::group_by(pred,similarity), mass = sum(width) / 1000000)
            # SimMatrix[i] <- list(sim.mass.summary)
            
            SimMatrix[i] <- list(table(factor(
                binned.similarities,
                levels = levels(binned.similarities)
            )))
            
            # count the number of predicted LTR transposons
            nLTRs[i] <- length(unique(pred$ID))
            # determine the total length of all LTR transposons in Mega base pairs
            total.LTR.mass[i] <- sum(pred$width) / 1000000
            # determine the genome size
            genome.size <-
                Biostrings::readDNAStringSet(file.path(genome.folder, genomes[i]))
            # compute genome size in Mega base pairs
            gs[i] <- sum(as.numeric(genome.size@ranges@width)) / 1000000
            
            # compute normalized LTR count: LTR count / genome size in Mbp
            nLTRs.normalized[i] <-
                as.numeric(length(unique(pred$ID)) / gs[i])
            # compute the proportion of LTR retrotransposons with the entire genome
            LTR.prop[i] <- total.LTR.mass[i] / gs[i]
            
            # compute relative frequency of N's in genome: abs N / genome length
            genome.quality[i] <- sum(as.numeric(Biostrings::vcountPattern("N", genome.size))) / sum(as.numeric(genome.size@ranges@width))
        }
        
        names(nLTRs) <- folders0
        names(nLTRs.normalized) <- folders0
        names(gs) <- folders0
        
        GenomeInfo <- data.frame(
            organism    = genomes,
            nLTRs       = nLTRs,
            totalMass   = total.LTR.mass,
            prop        = LTR.prop,
            norm.nLTRs  = nLTRs.normalized,
            genome.size = gs,
            genome.quality = genome.quality
        )
        
        SimMatrix <- do.call(rbind, SimMatrix)
        SimMatrix <- data.frame(organism = genomes , SimMatrix)
        
        if (!is.null(file.name)) {
            # store results in working directory
            utils::write.table(
                SimMatrix,
                paste0(file.name, "_SimilarityMatrix.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
            
            utils::write.table(
                GenomeInfo,
                paste0(file.name, "_GenomeInfo.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
        }
        
        if (is.null(file.name)) {
            # store results in working directory
            utils::write.table(
                SimMatrix,
                paste0(basename(result.folder), "_SimilarityMatrix.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
            
            utils::write.table(
                GenomeInfo,
                paste0(basename(result.folder), "_GenomeInfo.csv"),
                sep       = ";",
                quote     = FALSE,
                col.names = TRUE,
                row.names = FALSE
            )
        }
        cat("Finished meta analysis!")
    }
}








