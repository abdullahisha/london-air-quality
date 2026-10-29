WITH scored AS (
  SELECT
    site_code,
    pollutant,
    measured_at,
    CASE
      WHEN pollutant = 'PM25' THEN
        AVG(value) OVER (
          PARTITION BY site_code, pollutant
          ORDER BY measured_at
          RANGE BETWEEN INTERVAL 23 HOURS PRECEDING AND CURRENT ROW
        )
      ELSE value
    END AS level
  FROM readings
  WHERE value IS NOT NULL
),
latest AS (
  SELECT *
  FROM scored
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY site_code, pollutant
    ORDER BY measured_at DESC
  ) = 1
)
SELECT
  s.site_name,
  l.pollutant,
  l.measured_at,
  ROUND(l.level, 1) AS level,
  CASE
    WHEN l.pollutant = 'NO2' THEN
      CASE
        WHEN l.level <= 200 THEN 'Low'
        WHEN l.level <= 400 THEN 'Moderate'
        WHEN l.level <= 600 THEN 'High'
        ELSE 'Very High'
      END
    ELSE
      CASE
        WHEN l.level <= 35 THEN 'Low'
        WHEN l.level <= 53 THEN 'Moderate'
        WHEN l.level <= 70 THEN 'High'
        ELSE 'Very High'
      END
  END AS band
FROM latest AS l
JOIN sites AS s USING (site_code)
ORDER BY s.site_name, l.pollutant;