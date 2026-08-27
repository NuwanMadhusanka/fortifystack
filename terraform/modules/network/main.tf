###############################################################################
# Network module - VPC with 3 subnet tiers across N availability zones
#   - public   : ALB + NAT gateway (internet-facing)
#   - app      : EC2 app instances (private, egress via NAT)
#   - data     : RDS (private, isolated)
# Cost note: a single NAT gateway is used by default to keep the portfolio
# cheap. Set one_nat_per_az = true for production-grade AZ-independent egress.
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = var.az_count
  azs      = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  # Deterministic /24 carving out of the /16 VPC CIDR.
  public_subnets = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  app_subnets    = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  data_subnets   = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 20)]

  nat_count = var.one_nat_per_az ? local.az_count : 1
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

# ---------- Subnets ----------
resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "app" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.app_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = "${var.name}-app-${local.azs[count.index]}"
    Tier = "app"
  }
}

resource "aws_subnet" "data" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.data_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = "${var.name}-data-${local.azs[count.index]}"
    Tier = "data"
  }
}

# ---------- NAT ----------
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "${var.name}-nat-${count.index}" }
  depends_on    = [aws_internet_gateway.this]
}

# ---------- Route tables ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One private route table per AZ so we can point each at the right NAT.
resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.one_nat_per_az ? aws_nat_gateway.this[count.index].id : aws_nat_gateway.this[0].id
  }
  tags = { Name = "${var.name}-private-rt-${local.azs[count.index]}" }
}

resource "aws_route_table_association" "app" {
  count          = local.az_count
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Data subnets: no internet route at all (fully isolated). They still reach
# S3 via the gateway endpoint below.
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-data-rt" }
}

resource "aws_route_table_association" "data" {
  count          = local.az_count
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

# ---------- S3 gateway endpoint (free; keeps S3 traffic off NAT) ----------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.private[*].id, [aws_route_table.data.id])
  tags              = { Name = "${var.name}-s3-endpoint" }
}
