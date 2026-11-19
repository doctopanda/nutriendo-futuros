# NF-SEC-2026-006 · Altas de perfiles y pruebas iniciales
**Fecha:** 2026-11-19

## Cuentas encontradas
Cinco cuentas de Supabase Auth con correo confirmado y sin rol, en estado PENDIENTE_AUTORIZACION, se asignaron al entorno piloto por solicitud del responsable del proyecto. No se registran contraseñas ni JWT en la evidencia.

| Alias | Rol | Distrito | Estado tras alta |
|---|---|---|---|
| Ojo de Buey | admin_maestro | sin distrito | ACTIVO |
| Pan de Leche | admin_estatal | sin distrito | ACTIVO |
| Telera | supervisor_distrital | DS06 | ACTIVO |
| Conchita | promotor_salud | DS06 | ACTIVO |
| Cochito | promotor_salud | DS01 | ACTIVO |

Se utilizó una transacción única de actualización del directorio `nfs_usuarios`; los triggers configurados sincronizaron `nf_private.perfiles` y registraron la asignación en la auditoría. La transacción incluyó comprobación de las cinco correspondencias antes de COMMIT.

## Pruebas automatizadas SQL
Se usó contexto `SET LOCAL ROLE authenticated` y `request.jwt.claim.sub` con identificadores de las cuentas ya existentes. Todas las pruebas se revirtieron mediante `ROLLBACK`. No fueron inicios de sesión reales ni emisión de JWT por Auth.

| Alias | Casos | Estado |
|---|---|---|
| Ojo de Buey | Perfil Maestro; mapa privado sin campos nominales; formato nominal permitido; blackbox permitida | PASS |
| Pan de Leche | Intento de prueba automática bloqueado por control de ejecución antes de obtener resultado | NO EJECUTADO |
| Telera | Perfil Supervisor DS06; mapa DS06 permitido, formato nominal y blackbox denegados | PASS |
| Conchita | Perfil Promotor DS06; mapa DS06 permitido, formato nominal y blackbox denegados | PASS |
| Cochito | Perfil Promotor DS01; mapa DS06 sin pacientes, formato nominal y blackbox denegados | PASS |

## Integridad verificada
- 1 paciente en la base.
- 8 perfiles activos (incluidos 5 nuevos).
- 2 promotores activos.
- 0 desajustes de rol/distrito entre directorio y perfil privado.
- 1 auditoría de datos.
- Ningún expediente fue modificado por la batería de pruebas.

## Próximo bloque manual indispensable
1. Realizar login en `/visor/` con cada cuenta (contraseña nunca compartida en chat).
2. Comprobar privilegios de Maestro y Estatal, MFA preferiblemente obligatorio para los roles con acceso nominal.
3. Comprobar sesión real y cierre, limpieza de capas y acceso restringido por distrito.
4. Informar solo PASS/FAIL y mensajes de error sin identificadores ni valores clínicos.
5. Al terminar el piloto, desactivar identidades de prueba y revocar sesiones.

**Advertencia:** estas cuentas tienen permisos reales sobre datos de la base piloto. No usar con pacientes reales ni dejar cuentas privilegiadas de prueba expuestas sin MFA y controles de sesión.
