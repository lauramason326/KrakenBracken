## 1) First step, after downloading Kraken is to build the database

```
kraken2-build --download-taxonomy --db custom_db
```

## 2) The next step is to get a list of taxonomy IDs from NCBI, even if the database you are making isn't from NCBI

```
kraken2-build --download-taxonomy --db /home/projects/Agribiome/Kraken2_fungi_db/kraken_fungi_db
```

## 3) Download databases 
### Ensembl 
- Go to this page http://ftp.ensemblgenomes.org/pub/fungi/release-61/fasta

- Download the dir
```
mkdir -p ensembl_fungi && cd ensembl_fungi
wget -r -nH --cut-dirs=5 -A "*.fa.gz" -np -R "index.html*" \
ftp://ftp.ensemblgenomes.org/pub/fungi/release-61/fasta/
```

I pulled the file names from the ensembl dir I downloaded last week and clean up the list:

```
ls ensembl_fungi/ > species_list.txt
cut -d'_' -f1,2 species_list.txt
sort -u species_list.txt > species_u.txt
sed -i 's/_/ /g' species_u.txt
```

### FungiDB

- go to the FungiDB preferred organisms page
- select fungi (not oomycetes), release 67, fasta, and genome = 282 fasta files
- copy-paste this list into Excel
 use a macro to generate the list as a batch: 
1. Open your Excel workbook
2. Press `Fn + Option + F11`
3. In the VBA Editor, go to Insert > Module.
    
4. Paste this macro code:
   
    Function GetURL(cell As Range) As String
    On Error Resume Next
    GetURL = cell.Hyperlinks(1).Address
End Function

    
5. Press `Command + S` and save your workbook as macro-enabled (`.xlsm`).
    
6. Close the editor.
    
7. Back in your spreadsheet, use the formula like this in **Column B**:
    `=GetURL(A2)`
    Fill down the column to extract all URLs.
    
Save just the urls in a file called: fungi_urls.txt and upload to the Kraken2_fungi_db folder server via filezilla

```
mkdir -p fungidb_genomes
cd fungidb_genomes
wget -i ../fungi_urls.txt
```

## put all genomes into one directory and unzip

## 4) Reformat headers
#### no headers (even those from NCBI) are formatted improperly and need to be reformated

```
mapfile -t species_list < species_keys.txt

Create or clear the output file
> species_with_taxids.tsv

Loop over the array
for species in "${species_list[@]}"; do
  echo "Searching: $species" >&2
  taxid=$(esearch -db taxonomy -query "$species" | efetch -format uid)

  if [ -z "$taxid" ]; then
    echo -e "$species\tNOT_FOUND" >> species_with_taxids.tsv
  else
    echo -e "$species\t$taxid" >> species_with_taxids.tsv
  fi
done
```
### Rename headers
```
TAXID_TABLE="genome_taxid_table.tsv"
GENOME_DIR="."
OUT_DIR="kraken_ready_fastas"

mkdir -p "$OUT_DIR"

tail -n +2 "$TAXID_TABLE" | while IFS=$'\t' read -r file taxid; do
    input_file="$GENOME_DIR/$file"
    output_file="$OUT_DIR/$file"

    if [ ! -f "$input_file" ]; then
        echo "⚠️  Missing input: $input_file"
        continue
    fi

    echo "  Fixing: $file with taxid $taxid"

    awk -v taxid="$taxid" -v base="$(basename "$file" .fasta)" '
        BEGIN { count = 0 }
        /^>/ {
            count += 1
            print ">kraken_seq_" base "_" count "|kraken:taxid|" taxid
            next
        }
	{ print }
    ' "$input_file" > "$output_file"
done

echo "  All FASTA headers updated in: $OUT_DIR"
```

## 5) Once all headers have been renamed, you are ready to build your custom DB

```
for file in kraken_ready_fastas/*.fna; do
  kraken2-build --add-to-library "$file" --db /home/projects/Agribiome/Kraken2_fungi_db/kraken_fungi_db

done
kraken2-build --build --db /home/projects/Agribiome/Kraken2_fungi_db/kraken_fungi_db
```
### zip all genomes! They take up sooooo much space

## 6) Inspect your build
```
kraken2-inspect --db /path/to/kraken2_db
```

## 7) Download library
### you do this step NOW and not with the rest of the download because it makes a hash table that cannot be overwritten by your custom hash table. However, you cannot build Bracken without this file
```
kraken2-build --download-library fungi --db /home/projects/Agribiome/Kraken2_fungi_db/kraken_fungi_db
```
## 8) Build Bracken
### -l refers to the length of your reads
```
bracken-build -k 35 -l 151 -d /home/projects/Agribiome/Kraken2_fungi_db/kraken_fungi_db
```

## 9) Clean up your database
```
kraken2-clean --db /path/to/kraken2_db
```


