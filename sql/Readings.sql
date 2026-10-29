CREATE TABLE IF NOT EXISTS readings (
  site_code    VARCHAR,
  pollutant    VARCHAR,
  measured_at  TIMESTAMP,
  value        DOUBLE,
  PRIMARY KEY (site_code, pollutant, measured_at)
);

INSERT INTO readings
SELECT
  r.RawAQData."@SiteCode",
  r.RawAQData."@SpeciesCode",
  d."@MeasurementDateGMT",
  CAST(NULLIF(d."@Value", '') AS DOUBLE)
FROM read_json('data/raw/readings/*.json') AS r,
     unnest(r.RawAQData.Data) AS t(d)
     WHERE d."@Value" <> ''
ON CONFLICT DO NOTHING;