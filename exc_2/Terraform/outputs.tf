output "private_ip_address_target" {
  value = yandex_compute_instance.target.network_interface.*.ip_address
}
output "private_ip_address_cluster" {
  value = yandex_compute_instance.cluster[*].network_interface.*.ip_address
}
output "public_ip_address_target" {
  value = yandex_compute_instance.target.network_interface.0.nat_ip_address
}
output "public_ip_address_cluster" {
  value = yandex_compute_instance.cluster[*].network_interface.0.nat_ip_address
}