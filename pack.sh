#!/bin/bash

# Skru av eller på å kopiere frå kjeldekatalog
ENABLE_COPY_FROM_SOURCE=false

# Kor mange MB er kjelde-katalogen på?
du -sh ../ldir

# Find and print the timestamp of the newest file in ../ldir
find ../ldir -type f -exec stat -f "%m %N" {} \; | sort -n | tail -n 1 | awk '{print $1, $2}' | while read timestamp file; do echo "Nyaste fil: $(date -r $timestamp) $file"; done

if $ENABLE_COPY_FROM_SOURCE ; then
    # Start frå botn av; slett alt i datasett-katalogen
    rm -rf datasets/*

    # Kopiere inn alle filene
    cp -r ../ldir/* datasets/

    # Slett overflødige filer
    find datasets/ -type f ! -name "meta.xml" ! -name "fields.xml" ! -name "dataset.csv" -delete
fi

# Skriv ut liste over 10 største CSV-filer i datasets-katalogen, med både filnamn og menneskelesbar filstørrelse
echo "\nStørste filer"
find datasets/ -name "*.csv" -type f -exec du -sh {} \; | sort -rh # | head -n 10