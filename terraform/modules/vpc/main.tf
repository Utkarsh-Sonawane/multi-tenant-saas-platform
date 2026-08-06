# 1. Availability Zones used by this VPC module
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. The VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}
#resource "aws_internet_gateway_attachment" "attach_gateway" {
  #vpc_id             = aws_vpc.main_vpc.id
 # internet_gateway_id = aws_internet_gateway.igw.id
#}

# 4. 2 Public Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  count                   = 2
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Good practice: auto-assign public IPs here
  tags = {
    Name        = "${var.environment}-public-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.environment
    "kubernetes.io/role/elb"   = "1"
  }
}
# 
# 4. 2 Private Subnets
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  count             = 2
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name        = "${var.environment}-private-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.environment
  }
}

# 5. 2 Elastic IPs
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags = {
    # FIXED: Added index to EIP names so they don't have duplicate names in AWS
    Name        = "${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# 6. 2 NAT Gateways
resource "aws_nat_gateway" "nat_gw" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags = {
    Name        = "${var.environment}-nat-gateway_${count.index + 1}"
    Environment = var.environment
  }
  depends_on = [aws_internet_gateway.igw]
}

#7. 2 Private Route Tables
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  count  = 2
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  tags = {
    Name        = "${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
  }
}  

#8. Associate Private Route Tables with Private Subnets
resource "aws_route_table_association" "private_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

#9. Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id 
  }
  tags = {
    Name        = "${var.environment}-public_rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}