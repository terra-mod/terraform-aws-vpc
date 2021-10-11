locals {
  // Merge default tags into the list given
  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
    }
  )

  // Build out the filters used to identify the AZs to be used
  az_filters = concat([
    {
      name   = "opt-in-status"
      values = var.allow_local_zones ? ["not-opted-in", "opted-in", "opt-in-not-required"] : ["opt-in-not-required"]
    },
    {
      name   = "region-name"
      values = [data.aws_region._.name]
    }
    ], length(var.availability_zones) > 0 ? [{
      name   = "zone-name"
      values = var.availability_zones
  }] : [])

  // Map of ip count to bits for cidr ranges
  bits = {
    16    = 4
    32    = 5
    64    = 6
    128   = 7
    256   = 8
    512   = 9
    1024  = 10
    2048  = 11
    4096  = 12
    8128  = 13
    16256 = 14
  }

  // Get the current CIDR bitmask
  mask = tonumber(regex("/(\\d?\\d)", var.cidr)[0])

  // Determine the count of Availability Zones that will be used either from the explicit list or a count from the
  // default available zones.
  zone_count = length(var.availability_zones) > 0 ? length(var.availability_zones) : var.availability_zone_count

  // Separate the subnets out for easier looping below
  external_subnets = [ for n, cidr in module.cidr_blocks.network_cidr_blocks : cidr if substr(n, 0, 8) == "external" ]
  internal_subnets = [ for n, cidr in module.cidr_blocks.network_cidr_blocks : cidr if substr(n, 0, 8) == "internal" ]
}

/**
 * Gets the current Region based on the AWS Provider configuration / IAM Access Key credentials.
 */
data aws_region _ {
  name = length(var.region) > 0 ? var.region : null
}

/**
 * Resolve the Availability Zones for the given Region.
 */
data aws_availability_zones _ {
  state                  = "available"
  all_availability_zones = true

  dynamic filter {
    for_each = local.az_filters

    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

module cidr_blocks {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = var.cidr
  networks = concat(
    [ for s in range(0, local.zone_count) : { name = "external_${s}", new_bits = local.mask - local.bits[element(var.external_subnets, s)] } ],
    [ for s in range(0, local.zone_count) : { name = "internal_${s}", new_bits = local.mask - local.bits[element(var.internal_subnets, s)] } ],
  )
}


/**
 * Create the VPC.
 */
resource aws_vpc _ {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags
}

/**
 * Generate the Internet Gateway
 */
resource aws_internet_gateway _ {
  vpc_id = aws_vpc._.id

  tags = local.tags
}

/**
 * If required, create the Elastic IPs for each Nat Gateway
 */
resource aws_eip nat {
  count = length(local.internal_subnets)

  vpc = true

  depends_on = [aws_internet_gateway._]

  tags = merge(local.tags, {
    Name = "${var.name}-${var.environment}-nat-gateway"
  })
}

/**
 * If required, create the Nat Gateways for each internal Subnet
 */
resource aws_nat_gateway _ {
  count = length(local.internal_subnets)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.external[count.index].id
  depends_on    = [aws_internet_gateway._]

  tags = merge(local.tags, {
    Name = "${var.name}-${var.environment}-nat-gateway"
  })
}

/**
 * Create the Internal Subnets.
 */
resource aws_subnet internal {
  count = length(local.internal_subnets)

  vpc_id            = aws_vpc._.id
  cidr_block        = local.internal_subnets[count.index]
  availability_zone = data.aws_availability_zones._.names[count.index]

  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name       = "${var.name}-${var.environment}-${format("internal-%v", count.index + 1)}"
    Visibility = "private"
  })
}

/**
 * Create the Public Subnets.
 */
resource aws_subnet external {
  count = length(local.external_subnets)

  vpc_id            = aws_vpc._.id
  cidr_block        = local.external_subnets[count.index]
  availability_zone = data.aws_availability_zones._.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name       = "${var.name}-${var.environment}-${format("external-%v", count.index + 1)}"
    Visibility = "public"
  })
}

/**
 * Generate a Route Table for the Public subnets.
 */
resource aws_route_table external {
  vpc_id = aws_vpc._.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway._.id
  }

  tags = merge(local.tags, {
    Name = "${var.name}-external-001"
  })
}

/**
 * Create the Route Tables for Internal subnets. We need one for each subnet to associate to the correct Nat Gateway.
 */
resource aws_route_table internal {
  count = length(local.internal_subnets)

  vpc_id = aws_vpc._.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway._[count.index].id
  }

  tags = merge(local.tags, {
    Name = "${var.name}-${var.environment}-${format("internal-%v", count.index + 1)}"
  })
}

/**
 * Associate the Internal subnets to the Route Table.
 */
resource aws_route_table_association internal {
  count = length(local.internal_subnets)

  subnet_id      = aws_subnet.internal[count.index].id
  route_table_id = aws_route_table.internal[count.index].id
}

/**
 * Associate the Public subnets to the Route Table.
 */
resource aws_route_table_association external {
  count = length(local.external_subnets)

  subnet_id      = aws_subnet.external[count.index].id
  route_table_id = aws_route_table.external.id
}
