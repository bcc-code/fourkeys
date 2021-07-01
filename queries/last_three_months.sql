 SELECT
      TIMESTAMP(day) AS day,
      EXTRACT(WEEK FROM DATE (day)) AS week,
      EXTRACT(MONTH FROM DATE (day)) AS month
    FROM
      UNNEST(
        GENERATE_DATE_ARRAY(
          DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH),
          CURRENT_DATE(),
          INTERVAL 1 DAY)) AS day
    # FROM the start of the data
    WHERE day > (SELECT date(min(time_created)) FROM four_keys.events_raw)
    order by day desc