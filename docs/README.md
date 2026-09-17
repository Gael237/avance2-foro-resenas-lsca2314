# Foro y Reseñas de Productos — Sistema de Catálogo Retail

Aplicación de foro donde los usuarios registrados abren hilos de discusión
sobre productos y publican comentarios con calificación. Todo comentario
pasa por un servicio de moderación independiente antes de publicarse.

## Servicios

- **`app/api`** (puerto 5000): API Flask + SQLAlchemy. Registro, login,
  hilos, comentarios. Se conecta a una base de datos PostgreSQL real en AWS RDS.
- **`app/moderacion`** (puerto 5001): microservicio Flask independiente.
  Recibe un texto por HTTP y decide si se aprueba, aplicando 3 reglas:
  palabras prohibidas, longitud mínima, y detección de contenido duplicado.

## Cómo levantarlo

1. Crea un archivo `.env` en la raíz con:
DATABASE_URL=postgresql://usuario:password@host:5432/foro
2. Corre:
```bash
   docker compose up --build -d
```
3. Verifica:
```bash
   curl http://localhost:5000/salud
   curl http://localhost:5001/salud
```

## Flujo de negocio completo

```bash
curl -X POST http://localhost:5000/registro -H "Content-Type: application/json" \
  -d '{"nombre_usuario":"cliente1","password":"clave123"}'

TOKEN=$(curl -s -X POST http://localhost:5000/login -H "Content-Type: application/json" \
  -d '{"nombre_usuario":"cliente1","password":"clave123"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['token'])")

curl -X POST http://localhost:5000/hilos -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"producto":"Audifonos inalambricos","titulo":"Se desconectan solos"}'

curl -X POST http://localhost:5000/hilos/1/comentarios -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"texto":"A mi tambien me paso lo mismo","calificacion":2}'
```

## Servicios de AWS que usa

- **S3**: bucket `avance2-foro-resenas-adjuntos-f2cc794f` — almacenamiento de
  adjuntos, con acceso público bloqueado y cifrado con AES256.
- **RDS**: instancia PostgreSQL `avance2-foro-db`, cifrada, sin acceso
  público a internet (alcanzable solo desde dentro de la misma VPC donde
  vive la instancia de la aplicación).

## Pipeline

Ver `docs/tabla_decisiones_pipeline.md` para la justificación completa de
cada etapa. Para correrlo:
```bash
bash pipeline/bootstrap_pipeline.sh
bash pipeline/pipeline_local.sh
```
