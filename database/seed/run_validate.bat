@echo off
setlocal EnableExtensions

REM ============================================================================
REM run_validate.bat - Validate seeded HDB Oracle database integrity and joins
REM Reads connection settings from repository .env (never prints credentials).
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
  "$ez = $cfg['FLYWAY_URL'] -replace '^jdbc:oracle:thin:@','';" ^
  "$sb = New-Object System.Text.StringBuilder;" ^
  "[void]$sb.AppendLine('WHENEVER SQLERROR EXIT SQL.SQLCODE');" ^
  "[void]$sb.AppendLine(('CONNECT ' + $cfg['FLYWAY_USER'] + '/\"' + $cfg['FLYWAY_PASSWORD'] + '\"@' + $ez + ' AS SYSDBA'));" ^
  "[void]$sb.AppendLine((Get-Content (Join-Path $seedDir 'validate_seed_data.sql') -Raw));" ^
  "$payload = $sb.ToString();" ^
  "$localSqlplus = Get-Command sqlplus -ErrorAction SilentlyContinue;" ^
  "if ($localSqlplus) {" ^
  "  $payload | & $localSqlplus.Source -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "} else {" ^
  "  $container = $env:ORACLE_DOCKER_CONTAINER;" ^
  "  if (-not $container) { $container = (docker ps --filter 'publish=1521' --format '{{.Names}}' | Select-Object -First 1) };" ^
  "  if (-not $container) { throw 'Neither local sqlplus nor a running Oracle Docker container on port 1521 was found.' };" ^
  "  $payload | docker exec -i $container sqlplus -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "}"

exit /b %ERRORLEVEL%
