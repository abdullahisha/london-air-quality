CREATE OR REPLACE TABLE sites AS
SELECT DISTINCT
  s."@SiteCode"            AS site_code,
  s."@SiteName"            AS site_name,
  s."@LocalAuthorityName"  AS borough,
  CAST(s."@Latitude"  AS DOUBLE) AS latitude,
  CAST(s."@Longitude" AS DOUBLE) AS longitude
FROM (
  SELECT unnest(Sites.Site) AS s
  FROM read_json('data/raw/sites/*.json')
)
WHERE s."@SiteCode" IN ('CE3', 'CE2', 'CD1', 'LB4', 'TH2', 'WAC');