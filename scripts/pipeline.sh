#Download all the files specified in data/filenames
for url in $(<data/urls/list_of_urls>) #TODO
do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes #TODO

# Index the contaminants file
bash scripts/index.sh res/filtered_contaminants.fasta res/filtered_contaminants_idx

# Merge the samples into a single file
for sid in $(basename -s .fastq.gz -a data/*.fastq.gz | sort -u) #TODO
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
for infile in out/merged/*.fastq.gz
do
sid=$(basename "$infile".fastq.gz)
trimmed_file="out/trimmed/${sid}.trimmed.fastq.gz"
log_file="log/cutadapt/${sid}.log"
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
     -o "$trimmed_file" "$infile" > "$log_file"
done

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename "$fname".trimmed.fastq.gz)
    output_directory="out/star/$sid"
    mkdir -p "$output_directory"
    STAR --runThreadN 4 --genomeDir res/filtered_contaminants_idx \
        --outReadsUnmapped Fastx --readFilesIn "$trimmed_file" \
       --readFilesCommand gunzip -c --outFileNamePrefix "$output_directory"
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
for sid in $(basename -s .trimmed.fastq.gz -a out/trimmed/*.fastq.gz | sort -u) # Extract unique sample IDs
do
    cutadapt_log="log/cutadapt/${sid}.log"
    star_log="out/star/${sid}/Log.final.out"
    pipeline_log="log/pipeline.log"

cutadapt_info=$(grep "Reads with adapters" "$cutadapt_log")
cutadapt_bp_info=$(grep "Total basepairs processed" "$cutadapt_log")

star_info=$(grep -E "Uniquely mapped reads|Number of reads mapped to multiple loci|Number of reads mapped to too many loci" "$star_log")

 echo "Sample: $sid" >> "$pipeline_log"
    echo "Cutadapt Info: $cutadapt_info" >> "$pipeline_log"
    echo "Cutadapt Basepair Info: $cutadapt_bp_info" >> "$pipeline_log"
    echo "STAR Info: $star_info" >> "$pipeline_log"
    echo "----------------------------------------" >> "$pipeline_log"
done
