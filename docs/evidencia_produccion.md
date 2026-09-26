# Evidencia de promoción a Producción

## Instancia de Producción
- **Nombre:** foro-resenas-produccion
- **IP pública:** 44.215.103.7
- **Security group:** sg-0d97ef075e2b46c99 (launch-wizard-3, nuevo, creado
  específicamente para esta instancia)

## Qué se promovió
Se clonó el repositorio y se hizo checkout al branch `produccion`
(sincronizado con `main` en el commit `38a266e`), que contiene el código
YA remediado del hallazgo XSS (CWE-79) — nunca se aplicó el parche crudo
directamente en esta instancia.

## Verificación en Producción

1. **Acceso público confirmado:** `http://44.215.103.7:5000/` carga la
   interfaz web de la aplicación correctamente.
2. **Remediación del XSS confirmada en este ambiente:**

curl -s -X POST http://localhost:5001/moderacion/resenas/1/vista-previa
-d "contenido=<script>alert(1)</script>"

 Respuesta: `&lt;script&gt;alert(1)&lt;/script&gt;` (escapado
   correctamente, igual que en QA).
3. **Flujo de negocio funcionando contra la base de datos real:** se
   registró un usuario de prueba (`cliente_produccion`) y quedó guardado
   en la misma instancia de RDS que usa QA.

## Conexión a RDS desde Producción
Fue necesario autorizar el security group de Producción
(`sg-0d97ef075e2b46c99`) en las reglas de entrada del security group de
RDS (`sg-03550cdade981e147`), ya que por diseño la base de datos solo
acepta conexiones desde security groups explícitamente autorizados, no
desde cualquier instancia de la cuenta.
