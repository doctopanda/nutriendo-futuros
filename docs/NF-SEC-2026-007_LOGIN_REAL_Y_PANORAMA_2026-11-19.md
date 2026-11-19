# NF-SEC-2026-007 · Verificación de login real y pantalla por rol
Fecha: 2026-11-19 (hora Hermosillo).

## Evidencia proporcionada por el responsable del piloto
Cinco capturas del visor institucional, asociadas por el responsable a Cochito, Conchita, Telera, Pan de Leche y Ojo de Buey.

| Alias | Rol previamente asignado | Pantalla capturada | Supabase Auth last_sign_in_at | Estado |
|---|---|---|---|---|
| Cochito | promotor_salud DS01 | Distrito DS01; expedientes 0, seguimiento 0, valoraciones 0, distritos operativos 0 | 2026-11-19 18:22:53 UTC | LOGIN + PANORAMA PASS |
| Conchita | promotor_salud DS06 | Distrito DS06; expedientes 1, seguimiento 1, valoraciones 1, distritos operativos 1 | 2026-11-19 18:24:14 UTC | LOGIN + PANORAMA PASS |
| Telera | supervisor_distrital DS06 | Distrito DS06; expedientes 1, seguimiento 1, valoraciones 1, distritos operativos 1 | 2026-11-19 18:26:21 UTC | LOGIN + PANORAMA PASS |
| Pan de Leche | admin_estatal | Alcance estatal; expedientes 1, seguimiento 1, valoraciones 1, distritos operativos 1 | 2026-11-19 18:27:07 UTC | LOGIN + PANORAMA PASS |
| Ojo de Buey | admin_maestro | Alcance estatal; expedientes 1, seguimiento 1, valoraciones 1, distritos operativos 1 | 2026-11-19 18:28:07 UTC | LOGIN + PANORAMA PASS |

Se contrastaron los cinco accesos visibles con `auth.users.last_sign_in_at`. El instante de login es observado en Auth, no demuestra por sí mismo que una sesión siga vigente; al consultar la tabla de sesiones se observó una fila actual de Ojo de Buey y ninguna para los otros cuatro. No equiparar esto con certificación de revocación.

## Verificado y no verificado
- PASS: inicio de sesión registrado en Auth para las cinco cuentas; visor accesible y filtros territoriales congruentes con rol.
- PASS visual: DS01 (Cochito) no muestra caso de DS06; DS06 y roles estatales sí lo muestran.
- PENDIENTE: operaciones de edición/captura, bloqueos nominales ejecutados desde navegador con JWT real, búsqueda de folios ajenos mediante API autenticada, cierre de sesión/refresh/revocación, limpieza de marcadores privados, MFA y protección contra contraseñas filtradas.
- No se almacenan capturas con nombres de paciente, contraseñas, JWT ni datos clínicos identificables en este repositorio público.
- Las capturas son evidencia proporcionada en la conversación; el documento registra resultados textuales y no incorpora los archivos binarios.

**Alcance de aprobación:** login y panorama por rol, no certificación E2E integral. Mantener piloto técnico sin datos reales de menores hasta revisión de seguridad y autorización institucional.
