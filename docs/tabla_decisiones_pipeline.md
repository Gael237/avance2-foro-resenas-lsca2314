# Tabla de decisiones del pipeline

| Etapa | Riesgo de MI aplicación que cubre | Umbral de bloqueo | Por qué este umbral |
|---|---|---|---|
| 10 - Secretos en el código | La API se conecta a RDS con credenciales por variable de entorno; un secreto hardcodeado por error (como pasó con la API key del Sistema de Catálogo Retail en prácticas anteriores) expondría acceso directo a la base de datos de usuarios. | 0 hallazgos en `app/`, `pipeline/`, `docs/` y archivos raíz. Se excluyó explícitamente `infra/` porque el estado de Terraform guarda secretos en texto plano por diseño (limitación conocida sin backend remoto cifrado), y ese archivo ya está protegido por `.gitignore`, nunca llega al repositorio. | Bloquear con cualquier hallazgo es correcto aquí porque el código de aplicación NUNCA debe tener secretos; no hay excusa válida para tolerar ni uno. |
| 20 - Secretos en el historial | Si alguna vez se sube una credencial y luego se "limpia" en un commit posterior, sigue viva en el historial de git para cualquiera que haya clonado antes. | No bloquea; solo documenta hallazgos. | Un secreto ya publicado no se puede "des-publicar" borrando el commit; la única acción real es rotarlo. Bloquear el pipeline por esto no resuelve nada, solo genera fricción. |
| 30 - Dependencias (SCA) | La API usa Flask, SQLAlchemy, requests y psycopg2; el moderador usa Flask. Una vulnerabilidad conocida en cualquiera de estas (ej. deserialización insegura, RCE) es explotable sin que el atacante toque mi código. | 0 vulnerabilidades conocidas, auditadas con Python 3.12 (la misma versión del Dockerfile de producción, no la del host). | Cero tolerancia porque las dependencias son la superficie de ataque más grande y más fácil de mantener al día con un simple `pip install --upgrade`. |
| 40 - Código propio (SAST) | Mi propio código maneja contraseñas (hash), tokens, y consultas a base de datos vía ORM. Un error como concatenar SQL directo o loggear una contraseña sería introducido por mí mismo, no por una dependencia. | 0 hallazgos ERROR en semgrep (reglas `p/security-audit`) y 0 HIGH en bandit. | Los hallazgos MEDIUM/LOW de bandit (como advertencias informativas) no bloquean porque no representan explotabilidad directa; ERROR/HIGH sí. |
| 50 - Infraestructura como código | Mi RDS guarda contraseñas de usuarios (con hash) y el contenido del foro; una configuración insegura de red (acceso público, egreso sin restricción) expondría la base de datos completa a internet. | 0 hallazgos HIGH o CRITICAL. Los LOW/MEDIUM (como falta de Performance Insights o retención de backup baja) quedan reportados. | Bloquear con severidades menores generaría tanta fricción que el equipo terminaría ignorando el control por completo; se prioriza lo explotable. |
| 60 - Imágenes de contenedor | Ambos Dockerfiles corren procesos que reciben datos externos (peticiones HTTP); una imagen corriendo como root o sin versión fija amplía el daño posible si el proceso se compromete. | 0 hallazgos HIGH o CRITICAL por Dockerfile. | Mismo criterio que la Etapa 50: severidad real, no perfección cosmética. |
| 70 - SBOM | No es un control de riesgo, es preparación para el futuro: si mañana sale una CVE nueva en cualquier librería, necesito responder "¿me afecta?" sin auditar manualmente. | No bloquea; genera el artefacto `sbom_cyclonedx.json`. | Un inventario nunca debería bloquear un despliegue, solo existir. |
| 80 - Pruebas dinámicas (DAST) | El endpoint `/hilos` sin autenticación permitiría que cualquiera cree contenido a nombre de otro usuario; un login que acepte contraseñas incorrectas rompería la identificación de usuario que exige el proyecto. | 0 pruebas críticas fallidas: la API responde, el login rechaza credenciales inválidas, y las rutas protegidas exigen token. | Estas son pruebas de comportamiento real en ejecución, no de código estático; fallar cualquiera de ellas significa que el requisito mínimo de "identificación de usuario" no se cumple de verdad. |
| 90 - Puerta de control | Consolida las 8 etapas en un único veredicto (bloquear/permitir), deja constancia en `reportes/audit.log`, y simula una notificación al equipo. | Bloquea si cualquier etapa marcada como bloqueante (10, 30, 40, 50, 60, 80) falla. | Sin esta etapa, tendría 8 controles sueltos sin ninguna decisión final — exactamente el error que las notas del curso señalan como el más frecuente. |

## Qué decidí NO cubrir, y por qué

- **Rate limiting / protección contra fuerza bruta en `/login`:** no hay
  ningún control que detecte múltiples intentos fallidos de login desde la
  misma fuente. Quedó fuera del alcance de 4 días; en un entorno real sería
  indispensable.
- **Escaneo de la imagen ya construida (Trivy image, no solo Dockerfile):**
  el pipeline analiza el Dockerfile de forma estática, pero no escanea la
  imagen final con las dependencias del sistema operativo base ya
  instaladas (vulnerabilidades del propio `python:3.12-slim`). Se
  documenta como mejora futura.
- **Cifrado en tránsito (TLS) entre contenedores:** la comunicación entre
  `api` y `moderacion` va sin TLS dentro de la red interna de Docker
  Compose. Se acepta el riesgo porque el tráfico nunca sale de la red
  interna del host.
