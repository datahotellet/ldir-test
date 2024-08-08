# Test av GitHub for distribusjon av datasett

Dette er eit repo for å teste å distribuere datasett via GitHub.
Både for å undersøke generelt kva fordeler og ulemper det er ved å bruke GitHub, og spesifikt for korleis overføre datasett som i dag er distribuert via Datahotellet.

Testar med Landbruksdirektoratet sine datasett på [Datahotellet](https://hotell.difi.no/).

## Vurdering av GitHub som datalager

[+] Uavhengig. Dersom ein legg ut filer på eigen nettstad, må ein sørge for å flytte desse når ein byter nettside-plattform

[+] Får historikk på datasett

[+] Kan bruke GitHub sin funksjonalitet
- Opprette Issue for spørsmål og tilbakemeldingar
- Konsumentar kan setje opp varsling
- Konsumentar kan setje opp synkronisering

[+] Gratis. For dette scenariet kan ein bruke GitHub gratis. Datautgjevar kan opprette organisasjon på GitHub om dei ikkje allereie har det, og legge ut data i eit opent repository. I eit scenario med større filer (over 100 MB) vil ein måtte betale for Large File Storage (LFS).

[+] Komprimering. Ser ut til å vere gzip-komprimering under overføring av filer som standard. F.eks. CSV-fil på 750 KB er berre 350 KB overført.

[+] Førehandsvisning er støtta i GitHub i nettlesaren

[-] Førehandsvisning krev tilrettelegging. Kun førehandsvisning på filer som er maks 512 KB. Støtter ikkje alle CSV-variantar (må vere kommaseparert — ikkje semikolon). Må difor lage ei eiga fil for førehandsvisning som er kutta ned i størrelse og konvertert til kompatibelt CSV-format.

[-] Ikkje noko API for å gjere søk, filtrering o.l. på data

[-] Egnar seg ikkje for store datamengder. Enkeltfiler bør vere under 50 MB. Kan ikkje vere over 100 MB.

[-] Egnar seg ikkje for data som blir oppdatert ofte — repo blir fort stort

[-] Lite statistikk om tal på nedlastingar tilgjengeleg. Er noko tilgjengeleg under Insights --> Traffic

## Oppsett
Scriptet pack.sh gjer tilrettelegging av data.
0. Forutsetning: har lasta ned heile katalogen "ldir" som ligg på Datahotellet
1. Kopierer filer frå ldir-katalog og fjerner overflødige filer
2. Genererer filer for kvart datasett:
  - sample.csv. For førehandsvisning. Konverterer til CSV-format (kommaseparert) som fungerer med førehandsvisning i GitHub
  - fields.csv. Henta frå fields.xml. Tar med felta shortName, name og content
  - README. Oversikt over filene i datasettet. Tar med tittel og sist-endra-tidspunkt frå meta.xml, samt feltdefinisjonar frå fields.csv

## Ikkje dekka her
Har ikkje sett på korleis Large File Storage (LFS) kan fungere.

## Korleis integrere bruk av GitHub i dataeigar sin arbeidsflyt med publisering av data?

TODO: skriv meir her

Dersom ein opprettar nye datasett som ikkje tidlegare har ligge på Datahotellet, bør ein nytte anledninga til å gjere nokre endringar. Treng ikkje ha med meta.xml og fields.xml lenger.
- dataset.csv : bør gå for eit meir standardisert format (sjå RFC-ar om CSV som format). Datahotellet har brukt slash (\\) som escape-teikn. Bør bruke dobbelt hermeteikn som er meir vanleg i dag.

## Vidare
- Oppskrift for registrering på data.norge.no
- Skriv om til å generere meta.csv og endre generering av README til å hente frå meta.csv. Formålet er å gjere det lettare å oppdatere datasett ved å sleppe å forhalde seg til XML-formatet.