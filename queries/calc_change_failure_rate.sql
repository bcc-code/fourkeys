WITH daily_incidents_vs_deployments AS(
        SELECT
        #incident_id,
        day,
        d.daily_deployments,
        COUNT(time_created) as incidents,
        FROM
        four_keys.incidents i
        FULL OUTER JOIN four_keys.calc_deployments d on TIMESTAMP_TRUNC(i.time_created, DAY) =  d.day
        GROUP BY day, d.daily_deployments
        order by day desc
    ),
    daily_change_failure_rate AS (
        SELECT 
        day,
        incidents,
        daily_deployments,   
        CASE WHEN CAST(IEEE_DIVIDE(incidents, daily_deployments) AS STRING) = "nan" then 0
            WHEN CAST(IEEE_DIVIDE(incidents, daily_deployments) AS STRING) = "inf" then 0
            ELSE IEEE_DIVIDE(incidents, daily_deployments) END AS daily_failure_rate
        FROM 
        daily_incidents_vs_deployments 
    ),
    buket_calculation AS (
        SELECT 
        SUM(incidents) as sum_incidents,
        SUM(daily_deployments) as sum_daily_deployments,
        IEEE_DIVIDE(SUM(incidents), SUM(daily_deployments)) as change_failure_rate,
        CASE WHEN IEEE_DIVIDE(SUM(incidents), SUM(daily_deployments)) <= .15 THEN "0-15%"
            WHEN IEEE_DIVIDE(SUM(incidents), SUM(daily_deployments)) <= .46 THEN "16-45%"
            ELSE "46-60%" END AS change_failure_rate_bucket
        FROM 
        daily_change_failure_rate
    )

SELECT
day,
incidents,
daily_deployments,
daily_failure_rate,
change_failure_rate,
change_failure_rate_bucket
FROM 
daily_change_failure_rate
CROSS JOIN buket_calculation
ORDER BY day DESC