## Arquitectura actual · 16 octubre 2026
- **GitHub Pages se reserva para cartografía y establecimientos públicos.** La app privada de captura y visor se entrega como HTML independiente, no se aloja en este repositorio público.
- `index.html`: mapa v8, conserva polígonos v7.2, exige Distrito de Salud para activar CLUES y escuelas CCT.
- `respaldos/mapa_desnutricion_ultra_v7_2_respaldo.html`: copia completa original (restauración).
- `nfs_capas_distritales_v8.js` y `nfs_capas_distritales_v8.css`: controles cartográficos y filtrado.
- **CLUES:** 73 establecimientos ya embebidos en el mapa en Hermosillo (DS01), Nogales (DS03) y San Luis Río Colorado (DS06). No equivalen a adscripción.
- **Escuelas:** identificadores CCT, no CLUES. Para visualizar la capa debe importarse CSV oficial SEP con campos CCT,NOMBRE,MUNICIPIO,LATITUD,LONGITUD; no se han precargado escuelas no verificadas.
- **Datos de pacientes:** nunca incluir nominales, domicilios ni coordenadas de hogares. La aplicación privada permanece bloqueada hasta aprobar Supabase Auth, RLS, auditoría, catálogo de distritos/CLUES y los flujos de consentimiento.
- **Marco de referencia:** Ley General de Protección de Datos Personales en Posesión de Sujetos Obligados (DOF 20-mar-2025), Ley 82 de Protección de Datos Personales en Posesión de Sujetos Obligados del Estado de Sonora (BO 29-ago-2025), NOM-004-SSA3-2012 y lineamiento DAI 2026. Requiere validación jurídica e institucional.


---

# 🌱 Nutriendo Futuros Saludables | Sonora

## Estado del despliegue
- **Mapa geográfico:** \`index.html\`, derivado del respaldo **RIESGO DESNUTRICIÓN ULTRA v7.2** (Hermosillo, Nogales y San Luis Río Colorado). Incluye polígonos, categorías de riesgo exploratorias y correspondencia geográfica con unidades CLUES.
- **Carátula digital:** \`captura.html\`, contiene variables de la cédula oficial y hasta 12 consultas, pero **no habilitar captura real** hasta completar Supabase y auditoría.
- **Datos nominales:** **NO** están almacenados en este repositorio. \`INFO NOGALES.xlsx\` es material privado de trabajo, no se sube ni se incrusta en JavaScript.
- **Supabase:** los archivos \`supabase/schema_v0_1.sql\`, \`supabase/migracion_v0_2_edicion.sql\` y \`supabase/migracion_v0_3_catalogo_clues.sql\` contienen una propuesta estructural pendiente de pruebas y revisión de seguridad. La migración v0.3 bloqueará altas sin CLUES verificadas.
- **Acceso público:** GitHub Pages, una vez activado en **Settings → Pages → Deploy from a branch → main → /(root)**.

## URLs previstas
- Mapa: https://doctopanda.github.io/nutriendo-futuros/
- Captura: (aplicación privada no alojada en GitHub Pages)

## Conexión a Supabase (NO activar aún con información real)
1. Crear un **nuevo proyecto Supabase** para esta estrategia.
2. Revisar políticas RLS y permisos **antes** de introducir registros.
3. Ejecutar/ajustar el SQL, crear usuarios por Supabase Auth y asignar distritos/roles en \`nf_private.perfiles\`.
4. Integrar un catálogo validado **CLUES → municipio → distrito** y bloquear discrepancias en el servidor (pendiente).
5. Configurar \`config.js\` con solo **Project URL** y **publishable/anon key**. Ambas pueden estar en un cliente web cuando RLS sea seguro; **nunca** usar \`service_role\`, secretos, contraseñas, tokens administrativos ni claves privadas.
6. Probar con identidades **ficticias**: nuevo caso, mismo caso, concurrencia, folios, cambio de distrito, seguimiento, sesión inválida y rechazo de acceso entre distritos.
7. Aprobar formalmente anonimización territorial, seguridad, respaldos y tratamiento de información de menores antes del pilotaje real.

Ver **docs/diccionario_cedula_dai.md** para variables de la cédula y la conciliación de Nogales.

## Modelo lógico
\`\`\`
GitHub Pages (interfaz pública)
 ├─ index.html                → Mapa territorial v7.2 SIN DATOS NOMINALES
 ├─ captura.html              → Acceso autenticado; campos nominales solo durante captura
 └─ config.js                 → URL y clave pública (VACÍAS al inicio)
                         ↓ HTTPS/TLS + Supabase Auth
Supabase
 ├─ nf_private.perfiles       → rol, distrito, autorización
 ├─ nf_private.pacientes     → identidad restringida + folio
 ├─ nf_private.seguimientos  → 1:N, cédulas longitudinales
 ├─ nf_private.folios_distritales → secuencias transaccionales por distrito
 ├─ nf_private.auditoria     → eventos sin información identificable
 └─ public.nf_agregados_autorizados → publicación manual validada, sin celdas pequeñas
\`\`\`

## Formato y duplicados
Folio \`NF-DSn-00000001\`, con \`n\` entre 1 y 6. Cada distrito tiene un contador atómico en la base. Se busca CURP si está disponible y/o coincidencia exacta del nombre normalizado, fecha de nacimiento y sexo. Si se detecta un registro del distrito, se muestra **solo el folio**, sin presentar nombre ni otros identificadores. Un caso de otro distrito requiere revisión institucional (no se revela su folio). Los falsos positivos, faltantes y traslados entre distritos necesitan reglas operativas adicionales.

## Fundamento clínico-operativo
Fuentes entregadas:
- *Lineamiento Técnico Operativo para el abordaje de la Desnutrición Aguda Infantil en México* (2026).
- *Estrategia para el Manejo de la DAI, Nutriendo Futuros Saludables*: guía de actividades.
- *Manual de Funciones Operativas: Estrategia Nutriendo Futuros Saludables*.
- *Cédula de seguimiento de la DAI en niñas y niños de 0 a 5 años*.

La plataforma refleja los campos de esos formatos. **No calcula ni valida puntajes Z automáticamente**, ya que hacerlo correctamente exige tablas OMS, reglas de edad/sexo y validación clínica. Tampoco se debe interpretar el índice cartográfico exploratorio de v7.2 como prevalencia confirmada.

## Principios de seguridad
- No incorporar fuentes originales nominales, carpetas de descargas, archivos Excel personales o exportaciones individualizadas en commits, GitHub Pages ni GitHub Actions.
- No permitir consultas API directas sobre \`nf_private\` desde el navegador.
- No mostrar nombres en tablas, búsquedas, reportes o respuestas de registro; la pantalla de captura por necesidad sí solicita identidad al personal autorizado.
- Suprimir/perturbar resultados agregados con riesgo de reidentificación y evitar publicar coordenadas de viviendas o rutas individualizadas.
- Aprobar reglas de conservación, corrección, consentimiento, responsables del tratamiento, control de accesos, bitácora y respuesta a incidentes antes de operar.
- Mantener respaldo de la versión v7.2 antes de alterar cartografía o lógica.

**Etapa actual (16-oct-2026):** código publicado en el repositorio y URL/clave publicable configuradas; `enableCapture: false`. El conector Supabase accesible desde ChatGPT solo muestra el proyecto PULSO, no `neoihelwsuitgoeowrbc`: no se han aplicado migraciones ni confirmado el RLS de este proyecto. No es un sistema clínico validado ni un repositorio de pacientes operativo.
