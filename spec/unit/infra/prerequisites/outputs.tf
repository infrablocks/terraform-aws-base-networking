output "public_zone_id" {
  value = module.dns_zones.public_zone_id
}

output "public_zone_name_servers" {
  value = module.dns_zones.public_zone_name_servers
}

output "private_zone_id" {
  value = module.dns_zones.private_zone_id
}

output "private_zone_name_servers" {
  value = module.dns_zones.private_zone_name_servers
}
