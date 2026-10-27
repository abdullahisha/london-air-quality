#!/bin/bash
cd "$(dirname "$0")/.."
mkdir -p data/raw/sites
curl -sf --retry 3 --retry-delay 5 \
  "https://api.erg.ic.ac.uk/AirQuality/Information/MonitoringSiteSpecies/GroupName=London/Json" \
  -o "data/raw/sites/sites_$(date +%Y%m%d_%H%M%S).json"