SELECT 
l.day,
IFNULL(daily_med_time_to_change_hour, 0) as median_time_to_change,
med_time_to_change_bucket as lead_time_to_change,
daily_failure_rate as change_fail_rate,
change_failure_rate_bucket,
d.daily_deployments as deployments,
deployment_frequency_bucket as deployment_frequency,
IFNULL(daily_med_time_to_restore, 0) as median_time_to_resolve,
med_time_to_restore_bucket as time_to_restore_buckets
FROM four_keys.last_three_months l
INNER JOIN four_keys.calc_time_to_change c ON l.day = c.day
INNER JOIN four_keys.calc_change_failure_rate f ON l.day = f.day
INNER JOIN four_keys.calc_deployments d ON l.day = d.day
INNER JOIN four_keys.calc_time_to_restore t ON l.day = t.day
ORDER BY day DESC;