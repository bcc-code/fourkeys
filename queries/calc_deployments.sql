
WITH daily_deployments AS (
        SELECT
        l.day,
        l.week,
        l.month,
        #TIMESTAMP_TRUNC(time_created, DAY) AS day,
        COUNT(distinct deploy_id) AS daily_deployments,
        IF (COUNT(distinct deploy_id) > 0,1,0) as deployment_that_day,
        FROM four_keys.last_three_months l
            LEFT JOIN four_keys.deployments d on
            l.day = TIMESTAMP_TRUNC(d.time_created, DAY)

        GROUP BY l.day,l.week,l.month
        ORDER BY day DESC
    ),
    weekly_deployments AS (
        SELECT 
        week,                
        SUM(deployment_that_day) AS deployments_days_per_week,
        PERCENTILE_CONT(SUM(deployment_that_day),0.5)
            OVER () AS med_deployments_days_per_week,
        FROM daily_deployments
        GROUP BY week        
        ORDER BY deployments_days_per_week DESC
    ),
    monthly_deployments AS (
        SELECT 
        month,        
        SUM(deployment_that_day) AS deployments_days_per_month,
        PERCENTILE_CONT(SUM(deployment_that_day),0.5)
            OVER () AS med_deployments_days_per_month,
        FROM daily_deployments
        GROUP BY month        
        ORDER BY deployments_days_per_month DESC
    )
#select * from monthly_deployments

SELECT 
d.day,
d.daily_deployments,
d.week,
w.deployments_days_per_week,
w.med_deployments_days_per_week ,
d.month,
m.deployments_days_per_month,
m.med_deployments_days_per_month,
CASE WHEN w.med_deployments_days_per_week >= 3 THEN 'Daily'
     WHEN w.med_deployments_days_per_week >= 1 THEN 'Weekly'
     WHEN m.med_deployments_days_per_month >= 1 THEN 'Monthly'
     ELSE "Yearly" 
     END as deployment_frequency_bucket,
FROM  daily_deployments d
LEFT JOIN weekly_deployments w ON d.week = w.week
LEFT JOIN monthly_deployments m ON d.month = m.month
ORDER BY day desc
