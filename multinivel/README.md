# Nutriendo Futuros · Red Multinivel v0.1

**Un expediente, un folio, un futuro.**

Seis carátulas responsivas con la identidad **Mezquite**: Promotor, Unidad de Salud, DIF, Supervisor Distrital, Administrador Estatal y Administrador Maestro.

## Abrir

Abre `index.html` en un navegador moderno o publica estos archivos en una subcarpeta estática. No necesita internet ni claves.

## Interacciones

1. Cambia de rol con el selector superior o menú izquierdo.
2. En Promotor completa los datos **ficticios**, escribe `Ejemplo` como dirección, elige una sugerencia, declara derechohabiencia y una unidad simulada. Genera referencia.
3. Ve a Unidad de Salud: selecciona el folio y registra `Atendido · nueva cita`, `Atendido · referido`, `No acudió` o cita programada.
4. Ve a DIF: comprueba el bloqueo de domicilio antes de atención. Tras marcar atendido y con consentimiento DIF, aparece el formulario de hogar.
5. Revisa las alertas distritales, indicadores estatales y bitácora maestra.
6. Los botones **Ver cédula** y **Ver referencia** ofrecen borradores visuales imprimibles. Son demostrativos, **no formatos oficiales**.

## Seguridad y límites

- Los folios y las unidades son ficticios; no hay pacientes reales.
- Los datos existen solo en la memoria de la pestaña abierta. Se borran al recargar y no se envían a servidor.
- El selector de roles no es un mecanismo de seguridad.
- El autocomplete geográfico solo busca en direcciones ficticias precargadas, **no** en direcciones reales de Sonora.
- No hay conexión efectiva con Supabase en esta versión: ver `ARQUITECTURA_Y_CONEXIONES.md` y la migración SQL **sin ejecutar**.
- No se asignan unidades clínicas reales ni se calcula distancia física real.

## Archivos

- `index.html`: carátulas y lógica de demostración.
- `assets/*.svg`: emblema del mezquite recuperado de la identidad gráfica aprobada.
- `nf_multinivel_esquema_propuesto_v0_1.sql`: tablas privadas adicionales propuestas, acceso denegado por defecto.
- `ARQUITECTURA_Y_CONEXIONES.md`: estados, reglas de acceso, APIs planeadas, fuentes y pasos de despliegue.
- `caratula-*.png`: capturas de referencia de las seis vistas.

Versión para evaluar con promotores y enlaces institucionales. No ingresar datos reales en una página de prueba, aunque sea local.
