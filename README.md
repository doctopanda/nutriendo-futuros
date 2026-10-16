# 🌱 Nutriendo Futuros Saludables · Mapa Sonora

Mapa territorial público para la estrategia de Desnutrición Aguda Infantil. **Este repositorio NO es una base nominal ni un sitio de captura de pacientes.**

## Visor
- `index.html`: visor cartográfico basado en RIESGO DESNUTRICIÓN ULTRA v7.2.
- `nfs_capas_distritales_v8.js` y `.css`: selección obligatoria de Distrito de Salud para activar establecimientos.
- `respaldos/mapa_desnutricion_ultra_v7_2_respaldo.html`: copia íntegra del mapa previo.
- `supabase/`: borradores SQL para el sistema interno. **No aplicados ni verificados en el proyecto Supabase de destino.**

GitHub Pages (una vez habilitado): https://doctopanda.github.io/nutriendo-futuros/

## Distritos y alcance inicial
Se ofrecen los seis distritos oficiales de Sonora: 01 Hermosillo, 02 Caborca, 03 Santa Ana, 04 Cajeme, 05 Navojoa, 06 San Luis Río Colorado.
El respaldo cartográfico sólo incluye polígonos recuperados en **Hermosillo (DS01), Nogales (DS03) y San Luis Río Colorado (DS06)**. Los demás distritos no deben representarse como cubiertos hasta integrar cartografía validada.

## Capas y catálogos
- **CLUES (salud):** 73 establecimientos de primer y segundo nivel, provenientes del catálogo maestro `ESTABLECIMIENTO_SALUD_202608` ya integrado en v7.2. La asignación por proximidad es territorial, **no adscripción**.
- **CCT (escuelas):** casilla separada con importador CSV local. No se inventan claves ni ubicaciones; para dibujar escuelas hay que cargar un CSV oficial SEP con columnas `CCT,NOMBRE,MUNICIPIO,LATITUD,LONGITUD`. El archivo se procesa únicamente en el navegador.
- **Condición de visibilidad:** ambas casillas están deshabilitadas hasta seleccionar un distrito. Sólo se dibujan establecimientos de los municipios disponibles correspondientes al distrito elegido.
- **Fuente CCT:** https://www.datos.gob.mx/dataset/catalogo_centros_trabajo_sep
- **Distritos oficiales:** https://salud.sonora.gob.mx/index.php?id=61&option=com_sppagebuilder&view=page

## Plataforma privada NFS
La **Carátula y Visor NFS** es un HTML independiente entregado fuera de GitHub Pages. Su estructura prevé Supabase Auth, RLS, funciones RPC, folio `NF-DSn-00000001`, detección de duplicados y auditoría. Permanecerá bloqueado hasta instalar, auditar y aprobar migraciones, perfiles y catálogo CLUES por distrito.

**PROHIBIDO** incorporar expedientes, CURP, nombres de pacientes, domicilios, teléfonos, fotos de menores, coordenadas de hogares, secretos `service_role` o archivos nominales a commits/Issues/Actions de GitHub.

## Revisión normativa indispensable antes del piloto
- Ley General de Protección de Datos Personales en Posesión de Sujetos Obligados (DOF 20-03-2025).
- **Ley 82** de Protección de Datos Personales en Posesión de Sujetos Obligados del Estado de Sonora (Boletín Oficial 29-08-2025).
- NOM-004-SSA3-2012 del expediente clínico.
- Lineamiento Técnico Operativo para el abordaje de la DAI (2026).
- Verificación jurídica de aviso de privacidad, fundamento del tratamiento, consentimiento cuando proceda, finalidad, plazo de conservación, contratos con encargados, transferencias, accesos y ejercicio ARCO.

**Estado:** cartografía e interfaz preparadas. La conexión, la autorización de usuarios y el cumplimiento técnico-jurídico del tratamiento de datos deben probarse antes de capturas reales.
