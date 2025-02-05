#!/bin/bash

# Check if dependencies are installed

if ! command -v docker &> /dev/null
then
    echo "docker could not be found, please install it to proceed."
    exit 1
fi

# Check if KONNECT_TOKEN is set

if [ -z "$KONNECT_TOKEN" ]; then
  echo "KONNECT_TOKEN is not set. Please set it to proceed."
  exit 1
fi

# Set default values for environment variables if not set

export KONNECT_REGION=${KONNECT_REGION:-eu}
export KONG_CLUSTER_CONTROL_PLANE=""
export KONG_CLUSTER_SERVER_NAME=""
export KONG_CLUSTER_TELEMETRY_ENDPOINT=""
export KONG_CLUSTER_TELEMETRY_SERVER_NAME=""

# Get Insomnia-Demo Kong Konnect Control Plane ID 

export "KONNECT_CONTROL_PLANE_ID=$(curl --request GET \
  --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes" \
  --header 'accept: application/json' \
  --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r '.data[] | select(.labels.labels == "insomnia-demo") | .id')"

# Delete Insomnia-Demo Konnect Control Plane

curl --request DELETE \
  --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}" \
  --header 'accept: */*' \
  --header "Authorization: Bearer ${KONNECT_TOKEN}"

# Run Docker Compose to Deploy Kong Gateway, Backend Application, KeyCloak and Insomnia Mock Server

docker compose down -v --remove-orphans
