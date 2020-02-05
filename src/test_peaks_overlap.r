setwd("/Users/eteleeb/Desktop/SV-Hotspot/sv-hotspot_docker_image/SV-HOTSPOT-TEST")

pickTopPeaks <- function (peaks, genes) {
  
  ### function to extract the top peak 
  selectTopPeak <- function (pks) {
    top.peak <- peaks[peaks$Peak.name %in% pks, c('Peak.name', 'Percentage.SV.samples')]
    top.peak <- top.peak[top.peak$Percentage.SV.samples == max(top.peak$Percentage.SV.samples), 'Peak.name']
    return (top.peak)
  }
  
  ### read genes assoicated with the peaks file 
  #genes <- read.table('sv-hotspot-output/genes.associated.with.SVs.tsv', header =T, stringsAsFactors = F, check.names = F)
  #assoc.genes <- unique(genes$Gene)
  
  ### read annotated summary file
  #peaks <- read.table('sv-hotspot-output/annotated_peaks_summary.tsv', header =T, stringsAsFactors=F, check.names=F)
  
  total_samples <- samples.with.sv
  filtered.res <- NULL
  for (i in 1:length(assoc.genes)) {
    g <- assoc.genes[i]
    ### extract peaks assoicated with the gene 
    gene.peaks <- unique(genes[genes$Gene==g, 'Peak.name']) 
    
    ### loop through al peaks and compare 
    all.pairs = as.data.frame(t(combn(as.character(gene.peaks),2)), stringsAsFactors = F)
    colnames(all.pairs) <- c('peak1', 'peak2')
    all.pairs$pval <- 0
    all.pairs$status <- NA
    for (j in 1:nrow(all.pairs)) {
      p1.sample <- unique(unlist(strsplit(peaks[peaks$Peak.name==all.pairs$peak1[j], 'SV.sample'], ",")))
      p2.sample <- unique(unlist(strsplit(peaks[peaks$Peak.name==all.pairs$peak2[j], 'SV.sample'], ",")))
      ov <- length(intersect(p1.sample, p2.sample))
      ss <- total_samples - (length(p1.sample) - ov) - (length(p2.sample) - ov) - ov
      
      test.mat <-matrix(c(ov, length(p1.sample) - ov, 
                          length(p2.sample) - ov,  ss), nrow = 2,
                        dimnames = list(Peak1 = c("yes", "no"),
                                        Peak2 = c("yes", "no")))
      
      test.pval <- fisher.test(test.mat, alternative = "two.sided")$p.value
      all.pairs$pval[j] <- test.pval
      if (test.pval < 0.05) { 
        all.pairs$status[j] <- 'D'
      } else {
        all.pairs$status[j] <- 'I'
      }
      
    }  ## end of all pairs 
    
    ### determine the status of the peaks
    if (nrow(all.pairs[all.pairs$status=="I", ])==0) {
      topPeak <- selectTopPeak(gene.peaks) 
      d <- data.frame(Gene=g, Peak.name = topPeak)
      filtered.res <- rbind(filtered.res, d)
    } else {
      dep.peaks <- all.pairs[all.pairs$status=="D", c('peak1', 'peak2')]
      dep.peaks <- unique(c(dep.peaks$peak1, dep.peaks$peak2))
      topPeak <- selectTopPeak(gene.peaks) 
      d <- data.frame(Gene=g, Peak.name = topPeak)
      filtered.res <- rbind(filtered.res, d)
      
      indep.peaks <- all.pairs[all.pairs$status=="I", c('peak1', 'peak2')]
      indep.peaks <- unique(c(indep.peaks$peak1, indep.peaks$peak2))
      
      ### loop through the indepdendent peaks and check if they are not in the dependent group
      for (k in 1:length(indep.peaks)) {
        if (!indep.peaks[k] %in% dep.peaks) {
          d2 <- data.frame(Gene=g, Peak.name = indep.peaks[k])
          filtered.res <- rbind(filtered.res, d2)
        }
      } ## end of independent peaks 
      
    }
    
    
  }    ## end of all genes 
  
  ### filter results 
  genes.final <- merge(genes, filtered.res, sort =F)
  annot.pks.final <- peaks[peaks$Peak.name %in% filtered.res$Peak.name, ]
}



