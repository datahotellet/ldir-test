#!/bin/bash

# Skru av eller på å kopiere frå kjeldekatalog
ENABLE_COPY_FROM_SOURCE=false

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

    # Kort ned filstørrelsen til under 512 KB så førehandsvisning i GitHub fungerer
    find datasets/ -name "sample.csv" -type f -exec sh -c 'bash trim.sh $1' sh {} \;

    # Les ut felta name, shortName og content (om dei eksisterer) frå fields.xml og skriv til CSV
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
    fi
done

# Lag liste over datasett (alle underkatalogar som inneheld fil ved namn dataset.csv)
> datasets.txt # Truncate datasets.txt to ensure results from previous runs don't persist
find datasets -type f -name "dataset.csv" | while read dataset; do
    dir=$(dirname "$dataset")
    echo "$dir" >> datasets.txt
done

# Skriv ut liste over 10 største CSV-filer i datasets-katalogen, med både filnamn og menneskelesbar filstørrelse
# echo "\nStørste filer"
# find datasets/ -name "*.csv" -type f -exec du -sh {} \; | sort -rh # | head -n 10
