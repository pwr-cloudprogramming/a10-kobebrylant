#!/bin/bash
set -e

# Update and install necessary packages
sudo apt-get update > /tmp/apt_get_update.log 2>&1
sudo apt-get install -y docker.io > /tmp/docker_install.log 2>&1
sudo apt-get install -y git > /tmp/git_install.log 2>&1
sudo apt-get install -y docker-compose > /tmp/docker_compose_install.log 2>&1

# Enable and start Docker service
sudo systemctl enable docker > /tmp/docker_enable.log 2>&1
sudo systemctl start docker > /tmp/docker_start.log 2>&1

# Get instance metadata
API_URL="http://169.254.169.254/latest/api"
TOKEN=$(curl -X PUT "$API_URL/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
TOKEN_HEADER="X-aws-ec2-metadata-token: $TOKEN"
METADATA_URL="http://169.254.169.254/latest/meta-data"
AZONE=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/placement/availability-zone)
IP_V4=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/public-ipv4)
INTERFACE=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/ | head -n1)
SUBNET_ID=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/$INTERFACE/subnet-id)
VPC_ID=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/$INTERFACE/vpc-id)

echo "Your EC2 in: AvailabilityZone: $AZONE, VPC: $VPC_ID, VPC subnet: $SUBNET_ID, IP address: $IP_V4"

# Save IP address to a file
echo "$IP_V4" > /tmp/ec2_ip_address.txt

# Export the IP address and other variables as environment variables for frontend and backend
export VUE_APP_API_URL="http://$IP_V4:8080"
export VUE_APP_COGNITO_REGION="${cognito_region}"
export VUE_APP_USER_POOL_ID="${user_pool_id}"
export VUE_APP_USER_POOL_CLIENT_ID="${user_pool_client_id}"
export JWT_SECRET_KEY="${jwt_secret_key}"
export USER_POOL_ID="${user_pool_id}"
export APP_CLIENT_ID="${user_pool_client_id}"
export COGNITO_REGION="${cognito_region}"

# Clone the repository with sudo and set correct permissions
sudo mkdir -p /app
sudo chown -R $USER:$USER /app
git clone https://github.com/pwr-cloudprogramming/a10-kobebrylant.git /app > /tmp/git_clone.log 2>&1

# Navigate to the app directory
cd /app

# Create a docker-compose.override.yml to inject environment variables
cat <<EOF > docker-compose.override.yml
version: '3.8'
services:
  frontend:
    environment:
      - VUE_APP_API_URL
      - VUE_APP_COGNITO_REGION=\${VUE_APP_COGNITO_REGION}
      - VUE_APP_USER_POOL_ID=\${VUE_APP_USER_POOL_ID}
      - VUE_APP_USER_POOL_CLIENT_ID=\${VUE_APP_USER_POOL_CLIENT_ID}
  backend:
    environment:
      - JWT_SECRET_KEY=\${JWT_SECRET_KEY}
      - USER_POOL_ID=\${USER_POOL_ID}
      - APP_CLIENT_ID=\${APP_CLIENT_ID}
      - COGNITO_REGION=\${COGNITO_REGION}
EOF

# Start the application using Docker Compose with environment variables
sudo -E docker-compose up --build > /tmp/docker_compose_up.log 2>&1
