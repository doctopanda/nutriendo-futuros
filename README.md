# 🌱 Nutriendo Futuros Saludables · Mapa Sonora v9

Este **repositorio público** alberga únicamente la representación territorial y los catálogos de establecimientos. **NO** alberga pacientes, historiales clínicos ni referencias por folio.

## Mapa público
- [Abrir mapa (GitHub Pages)](https://doctopanda.github.io/nutriendo-futuros/) una vez que GitHub Pages esté habilitado.
- `index.html`: **v9 multidistrital**, permite seleccionar uno, varios o los seis Distritos de Salud, o limpiarlos todos.
- **1,256 preescolares CCT** con coordenadas, procesados del archivo `concentrado_escuelas.xls` proporcionado para el proyecto; aparecen al activar la capa escolar en distritos seleccionados.
- **73 unidades médicas** de CLUES provenientes de la cartografía previa, actualmente disponibles para Hermosillo, Nogales y San Luis Río Colorado.
- Regionalización distrital por colores: basada en adscripción de 72 municipios y geometría municipal cuando esté disponible. Puede importarse GeoJSON oficial desde [Datos Abiertos de Sonora](https://datos.sonora.gob.mx/dataset/).
- Regionalización IMSS-Bienestar: 10 regiones operativas nominales; sus límites geográficos se dibujan **únicamente** al importar GeoJSON oficial validado. No se generan límites ficticios.
- `respaldos/mapa_desnutricion_ultra_v7_2_respaldo.html`: **respaldo íntegro** de la última versión buena original v7.2.
- Los archivos anteriores de apoyo v8 son históricos; `index.html` es el visor v9 vigente.

## Referencias y carátula: aplicación separada
El HTML **NFS_Caratula_Visor_Referencias_v2.html** se entrega fuera del repositorio público. Contiene captura de cédula, visor protegido por folio, referencia, PDF sobre el original de 4 páginas, mapa **interno** entre CLUES, directorio del Grupo Interinstitucional Estatal y formatos de designación, acta y hospitales.

**No se despliega en GitHub Pages, no hay datos nominales en este repositorio y no se deben subir archivos con información de menores**. Los folios de referencia y su historial se consultarán exclusivamente mediante roles autenticados y RLS en Supabase. No existe publicación pública de trazados asistenciales individuales.

## Estado operativo
La configuración publicable de Supabase está documentada en el aplicativo privado, con `enableProduction=false`. No se ha confirmado acceso administrativo al proyecto `neoihelwsuitgoeowrbc` para instalar/verificar migraciones, RLS, catálogos CLUES o permisos clínicos. **No utilizar datos reales todavía.**

Revisar Ley General de Protección de Datos Personales en Posesión de Sujetos Obligados (2025), Ley 82 de Sonora (2025), NOM-004-SSA3-2012 y Lineamiento Técnico Operativo DAI (2026), así como las autorizaciones de la unidad jurídica y del responsable de datos personales.

## Fuentes
- [Portal de Datos Abiertos Sonora: geometrías municipales](https://datos.sonora.gob.mx/dataset/)
- [Secretaría de Salud Sonora: diez regiones operativas IMSS-Bienestar](https://salud.sonora.gob.mx/acerca-de/acciones/salud/gobernador-durazo-fortalece-atencion-medica-en-todo-el-estado-con-entrega-de-231-vehiculos-y-ambulancias-de-imss-bienestar)
- Cartografía v7.2 y catálogo de preescolares proporcionados para esta estrategia.

Última actualización del mapa: 16 de octubre de 2026.
