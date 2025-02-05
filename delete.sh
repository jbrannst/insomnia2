#!/bin/bash

# Setup

export KONNECT_REGION=${KONNECT_REGION:-eu}

# Get Insomnia-Demo Kong Konnect Control Plane ID 

export "KONNECT_CONTROL_PLANE_ID=$(curl --request GET \
  --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes" \
  --header 'accept: application/json' \
  --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r '.data[] | select(.labels.labels == "insomnia-demo") | .id')"

# Delete Insomnia-Demo Konnect Control Plane

curl --request DELETE \
  --url https://${KONNECT_REGION}.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID} \
  --header 'accept: */*' \
  --header "Authorization: Bearer ${KONNECT_TOKEN}"

# Run Docker Compose to Deploy Kong Gateway, Backend Application, KeyCloak and Insomnia Mock Server

docker compose down -v --remove-orphans
