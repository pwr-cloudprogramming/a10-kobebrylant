terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.name
}

resource "aws_vpc" "tictactoe_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "TicTacToeVPC"
  }
}

resource "aws_subnet" "tictactoe_subnet" {
  vpc_id            = aws_vpc.tictactoe_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "TicTacToeSubnet"
  }
}


resource "aws_internet_gateway" "tictactoe_igw" {
  vpc_id = aws_vpc.tictactoe_vpc.id
  tags = {
    Name = "TicTacToeIGW"
  }
}

resource "aws_route_table" "tictactoe_rt" {
  vpc_id = aws_vpc.tictactoe_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tictactoe_igw.id
  }
  tags = {
    Name = "TicTacToeRouteTable"
  }
}

resource "aws_route_table_association" "tictactoe_rta" {
  subnet_id      = aws_subnet.tictactoe_subnet.id
  route_table_id = aws_route_table.tictactoe_rt.id
}
resource "aws_security_group" "tictactoe_sg" {
  name        = "TicTacToeSG"
  description = "Security Group for TicTacToe app"
  vpc_id      = aws_vpc.tictactoe_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TicTacToeSG"
  }
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "tic-tac-toe-profile-"
  role        = "LabRole"
}

resource "aws_instance" "tictactoe_instance" {
  ami           = "ami-080e1f13689e07408"
  instance_type = "t2.micro"
  key_name = "vockey"
  subnet_id     = aws_subnet.tictactoe_subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.tictactoe_sg.id]

  user_data = <<-EOF
                #!/bin/bash
                set -e
                sudo apt-get update > /tmp/apt_get_update.log 2>&1
                wait
                sudo apt-get install -y docker.io > /tmp/docker_install.log 2>&1
                wait
                sudo apt-get install -y git > /tmp/git_install.log 2>&1
                wait
                sudo apt install -y docker-compose > /tmp/docker_compose_install.log 2>&1
                wait
                sudo systemctl enable docker > /tmp/docker_enable.log 2>&1
                wait
                sudo systemctl start docker > /tmp/docker_start.log 2>&1
                wait

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
                # Export the IP address as an environment variable
                export VUE_APP_API_URL="http://$IP_V4:8080"

                export COGNITO_USER_POOL_ID=${aws_cognito_user_pool.user_pool.id}
                export COGNITO_CLIENT_ID=${aws_cognito_user_pool_client.client.id}
                export COGNITO_REGION=${local.region}

                git clone https://github.com/pwr-cloudprogramming/a10-kobebrylant.git > /tmp/git_clone.log 2>&1
                wait
                cd a10-kobebrylant/
                wait
                sudo -E docker-compose up --build > /tmp/docker_compose_up.log 2>&1
                wait
          EOF

  iam_instance_profile = aws_iam_instance_profile.profile.name
  tags = {
    Name = "TicTacToeInstance"
  }
}

# Define Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "tic-tac-toe-user-pool"

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "client" {
  name = "tic-tac-toe-cognito-client"

  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

output "cognito-user-pool-id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito-client-id" {
  value = aws_cognito_user_pool_client.client.id
}

output "cognito-region" {
  value = local.region
}