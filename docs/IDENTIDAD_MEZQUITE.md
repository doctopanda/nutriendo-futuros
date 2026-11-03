# Identidad visual oficial · Mezquite 🌳

**Proyecto:** Nutriendo Futuros Saludables, Sonora  
**Adopción:** 3 de noviembre de 2026  
**Concepto rector:** Cobijo, alimento y comunidad desde las raíces.

## Frase oficial del proyecto

> **Un expediente, un folio, un futuro.**

Lema para la plataforma Nutriendo Futuros. Conservar esta redacción exacta como referencia para futuras piezas de comunicación e interfaz. No reemplaza automáticamente los textos ya publicados.


El **mezquite sonorense** es el emblema de la plataforma, el visor institucional, el mapa, los marcadores institucionales y las futuras superficies móviles. La imagen es una **interpretación gráfica** del mezquite y no pretende sustituir una lámina taxonómica.

## Colores maestros (inspiración Venusaur)
| Rol | Color |
|---|---|
| Verde azulado principal | `#409993` |
| Aqua de apoyo | `#7BB7B7` |
| Verde follaje | `#5E9569` |
| Rosa flor / acento | `#EC889B` |
| Tierra / madera | `#817060` |
| Crema de contraste | `#F6F0E4` |
| Verde petróleo institucional | `#075A59` |
| Contorno oscuro | `#083F42` |

## Activos fuente dentro del repositorio
- `assets/mezquite-emblema.svg`: árbol con copa y raíces, para portadas, encabezados y escenas.
- `assets/mezquite-icono.svg`: miniatura de instalación web / iconografía adaptable a móvil.
- `assets/mezquite-sello.svg`: sello circular del visor institucional.
- `assets/mezquite-marcador.svg`: marcador visual del programa. **No se asigna automáticamente a casos o establecimientos**: su uso georreferenciado requiere una capa de puntos reales autorizados.
- `assets/mezquite-theme.css`: estilo compartido aplicado al mapa y al visor.

La línea `<body class="nf-mezquite nf-visor">` del visor y `<body class="nf-mezquite nf-map">` del mapa activa los estilos sin reemplazar la lógica original.

## Reglas de despliegue
1. **Reutilizar los archivos compartidos** para evitar dos versiones distintas del logo. Las rutas son relativas a GitHub Pages.
2. Mantener contraste, controles y estados de foco visibles. Los colores de distritos y categorías conservan su codificación semántica; no forzar todo al verde.
3. En móvil, usar el icono sin texto. En escritorio, usar el emblema y el nombre. En reportes y capturas, preferir el sello.
4. No mostrar nombres, números de expediente, direcciones ni datos personales en recursos estáticos.
5. No confundir **marca visual publicada** con **validación de accesos**: Supabase RLS/RPC debe verificarse por rol antes de capturar registros reales.

## Cobertura inicial
- Mapa GitHub Pages (`index.html`): cabecera Mezquite, paleta de paneles, controles, favicon, muestra de marcador y contenedor de selección distrital.
- Visor (`visor/index.html`): acceso institucional con árbol emblema, navegador lateral, sello del visor, hero, controles y estilos móviles.
- Funciones geográficas, catálogos, captura, autorización y RPC existentes: no alterados por esta fase estética.

## Futuro
Para las funciones nuevas, integrar el diseño en componentes y evitar estilos duplicados. Si se necesita una **ubicación Nutriendo Futuros** en el mapa, usar `mezquite-marcador.svg` solo para coordenadas verificadas de una capa de programa diferenciada de CLUES/CCT y de indicadores agregados protegidos.

**Estado:** Identidad aplicada en código. La comprobación visual final en navegadores y pruebas funcionales con cuentas por rol quedan pendientes.


## Corrección de fidelidad del 3 de noviembre de 2026

La primera versión de los archivos `mezquite-*.svg` del sitio era una reinterpretación vectorial del árbol y difería del arte aprobado (opción B, Mezquite).

Los seis recursos actuales proceden **directamente de la lámina original aprobada**, mediante extracción de cada elemento, tratamiento de transparencia y optimización WebP. Se empaquetan como SVG con imagen WebP incrustada para conservar el nombre y las referencias utilizadas por el mapa y el visor. **No son trazados vectoriales editables**: conservan los píxeles ilustrativos de la propuesta, encapsulados en SVG. Los PNG separados se entregan en el kit descargable.

- `assets/mezquite-emblema.svg`: árbol original, copa, flores, raíces y vegetación sonorense
- `assets/mezquite-sello.svg`: sello circular aprobado
- `assets/mezquite-icono.svg` y `assets/mezquite-icono-claro.svg`: dos miniaturas
- `assets/mezquite-marcador.svg` y `assets/mezquite-marcador-rosa.svg`: dos marcadores

Estas actualizaciones sustituyen **solamente** recursos visuales compartidos. No se alteran el HTML, las funciones JavaScript, la lógica Leaflet, RLS, autenticación, conexión Supabase ni archivos de datos. Los pines de la identidad son ejemplos institucionales, no coordenadas asociadas a casos.

Vista previa pública: `identidad.html`.
