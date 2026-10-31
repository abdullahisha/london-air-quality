#!/bin/bash
set -e
cd "$(dirname "$0")/.."

DB=air_quality.duckdb

echo "Fetching data..."
./scripts/extract_sites.sh
./scripts/extract_readings.sh

BEFORE=$(duckdb $DB -noheader -list "SELECT count(*) FROM readings;" 2>/dev/null || echo 0)

duckdb $DB < sql/readings.sql
duckdb $DB < sql/sites.sql

AFTER=$(duckdb $DB -noheader -list "SELECT count(*) FROM readings;")
echo "Readings before: $BEFORE, after: $AFTER, new rows: $((AFTER - BEFORE))"

duckdb $DB < sql/report.sql