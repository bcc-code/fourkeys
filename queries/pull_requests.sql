WITH events_raw_ordered AS (
    SELECT 
    *
    FROM four_keys.events_raw
    ORDER BY time_created DESC
),
pull_request AS (
        SELECT 
        id,
        JSON_EXTRACT_SCALAR(metadata, '$.pull_request.title') as title,
        TIMESTAMP_TRUNC(TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.pull_request.created_at')),hour) as time_created,
        JSON_EXTRACT_SCALAR(metadata, '$.pull_request.html_url') as url,
        ARRAY_AGG(JSON_EXTRACT_SCALAR(metadata, '$.pull_request.state'))  as state,        
        FROM events_raw_ordered
        WHERE event_type = 'pull_request'
        GROUP BY 1,2,3,4
        ORDER BY time_created DESC
)

SELECT 
id,
title,
time_created,
url,
state[OFFSET(0)] as state
FROM pull_request
ORDER BY time_created DESC