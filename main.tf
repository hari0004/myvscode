provider "aws" {
  region = "eu-west-2"
}

# -------------------
# 1. VPC
# -------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# -------------------
# 2. Internet Gateway
# -------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# -------------------
# 3. Public Subnet
# -------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# -------------------
# 4. Route Table
# -------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# -------------------
# 5. Route Table Association
# -------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------
# 6. Security Group
# -------------------
resource "aws_security_group" "devops_sg" {
  name        = "devops-sg"
  description = "Allow SSH & HTTP"
  vpc_id      = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg"
  }
}

# -------------------
# 7. EC2 Instance + Apache + Website Deployment
# -------------------
resource "aws_instance" "DevOps_ubuntu" {
  ami                         = "ami-044415bb13eee2391" # Ubuntu 22.04 (London)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  associate_public_ip_address = true
  # key_name                  = "Docker" # replace with your key pair

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y

    # Check if Apache is installed
    if ! dpkg -s apache2 >/dev/null 2>&1; then
      echo "Apache not found. Installing..."
      sudo apt-get install -y apache2
      sudo systemctl start apache2
      sudo systemctl enable apache2
    else
      echo "Apache already installed"
      sudo systemctl start apache2
    fi

    # Install unzip if not available
    if ! command -v unzip &> /dev/null; then
      sudo apt-get install -y unzip
    fi

    # Deploy template
    cd /var/www/html
    sudo rm -rf ./*
    wget https://templatemo.com/tm-zip-files-2020/templatemo_596_electric_xtra.zip -O site.zip
    unzip site.zip
    sudo mv templatemo_596_electric_xtra/* .
    sudo rm -rf templatemo_596_electric_xtra site.zip
    sudo chown -R www-data:www-data /var/www/html
  EOF

  tags = {
    Name = "DevOps-ubuntu"
  }
}
