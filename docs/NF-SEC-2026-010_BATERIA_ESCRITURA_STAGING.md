# NF-SEC-2026-010 · Batería de escritura y consistencia del piloto
Fecha: 2026-11-19 · Estado: preparada, ejecución de escritura pendiente de staging aislado.

## Punto de partida comprobado
- Se consultó Supabase: no hay ramas de desarrollo existentes (`list_branches` vacío).
- Existen migraciones vigentes hasta NF-SEC-003. La rama de GitHub no es un entorno de base de datos.
- Restricciones de base verificadas: `pacientes.folio` UNIQUE y CHECK `^NF-DS[1-6]-[0-9]{8}$`; `folios_distritales.distrito_id` PK, contador entre 0 y 99999999; `seguimientos` UNIQUE (paciente_id, numero_consulta).
- Estas restricciones respaldan consistencia, pero la concurrencia y deduplicación todavía requieren pruebas activas.
- No se han creado pacientes sintéticos en la base del piloto.

## Matriz de escritura staging · Caso → expectativa
| Caso | Actor | Operación | Resultado esperado | Evidencia |
|---|---|---|---|---|
| W01 | Promotor DS01 | Registrar cédula sintética DS01, validación SITIO | Folio NF-DS1-######## único; auditoría completa | JSON reducido sin identidad |
| W02 | Promotor DS06 | Registrar cédula sintética DS06 | Folio NF-DS6-######## único | Conteos y folio enmascarado |
| W03 | Promotor DS01 | Buscar/editar folio existente del DS06 | Denegación explícita; cero cambios | Código de error |
| W04 | Supervisor DS06 | Completar solo campo marcado faltante de paciente DS06 | Guardado, motivo y bitácora | Campos cambiados (nombres no valores) |
| W05 | Promotor DS06 | Alterar nombre o CURP por RPC de corrección | Denegación | Código de error |
| W06 | Estatal | Rectificar identidad de paciente sintético con motivo válido | Cambio auditado | Conteo de eventos |
| W07 | Promotor DS01 | Intentar `nf_editar_paciente` | Denegación | Código de error |
| W08 | Dos sesiones DS06 | Altas simultáneas de pacientes sintéticos distintos | Dos folios únicos y consecutivos | Diferencia entre contadores |
| W09 | Dos sesiones | Intentar registrar la misma identidad sintética | Una sola alta; otra requiere revisión o rechazo | Conteo de expedientes |
| W10 | Todos | Enviar cédula sin autorización documentada | Denegación, sin folio nuevo | Conteos antes/después |
| W11 | Todos | Enviar cédula con datos esenciales incompletos | Denegación con razón válida | Código no nominal |
| W12 | Promotor/ Supervisor | Intentar acceder a tablas `nf_private` directamente | Acceso bloqueado | Código SQL/PostgREST |
| W13 | Maestro | Consultar bitácora y blackbox tras escrituras sintéticas | Eventos visibles y atribuibles | Conteo e ID aleatorio de ejecución |
| W14 | Roles de ensayo | Logout, refresh y JWT revocado | Sin acceso nuevo ni caché privada visible | Resultado navegador |
| W15 | Administrativo | Verificar MFA antes de revelar nominales | AAL2 cuando la política lo exija | Respuesta AAL, no factor |
| W16 | Piloto | Verificar que el contador mantenga los 6 distritos | Sin alteración fuera de staging | Snapshot agregado |

## Estrategia de ejecución
1. Obtener entorno staging **separado**, sin pacientes ni secretos reales. Preferir Supabase Branching cuando costo y permisos estén autorizados; la creación podría producir facturación y no se ha autorizado aún.
2. Reaplicar migraciones al branch. Comprobar que todas las funciones y triggers requeridos estén instalados.
3. Crear identidades de prueba exclusivas del branch, confirmarlas por Auth y asignar roles. Nunca replicar contraseñas ni JWT de producción.
4. Insertar exclusivamente identidad ficticia con identificador aleatorio y fechas coherentes. Marcar toda evidencia TEST.
5. Ejecutar W01–W16; no usar SQL SET ROLE para afirmar que se probaron JWT auténticos.
6. Registrar PASS/FAIL/SKIP, medición de auditoría, evidencia minimizada y plan de limpieza. Eliminar o resetear staging después de cerrar el piloto.

## Guardas de seguridad
- No ejecutar esta batería con el project_id productivo `neoihelwsuitgoeowrbc`.
- No enviar información clínica o personal a GitHub Pages ni repositorio público.
- No hacer escrituras de prueba sobre datos reales, ni registrar valores nominales en JSON.
- No confundir `SECURITY DEFINER` con políticas RLS sobre tablas; medir ambas capas.
- Prioridad: W01–W03, W08–W09, luego auditoría/corrección y sesiones.

## Estado
**Preparación de la matriz y verificación estática: completadas. Escrituras y staging: pendientes.**
