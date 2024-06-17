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
            "- [fields.xml](fields.xml) — feltdefinisjonar\n" \
            > "$dir/README.md"
    fi
done

# Skriv ut liste over 10 største CSV-filer i datasets-katalogen, med både filnamn og menneskelesbar filstørrelse
# echo "\nStørste filer"
# find datasets/ -name "*.csv" -type f -exec du -sh {} \; | sort -rh # | head -n 10
