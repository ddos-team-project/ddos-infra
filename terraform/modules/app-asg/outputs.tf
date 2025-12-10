output "app_sg_id" {
  value = length(var.app_sg_ids) > 0 ? var.app_sg_ids[0] : null
}
