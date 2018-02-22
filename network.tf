resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-${var.application}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.environment}-${var.application}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "private" {
  count                   = "${length(var.private_subnet_ranges)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.private_subnet_ranges[count.index]}"
  availability_zone       = "${var.availability_zones[count.index]}"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-${var.application}-private-subnet-${var.availability_zones[count.index]}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

output "private_aws_subnets" {
  value = "${aws_subnet.public.*.id}"
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_subnet_ranges)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_subnet_ranges[count.index]}"
  availability_zone       = "${var.availability_zones[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-${var.application}-public-subnet-${var.availability_zones[count.index]}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

output "public_aws_subnets" {
  value = "${aws_subnet.public.*.id}"
}

resource "aws_eip" "nat" {
  count = "${length(var.public_subnet_ranges)}"
  vpc   = true
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = "${length(var.public_subnet_ranges)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  tags = {
    Name        = "${var.environment}-${var.application}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "public" {
  count  = "${length(var.public_subnet_ranges)}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.environment}-${var.application}-public-route-table-${var.availability_zones[count.index]}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "private" {
  count  = "${length(var.private_subnet_ranges)}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.environment}-${var.application}-private-route-table-${var.availability_zones[count.index]}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "public_igw" {
  count                  = "${length(var.public_subnet_ranges)}"
  route_table_id         = "${element(aws_route_table.public.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet_gateway.id}"
  depends_on             = ["aws_route_table.public"]
}

resource "aws_route" "private_nat" {
  count                  = "${length(var.private_subnet_ranges)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat_gateway.*.id, count.index)}"
  depends_on             = ["aws_route_table.private"]
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnet_ranges)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnet_ranges)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
