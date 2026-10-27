#!/bin/bash
cd "$(dirname "$0")/.."
mkdir -p data/raw/index

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

for SITE in BL0 CD1; do
  curl -sf --retry 3 --retry-delay 5 \
    "https://api.erg.ic.ac.uk/AirQuality/Hourly/MonitoringIndex/SiteCode=$SITE/Json" \
    -o "data/raw/index/${SITE}_${TIMESTAMP}.json"
  sleep 1
done
