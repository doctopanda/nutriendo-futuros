# NUTRIENDO FUTUROS | Protocolo de piloto de campo
**Vigente técnicamente:** 18 de noviembre de 2026 · **modalidad:** validación operativa en sitio.

## Decisión temporal
Se suspende la aprobación estatal previa de nuevos ingresos/casos para capturas autorizadas del piloto. El personal institucional autorizado genera el expediente directamente en su distrito y el backend registra `validacion_modalidad = SITIO`. Esta marca significa **registro aceptado operativamente en campo**, no revisión clínica estatal, autorización jurídica ni certificación de calidad diagnóstica.

## Flujo de captura
1. Ingreso mediante sesión Supabase Auth y perfil activo, con acceso según distrito.
2. Captura de identidad mínima y valoración. Se mantiene la verificación de autorización/consentimiento aplicable.
3. Antes del guardado, `nf_prevalidar_cedula` devuelve impedimentos esenciales y la lista de faltantes no bloqueantes.
4. La interfaz muestra los campos pendientes y permite **corregir** o **continuar con advertencia**. Se evita generar folio si el usuario cancela.
5. `nf_registrar_cedula` evita duplicados de identidad, asigna folio único y consecutivo `NF-DS{1..6}-00000001` en transacción y almacena los datos en `nf_private`.
6. Al registrar una valoración, un trigger recalcula la calidad. Se guarda el indicador `datos_incompletos`, la lista `campos_faltantes`, y un evento histórico en `nf_private.auditoria_datos`.
7. Los visores autorizados muestran el folio, la marca de información incompleta y el número de pendientes; el detalle por folio incluye la lista. Las correcciones posteriores actualizan la marca de calidad y dejan historia.

## Controles que permanecen obligatorios
- Usuario institucional autorizado y activo; distrito válido (1 a 6).
- Autorización documentada para la encuesta y el manejo de información.
- Identidad mínima: nombre, fecha de nacimiento, sexo y fecha de primera evaluación/valoración coherentes.
- Verificación de CURP cuando se proporciona; si no se tiene, puede omitirse.
- Detección de duplicados (no crear dos expedientes para una misma identidad).
- Expediente nominal solo en esquema `nf_private`, sin exposición pública ni permisos directos a visitantes.
- Roles `admin_maestro`, `admin_estatal`, `supervisor_distrital`, `promotor_salud`; los perfiles distritales solo capturan en su distrito.

## Auditoría de calidad
Los campos prioritarios evaluados incluyen cuidador, dirección, teléfono, CLUES, municipio, localidad, fecha de valoración, talla, peso y perímetro braquial. El catálogo CLUES no verificado también se identifica como pendiente, sin bloquear el alta. El estado de calidad se reevalúa en nuevas valoraciones o rectificaciones. No se incluyen nombres ni domicilios en los mensajes de auditoría pública.

**Tablas nuevas/campos:** `nf_private.auditoria_datos`, `pacientes.datos_incompletos`, `pacientes.campos_faltantes`, `pacientes.validacion_modalidad`, `pacientes.validado_en_sitio_en`, `pacientes.validado_en_sitio_por`, `pacientes.auditoria_datos_actualizada_en`.

## Evidencia de pruebas técnicas
- Registro simulado con rol Maestro y rol Supervisor Distrital, incluyendo CLUES y contacto ausentes: alta válida, folio distrital y marca de datos incompletos.
- Preauditoría simulada con datos incompletos: captura permitida con advertencias.
- Validación de disparadores de auditoría e integridad: sin fallos detectados en estas pruebas.
- Pruebas dentro de transacciones reversibles, **sin conservar pacientes ficticios**.
- Análisis sintáctico del módulo JavaScript de captura: correcto.
- GitHub Pages informó despliegue satisfactorio del cambio de interfaz en commit `3e0f5fec`.

## Limitaciones y salida del piloto
Las pruebas automatizadas no equivalen a una validación completa en navegador y en dispositivos con usuarios reales. Antes de ingresar expedientes reales de menores, verificar autorizaciones institucionales, aviso de privacidad, controles de sesión, pruebas de perfiles, respaldos, incidentes y normas aplicables. No modificar retroactivamente el historial de auditoría cuando se restablezca la revisión estatal.

**Rollback:** conservar copias/versionado de funciones y esquema; revertir el commit de interfaz si procede, y migrar el backend mediante un cambio compensatorio controlado. No borrar historiales ni folios para deshacer el piloto.

**Código de migración:** [supabase/migracion_piloto_campo_validacion_sitio_20261118.sql](../supabase/migracion_piloto_campo_validacion_sitio_20261118.sql).
