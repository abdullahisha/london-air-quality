import duckdb
import streamlit as st

st.title("London air on repeat")
st.caption("Hourly NO2 and PM2.5 from the London Air Quality Network, Imperial College London")

con = duckdb.connect("air_quality.duckdb", read_only=True)

sites = con.execute("SELECT site_name FROM sites ORDER BY site_name").fetchall()
site = st.selectbox("Pick a site", [s[0] for s in sites])

latest = con.execute(
    open("sql/report.sql").read().replace(
        "ORDER BY s.site_name, l.pollutant;",
        "WHERE s.site_name = ? ORDER BY l.pollutant;",
    ),
    [site],
).df()
st.subheader("Latest reading")
st.dataframe(latest, hide_index=True)

pattern = con.execute(
    """
    SELECT r.pollutant, hour(r.measured_at) AS hour_of_day,
           ROUND(AVG(r.value), 1) AS usual_level
    FROM readings AS r
    JOIN sites AS s USING (site_code)
    WHERE s.site_name = ?
    GROUP BY r.pollutant, hour_of_day
    ORDER BY hour_of_day
    """,
    [site],
).df()
st.subheader("Usual level by hour of day")
st.line_chart(pattern, x="hour_of_day", y="usual_level", color="pollutant")