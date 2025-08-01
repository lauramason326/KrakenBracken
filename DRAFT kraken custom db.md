# 1) First step, after downloading Kraken is to build the database
```
kraken2-build --download-taxonomy --db custom_db
```
# 2) The next step is to get a list of taxonomy IDs from NCBI, even if the database you are making isn't from NCBI


# 2) Download databases 
## Ensembl (I did this one first)
Go to this page http://ftp.ensemblgenomes.org/pub/fungi/release-61/fasta


```mkdir -p ensembl_fungi && cd ensembl_fungi

wget -r -nH --cut-dirs=5 -A "*.fa.gz" -np -R "index.html*" \
ftp://ftp.ensemblgenomes.org/pub/fungi/release-61/fasta/ ```

I pulled the file names from the ensembl dir I downloaded last week and clean up the list:
```
ls ensembl_fungi/ > species_list.txt
cut -d'_' -f1,2 species_list.txt
sort -u species_list.txt > species_u.txt
sed -i 's/_/ /g' species_u.txt
```
## FungiDB

- go to the FungiDB preferred organisms page
- select fungi (not oomycetes), release 67, fasta, and genome = 282 fasta files
- copy-paste this list into Excel
 use a macro to generate the list as a batch: 
1. **Open your Excel workbook.**
    
2. Press **`Fn + Option + F11`**  
3. In the VBA Editor, go to **Insert > Module**.
    
4. Paste this macro code:
    
```
    Function GetURL(cell As Range) As String
    On Error Resume Next
    GetURL = cell.Hyperlinks(1).Address
End Function
```
    
5. Press **`Command + S`** and save your workbook as **macro-enabled** (`.xlsm`).
    
6. Close the editor.
    
7. Back in your spreadsheet, use the formula like this in **Column B**:
    `=GetURL(A2)`
    🔁 Fill down the column to extract all URLs.
    

Save just the urls in a file called: fungi_urls.txt and upload to the Kraken2_fungi_db folder server via filezilla

```
mkdir -p fungidb_genomes
cd fungidb_genomes
wget -i ../fungi_urls.txt
```
## put all genomes into one directory and unzip

# 4) Reformat headers
### no headers (even those from NCBI) are formatted improperly and need to be reformated

## Look up the Taxids from NCBI based on the species names in your custom db
input="full_orgs_names.txt"
output="full_orgs_list_w_taxids.tsv"

# Clear the output file
> "$output"

# Read species names (first column) into array
mapfile -t species_array < <(cut -f1 "$input")

# Loop through array
for species in "${species_array[@]}"; do
  echo "Searching: $species" >&2
  taxid=$(esearch -db taxonomy -query "$species" | efetch -format uid)

  if [[ -z "$taxid" ]]; then
    echo -e "$species\tNOT_FOUND" >> "$output"
  else
    echo -e "$species\t$taxid" >> "$output"
  fi
done






