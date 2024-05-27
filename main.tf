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
  region = var.region
}

variable "region" {
  description = "The AWS region to deploy into"
  default     = "us-east-1"
}

variable "jwt_secret_key" {
  description = "JWT Secret Key"
  type        = string
}

variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  type        = string
}

# Define VPC
resource "aws_vpc" "tictactoe_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "TicTacToeVPC"
  }
}

# Define Subnet
resource "aws_subnet" "tictactoe_subnet" {
  vpc_id                  = aws_vpc.tictactoe_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = {
    Name = "TicTacToeSubnet"
  }
}

# Define Internet Gateway
resource "aws_internet_gateway" "tictactoe_igw" {
  vpc_id = aws_vpc.tictactoe_vpc.id
  tags = {
    Name = "TicTacToeIGW"
  }
}

# Define Route Table
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

# Define Security Group
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
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
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

# Define EC2 Instance
resource "aws_instance" "tictactoe_instance" {
  ami                         = "ami-080e1f13689e07408"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.tictactoe_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.tictactoe_sg.id]

  user_data = templatefile("${path.module}/userdata.sh", {
    user_pool_id        = aws_cognito_user_pool.tictactoe_user_pool.id
    user_pool_client_id = aws_cognito_user_pool_client.tictactoe_user_pool_client.id
    cognito_region      = var.region
    jwt_secret_key      = var.jwt_secret_key
  })

  tags = {
    Name = "TicTacToeInstance"
  }
}

# Define Cognito User Pool
resource "aws_cognito_user_pool" "tictactoe_user_pool" {
  name = "TicTacToeUserPool"
}

# Define Cognito User Pool Client
resource "aws_cognito_user_pool_client" "tictactoe_user_pool_client" {
  name         = "TicTacToeUserPoolClient"
  user_pool_id = aws_cognito_user_pool.tictactoe_user_pool.id
  generate_secret = false
}

# Define Cognito Identity Pool
resource "aws_cognito_identity_pool" "tictactoe_identity_pool" {
  identity_pool_name               = "TicTacToeIdentityPool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id   = aws_cognito_user_pool_client.tictactoe_user_pool_client.id
    provider_name = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.tictactoe_user_pool.id}"
  }
}

# Outputs
output "user_pool_id" {
  value = aws_cognito_user_pool.tictactoe_user_pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.tictactoe_user_pool_client.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.tictactoe_identity_pool.id
}

