terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# S3 - almacena las imagenes/adjuntos de los hilos del foro
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# RDS - base de datos real del foro (Postgres)
# ---------------------------------------------------------------------------
resource "aws_security_group" "foro_db_sg" {
  name        = "avance2-foro-db-sg"
  description = "Acceso a la base de datos del foro"

  ingress {
    description = "Postgres desde la instancia de la aplicacion"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups  = ["sg-08bb0403cd54b7be9"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "foro_db" {
  identifier              = "avance2-foro-db"
  engine                  = "postgres"
  engine_version          = "15.17"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "foro"
  username                = var.db_usuario
  password                = var.db_password
  vpc_security_group_ids  = [aws_security_group.foro_db_sg.id]
  publicly_accessible     = true
  storage_encrypted       = true
  skip_final_snapshot     = true
  backup_retention_period = 1
}
