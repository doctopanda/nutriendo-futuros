# NF-SEC-2026-009 · Consolidado de seis informes RLS reales
Fecha de ejecución: 19 de noviembre de 2026. Origen: exportaciones `NF-RLS-E2E-READONLY-v1` proporcionadas por la coordinación del piloto. Este documento resume resultados sin correos, JWT, CURP, folios ni datos clínicos.

## Resumen
- 6 ejecuciones con sesiones autenticadas, 18 controles por ejecución.
- 108 resultados en total: **104 PASS, 0 FAIL, 4 SKIP**.
- Cinco perfiles operativos (Maestro repetido en dos ejecuciones); cuatro roles distintos.
- Las pruebas son **de lectura y permisos**, no certifican escrituras ni revocación de sesiones.

| Alias asociado a cuenta de prueba | Rol | Distrito | Fecha UTC | PASS | FAIL | SKIP |
|---|---|---|---|---:|---:|---:|
| Ojo de Buey | admin_maestro | estatal | 18:38:03 | 17 | 0 | 1 |
| Cochito | promotor_salud | DS01 | 18:40:26 | 17 | 0 | 1 |
| Conchita | promotor_salud | DS06 | 18:40:59 | 18 | 0 | 0 |
| Telera | supervisor_distrital | DS06 | 18:41:30 | 18 | 0 | 0 |
| Ojo de Buey (repetición) | admin_maestro | estatal | 18:42:07 | 17 | 0 | 1 |
| Pan de Leche | admin_estatal | estatal | 18:42:32 | 17 | 0 | 1 |

## Resultados relevantes
- DS01 (Cochito): mapa y listado sin expedientes; consulta solicitada del DS06 con cero resultados, PASS.
- DS06 (Conchita/Telera): 1 expediente permitido; consulta DS01 sin resultados; control de nominales denegado, PASS.
- Administradores: un expediente estatal; exportación nominal autorizada; Blackbox solo Maestro, PASS.
- RPCs de mapa/formato bajo sesión anónima: denegadas en las seis ejecuciones, PASS.
- Consulta directa a tabla privada y directorio: respuestas bloqueadas en todas las ejecuciones, PASS.

## Omisiones (no fallos)
- Tres SKIP: consulta de distrito ajeno, no aplicable a rol con alcance estatal (dos ejecuciones Maestro, una Estatal).
- Un SKIP: detalle clínico no nominal del DS01 sin expedientes accesibles. **No se ha probado acceso a un caso propio para ese perfil**.

## Límites metodológicos
1. En un distrito vacío, un resultado 0 o PASS por ausencia de campos sensibles no prueba que el filtrado/serialización sea correcto con un caso del propio distrito.
2. Las funciones de lectura pueden registrar eventos de auditoría. No se comprobaron transacciones de escritura con datos sintéticos.
3. Las pruebas no comprueban cierre de sesión, refresh, revocación de tokens, MFA ni controles administrativos de Supabase Auth.
4. El probador no inspecciona directamente políticas RLS de tablas internas: comprueba el comportamiento de las RPC con JWT reales y los grants de Data API.
5. Los exportes solo incluyen rol, distrito, momento y resultados agregados. La atribución a alias se basa en las cuentas de prueba y su orden de ejecución informado, no en un identificador personal dentro del archivo.

## Siguientes pruebas
- Preparar base de ensayo aislada para crear expedientes **sintéticos** en DS01 y DS06, probar lectura cruzada con datos no vacíos y ediciones/correcciones, así como no duplicación y generación concurrente de folios.
- Probar en navegador cierre, limpieza de caché/cartografía, refresh y revocación.
- Configurar MFA para Maestro/Estatal; activar protección contra contraseñas filtradas.
- Mantener el piloto sin cargas de datos reales de menores hasta autorización institucional.

**Conclusión**: batería `NF-RLS-E2E-READONLY-v1` satisfactoria en escenarios evaluables; no corresponde calificar de certificación completa de seguridad clínica.
