# London air, on repeat

A small data pipeline that collects hourly NO2 and PM2.5 readings for six busy London locations, builds up a history over time, and shows it in a simple Streamlit app.

## What I built and who for

This is for people with asthma and other breathing conditions who travel through busy parts of London. It answers one question: **when is the air on my route usually cleanest, and how does the latest reading compare?**

Traffic pollution is mainly NO2 and PM2.5, two of the most harmful pollutants for people with breathing conditions. The figures are published, but nothing tells someone when a place they pass through is usually cleaner. In the app you pick a site, see its latest reading with a band on the official UK scale and the time it was taken, and see the usual level for each hour of the day. That way you can plan around the worst hours.

Two ideas shaped the design. A number needs a yardstick, so every reading comes with a band and the usual level for that hour. And less is more, so you pick one site instead of seeing everything at once.

## The data

**Source.** Readings come from the [London Air Quality Network](https://www.londonair.org.uk) API, run by the Environmental Research Group at Imperial College London. Two endpoints are used:

- `Information/MonitoringSiteSpecies/GroupName=London/Json` for the monitoring sites and what each one measures
- `Data/SiteSpecies/SiteCode=…/SpeciesCode=…/StartDate=…/EndDate=…/Json` for hourly readings

**Bands.** The bands use the thresholds of Defra's [Daily Air Quality Index](https://uk-air.defra.gov.uk/air-pollution/daqi). NO2 is banded on each hourly value and PM2.5 on a 24-hour mean, as the index does. I apply these thresholds to the readings myself, because the API's own live index returned "No data" (with a score of 0) for most sites, and a 0 looks like the cleanest air possible.

| Band | NO2, hourly (µg/m³) | PM2.5, 24-hour mean (µg/m³) |
| --- | --- | --- |
| Low | 0 to 200 | 0 to 35 |
| Moderate | 201 to 400 | 36 to 53 |
| High | 401 to 600 | 54 to 70 |
| Very High | 601 or more | 71 or more |

**Sites.** I kept only sites that are still open and still measure NO2 or PM2.5, shortlisted nine at busy travel spots, then fetched two weeks of readings for each and counted the hours with a real value. Three sent nothing, so six remain:

| Code | Site | Borough |
| --- | --- | --- |
| CD1 | Swiss Cottage | Camden |
| CE2 | Waterloo Place | Westminster |
| CE3 | Regent Street | Westminster |
| LB4 | Brixton Road | Lambeth |
| TH2 | Mile End Road | Tower Hamlets |
| WAC | Lavender Hill | Wandsworth |

**Data model.** Two tables in DuckDB:

- `readings`: one row per site, pollutant and hour (`site_code`, `pollutant`, `measured_at`, `value`). The primary key is those first three columns, so an hour can only be stored once.
- `sites`: a small lookup with each site's name, borough, latitude and longitude.

**Things to know.** Readings are published with a lag, which varies by site, so the app always shows when the latest reading was taken. Hours with no value are not stored. Times are in GMT, as the API gives them.

Data credit: London Air Quality Network, Environmental Research Group, Imperial College London. Bands based on Defra's Daily Air Quality Index.

## How it works

```
LAQN API ──curl──▶ data/raw/*.json ──DuckDB──▶ readings + sites ──▶ reports ──▶ Streamlit app
                         ▲
            GitHub Actions, every six hours
```

1. **Extract.** `scripts/extract_sites.sh` saves the site list. `scripts/extract_readings.sh` loops over six sites and two pollutants (12 requests, one second apart) and asks for the last 30 days, so late readings are picked up. Every response is saved untouched, with the date and time in the file name, so nothing is overwritten and every table can be rebuilt from the raw files.
2. **Load.** `sql/readings.sql` creates the table once (`CREATE TABLE IF NOT EXISTS`) and inserts every raw file. Because runs overlap, the same hour appears in several files, so a `QUALIFY ROW_NUMBER()` step keeps only the copy from the newest file, and `ON CONFLICT DO NOTHING` skips hours already in the table. `sql/sites.sql` rebuilds the lookup each run.
3. **Shape.** `sql/report.sql` gives the latest reading for each site and pollutant, with its band. A window function works out the 24-hour PM2.5 mean, and a `CASE WHEN` applies the thresholds. `sql/hourly_pattern.sql` averages readings by hour of day and counts how many readings sit behind each average.
4. **Use.** `app.py` opens the database read-only and shows a site dropdown, the latest reading with its band, and a chart of the usual level by hour.
5. **Collect history.** `scripts/build.sh` runs everything in order and prints the row count before and after. `.github/workflows/collect.yml` runs it every six hours and commits the new raw files, so the history keeps growing.

**What happens on a second run:** only new hours are added. Run `build.sh` twice in a row and the second run reports `new rows: 0`.

## How to run it

You need Bash, curl, the [DuckDB CLI](https://duckdb.org/docs/installation/) and Python 3. On macOS, DuckDB installs with `brew install duckdb`. On Windows, use Git Bash or WSL. No API key is needed.

```bash
git clone https://github.com/abdullahisha/london-air-quality.git
cd london-air-quality

# fetch the latest data and build the database
./scripts/build.sh

# run it again to check that it adds only new data
./scripts/build.sh

# start the app
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py
```

`build.sh` must run before the app, because the database is built from the raw files and is not stored in the repo.

## What I would do next

- **Put it online** with Streamlit Community Cloud, so it works on a phone. The app would build the database from the raw files when it starts.
- **Split weekdays from weekends**, because rush-hour peaks only happen on weekdays and mixing them flattens the pattern.
- **Add a map** of the sites, using the latitude and longitude already in the `sites` table.
- **Fetch only new hours** instead of 30 days every run, which is kinder to the API and keeps the raw folder smaller.
- **Show times in UK time**, since GMT is an hour off the clock during British Summer Time.
- **Keep the site list in one place**. The six codes are currently written in both `extract_readings.sh` and `sites.sql`.

## Where AI helped

I used Claude mainly for two parts of this project.

The first was automation. In my last project the pipeline only ran on my laptop, so it stopped collecting whenever my laptop was off. Claude helped me set up a GitHub Actions workflow that runs the pipeline in the cloud every six hours and commits the new data back to the repo, so the history keeps growing on its own.

The second was the app. My last project, a TfL lift status pipeline, only showed results in the terminal, and it listed every station at once rather than letting someone look at the line they cared about. I wanted to change both this time. The people using this need to see at a glance when the air is worse, and they only care about the places they travel through. I considered Tableau, but it sits outside my code, so it would be harder for someone to rebuild everything from my repo. So Claude helped me build `app.py` in Streamlit, with a dropdown to pick one site, the latest reading and its band, and a chart of the usual level for each hour of the day.

Claude also helped me debug a problem in my SQL. Once the scheduled runs were collecting data, they started failing, because each run fetches 30 days, so the same hour ended up in several files and appeared twice in a single insert. We traced it from the error message, and I fixed it with a `QUALIFY ROW_NUMBER()` step that keeps only the newest copy of each hour. I tested the fix by rebuilding from an empty database and running it twice to check that no duplicates were added.