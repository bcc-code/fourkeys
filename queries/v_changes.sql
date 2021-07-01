# Changes Table
WITH changes_depoyed as (
        SELECT deploy_id,
        time_created,
        change_id,
        FROM 
        four_keys.deployments d,
        UNNEST(d.changes) as change_id    
    ),
    commits as (
        SELECT 
        source,
        event_type,        
        JSON_EXTRACT_SCALAR(commit, '$.id') commit_id,        
        TIMESTAMP_TRUNC(TIMESTAMP(JSON_EXTRACT_SCALAR(commit, '$.timestamp')),second) as time_created,
        #JSON_EXTRACT_SCALAR(metadata, '$.head_commit.message') as message,
        FROM four_keys.events_raw e,
        UNNEST(JSON_EXTRACT_ARRAY(e.metadata, '$.commits')) as commit
        WHERE event_type in ("pull_request", "push", "merge_request")
        GROUP BY 1,2,3,4
    )


SELECT 
c.source,
c.event_type,
d.deploy_id,
c.time_created,
d.time_created as time_deployed,
IF(
    TIMESTAMP_DIFF(d.time_created, c.time_created , MINUTE) > 0,
    TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE),
    NULL) as time_to_change_in_min,
c.commit_id,
FROM commits c
LEFT JOIN changes_depoyed d
on c.commit_id = d.change_id
ORDER BY time_to_change_in_min desc