output "bucket_nombre" {
  # Este bucket se crea y configura con AWS CLI, no con Terraform, debido a
  # una restriccion de politica (SCP) de AWS Academy que bloquea la lectura
  # de Object Lock Configuration en S3 -- API que Terraform necesita
  # consultar incluso solo para leer el estado del bucket.
  value = "avance2-foro-resenas-adjuntos-f2cc794f"
}

output "rds_endpoint" {
  value = aws_db_instance.foro_db.endpoint
}
