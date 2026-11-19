# NF-SEC-2026-004 · Matriz de pruebas de autorización (2026-11-19)

## Alcance y límite
Pruebas de funciones RPC de Supabase, bajo `SET LOCAL ROLE authenticated` con `request.jwt.claim.sub` definido en transacciones SQL y `ROLLBACK`. **No equivalen a sesiones JWT emitidas por Supabase Auth ni a navegación E2E real**. No se muestran identificadores personales ni valores nominales.

## Resultados
| Contexto de rol | Evidencia | Resultado |
|---|---|---|
| Maestro activo | `nf_folios_para_mapa`: 1 resultado permitido y sin campos nombre/CURP/telefono/direccion/municipio/localidad/CLUES; `nf_datos_para_envio`: formato habilitado; `nf_listar_blackbox`: estructura JSON tipo lista | PASS |
| Estatal activo | `nf_folios_para_mapa`: 1 resultado; formato nominal habilitado; `nf_listar_blackbox`: denegado | PASS |
| Supervisor DS6 activo | Mapa DS6: 1; mapa DS1: 0; listado propio: 1; detalle propio habilitado; formato nominal denegado; bitácora administrativa denegada | PASS |
| Promotor DS6 simulado | Perfil de Supervisor cambió temporalmente a Promotor dentro de la misma transacción, revertido mediante ROLLBACK. Mapa DS6: 1; DS1: 0; listado propio: 1; formato nominal y listado de accesos denegados | PASS, transaccional |

## Verificación posterior
- Expedientes: 1
- Perfiles: 3
- Promotores permanentes: 0
- Auditorías de datos: 1
- Contadores distritales: 6
- Hospitales de referencia verificados: 0
- Eventos de bitácora al corte: 212 (no se atribuye la diferencia respecto a cortes previos exclusivamente a estas pruebas).

## Pendientes obligatorios
1. E2E con JWT y sesiones reales: Maestro/Estatal/Supervisor/Promotor (crear o habilitar una cuenta de prueba autorizada para Promotor).
2. Validar cierre/revocación de sesión y limpieza de capas privadas en navegador.
3. Confirmar compatibilidad de eventos UI `ui_*` con el panel de auditoría.
4. Activar protección contra contraseñas filtradas en Supabase Auth.
5. Revisar el resto de funciones privilegiadas y completar autorización institucional antes de datos reales de menores.

Ningún usuario ni expediente de prueba queda creado por esta matriz. No altera la validación de campo `SITIO`.
