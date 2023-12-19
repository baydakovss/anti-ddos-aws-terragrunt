resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    terraform = "true"
    Name      = "vpc-${var.project}"
    Project   = var.project
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    terraform = "true"
    Name      = "igw-${var.project}"
    Project   = var.project
  }
}

resource "aws_subnet" "public_subnets" {
  #count                   = length(var.public_subnet_cidrs)
  count  = 2
  vpc_id = aws_vpc.this.id
  #cidr_block              = element(var.public_subnet_cidrs, count.index)
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    terraform = "true"
    Name      = "public-subnet-${var.project}"
    Project   = var.project
  }
}

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    terraform = "true"
    Name      = "rt-${var.project}"
    Project   = var.project
  }
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

resource "aws_eip" "my_eip" {
  instance = aws_instance.proxy.id
  tags = {
    terraform = "true"
    Name      = "eip-${var.project}"
    Project   = var.project
  }
}

resource "aws_security_group" "this" {
  name   = "allow_all"
  vpc_id = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    terraform = "true"
    Name      = "sg-${var.project}"
    Project   = var.project
  }

}

