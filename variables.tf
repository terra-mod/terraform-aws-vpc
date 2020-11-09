// Required Variables

variable name {
  description = "Name for the VPC - used in the Name tag."
  type        = string
}

variable environment {
  description = "The environment the VPC is used for."
  type        = string
}

// CIDR Address

variable cidr {
  description = <<DESC
The CIDR block for the VPC. The Net Mask of the CIDR should be sufficient to support the required amount of IP Addresses
requested for each subnet (both external and internal).
DESC
  type        = string
  default     = "10.0.0.0/16"
}

// Availability Zones
variable region {
  description = "The AWS Region to generate the VPC in."
  type        = string
  default     = ""
}

variable allow_local_zones {
  description = "Whether to include Local Zones in how subnets are mapped to Availability Zones."
  type        = bool
  default     = false
}

variable availability_zones {
  description = "List of availability zones."
  type        = list(string)
  default     = []
}

variable availabilty_zone_count {
  description = <<DESC
Selects a given number of Availability Zones from the specified Region. Then variable is ignored when a explicit list
of Availability Zones are provided.
DESC
  type        = number
  default     = 2
}

variable external_subnets {
  description = <<DESC
A list of IP Address counts requested for each external subnet. Passing a single element will use that value for all
subnets. Each item in the list should be a value that can be represented by a bitmask - this module supports:
`16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8128, 16256`.
DESC
  type        = list(number)
  default     = [256]
}

variable internal_subnets {
  description = <<DESC
A list of IP Address counts requested for each internal subnet. Passing a single element will use that value for all
subnets. Each item in the list should be a value that can be represented by a bitmask - this module supports:
`16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8128, 16256`.
DESC
  type        = list(number)
  default     = [256]
}

variable use_nat_gateways {
  description = "Whether the Internal Subnets should have egress to the internet via a Nat Gateway."
  type        = bool
  default     = true
}

// Tagging
variable tags {
  description = "A key/value map of tags that should be applied to taggable resources."
  type        = map(string)
  default     = {}
}
