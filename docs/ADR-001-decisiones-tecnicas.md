# ADR-001: Decisiones técnicas del proyecto

## Contexto
Foro y Reseñas de Productos, Tema 4 del Avance 2. Aplicación Flask con
2 servicios en contenedores, RDS Postgres, S3, y pipeline propio.

## Decisiones

### 1. Autenticación con token simple en memoria, no JWT
**Decisión:** un diccionario `TOKENS = {}` en memoria, sin persistencia.
**Alternativa descartada:** JWT firmado.
**Por qué:** para el alcance de 4 días, un JWT agrega complejidad de manejo
de expiración y firma sin aportar valor demostrable adicional al proyecto.
**Trade-off aceptado:** los tokens se pierden si el contenedor se reinicia,
y no hay expiración. En un entorno real esto no sería aceptable.

### 2. RDS sin acceso público, en la misma VPC que la aplicación
**Decisión:** `publicly_accessible = false`, comunicación por IP privada.
**Por qué:** la aplicación corre en la misma VPC que la base de datos, así
que el acceso público a internet no aporta nada y sí aumenta la superficie
de ataque (hallazgo AWS-0180 de Trivy). Se corrigió después de descubrir
en la práctica que la conexión por IP privada funciona igual sin necesitar
exposición pública.

### 3. Bucket S3 gestionado parcialmente fuera de Terraform
**Decisión:** el bucket se crea/configura vía AWS CLI, no vía
`aws_s3_bucket` de Terraform.
**Por qué:** la cuenta de AWS Academy tiene una política de organización
(SCP) que bloquea explícitamente `s3:GetBucketObjectLockConfiguration`,
llamada que el proveedor de Terraform hace internamente incluso para
operaciones simples de lectura/creación de un bucket. Se intentó con las
versiones 5.x y 4.67 del proveedor, ambas fallan por la misma razón.
**Trade-off aceptado:** el bucket no aparece en el `terraform plan`/`apply`
como recurso gestionado; se documenta explícitamente en `infra/outputs.tf`
y en este ADR para que quede claro que es una decisión consciente, no un
descuido.

### 4. SCA auditado con Python 3.12 en contenedor descartable, no con el
### entorno virtual del host (Python 3.9)
**Decisión:** la Etapa 30 del pipeline usa `docker run python:3.12-slim`
para correr `pip-audit`, en vez del `venv` local del host.
**Por qué:** el host de la instancia EC2 tiene Python 3.9, pero la
aplicación real corre en contenedores con `python:3.12-slim`. Auditar con
Python 3.9 daba falsos "sin arreglo disponible" en 3 paquetes que sí
tienen versión corregida para Python 3.10+.

### 5. Servicio de moderación con reglas en memoria, sin modelo de ML
**Decisión:** 3 reglas explícitas (palabras prohibidas, longitud mínima,
duplicados) en vez de un modelo de clasificación de texto.
**Por qué:** para el alcance del proyecto, reglas explícitas son
suficientes para demostrar el patrón arquitectónico (servicio de
moderación separado, en su propio contenedor) sin la complejidad de
entrenar o integrar un modelo.
