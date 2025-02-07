#!/bin/bash

# Check if dependencies are installed

if ! command -v openssl &> /dev/null
then
    echo "openssl could not be found, please install it to proceed."
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "jq could not be found, please install it to proceed."
    exit 1
fi

if ! command -v docker &> /dev/null
then
    echo "docker could not be found, please install it to proceed."
    exit 1
fi

if ! command -v deck &> /dev/null
then
    echo "deck could not be found, please install it to proceed."
    exit 1
fi

# Check if KONNECT_TOKEN is set

if [ -z "$KONNECT_TOKEN" ]; then
  echo "KONNECT_TOKEN is not set. Please set it to proceed."
  exit 1
fi

# Set default values for environment variables if not set

export KONNECT_REGION=${KONNECT_REGION:-eu}

# Generate TLS Key and Cert

mkdir -p ./config/tls
openssl req -new -x509 -nodes -newkey rsa:2048 -subj "/CN=insomnia-demo/C=US" -keyout ./config/tls/tls.key -out ./config/tls/tls.crt

export CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ./config/tls/tls.crt)

# Create Kong Konnect Control Plane

export CONTROL_PLANE=$(curl --request POST \
  --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes" \
  --header 'Content-Type: application/json' \
  --header 'accept: application/json' \
  --header "Authorization: Bearer ${KONNECT_TOKEN}" \
  --data '{"name":"insomnia-demo","description":"Control Plane for Insomnia demonstrations.","cluster_type":"CLUSTER_TYPE_HYBRID","cloud_gateway":false,"proxy_urls":[{"host":"localhost","port":443,"protocol":"https"}],"labels":{"labels":"insomnia-demo"}}' | jq . -r)

# Grab Parameters Required for Docker Compose to Associate our Gateway to the Control Plane and to Upload the Cert

export CONTROL_PLANE_ID=$(echo $CONTROL_PLANE | jq .id -r)

export KONG_CLUSTER_CONTROL_PLANE=$(echo $CONTROL_PLANE | jq .config.control_plane_endpoint -r | sed 's|https://||'):443
export KONG_CLUSTER_SERVER_NAME=$(echo $CONTROL_PLANE | jq .config.control_plane_endpoint -r | sed 's|https://||')

export KONG_CLUSTER_TELEMETRY_ENDPOINT=$(echo $CONTROL_PLANE | jq .config.telemetry_endpoint -r | sed 's|https://||'):443
export KONG_CLUSTER_TELEMETRY_SERVER_NAME=$(echo $CONTROL_PLANE | jq .config.telemetry_endpoint -r | sed 's|https://||')

# Update Certificate on Konnect Control Plane
echo "about to update the certificate on Konnect control plane"

curl --request POST \
  --url "https://${KONNECT_REGION}.api.konghq.com/v2/control-planes/${CONTROL_PLANE_ID}/dp-client-certificates" \
  --json '{"cert":"'"$CERT"'"}' \
  --header "Authorization: Bearer ${KONNECT_TOKEN}"

# Run Docker Compose to Deploy Kong Gateway, Backend Application, KeyCloak and Insomnia Mock Server

echo "about to start docker compose"

docker compose up -d

echo "docker compose started"

# Configure Kong Gateway to Proxy to Backend Application and Use OIDC

deck gateway sync ./config/kong/kong.yaml \
  --konnect-control-plane-name insomnia-demo \
  --konnect-addr "https://${KONNECT_REGION}.api.konghq.com"

echo "set up complete"
