# Declaración de uso de IA

## Qué usé
Usé Claude (Anthropic) como asistente durante el desarrollo del
proyecto: generación opciones de código inicial de la API y el servicio de
moderación, los archivos de Terraform, los scripts del pipeline.

## Qué escribió la IA vs. qué hice yo
- La IA generó el código base de `app/api/api.py`, `app/moderacion/moderador.py`,
  los Dockerfiles, `infra/main.tf`, y los scripts de `pipeline/`.
- Yo ejecuté cada comando, leí cada error real que ocurrió, y en varios
  casos el problema NO se resolvió con lo que la IA sugirió al primer
  intento — por ejemplo: [aquí describe con tus palabras 1-2 casos reales,
  como el problema de la política SCP de AWS Academy con Object Lock, o el
  problema de IP pública vs privada en la misma VPC, que tomó varios
  intentos de diagnóstico real antes de encontrar la causa].
- Yo decidí las prioridades de remediación (qué hallazgo corregir primero)
  y verifiqué cada corrección corriendo los comandos yo mismo, revisando
  la salida real antes de continuar.

## Qué corregí o cuestioné de lo que propuso la IA
-La IA proponia usar una ip que no existia y use la ip privada,
 utilizar versiones más viejas y obsoletas que no funcionaban correctamente,
-Cuestiones el por que se tenia que sacar el S3 de terraform para que funcionara correctamente,
 por que ciertas versiones no eran compatibles.

## Qué entiendo y puedo explicar sin apoyo de IA
- Por qué mi RDS no necesita acceso público si está en la misma VPC que mi
  aplicación.
- Por qué la Etapa 30 audita con Python 3.12 y no con el Python del host.
- Por qué la Etapa 20 (secretos en el historial) nunca bloquea el pipeline.
- La diferencia entre lo que detecta SAST (Etapa 40) y DAST (Etapa 80) en
  mi propia aplicación.
