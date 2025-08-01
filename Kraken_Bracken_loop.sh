# --- SETUP ---

# Directories
RAW_INPUT_DIR="/home/projects/Agribiome/IN_RICHES/class_dataset/processed_reads"
KRAKEN_OUTPUT_DIR="/home/projects/Agribiome/IN_RICHES/class_dataset/kraken_out"
BRACKEN_OUTPUT_DIR="${KRAKEN_OUTPUT_DIR}/bracken_out"
KRONA_OUTPUT_DIR="${BRACKEN_OUTPUT_DIR}/krona_tables"
DB_DIR="/home/projects/Agribiome/SPUR_green_roofs/MetaG/Kraken/kraken_fungi_db"
KRONA_SCRIPT="/home/projects/Agribiome/IN_RICHES/KrakenTools/kreport2krona.py"

# Make output directories
mkdir -p "$KRAKEN_OUTPUT_DIR" "$BRACKEN_OUTPUT_DIR" "$KRONA_OUTPUT_DIR"

# Sample list
SAMPLES=(
  "Josh_NT10_1_2"
  "Josh_NT10_1_4"
  "Josh_NT10_1_7"
  "Josh_NT30_1_1"
  "Josh_NT30_1_3"
  "Josh_NT30_1_7"
)

# --- STEP 1: Kraken2 ---
echo "Running Kraken2 classification..."
for SAMPLE in "${SAMPLES[@]}"; do
  echo "Running Kraken2 for $SAMPLE..."

  R1="${RAW_INPUT_DIR}/${SAMPLE}_R1_trimmed_bbduk.fastq"
  R2="${RAW_INPUT_DIR}/${SAMPLE}_R2_trimmed_bbduk.fastq"
  REPORT="${KRAKEN_OUTPUT_DIR}/${SAMPLE}_fungal_report.txt"
  OUTPUT="${KRAKEN_OUTPUT_DIR}/${SAMPLE}_fungal_output.txt"
  CLASSIFIED="${KRAKEN_OUTPUT_DIR}/${SAMPLE}_classified#_R#.fq"
  UNCLASSIFIED="${KRAKEN_OUTPUT_DIR}/${SAMPLE}_unclassified#_R#.fq"

  # Skip if input files are missing
  if [[ ! -f "$R1" || ! -f "$R2" ]]; then
    echo "Missing input files for $SAMPLE. Skipping."
    continue
  fi

  kraken2 \
    --db "$DB_DIR" \
    --threads 20 \
    --paired "$R1" "$R2" \
    --report "$REPORT" \
    --output "$OUTPUT" \
    --classified-out "$CLASSIFIED" \
    --unclassified-out "$UNCLASSIFIED"
done

# --- STEP 2: Bracken ---
echo "Running Bracken refinement..."
for SAMPLE in "${SAMPLES[@]}"; do
  echo "Running Bracken for $SAMPLE..."

  REPORT="${KRAKEN_OUTPUT_DIR}/${SAMPLE}_fungal_report.txt"
  B_REPORT="${BRACKEN_OUTPUT_DIR}/${SAMPLE}_bracken_report.txt"
  B_OUTPUT="${BRACKEN_OUTPUT_DIR}/${SAMPLE}_bracken_output.txt"

  if [[ ! -f "$REPORT" ]]; then
    echo "Missing Kraken report for $SAMPLE. Skipping Bracken."
    continue
  fi

  bracken \
    -d "$DB_DIR" \
    -i "$REPORT" \
    -r 151 \
    -t 10 \
    -o "$B_OUTPUT" \
    -w "$B_REPORT"
done

# --- STEP 3: kreport2krona + Labeling ---
echo "Generating Krona tables with sample labels..."
for SAMPLE in "${SAMPLES[@]}"; do
  echo "Processing $SAMPLE for Krona..."

  BRACKEN_REPORT="${BRACKEN_OUTPUT_DIR}/${SAMPLE}_bracken_report.txt"
  KRONA_OUT="${KRONA_OUTPUT_DIR}/${SAMPLE}_krona_table.txt"
  KRONA_LABELED="${KRONA_OUTPUT_DIR}/${SAMPLE}_krona_table_with_sample.txt"

  if [[ ! -f "$BRACKEN_REPORT" ]]; then
    echo "Missing Bracken report for $SAMPLE. Skipping Krona."
    continue
  fi

  python "$KRONA_SCRIPT" -r "$BRACKEN_REPORT" -o "$KRONA_OUT"
  awk -v sample="$SAMPLE" 'BEGIN{OFS="\t"} {print sample, $0}' "$KRONA_OUT" > "$KRONA_LABELED"
done 
