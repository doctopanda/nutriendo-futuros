# NF-TEST-2026-005 · Preparación de cuentas y ejecución automática

## Estado comprobado
- Supabase Auth contiene **3 usuarios**, todos con perfil asignado y activo.
- Roles actuales: Maestro, Estatal, Supervisor Distrital DS6.
- **No hay Promotor activo ni usuario sin perfil** disponible para reasignación.
- No se crean usuarios directamente con SQL en `auth.users`, pues el flujo oficial exige correo verificable, credenciales gestionadas por Supabase Auth y aprobación del rol mediante el mecanismo institucional.

## Cuentas de prueba sugeridas
Se recomienda utilizar cuentas de prueba con correos reales y controlados por el equipo, distintas de las cuentas administrativas operativas. Para la primera ronda E2E, al menos una nueva cuenta `promotor_salud` DS1 (para ensayar acceso ajeno a DS6) y, idealmente, un `supervisor_distrital` DS1. Las funciones de aprobación deben asignar roles únicamente después de confirmar el correo. No compartir contraseñas ni códigos MFA por chat.

El entorno de producción conserva los perfiles actuales. Si es necesario aislamiento completo, solicitar proyecto/branch de staging antes de capturar expedientes sintéticos persistentes: una nueva branch puede tener costo, que debe autorizarse aparte.

## Automatización preparada
`tests/nf_auth_rpc_smoke.py` usa Python 3 y biblioteca estándar; no modifica expedientes, roles, solicitudes ni permisos. Realiza login con Auth de cada rol usando variables de entorno protegidas, comprueba la identidad del rol, minimización del mapa, jurisdicción y bloqueos de datos nominales, blackbox y bitácora. No imprime datos clínicos, folios, tokens ni contraseñas. Salida `PASS/FAIL/SKIP`. Código de salida: `0` todo PASS; `1` FAIL; `3` pruebas incompletas (SKIP).

Variables: `NF_SUPABASE_URL`, `NF_PUBLISHABLE_KEY` y `NF_<MAESTRO|ESTATAL|SUPERVISOR|PROMOTOR>_EMAIL` / `_PASSWORD`.

### Uso local (sin guardar secretos)
1. Configurar variables del entorno local o del gestor de secretos del equipo.
2. Ejecutar `python3 tests/nf_auth_rpc_smoke.py` desde la raíz del repositorio.
3. Conservar únicamente los estados PASS/FAIL/SKIP en la bitácora. No capturar pantallas nominales.
4. Para repetir, basta ejecutar el comando: no requiere volver a elaborar consultas SQL manualmente.

## Límites obligatorios
- Las pruebas con tokens reales solo serán válidas después de que las cuentas existan y sus credenciales se faciliten **al entorno local**, no al repositorio.
- Para comprobar cierre de sesión, expiración/revocación JWT, interacción del iframe y limpieza visual del mapa hace falta una prueba de navegador autenticado.
- El smoke test sólo evalúa un subconjunto crítico de RPC. No certifica todas las 34 funciones privilegiadas ni habilita datos reales de menores.
- Antes de producción activar la protección de contraseñas filtradas, completar pruebas de seguridad institucional y mantener la auditoría de acceso.

## Evidencia técnica previa
`docs/NF-SEC-2026-004_MATRIZ_PRUEBAS_ROLES_2026-11-19.md` contiene el ensayo transaccional SQL, **no** E2E real.
