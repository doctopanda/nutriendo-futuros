# NF-SEC-012 · Laboratorio local gratuito

Requisitos: motor Docker/Compose compatible y Python 3. Consulta las condiciones de licencia de Docker Desktop según tu organización. La base PostgreSQL 16 vive en tmpfs, sin puertos públicos ni información real. **No es copia de todo Supabase ni certifica RLS.**

En Windows: ejecutar `powershell -ExecutionPolicy Bypass -File .\EJECUTAR_WINDOWS.ps1` desde esta carpeta. Reporte: `results/nf_concurrency_results.json`.

Escenarios: misma identidad/ mismo distrito, misma identidad/distritos distintos, identidades distintas/mismo distrito. Dos conexiones reales PostgreSQL en paralelo. La función de ensayo modela solo el tramo crítico (advisory lock + contador atómico + inserción). No hay llamadas a producción ni cargos cloud.

El ZIP descargable fue generado dentro de la conversación; los archivos de esta carpeta representan el código fuente del mismo laboratorio.