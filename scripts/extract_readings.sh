#!/bin/bash
cd "$(dirname "$0")/.."
mkdir -p data/raw/readings

START=$(date -v-30d +%Y-%m-%d)
END=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

for SITE in  CD1 CE2 CE3 LB4 TH2 WAC; do
  for SPECIES in NO2 PM25; do
    curl -sf --retry 3 --retry-delay 5 \
      "https://api.erg.ic.ac.uk/AirQuality/Data/SiteSpecies/SiteCode=$SITE/SpeciesCode=$SPECIES/StartDate=$START/EndDate=$END/Json" \
      -o "data/raw/readings/${SITE}_${SPECIES}_${TIMESTAMP}.json"
    sleep 1
  done
done
