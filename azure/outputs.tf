# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group the stack is deployed into"
  value       = local.resource_group_name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = local.location
}

# VNet Outputs
output "vnet_id" {
  description = "ID of the VNet"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Name of the VNet"
  value       = module.network.vnet_name
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.network.private_subnet_id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = module.network.database_subnet_id
}

# Network Security Group Outputs
output "web_nsg_id" {
  description = "ID of the web NSG"
  value       = module.security.web_nsg_id
}

output "app_nsg_id" {
  description = "ID of the app NSG"
  value       = module.security.app_nsg_id
}

output "database_nsg_id" {
  description = "ID of the database NSG"
  value       = module.security.database_nsg_id
}

# Compute Outputs
output "web_vm_ids" {
  description = "IDs of the web tier VMs"
  value       = module.compute.web_vm_ids
}

output "web_vm_public_ips" {
  description = "Public IP addresses of the web tier VMs"
  value       = module.compute.web_vm_public_ips
}

output "web_vm_private_ips" {
  description = "Private IP addresses of the web tier VMs"
  value       = module.compute.web_vm_private_ips
}

output "app_vm_ids" {
  description = "IDs of the app tier VMs"
  value       = module.compute.app_vm_ids
}

output "app_vm_private_ips" {
  description = "Private IP addresses of the app tier VMs"
  value       = module.compute.app_vm_private_ips
}

# Database Outputs
output "database_server_name" {
  description = "Name of the MySQL server"
  value       = module.database.database_server_name
}

output "database_fqdn" {
  description = "FQDN of the MySQL server"
  value       = module.database.database_fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = module.database.database_name
}

output "database_username" {
  description = "Database administrator username"
  value       = module.database.database_username
  sensitive   = true
}

output "database_password" {
  description = "Database administrator password"
  value       = random_password.db_password.result
  sensitive   = true
}

# Network Infrastructure Outputs
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.network.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = module.network.nat_gateway_public_ip
}
