# NUTRIENDO FUTUROS · LEET-1 · Visibilidad poscaptura
**Fecha:** 2026-11-18  
**Estado:** backend aplicado en Supabase; integración visual poscaptura pendiente de prueba completa.  
**Proyecto:** `neoihelwsuitgoeowrbc`.

## Regla de operación
1. La captura nominal requiere sesión institucional activa, autorización documentada y verificación de duplicados.
2. El alta almacena el expediente en `nf_private.pacientes`; genera automáticamente el folio transaccional distrital original `NF-DS{1..6}-00000001` y un alias aleatorio `NF-L33T1-...` en `nf_private.leet_aliases`.
3. Inmediatamente después del guardado la interfaz **debe** ocultar datos nominales, limpiar estados del formulario y cambiar al visor de folios. El frontend actual **requiere verificación** de este paso.
4. El listado `public.nf_listar_folios` devuelve folio, LEET, distrito y seguimiento mínimo. Oculta nombres, CURP, fecha de nacimiento, cuidadores, domicilio, teléfono, localidad, municipio, escuela, edad exacta y fechas exactas de visita; muestra grupo de edad amplio. Solo opera con sesión/perfil activo y alcance distrital.
5. La consulta de identidad para PDF/atención y la rectificación siguen reservadas a administradores institucionales autorizados por RPC; registrar motivo de acceso y prueba de cierre de sesión pertenece a la siguiente fase.
6. El visor público del mapa **nunca** mostrará expedientes individuales ni ubicaciones de hogares. Los agregados se liberan únicamente con evaluación de riesgo de reidentificación.

## Distinción de seguridad
- El folio y alias LEET son **seudónimos**, no anonimización irreversible ni cifrado.
- Almacenamiento clínico actual: columnas nominales dentro de un esquema privado Supabase, con aislamiento a través de RPC y verificaciones de rol/distrito. **No se han cifrado esas columnas a nivel de aplicación ni transcrito a LEET**.
- No se reemplazan los datos nominales por sustitución de letras y números, ya que sería reversible sin clave y haría fallar CURP, duplicados y seguimiento.
- El futuro cifrado autenticado y gestión de claves se transferirán de EDITH después de sus pruebas; LEET puede codificar una representación visual pero no es sustituto de criptografía.
- El mero conocimiento de un folio **no** concede autorización a reidentificar.

## Cambios de backend aplicados
- `nf_leet1_aliases_auditoria_20261118`: tabla privada de alias, generación automática en captura, RPC autorizada `nf_leet_codigo_por_folio`, auditoría.
- `nf_leet1_visor_seudonimo_folios_20261118` + `nf_leet1_visor_corregir_coalesce_20261118`: listado por folio filtrado y verificado, incluyendo `codigo_leet`.

## Evidencia y pendientes
Prueba SQL de `nf_listar_folios` ejecutada con identidad de Supervisor DS06 en una transacción sin cambios persistidos:
- 1 expediente en alcance, 0 claves nominales, 0 cuasiidentificadores finos devueltos, 0 códigos LEET inválidos y 0 expedientes fuera de distrito.
- Pendiente: comprobar permisos efectivos con tokens Supabase Auth de cada rol y sesiones reales (AAL), apertura/cierre de pantalla, limpieza de estado poscaptura y vistas de PDF/edición.
- Mantener piloto técnicamente separado de autorización institucional y jurídica de uso de datos reales de menores.
