#!/bin/bash
set -e

# Update and install necessary packages
sudo apt-get update > /tmp/apt_get_update.log 2>&1
sudo apt-get install -y docker.io > /tmp/docker_install.log 2>&1
sudo apt-get install -y git > /tmp/git_install.log 2>&1
sudo apt install -y docker-compose > /tmp/docker_compose_install.log 2>&1

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

# Export the IP address as an environment variable for frontend
export VUE_APP_API_URL="http://$IP_V4:8080"

# Export environment variables for backend
cat <<EOF > /app/.env
JWT_SECRET_KEY=secret_jwt
USER_POOL_ID=${user_pool_id}
APP_CLIENT_ID=${user_pool_client_id}
COGNITO_REGION=${cognito_region}
EOF

# Clone the repository
git clone https://github.com/pwr-cloudprogramming/a10-kobebrylant.git /app > /tmp/git_clone.log 2>&1

# Navigate to the app directory
cd /app

# Start the application using Docker Compose
sudo -E docker-compose up --build > /tmp/docker_compose_up.log 2>&1
