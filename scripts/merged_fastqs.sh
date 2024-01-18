# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <samples_directory> <output_directory> <sample_id>"
    exit 1
fi

samples_directory="$1"
output_directory="$2"
sample_id="$3"

mkdir -p "$output_directory"

cat "$samples_directory"/"$sample_id" > "$output_directory/merged_sample_${sample_id}.txt"
