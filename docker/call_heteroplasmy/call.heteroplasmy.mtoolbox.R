### PREAMBLE ######################################################################################
library(argparse);
library(cpcgene.utilities);
### call.heteroplasmy.R ################################################################
# 
#
### OBTAIN COMMAND LINE ARGUMENTS #################################################################
parser <- ArgumentParser();
parser$add_argument('-i', '--sample.id', type = 'character');
parser$add_argument('-n', '--normal.table', type = 'character');
parser$add_argument('-t', '--tumour.table', type = 'character');
parser$add_argument('-r', '--reference', type = 'character');
parser$add_argument('-o', '--output.dir', type = 'character');
parser$add_argument('-hf', '--heteroplasmy.fraction.diff', default = 0.2, type = 'double');
parser$add_argument('-m', '--min.coverage', default = 100, type = 'double');

args <- parser$parse_args();

#/.mounts/labs/cpcgene/private/projects/500pg/analysis/mt/test_gsnap_2017_10_12/CPCG0434/RunMToolBox/RSRS/OUT_CPCG0434-B1_mitochondria/CPCG0434-B1_mitochondria-table.txt
#/.mounts/labs/cpcgene/private/projects/500pg/analysis/mt/test_gsnap_2017_10_12/CPCG0434/RunMToolBox/RSRS/OUT_CPCG0434-F1_mitochondria/CPCG0434-F1_mitochondria-table.txt

######## Function ############################################################

get.adjusted.hf <- function(normal.HF, tumour.HF, cellularity = 1){

	#adjust HF based on qpure cellularity. the results should be identifical when cellularity = 1 (default)
	adjusted.tumour.HF <- ( tumour.HF - (1 - cellularity) * normal.HF ) / cellularity;

	# no HF more than 1 or less than 0
	adjusted.tumour.HF[adjusted.tumour.HF > 1] <- 1;
	adjusted.tumour.HF[adjusted.tumour.HF < 0] <- 0;

	return(adjusted.tumour.HF);

	}

# function to read in the table file
read.mt.table <- function(x, type) {

	#some positions are N and ConsNuc is #
	table <- read.table(x, header=TRUE, comment.char = '', sep="\t", as.is=TRUE, stringsAsFactors=FALSE);

	#parse base counts and create dataframe
	base.count <- gsub('[(|,|)]', '', table$BaseCount.A.C.G.T.);
	
	#split by space and make sure that counts are numeric
	base.count <- lapply(strsplit(base.count, "\\s"), as.numeric);
	
	base.count <- data.frame(do.call(rbind, base.count));
	
	#remove the original basecount column and cbind the parsed data with the subsetted data
	position.base <- table[,c('Position', 'RefNuc')];
	
	sample.specific.data <- table[,c('ConsNuc', 'Cov', 'MeanQ')];

	#calcluate heteroplasmy fraction
	het.frac <- base.count / sample.specific.data$Cov; 
	
	#define names
	base <- c('A', 'C', 'G', 'T'); # keep this order <- mtoolbox output
	sample.specific.data.name <- c('ConsNuc', 'Total.Coverage', 'MeanQ');
	
	#get max heteroplasmy fraction and its base for each pos
	HF.max <- apply(het.frac, 1, max);
	HF.max.base <- apply(het.frac, 1, function(x){ 

							max.base <- base[which( x == max(x))] 
							# this is possible --- will deal with it later.
							#if(length(max.base) > 1){stop (max.base, "in pos", count ," more than 2 bases were found\n");}

							return(paste(max.base, collapse = ','));

							});

	#combine them together
	data <- cbind(sample.specific.data, base.count, het.frac, HF.max, HF.max.base, stringsAsFactors=FALSE);

	#set colnames for normal and tumour
	data <- setNames(data, c(paste(sample.specific.data.name, type, sep='.'), paste(base, type, sep='.'), paste(base, type, 'HF', sep='.'), paste('HF.max', type, sep='.'), paste('HF.max.base', type, sep='.')));	
	
	#cbind pos and data
	out <- list();

	out$all <- cbind(position.base, data);
	out$data <- data;

	return(out);

	}


######## read in mtoolbox -table.txt files for both tumour & normal separately
normal.data <- read.mt.table(args$normal.table, type = 'normal');
tumour.data <- read.mt.table(args$tumour.table, type = 'tumour');

data <- cbind(normal.data$all, tumour.data$data);

#get qpure cellularity 


#adjust hf by cellularity
base <- c('A', 'C', 'G', 'T'); # keep this order <- mtoolbox output

for (i in base){
	#create column names
	normal.col.name <- paste0(base, '.normal.HF');
	tumour.col.name <- paste0(base, '.tumour.HF');
	adjusted.HF.col.name <- paste('adjusted', base, 'tumour.HF', sep='.');
	adjusted.HF.diff.col.name <- paste('adjusted', base, 'HF.diff', sep='.');

	data[,adjusted.HF.col.name] <- get.adjusted.hf(data[,normal.col.name], data[,tumour.col.name]);
	data[,adjusted.HF.diff.col.name] <- data[,tumour.col.name] - data[,normal.col.name];
	
	}

#bases with minimum change in VAF between normal and tumour
data$diff.HF.min.base <- apply(data[,adjusted.HF.diff.col.name], 1, function(x){ 
		
		paste(base[which( x == min(x))], collapse = ',');
		
		});
#bases with largest VAF in tumour relative to normal
data$diff.HF.max.base <- apply(data[,adjusted.HF.diff.col.name], 1, function(x){ 
		
		paste(base[which( x == max(x))], collapse = ',');
		
		});

#HF abs diff max
data$diff.HF.abs <- apply(data[,adjusted.HF.diff.col.name], 1, function(x){
		
		max(abs(x));
		
		});
#bases with HF abs diff max
data$diff.HF.abs.bases <- apply(data[,adjusted.HF.diff.col.name], 1, function(x){
		
		paste(base[which( abs(x) == max(abs(x)))], collapse = ',');
		
		});

#flag somatic heteroplasmy
data$somatic.heteroplasmy <- apply(data[,adjusted.HF.diff.col.name], 1, function(x){
				
			#skip low coverage positions
			if(any(is.na(x))){

				somatic.heteroplasmy <- 0;

				} else if(any(abs(x) > args$heteroplasmy.fraction.diff)){
					
					somatic.heteroplasmy <- 1;

				} else {

					somatic.heteroplasmy <- 0;

					}
			
			});

#output all positions
outfile.name <- paste0(args$sample.id,  '_heteroplasmy_call.tsv');

write.table(data, file.path(args$output.dir, outfile.name), sep='\t', row.names = FALSE, quote=FALSE); 


#In the RSRS (Reconstructed Sapiens Reference Sequence) reference genome, 523, 524 and 3107 are N's used to preserve historical numbering
#In the rCRS (revised Cambridge Reference Sequence) genome, only 3107 is an N. 523-524 are AC. However these positions are commonly deleted which is why they are not in RSRS. 
#Position 310, a homopolymer stretch is commonly misaligned, is removed from consideration as well.
data <- data[!data$Position %in% c('310','523','524','3107'),];

# apply coverage filter
data <- subset(data, Total.Coverage.normal >= args$min.coverage & Total.Coverage.tumour >= args$min.coverage);

#call somatic heteroplasmy
heteroplasmy.call <- subset(data, somatic.heteroplasmy == 1);

#output results
outfile.name <- paste0(args$sample.id,  '_filtered_heteroplasmy_call.tsv');

write.table(heteroplasmy.call, file.path(args$output.dir, outfile.name), row.names = FALSE, sep='\t', quote=FALSE); 

#annotation
#mitochondria.genome <- read.table('~/cpcgene/private/projects/mitochondrial_survey/Analysis/mitochondriagenomeloci.txt', sep='\t', header=TRUE, stringsAsFactors=FALSE);
#filteredsomatic.data$TotalLocus <- mitochondria.genome[c(filteredsomatic.data$Position),'TotalLoci']

