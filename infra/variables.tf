variable "db_usuario" {
  description = "Usuario administrador de la base de datos"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password de la base de datos"
  type        = string
  sensitive   = true
}

variable "ip_permitida" {
  description = "IP (formato CIDR) desde la que se permite conectar a la base de datos"
  type        = string
}
