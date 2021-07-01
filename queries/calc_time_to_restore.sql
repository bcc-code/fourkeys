WITH time_to_restore_bucket AS (
      SELECT
      CASE WHEN med_time_to_resolve < 24  then "One day"
          WHEN med_time_to_resolve < 168  then "One week"
          WHEN med_time_to_resolve < 730  then "One month"
          WHEN med_time_to_resolve < 730 * 6 then "Six months"
          ELSE "One year"
          END as med_time_to_restore_bucket,
      med_time_to_resolve
      FROM (
        SELECT                
        PERCENTILE_CONT(
          TIMESTAMP_DIFF(time_resolved, time_created, HOUR), 0.5)
          OVER() as med_time_to_resolve,
        FROM four_keys.incidents)
),
med_daily_time_to_restore AS (
  SELECT DISTINCT 
  TIMESTAMP_TRUNC(time_created, DAY) as day_created,    
  PERCENTILE_CONT(
    TIMESTAMP_DIFF(time_resolved, time_created, HOUR), 0.5)
    OVER(PARTITION BY TIMESTAMP_TRUNC(time_created, DAY)
    ) as daily_med_time_to_restore,
  FROM four_keys.incidents  
  ORDER BY day_created desc
)


SELECT DISTINCT 
day,
daily_med_time_to_restore,
med_time_to_resolve,
med_time_to_restore_bucket
FROM (four_keys.last_three_months l
FULL OUTER JOIN med_daily_time_to_restore i ON l.day = i.day_created)
CROSS JOIN time_to_restore_bucket
ORDER BY day DESC