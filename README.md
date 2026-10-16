# 🌱 Nutriendo Futuros Saludables · Mapa Sonora v9

Este **repositorio público** alberga únicamente la representación territorial y los catálogos de establecimientos. **NO** alberga pacientes, historiales clínicos ni referencias por folio.

## Rendimiento v9.2
- **1 Canvas compartido** para dibujar las escuelas; se eliminaron cientos de instancias de renderizado redundantes.
- Los marcadores CCT se crean sólo la primera vez que se activa cada distrito y se **reutilizan** al alternar las casillas.
- Las capas regionales se mantienen en memoria y se regeneran sólo cuando cambia el GeoJSON fuente.
- Las unidades CLUES no se redibujan por cambios exclusivos en escuelas/regionalización.
- **Siguiente paso recomendado:** sacar CCT, CLUES y polígonos del HTML y servir archivos geoespaciales públicos optimizados por distrito desde GitHub Pages/CDN. Los expedientes y referencias nominales siguen exclusivamente en Supabase privado, con RLS.

## Mapa público
- [Abrir mapa (GitHub Pages)](https://doctopanda.github.io/nutriendo-futuros/) una vez que GitHub Pages esté habilitado.
- `index.html`: **v9.2 multidistrital optimizado**, permite seleccionar uno, varios o los seis Distritos de Salud, o limpiarlos todos.
- **1,256 preescolares CCT** con coordenadas, procesados del archivo `concentrado_escuelas.xls` proporcionado para el proyecto; aparecen al activar la capa escolar en distritos seleccionados.
- **73 unidades médicas** de CLUES provenientes de la cartografía previa, actualmente disponibles para Hermosillo, Nogales y San Luis Río Colorado.
- Regionalización distrital por colores: basada en adscripción de 72 municipios y geometría municipal cuando esté disponible. Puede importarse GeoJSON oficial desde [Datos Abiertos de Sonora](https://datos.sonora.gob.mx/dataset/).
- Regionalización IMSS-Bienestar: 10 regiones operativas nominales; sus límites geográficos se dibujan **únicamente** al importar GeoJSON oficial validado. No se generan límites ficticios.
- `respaldos/mapa_desnutricion_ultra_v7_2_respaldo.html`: **respaldo íntegro** de la última versión buena original v7.2.
- Los archivos anteriores de apoyo v8 son históricos; `index.html` es el visor v9 vigente.

## Referencias y carátula: aplicación separada
El HTML **NFS_Caratula_Visor_Referencias_v2.html** se entrega fuera del repositorio público. Contiene captura de cédula, visor protegido por folio, referencia, PDF sobre el original de 4 páginas, mapa **interno** entre CLUES, directorio del Grupo Interinstitucional Estatal y formatos de designación, acta y hospitales.

**No se despliega en GitHub Pages, no hay datos nominales en este repositorio y no se deben subir archivos con información de menores**. Los folios de referencia y su historial se consultarán exclusivamente mediante roles autenticados y RLS en Supabase. No existe publicación pública de trazados asistenciales individuales.

## Plataforma privada · RBAC v3 (16-oct-2026)
La aplicación clínica **no se aloja en este repositorio público**. En el proyecto Supabase NFS se implementaron los cuatro roles: `admin_maestro`, `admin_estatal`, `supervisor_distrital`, `promotor_salud`.
- Únicamente `admin_estatal` puede usar los RPC que devuelven identificación y contacto o permiten emitir PDFs nominales.
- `supervisor_distrital` y `promotor_salud` consultan folios de su distrito sin identidad nominal.
- Las solicitudes de contacto de promotores/supervisores son resueltas por el Administrador Estatal; la respuesta operativa no incluye teléfonos o domicilios.
- Los supervisores solicitan altas de promotores por su distrito; las cuentas requieren aprobación y correo verificado en Supabase Auth.
- Tablas privadas sin acceso directo del rol `authenticated`; RPCs con autorización de servidor y auditoría.
- **La interfaz privada v3 se distribuye fuera de GitHub Pages y permanece en vista previa**; faltan primer usuario autorizado, catálogo CLUES verificado y pruebas autenticadas de extremo a extremo.

## Estado operativo
La configuración publicable de Supabase está documentada en el aplicativo privado, con `enableProduction=false`. Existe acceso administrativo y están aplicadas las migraciones de roles y solicitudes. RLS activado en 15 tablas privadas y permisos anónimos denegados. Pendientes creación de usuarios, CLUES autorizadas y pruebas operativas con autenticación. **No utilizar datos reales todavía.**

Revisar Ley General de Protección de Datos Personales en Posesión de Sujetos Obligados (2025), Ley 82 de Sonora (2025), NOM-004-SSA3-2012 y Lineamiento Técnico Operativo DAI (2026), así como las autorizaciones de la unidad jurídica y del responsable de datos personales.

## Fuentes
- [Portal de Datos Abiertos Sonora: geometrías municipales](https://datos.sonora.gob.mx/dataset/)
- [Secretaría de Salud Sonora: diez regiones operativas IMSS-Bienestar](https://salud.sonora.gob.mx/acerca-de/acciones/salud/gobernador-durazo-fortalece-atencion-medica-en-todo-el-estado-con-entrega-de-231-vehiculos-y-ambulancias-de-imss-bienestar)
- Cartografía v7.2 y catálogo de preescolares proporcionados para esta estrategia.

Última actualización del mapa: 16 de octubre de 2026.
