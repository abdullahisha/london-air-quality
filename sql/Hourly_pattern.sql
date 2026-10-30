SELECT
  s.site_name,
  r.pollutant,
  hour(r.measured_at)    AS hour_of_day,
  ROUND(AVG(r.value), 1) AS usual_level,
  COUNT(*)               AS readings_used
FROM readings AS r
JOIN sites AS s USING (site_code)
GROUP BY s.site_name, r.pollutant, hour_of_day
ORDER BY s.site_name, r.pollutant, hour_of_day;