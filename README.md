# 🌱 Nutriendo Futuros Saludables · Mapa Sonora v9

Este **repositorio público** alberga el mapa territorial, catálogos no nominales y desde el 3 de noviembre de 2026 la **interfaz institucional v5.5** (HTML/JS). La publicación del código de cliente **NO publica ni contiene** bases de pacientes, historiales, contraseñas ni referencias nominales: esos registros permanecen en Supabase con control de acceso de servidor. El código del navegador, incluido el valor público `sb_publishable_…`, es accesible para cualquiera; la seguridad debe descansar en Auth, permisos SQL y RPCs, nunca en ocultar el HTML.

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

## Visor institucional publicado · v5.5 (3-nov-2026)
- **[Abrir visor + mapa](https://doctopanda.github.io/nutriendo-futuros/visor/)**. Código fuente: [`visor/index.html`](visor/index.html).
- La interfaz ofrece acceso institucional, panorama, captura, visor de folios, seguimiento, referencias y generación de formatos PDF, directorios y seguridad. La pestaña **Visor y mapa** incrusta el mapa público de `index.html`.
- **No hay bases nominales, contraseñas ni secretos de servicio en este repositorio.** Los datos clínicos se solicitan mediante funciones RPC de Supabase bajo un usuario autenticado y permisos verificables.
- El **mapa público v9.2** permanece independiente y estático. En esta entrega, la capa cartográfica todavía no consume ni actualiza automáticamente indicadores desde Supabase. Las agregaciones `nf_agregados_autorizados` se publicarán únicamente después de revisión de privacidad y umbral mínimo por celda.
- **Estado: piloto técnico. NO capturar datos reales de menores** hasta completar pruebas de acceso de extremo a extremo por los cuatro roles, revisión de funciones SECURITY DEFINER, autorización institucional/jurídica, revisión de protección de datos y validación de catálogos CLUES. La interfaz no sustituye estas verificaciones.

## Backend privado · RBAC y auditoría
El código del navegador se publica, pero la información clínica se almacena exclusivamente en el proyecto Supabase NUTRIENDOFUTUROS. En el proyecto Supabase NFS se implementaron los cuatro roles: `admin_maestro`, `admin_estatal`, `supervisor_distrital`, `promotor_salud`.
- Las funciones que devuelven identificación y contacto están restringidas por validaciones de rol y jurisdicción en Supabase; se deben probar específicamente los perfiles `admin_maestro` y `admin_estatal` antes del uso real.
- `supervisor_distrital` y `promotor_salud` consultan folios de su distrito sin identidad nominal.
- Las solicitudes de contacto de promotores/supervisores son resueltas por el Administrador Estatal; la respuesta operativa no incluye teléfonos o domicilios.
- Los supervisores solicitan altas de promotores por su distrito; las cuentas requieren aprobación y correo verificado en Supabase Auth.
- Tablas privadas sin acceso directo del rol `authenticated`; RPCs con autorización de servidor y auditoría.
- La interfaz v5.5 se aloja en GitHub Pages, pero el acceso a datos depende de Supabase Auth y de cada RPC. Falta terminar las pruebas autenticadas de extremo a extremo.

## Estado operativo y verificación (3-nov-2026)
- GitHub Pages desplegó con éxito el commit `26f87b3`, que añadió el visor integrado. La conexión autenticada desde navegador todavía requiere prueba manual.
- Supabase proyecto `neoihelwsuitgoeowrbc`, activo; **2 perfiles**, **0 expedientes de pacientes**, **0 agregados públicos** al corte de la verificación.
- Las tablas de datos clínicos están en `nf_private`; el acceso de navegador se canaliza por RPC autorizados y auditables.
- El Security Advisor advierte de funciones `SECURITY DEFINER` ejecutables por usuarios autenticados y protección contra contraseñas filtradas deshabilitada. Las primeras deben auditarse individualmente, y la protección de contraseñas debe activarse antes de producción.
- Las actualizaciones de interfaz y mapa se publican con commits en GitHub. Las actualizaciones de datos, perfiles y permisos **no** se realizan mediante GitHub: se gestionan en Supabase.

Revisar legislación aplicable de datos personales y expediente clínico, las autorizaciones de la unidad jurídica y del responsable de datos personales antes del tratamiento de datos reales.

## Fuentes
- [Portal de Datos Abiertos Sonora: geometrías municipales](https://datos.sonora.gob.mx/dataset/)
- [Secretaría de Salud Sonora: diez regiones operativas IMSS-Bienestar](https://salud.sonora.gob.mx/acerca-de/acciones/salud/gobernador-durazo-fortalece-atencion-medica-en-todo-el-estado-con-entrega-de-231-vehiculos-y-ambulancias-de-imss-bienestar)
- Cartografía v7.2 y catálogo de preescolares proporcionados para esta estrategia.

Última actualización del mapa: 16 de octubre de 2026. Visor institucional incorporado: 3 de noviembre de 2026.
