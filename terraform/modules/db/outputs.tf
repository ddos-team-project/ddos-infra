output "cluster_id" {
  value = aws_rds_cluster.this.id
}

output "cluster_endpoint" {
  value = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.this.reader_endpoint
}

output "db_sg_id" {
  value = aws_security_group.db.id
}
output "global_cluster_id" {
  value       = var.is_primary ? aws_rds_global_cluster.this[0].id : null
  description = "Global Cluster ID if primary region"
}
