WITH median_calculations AS (
      SELECT DISTINCT 
      l.day,
      PERCENTILE_CONT(c.time_to_change_in_min,0.5)
        OVER (
          PARTITION BY TIMESTAMP_TRUNC(c.time_deployed, DAY)
        ) AS daily_med_time_to_change_min,
      PERCENTILE_CONT(c.time_to_change_in_min,
        0.5)
        OVER () AS med_time_to_change_min,
      FROM four_keys.last_three_months l
        LEFT JOIN four_keys.v_changes c on
        l.day = TIMESTAMP_TRUNC(c.time_deployed, DAY)
        ORDER BY day DESC 
)

SELECT
day,
IFNULL(daily_med_time_to_change_min / 60, 0) AS daily_med_time_to_change_hour,
IFNULL(daily_med_time_to_change_min,0) AS daily_med_time_to_change_min,
med_time_to_change_min,
IFNULL(med_time_to_change_min / 60, 0) AS med_time_to_change_hour,
CASE WHEN med_time_to_change_min < 24 * 60 then "One day"
     WHEN med_time_to_change_min < 168 * 60 then "One week"
     WHEN med_time_to_change_min < 730 * 60 then "One month"
     WHEN med_time_to_change_min < 730 * 6 * 60 then "Six months"
     ELSE "One year"
     END as med_time_to_change_bucket,
FROM median_calculations