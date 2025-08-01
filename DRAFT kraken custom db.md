
```
kraken2-build --download-taxonomy --db custom_db
```

The next step is to get a list of taxonomy IDs from NCBI, even if the database you are making isn
't from NCBI

####  I pulled the file names from the ensembl dir I downloaded last week and clean up the list:
```
ls ensembl_fungi/ > species_list.txt
cut -d'_' -f1,2 species_list.txt
sort -u species_list.txt > species_u.txt
sed -i 's/_/ /g' species_u.txt
```
#### I needed to install entrez and put it in my path
```
sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"
export PATH=$PATH:$HOME/edirect
source ~/.bashrc
```
#### use entrez to get the ids from NCBI
make_species_taxid_map.sh
```
# Read species into an array first
mapfile -t species_list < species_u.txt

# Create or clear the output file
> species_with_taxids.tsv

# Loop over the array
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

Kraken2 requires the fasta headers to include the **TaxID**, like this
`sequence_id|kraken:taxid|123456`

mine are set up like this:
```
>10 dna:chromosome chromosome:Zt_ST99CH_3D7:10:1:1845975:1 REF
```

