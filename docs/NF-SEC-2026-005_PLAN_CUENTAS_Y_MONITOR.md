# NF-SEC-2026-005 · Plan de cuentas de prueba y ejecución semiautomática
**Fecha:** 2026-11-19 · **Entorno:** NUTRIENDOFUTUROS (piloto técnico)

## Inventario verificado
- Activos en `nf_private.perfiles`: 1 Maestro, 1 Estatal, 1 Supervisor DS6, 0 Promotores.
- El espejo de `public.nfs_usuarios` y `nf_private.perfiles` no presenta desajustes de perfiles activos.
- Las cuentas no se crean con INSERT manual a `auth.users`: utilizar Auth signup/invite oficial, confirmar correo y completar asignación autorizada.
- No compartir contraseñas por chat, ni usar usuarios de producción para las pruebas destructivas.
- No almacenar datos nominales sintéticos en el repositorio público.

## Perfiles de prueba propuestos (crear solo tras contar con correos reales controlados y verificados)
| Etiqueta de prueba | Rol objetivo | Distrito | Propósito |
|---|---|---|---|
| NF-TST-MAESTRO | admin_maestro | sin distrito | acceso administrativo/blackbox, MFA si se habilita |
| NF-TST-ESTATAL | admin_estatal | sin distrito | formato nominal y aprobación, blackbox denegada |
| NF-TST-SUP-DS6 | supervisor_distrital | 6 | captura en sitio y lectura de DS6 |
| NF-TST-PROM-DS6 | promotor_salud | 6 | captura y seguimiento limitados a DS6 |
| NF-TST-PROM-DS1 | promotor_salud | 1 | prueba cruzada: no consultar/modificar DS6 |

**Mínimo de cuentas nuevas para cubrir los cuatro roles si se reutilizan cuentas institucionales de prueba ya autorizadas:** dos Promotores, uno DS6 y otro DS1. Si las cuentas existentes pertenecen a personal real, usar cuentas específicas del piloto para todos los roles.

## Procedimiento
1. Crear/invitar cada identidad exclusivamente mediante Supabase Auth y confirmar el correo por el propietario.
2. Verificar que las cuentas aparecen como pendientes y *sin acceso a datos clínicos*.
3. Aprobar solicitudes de `promotor_salud` / `supervisor_distrital` desde la bandeja institucional por usuario Maestro/Estatal autorizado. Asignación/reasignación administrativa directa mediante `nf_asignar_usuario_existente` exclusivamente Maestro.
4. Ejecutar el cuaderno `NF-SEC-005 · Monitor reutilizable del piloto` para revisar sincronización de roles y concesiones SQL.
5. Probar inicio de sesión y cierre en `/visor/` y `/calidad/`, consulta del distrito propio, rechazo del ajeno, acceso nominal denegado, cierre de sesión y limpieza de capas de mapa.
6. Registrar por prueba: código, hora, cuenta de prueba (alias, no correo), rol, distrito, resultado, evidencia minimizada y versión de aplicación/RPC.
7. Eliminar o desactivar las cuentas de prueba siguiendo el procedimiento de Auth y registrar la revocación de sesión al cerrar el piloto.

## Cuaderno automatizado en Supabase
https://supabase.com/dashboard/project/neoihelwsuitgoeowrbc/explorer/notebook/595b4b46-87c0-488a-9d75-3d959c56b03c

Sus cuatro consultas SQL solo leen inventario de roles, grants privados, estado del piloto y funciones privilegiadas. Se ejecutó por primera vez con éxito el 2026-11-19. El cuaderno no crea cuentas ni ejecuta pruebas de sesiones reales.

## Resultado inicial 2026-11-19
- Maestro 1; Estatal 1; Supervisor 1; Promotor 0; discordancias de directorio 0.
- Sin grants directos en tablas `nf_private` para `anon` ni `authenticated`.
- 1 expediente (incompleto); 6 contadores distritales; 0 hospitales verificados; 0 expedientes sin alias.
- Funciones `SECURITY DEFINER` listadas para auditoría individual: que `authenticated` tenga EXECUTE no implica autorización automática; verificar condiciones internas.

## Bloqueos
Pruebas E2E solo tras cuentas de correo verificadas. Protección de contraseñas filtradas pendiente. No cargar datos reales de menores antes de autorizaciones institucionales y pruebas completas.

## Seguridad operacional
Los datos sintéticos deben quedar señalados como TEST y ubicarse exclusivamente en una base de pruebas segregada cuando se requieran altas/ediciones reales. Las comprobaciones de lectura y pruebas SQL con `ROLLBACK` son aceptables en el piloto actual, pero no sustituyen un entorno de staging.
