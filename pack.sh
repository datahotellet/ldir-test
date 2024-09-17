#!/bin/bash

# Skru av eller på å kopiere frå kjeldekatalog
ENABLE_COPY_FROM_SOURCE=false

# Capture the start time
start_time=$(date +%s)

# Function to find escape character ('\"') in a CSV file
# will print the line of each occurrence
# if none found in file, print a message saying so
find_escape_char() {
    file=$1
    echo "Finding escape character in $file"
    awk -F, '
    BEGIN { found = 0 }
    {
        for (i=1; i<=NF; i++) {
            if ($i ~ /\\"/) {
                print "Found escape character in line " NR ", column " i ": " $i
                found = 1
            }
        }
    }
    END {
        if (found == 0) {
            print "No escape character found in " FILENAME
        }
    }' "$file"
}

# find_escape_char "datasets/grunneiendommer/dataset.csv" # escape-teikn er \
# find_escape_char "datasets/foretak/dataset.csv" # ingen escape-teikn brukt her
# exit 0

if $ENABLE_COPY_FROM_SOURCE ; then
    # Kor mange MB er kjelde-katalogen på?
    du -sh ../ldir

    # Find and print the timestamp of the newest file in ../ldir
    find ../ldir -type f -exec stat -f "%m %N" {} \; | sort -n | tail -n 1 | awk '{print $1, $2}' | while read timestamp file; do echo "Nyaste fil i kjeldekatalog: $(date -r $timestamp) $file"; done

    # Start frå botn av; slett alt i datasett-katalogen
    rm -rf datasets/*

    # Kopiere inn alle filene
    cp -r ../ldir/* datasets/

    # Slett overflødige filer
    find datasets/ -type f ! -name "meta.xml" ! -name "fields.xml" ! -name "dataset.csv" -delete

    # Generere eksempel-CSV som blir vist av GitHub
    # Datahotellet brukar semikolon (;) som kolonne-separator. GitHub støtter kun komma, så det må konverterast mellom ulike CSV-format
    find datasets/ -name "dataset.csv" -type f -exec sh -c 'csvformat -d ";" -D "," -e utf-8 "$1" > "$(dirname "$1")/sample.csv"' sh {} \;

    # Kort ned filstørrelsen til under 512 KB (GitHub-grense) så førehandsvisning i GitHub fungerer
    # sjå trim.sh for kva max filstørrelse er sett til
    find datasets/ -name "sample.csv" -type f -exec sh -c 'bash trim.sh $1' sh {} \;

    # Konvertere format på CSV frå Datahotell-format til dobbelt hermeteikn som escape-teikn
    # Først detektere kva escape-teikn som er i bruk i ei fil
    find datasets/ -name "dataset.csv" -type f -exec sh -c 'csvformat -d ";" -p "\\" -e utf-8 -D ";" "$1" > "$1.tmp" && mv "$1.tmp" "$1"' sh {} \;

    # Legg inn UTF8 BOM i alle dataset.csv dersom BOM ikkje allereie er på plass
    echo "Adding BOM to dataset.csv files"
    find . -name "dataset.csv" -type f -exec sh -c '
    if [ "$(xxd -p -l 3 "$1")" != "efbbbf" ]; then
        printf "\xEF\xBB\xBF" | cat - "$1" > temp && mv temp "$1" && echo "Added BOM to $1";
    else
        echo "BOM already present in $1";
    fi
    ' sh {} \;

    # Les ut felta name, shortName og content (om dei eksisterer) frå fields.xml og skriv til CSV
    echo "Konverterer fields.xml til fields.csv"
    find datasets/ -name "fields.xml" -type f -exec sh -c '
        if grep -q "§" "$1"; then
            echo "Error: $1 contains the character §. This character is used as a delimiter in the CSV file and must be removed from the XML file."
            exit 1
        fi
        xmlstarlet sel -t -m "//field" -v "shortName" -o "§" -v "name" -o "§" -v "content" -n "$1" > "$(dirname "$1")/fields.csv"
        # add header to CSV file. Add line at the top with "shortname§name§content"
        { echo "shortname§name§content"; cat "$(dirname "$1")/fields.csv"; } > temp && mv temp "$(dirname "$1")/fields.csv";
        # convert CSV file from using § as delimiter to using , as delimiter
        csvformat -d "§" -D "," -e utf-8 "$(dirname "$1")/fields.csv" > "$(dirname "$1")/fields.csv.tmp" && mv "$(dirname "$1")/fields.csv.tmp" "$(dirname "$1")/fields.csv"
    ' sh {} \;
fi

# Generer README.md for alle katalogar med datasett
# Les meta.xml, hent ut verdien i <updated> og konverter unix timestamp til menneskelesbar verdi
echo "Genererer README.md for alle datasett"
find datasets/ -type f -name "dataset.csv" | while read dataset; do
    dir=$(dirname "$dataset")
    meta_file="$dir/meta.xml"
    if [ -f "$meta_file" ]; then
        # Hent ut sist-oppdatert-verdi og konverter til menneskelesbar versjon
        lastupdated="ukjent"
        updated=$(sed -n 's|<updated>\(.*\)</updated>|\1|p' "$meta_file" | tr -d '[:space:]')
        if [ -n "$updated" ]; then
            len=${#updated}
            if [ $len -eq 13 ]; then
                updated=$(expr $updated / 1000)
            elif [ $len -ne 10 ]; then
                echo "Error: Unexpected timestamp length in $meta_file : $len — $updated"
                continue
            fi
            human_readable_date=$(date -r "$updated" +"%Y-%m-%d %H:%M")
            # echo "Dataset: $dir, Last updated: $human_readable_date"
            lastupdated="$human_readable_date"
        else
            echo "No <updated> tag found in $meta_file"
        fi

        # Hent ut tittel på datasettet
        name=$(sed -n 's|<name>\(.*\)</name>|\1|p' "$meta_file")
        
        # Lag README.md
        echo -e "# Datasett: $name\n"\
            "Sist oppdatert: $lastupdated\n\n" \
            "Filer:\n"\
            "- [sample.csv](sample.csv) — eksempeldata\n" \
            "- [dataset.csv](dataset.csv) — original datafil\n" \
            "- [meta.xml](meta.xml) — metadata (tittel og sist-oppdatert)\n" \
            "- [fields.xml](fields.xml) — feltdefinisjonar (XML)\n" \
            "- [fields.csv](fields.csv) — feltdefinisjonar (CSV)\n" \
            > "$dir/README.md"

        # Legg til innholdet av fields.csv som en tabell i README.md
        if [ -f "$dir/fields.csv" ]; then
            echo -e "\n## Feltdefinisjonar\nHenta frå fields.csv\n" >> "$dir/README.md"
            echo -e "| shortname | name | content |\n| --- | --- | --- |" >> "$dir/README.md"
            tail -n +2 "$dir/fields.csv" | while IFS=',' read -r shortname name content; do
                echo -e "| $shortname | $name | $content |" >> "$dir/README.md"
            done
        fi     

        # Legg til eksempeldata frå sample.csv som en tabell i README.md
        # if [ -f "$dir/sample.csv" ]; then
        #     echo -e "\n## Utdrag av datasettet\nHenta frå sample.csv\n" >> "$dir/README.md"
        #     head -n 50 "$1" | while IFS="," read -r shortname name content; do
        #         echo -e "| $shortname | $name | $content |" >> "$dir/README.md"
        #     done
        # fi                 
    fi
done

# Lag liste over datasett (alle underkatalogar som inneheld fil ved namn dataset.csv)
echo "Lagar liste over datasett --> datasets.txt"
> datasets.txt # Truncate datasets.txt to ensure results from previous runs don't persist
find datasets -type f -name "dataset.csv" | while read dataset; do
    dir=$(dirname "$dataset")
    echo "$dir" >> datasets.txt
done

# Skriv ut liste over 10 største CSV-filer i datasets-katalogen, med både filnamn og menneskelesbar filstørrelse
# echo "\nStørste filer"
# find datasets/ -name "*.csv" -type f -exec du -sh {} \; | sort -rh # | head -n 10

# Capture the end time
end_time=$(date +%s)

# Calculate the runtime
runtime=$((end_time - start_time))

# Print the runtime
echo "Køyretid script: $runtime sekund"