#!/bin/bash

# Skru av eller på å kopiere frå kjeldekatalog
ENABLE_COPY_FROM_SOURCE=true

# Kor mange MB er kjelde-katalogen på?
du -sh ../ldir

# Find and print the timestamp of the newest file in ../ldir
find ../ldir -type f -exec stat -f "%m %N" {} \; | sort -n | tail -n 1 | awk '{print $1, $2}' | while read timestamp file; do echo "Nyaste fil i kjeldekatalog: $(date -r $timestamp) $file"; done

if $ENABLE_COPY_FROM_SOURCE ; then
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

# Skriv ut liste over 10 største CSV-filer i datasets-katalogen, med både filnamn og menneskelesbar filstørrelse
# echo "\nStørste filer"
# find datasets/ -name "*.csv" -type f -exec du -sh {} \; | sort -rh # | head -n 10
