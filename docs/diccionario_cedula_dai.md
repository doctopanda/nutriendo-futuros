# Diccionario funcional · Cédula DAI → Nutriendo Futuros

**Fuente:** Cédula de seguimiento de la desnutrición aguda infantil en niñas y niños de 0 a 5 años entregada al proyecto.

## Datos maestros del paciente (nf_private.pacientes)

| En cédula | En captura | Almacenamiento |
|---|---|---|
| Autorización para la encuesta | autorizacion | Validación de alta (sí obligatoria) |
| Nombre de niña o niño | nombre | Identidad protegida |
| Sexo | sexo | Identidad protegida |
| Fecha de nacimiento | fecha_nacimiento | Identidad protegida |
| Madre/padre/cuidador | cuidador | Identidad protegida |
| Dirección / contacto | direccion / telefono | Identidad protegida |
| CLUE | clues | Catálogo CLUES verificado |
| Primera evaluación | primera_evaluacion | Fecha de ingreso |
| Veces come al día | comidas_dia | Contexto |
| Afiliación / cuál | afiliacion / institucion_afiliacion | Contexto |
| Recibe atención nutricional / cuál | atencion_nutricional / tipo_atencion | Contexto |

Campos operativos adicionales: folio, distrito_id, municipio, localidad, CURP opcional para conciliación, creado_por, estatus. Requieren aprobación institucional. La CURP no figura entre los campos obligatorios de la cédula entregada.

## Cédula longitudinal (nf_private.seguimientos)

Una valoración por fila y hasta 12 filas por cédula física. Un mismo expediente puede tener varias cargas con nuevas valoraciones.

| Grupo | Variables |
|---|---|
| Control | numero_consulta del servidor, fecha_valoracion, edad_anos, edad_meses |
| Alimentación | lactancia, tomas_dia, biberon, otros_alimentos |
| Agua | agua: hervida / filtrada o clorada / sin tratamiento |
| Síntomas última semana | gripe_tos, fiebre, diarrea, vomito, anorexia |
| Discapacidad | discapacidad, tipo_discapacidad |
| Clínica | prueba_apetito, edema, grado_edema |
| Somatometría | talla_cm, peso_kg, pbm_cm, hgb |
| Indicadores documentados | pz_plt, pz_lte, pz_pe |
| Clasificación clínica | clasificacion_pz, clasificacion_pbm |
| Intervención | desparasitacion, dosis_desparasitacion, micronutrientes, dosis_micronutrientes, intervencion, sobres |
| Evolución | aceptabilidad, resultado, abandono |

Los valores faltantes NO significan resultados negativos. La carátula no calcula puntajes Z automáticamente hasta incorporar referencias OMS verificadas.

## Importación restringida de INFO NOGALES.xlsx

El ejemplo nominal incluye las columnas CLUES, NOMBRE UNIDAD, LOCALIDAD, NOMBRE NIÑO, FECHA NACIMIENTO, GENERO, PESO KG, TALLA CM, DIRECCION, TELEFONO DE CONTACTO.

- NOMBRE UNIDAD es el nombre de la unidad, no del paciente.
- Los nombres de niños, fechas de nacimiento, domicilios y contactos son estrictamente confidenciales.
- PESO KG y TALLA CM pertenecen a una valoración clínica fechada, nunca deben reemplazar sin auditoría otra valoración.
- El formato de Nogales no incluye todos los campos de la cédula y necesita importación parcial con faltantes explícitos.
- Dos valores de peso contienen texto/unidad. No interpretar una cifra expresada en gramos como kilogramos; verificar con fuente clínica.
- Conciliar coincidencias antes de asignar folio y documentar validación humana de posibles homónimos.

NO subir INFO NOGALES.xlsx, su contenido o exportaciones de pacientes a GitHub.

## Uso territorial
Los índices de riesgo del mapa v7.2 y la proximidad a CLUES son capas territoriales, no prevalencia de DAI ni adscripción médica verificada. Publicar casos solo como agregados autorizados, evitando celdas pequeñas y riesgos de inferencia.

## Pendiente
- Catálogo de CLUES y su distrito oficial.
- Flujo de conciliación inter-distrital y posibles coincidencias aproximadas.
- Consentimiento, retención, auditoría, referencia y contrarreferencia.
- Referencias antropométricas OMS y validación clínica.
- Revisión legal y de seguridad previa al piloto nominal.
