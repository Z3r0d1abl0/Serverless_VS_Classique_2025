
# Création des subnets publics

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-public-${each.key}"
  })
}

# Création des subnets privés

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-private-${each.key}"
  })
}

# Création des EIP pour classique (nat gateway)

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? var.public_subnets : {}
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-eip-nat-${each.key}"
  })
}

# Création des NAT gateway pour classique

resource "aws_nat_gateway" "nat" {
  for_each      = var.enable_nat_gateway ? var.public_subnets : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-nat-${each.key}"
  })

  depends_on = [var.igw_id]
}

# Tables des routes privés (subnet)

resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = var.vpc_id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[each.key].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-rt-private-${each.key}"
  })
}

# Route des tables publics (subnet)

resource "aws_route_table" "public" {
  for_each = var.public_subnets
  vpc_id   = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }
  tags = merge(var.tags, {
    Name = "${var.env_prefix}-rt-public-${each.key}"
  })
}

# Association des tables privées

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Association des tables publics

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}
