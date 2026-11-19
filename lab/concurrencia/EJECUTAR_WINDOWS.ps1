$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Instala un motor Docker compatible con Compose.' }
if (-not (Get-Command py -ErrorAction SilentlyContinue)) { throw 'Instala Python 3 con lanzador py.' }
try {
  docker compose up -d --wait
  if ($LASTEXITCODE -ne 0) { throw 'Docker no inició correctamente' }
  Get-Content -Raw 'sql/00_lab.sql' | docker compose exec -T db psql -X -U nf_test -d nf_lab -v ON_ERROR_STOP=1
  if ($LASTEXITCODE -ne 0) { throw 'Error inicializando SQL' }
  py -3 lab.py
  if ($LASTEXITCODE -ne 0) { throw 'Alguna prueba falló' }
} finally {
  docker compose down
}
