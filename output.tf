output "all_availability_zones" {
  value = data.aws_availability_zones._.names
}

output "id" {
  description = "The VPC ID."
  value       = aws_vpc._.id
}

output vpc_name {
  description = "The VPC Name."
  value       = aws_vpc._.tags["Name"]
}

output "cidr_block" {
  description = "The CIDR Block for the VPC."
  value       = aws_vpc._.cidr_block
}

output "external_subnets" {
  description = "A comma-separated list of Public Subnet IDs."
  value       = [aws_subnet.external.*.id]
}

output "internal_subnets" {
  description = "A comma-separated list of Internal Subnet IDs."
  value       = ["${aws_subnet.internal.*.id}"]
}

output "security_group" {
  description = "The default Security Group for the VPC."
  value       = "${aws_vpc._.default_security_group_id}"
}

output "availability_zones" {
  description = "List of external availability zones."
  value       = ["${aws_subnet.external.*.availability_zone}"]
}

output "internal_rtb_id" {
  description = "The Internal Route Table ID."
  value       = "${join(",", aws_route_table.internal.*.id)}"
}

output "external_rtb_id" {
  description = "The External Route Table ID."
  value       = "${aws_route_table.external.id}"
}

output "internal_nat_ips" {
  description = "The EIPs associated to the Nat Gateways for internal subnets."
  value       = ["${aws_eip.nat.*.public_ip}"]
}
