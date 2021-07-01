DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

environment () {
  # Set values that will be overwritten if env.sh exists
  RANDOM_IDENTIFIER=$((RANDOM%999999))
  export PARENT_PROJECT=$(gcloud config get-value project)
  export FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $RANDOM_IDENTIFIER)
  export FOURKEYS_REGION=europe-west
  export HELLOWORLD_PROJECT=$(printf "helloworld-%06d" $RANDOM_IDENTIFIER)
  export HELLOWORLD_REGION=europe-west
  export HELLOWORLD_ZONE=${HELLOWORLD_REGION}1-a
  export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
  export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

  export PYTHONHTTPSVERIFY=0

  [[ -f "$DIR/env.sh" ]] && echo "Importing environment from $DIR/env.sh..." && . $DIR/env.sh
  echo "Writing $DIR/env.sh..."
  cat > $DIR/env.sh << EOF
export FOURKEYS_PROJECT=${FOURKEYS_PROJECT}
export FOURKEYS_REGION=${FOURKEYS_REGION}
export HELLOWORLD_PROJECT=${HELLOWORLD_PROJECT}
export HELLOWORLD_ZONE=${HELLOWORLD_ZONE}
export BILLING_ACCOUNT=${BILLING_ACCOUNT}
export PARENT_PROJECT=${PARENT_PROJECT}
export PARENT_FOLDER=${PARENT_FOLDER}
EOF
}

schedule_bq_queries(){
  echo "Check BigQueryDataTransfer is enabled" 
  enabled=$(gcloud services list --enabled --filter name:bigquerydatatransfer.googleapis.com)

  while [[ "${enabled}" != *"bigquerydatatransfer.googleapis.com"* ]]
  do gcloud services enable bigquerydatatransfer.googleapis.com
  # Keep checking if it's enabled
  enabled=$(gcloud services list --enabled --filter name:bigquerydatatransfer.googleapis.com)
  done

  echo "Creating BigQuery scheduled queries for derived tables.."; set -x
  cd ${DIR}/../queries/
   
   ./schedule.sh --query_file=deployments.sql --table=deployments --project_id=$FOURKEYS_PROJECT
   ./schedule.sh --query_file=incidents.sql --table=incidents --project_id=$FOURKEYS_PROJECT

    ./schedule_views.sh --query_file=v_changes.sql --table=v_changes --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=last_three_months.sql --table=last_three_months --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=calc_deployments.sql --table=calc_deployments --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=calc_time_to_change.sql --table=calc_time_to_change --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=calc_change_failure_rate.sql --table=calc_change_failure_rate --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=calc_time_to_restore.sql --table=calc_time_to_restore --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=metrics.sql --table=metrics --project_id=$FOURKEYS_PROJECT
    ./schedule_views.sh --query_file=pull_requests.sql --table=pull_requests --project_id=$FOURKEYS_PROJECT
  
  
  set +x; echo
  cd ${DIR}
}

environment
schedule_bq_queries