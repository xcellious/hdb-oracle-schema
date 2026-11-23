@echo off
setlocal EnableExtensions

REM ============================================================================
REM run_validate.bat - Validate seeded HDB Oracle database integrity and joins
REM Reads connection settings and target schema (FLYWAY_PLACEHOLDERS_HDB_USER)
REM from repository .env (never prints credentials).
REM ============================================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "REPO_ROOT=%%~fI"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$repoRoot = '%REPO_ROOT%';" ^
  "$seedDir = Join-Path $repoRoot 'database\seed';" ^
  "$envFile = Join-Path $repoRoot '.env';" ^
  "if (-not (Test-Path $envFile)) { throw '.env file not found at repo root.' }" ^
  "$cfg = @{};" ^
  "Get-Content $envFile | ForEach-Object { $l = $_.Trim(); if ($l -and -not $l.StartsWith('#') -and $l.Contains('=')) { $k,$v = $l.Split('=',2); $cfg[$k.Trim()] = $v.Trim() } };" ^
  "$hdbUser = if ($cfg['FLYWAY_PLACEHOLDERS_HDB_USER']) { $cfg['FLYWAY_PLACEHOLDERS_HDB_USER'].ToUpper() } else { 'HDBDBA' };" ^
  "if ($hdbUser -notmatch '^[A-Z][A-Z0-9_$#]{0,127}$') { throw ('Invalid FLYWAY_PLACEHOLDERS_HDB_USER value in .env: ' + $hdbUser) }" ^
  "$ez = $cfg['FLYWAY_URL'] -replace '^jdbc:oracle:thin:@','';" ^
  "$sb = New-Object System.Text.StringBuilder;" ^
  "[void]$sb.AppendLine('WHENEVER SQLERROR EXIT SQL.SQLCODE');" ^
  "[void]$sb.AppendLine(('CONNECT ' + $cfg['FLYWAY_USER'] + '/\"' + $cfg['FLYWAY_PASSWORD'] + '\"@' + $ez + ' AS SYSDBA'));" ^
  "[void]$sb.AppendLine((Get-Content (Join-Path $seedDir 'validate_seed_data.sql') -Raw).Replace('${hdb_user}', $hdbUser));" ^
  "$payload = $sb.ToString();" ^
  "$sqlplusCmd = Get-Command sqlplus -ErrorAction SilentlyContinue;" ^
  "if ($sqlplusCmd) {" ^
  "  $payload | & $sqlplusCmd.Source -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "} else {" ^
  "  $container = $env:ORACLE_DOCKER_CONTAINER;" ^
  "  if (-not $container) { $container = (docker ps --filter 'publish=1521' --format '{{.Names}}' | Select-Object -First 1) };" ^
  "  if (-not $container) { throw 'Neither sqlplus nor a running Oracle Docker container on port 1521 was found. Install sqlplus or set ORACLE_DOCKER_CONTAINER.' };" ^
  "  $payload | docker exec -i $container sqlplus -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "}"

exit /b %ERRORLEVEL%
