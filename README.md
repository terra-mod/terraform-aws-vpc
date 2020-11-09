# AWS VPC Module

Creates a VPC in AWS.

The default behavior of this module is to create a both an Internal and External for two Availability Zones for the AWS
Region configured on the AWS Provider.

### Availability Zones
You can either provide a list of subnets for the Region via the `availability_zones` input or allow the Module to resolve
the list of available zones and specify a count of how many Availability Zones should be used via the `availability_zones_count`
input. The count input is ignored when an explicit list is given.

This module does support [Local Zones](https://aws.amazon.com/about-aws/global-infrastructure/localzones/) by setting the
`allow_local_zones` input to `true`. When using Local Zones, its recommended to pass an explicit list of zones via the 
`availability_zones` input.

### Subnets
By Default a Public (external) and Private (internal) subnet will be provisioned for each Availability Zone used.

This module allows you to pass in the desired size of the Subnets based on the count of desired IP Addresses. The Subnet
sizes are determined via the `external_subnets` and `internal_subnets` list inputs. Internally, the size is resolved down
to the correct mask and CIDR Range will be produced based off the given VPC CIDR Block.

If you pass a single value in either the list input, that value will be used for all subnets of that type.

It's important that the CIDR Block for the VPC has the address space necessary to support the requested IP Address counts for
each subnet.

### NAT Gateways
The default behavior is to create a NAT Gateway for each Internal Subnet, to provide egress out to the internet. This
behavior can be disabled by passing the `use_nat_gateways` input as `false`.


##### Default Usage

     module "vpc" {
       source = "terra-mod/vpc/aws"

       environment = "production"
       name        = "some-vpc"
       
       cidr = "10.0.0.0/16"
       
       region = "us-west-2"
       
       // you can manually specify subnets, or just use the availability_zone_count
       availability_zone_count = 2
       
       // provision each external subnet with 256 ip addresses (/24)
       external_subnets = [256]
       
       // provision each internal subnet with 256 ip addresses (/24)
       internal_subnets = [256]
       
       // Use NAT Gateways to provide egress to the internet for the Internal subnets
       use_nat_gateways = true
     }

##### Example with Differing Subnet Sizes

     module "vpc" {
       source = "terra-mod/vpc/aws"

       environment = "production"
       name        = "some-vpc"
       
       cidr = "10.0.0.0/16"
       
       // you can manually specify subnets, or just use the availability_zone_count
       availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
       
       // provision three external subnets with 256 ip addresses each (/24)
       external_subnets = [256]
       
       // provision one /24 (in us-west-2a) and two /20's (might be useful for EIN heavy services, lambda, fargate, etc)
       internal_subnets = [256, 4096, 4096]
     }

