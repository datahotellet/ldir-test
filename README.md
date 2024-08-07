# Test av GitHub for distribusjon av datasett

Dette er eit repo for å teste å distribuere datasett via GitHub.

Testar med Landbruksdirektoratet sine datasett

## Vurdering av GitHub som datalager

[+] Uavhengig. Dersom ein legg ut filer på eigen nettstad, må ein sørge for å flytte desse når ein byter nettside-plattform

[+] Får historikk på datasett

[+] Kan bruke GitHub sin funksjonalitet
- - Opprette Issue for spørsmål og tilbakemeldingar
- - Konsumentar kan setje opp varsling
- - Konsumentar kan setje opp synkronisering

[+] Gratis. For dette scenariet kan ein bruke GitHub gratis. Datautgjevar kan opprette organisasjon på GitHub om dei ikkje allereie har det, og legge ut data i eit opent repository. I eit scenario med større filer (over 100 MB) vil ein måtte betale for Large File Storage (LFS).

[+] Komprimering. Ser ut til å vere gzip-komprimering under overføring av filer som standard. F.eks. CSV-fil på 750 KB er berre 350 KB overført.

[+] Førehandsvisning er støtta i GitHub i nettlesaren

[-] Førehandsvisning krev tilrettelegging. Kun førehandsvisning på filer som er maks 512 KB. Støtter ikkje alle CSV-variantar (må vere kommaseparert — ikkje semikolon). Må difor lage ei eiga fil for førehandsvisning.

[-] Ikkje noko API for å gjere søk, filtrering o.l. på data

[-] Egnar seg ikkje for store datamengder. Enkeltfiler bør vere under 50 MB. Kan ikkje vere over 100 MB.

[-] Egnar seg ikkje for data som blir oppdatert ofte — repo blir fort stort

[-] Svært lite statistikk om tal på nedlastingar tilgjengeleg

## Oppsett
Scriptet pack.sh gjer tilrettelegging av data.
0. Lastar ned heile "ldir"-katalogen som ligg på Datahotellet
1. Kopierer filer og fjerner overflødige filer
2. Genererer filer for kvart datasett:
  a) sample.csv. For førehandsvisning
  b) README. Oversikt over filene i datasettet. Tar med tittel og sist-endra-tidspunkt frå meta.xml

## Vidare
- Korleis integrere bruk av GitHub i dataeigar sin arbeidsflyt med publisering av data?
- Konvertere fields.xml til høveleg enklare format. Datapackage / frictionless data?
- Oppskrift for registrering på data.norge.no