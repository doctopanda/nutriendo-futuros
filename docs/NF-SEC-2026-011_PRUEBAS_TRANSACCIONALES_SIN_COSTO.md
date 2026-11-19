# NF-SEC-2026-011 · Ejecución gratuita de pruebas transaccionales
**Fecha:** 19 de noviembre de 2026. **Costo de nueva infraestructura:** 0 MXN. No se creó ninguna rama de Supabase ni proyecto facturable.

## Método y límites
Pruebas ejecutadas sobre el proyecto actual dentro de `BEGIN ... ROLLBACK` mediante la conexión SQL institucional y `SET LOCAL ROLE authenticated` + `request.jwt.claim.sub` con cuentas de prueba existentes. Las escrituras ficticias fueron visibles solo durante su transacción y desaparecieron tras `ROLLBACK`. Esto valida comportamiento SQL y control interno de las RPC, **no** equivale a solicitudes de escritura concurrentes con JWT emitidos por el navegador ni a aislamiento físico en una base staging. No se deben probar cargas/estrés sobre el piloto actual.

## Resultados
| Caso | Prueba | Resultado |
|---|---|---|
| W01 | Promotor DS01 registra cédula ficticia; servidor genera folio DS01, visible en su distrito, sin mostrar DS06 | PASS transaccional |
| W02 | Promotor DS06 registra cédula ficticia y obtiene folio DS06 | PASS transaccional |
| W03 | Tras crear paciente ficticio en DS06, al cambiar al contexto de Promotor DS01 se rechaza su lectura por `nf_detalle_folio` y su modificación por `nf_completar_faltantes` | PASS transaccional |
| W04 | Supervisor DS06 completa campo `localidad` pendiente de paciente ficticio DS06 y RPC confirma modificación | PASS transaccional |
| W05 | Supervisor DS06 intenta cambiar `nombre` por RPC de faltantes y recibe denegación | PASS transaccional |
| W09 secuencial | Repetir identidad ficticia en DS06 devuelve `requiere_revision` sin revelar folio a Promotor | PASS transaccional |
| W10 | Cédula sintética con `autorizacion=no` rechazada | PASS transaccional |
| W11 | Cédula sintética con identidad esencial insuficiente rechazada | PASS transaccional |

## Evidencia de reversión final
- Expedientes persistentes: **1**.
- Expedientes con nombres de prueba sintética: **0**.
- Perfiles activos: **8**.
- Auditorías de datos persistentes: **1**.
- Distritos con contador: **6**.
- Último folio en DS01: **0**; DS06: **1**.
- Sin cambios persistentes conocidos sobre expedientes ni contadores de folios.
- En el primer intento de W01, una consulta directa a `nf_private.pacientes` bajo `authenticated` fue denegada por PostgreSQL. Se corrigió el aserto para usar la RPC autorizada y la prueba aprobó. Este fallo del arnés no es un hallazgo de filtración.

## Pruebas sin ejecutar
- W06: rectificación estatal real, solo en staging aislado.
- W07: rechazo de `nf_editar_paciente` desde Promotor (comprobado anteriormente con otros roles, falta repetición específica).
- W08 y W09 simultánea: generación concurrente, carrera de duplicados y posibles deadlocks. Requieren conexiones separadas y staging libre de datos reales.
- W12–W16: aislamiento extendido, auditoría nominal de escritura, cierre de sesión y revocación, MFA y evaluación completa de calidad.
- Validación de rol real en API con JWT de escritura: pendiente. No promover a PASS a partir de este arnés SQL.

## Decisión de infraestructura
Se cumple la orden expresa: no compras ni nuevas suscripciones, costo 0 MXN. Las pruebas que requieren aislamiento físico o concurrencia se mantienen pendientes hasta disponer de una instalación local gratuita de PostgreSQL/Supabase con esquema/migraciones y exclusivamente datos ficticios, o de un recurso gratuito confirmado sin facturación.

No se alteraron migraciones ni funciones de producción durante esta etapa.
