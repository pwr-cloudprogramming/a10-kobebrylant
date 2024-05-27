terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  ingress = [
    80,
    3000
  ]
  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.name
  backend_repo = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/tic-tac-toe-backend"
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "main-sg" {
  name_prefix = "tic-tac-toe-sg-"
  vpc_id      = aws_vpc.main.id

  dynamic ingress {
    for_each = toset(local.ingress)
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.206.107.24/29"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_instance_profile" "profile" {
  name_prefix = "tic-tac-toe-profile-"
  role        = "LabRole"
}


resource "aws_instance" "app-instance" {
  ami = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main-sg.id]
  user_data = <<-EOF
              #!/bin/bash
              yum install -y docker
              systemctl enable docker
              systemctl start docker
              sudo chown $USER /var/run/docker.sock
              echo '#!/bin/bash' > /etc/rc.local
              echo 'sudo aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${local.region}.amazonaws.com' >> /etc/rc.local
              echo 'sudo docker pull ${local.backend_repo}:latest' >> /etc/rc.local
              echo 'sudo docker run --env COGNITO_USER_POOL_ID=${aws_cognito_user_pool.user_pool.id} --env COGNITO_APP_CLIENT_ID=${aws_cognito_user_pool_client.client.id} --env COGNITO_REGION=${local.region} -d -p 3000:3000 ${local.backend_repo}:latest' >> /etc/rc.local
              sudo chmod +x /etc/rc.local
              sudo bash /etc/rc.local
              EOF
  iam_instance_profile = aws_iam_instance_profile.profile.name
}

output "app-instance-ip" {
  value = aws_instance.app-instance.public_ip
}


resource "aws_cognito_user_pool" "user_pool" {
  name = "tic-tac-toe-user-pool"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "tic-tac-toe-cognito-client"

  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
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