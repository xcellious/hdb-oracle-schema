@echo off
setlocal EnableExtensions

REM ============================================================================
REM run_seed.bat - Populate the target HDB Oracle database with sample seed data
REM Reads connection settings and target schema (FLYWAY_PLACEHOLDERS_HDB_USER)
REM from repository .env (never prints credentials).
REM
REM Usage:
REM   database\seed\run_seed.bat                (load seed data)
REM   database\seed\run_seed.bat --validate     (load seed data + run validation)
REM ============================================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "REPO_ROOT=%%~fI"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$repoRoot = '%REPO_ROOT%';" ^
  "$seedDir = Join-Path $repoRoot 'database\seed';" ^
  "$envFile = Join-Path $repoRoot '.env';" ^
  "if (-not (Test-Path $envFile)) { throw '.env file not found at repo root. Copy .env.example to .env first.' }" ^
  "$cfg = @{};" ^
  "Get-Content $envFile | ForEach-Object { $l = $_.Trim(); if ($l -and -not $l.StartsWith('#') -and $l.Contains('=')) { $k,$v = $l.Split('=',2); $cfg[$k.Trim()] = $v.Trim() } };" ^
  "$url = $cfg['FLYWAY_URL']; $user = $cfg['FLYWAY_USER']; $pass = $cfg['FLYWAY_PASSWORD'];" ^
  "if (-not $url -or -not $user -or -not $pass) { throw 'FLYWAY_URL, FLYWAY_USER, and FLYWAY_PASSWORD must be set in .env' }" ^
  "$hdbUser = if ($cfg['FLYWAY_PLACEHOLDERS_HDB_USER']) { $cfg['FLYWAY_PLACEHOLDERS_HDB_USER'].ToUpper() } else { 'HDBDBA' };" ^
  "if ($hdbUser -notmatch '^[A-Z][A-Z0-9_$#]{0,127}$') { throw ('Invalid FLYWAY_PLACEHOLDERS_HDB_USER value in .env: ' + $hdbUser) }" ^
  "$ez = $url -replace '^jdbc:oracle:thin:@','';" ^
  "$files = @('00_preflight_and_prereqs.sql','01_core_lookup_reference.sql','02_sites_and_authorization.sql','03_external_data_mappings.sql','04_models_ensembles_and_cp.sql','05_timeseries_real_and_model.sql','06_alarms_and_monitoring.sql','07_decodes_telemetry.sql');" ^
  "$validate = ('%1' -eq '--validate' -or '%1' -eq '-v');" ^
  "if ($validate) { $files += 'validate_seed_data.sql' };" ^
  "$sb = New-Object System.Text.StringBuilder;" ^
  "[void]$sb.AppendLine('WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK');" ^
  "[void]$sb.AppendLine('WHENEVER OSERROR EXIT FAILURE ROLLBACK');" ^
  "[void]$sb.AppendLine(('CONNECT ' + $user + '/\"' + $pass + '\"@' + $ez + ' AS SYSDBA'));" ^
  "[void]$sb.AppendLine('SET DEFINE OFF FEEDBACK OFF VERIFY OFF ECHO OFF SERVEROUTPUT ON SIZE UNLIMITED LINESIZE 220 PAGESIZE 500');" ^
  "foreach ($f in $files) { $sql = (Get-Content (Join-Path $seedDir $f) -Raw).Replace('${hdb_user}', $hdbUser); [void]$sb.AppendLine($sql); };" ^
  "[void]$sb.AppendLine('EXIT 0');" ^
  "$payload = $sb.ToString();" ^
  "$sqlplusCmd = Get-Command sqlplus -ErrorAction SilentlyContinue;" ^
  "if ($sqlplusCmd) {" ^
  "  Write-Host ('Executing seed scripts (target schema: ' + $hdbUser + ') via sqlplus...');" ^
  "  $payload | & $sqlplusCmd.Source -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "} else {" ^
  "  $container = $env:ORACLE_DOCKER_CONTAINER;" ^
  "  if (-not $container) { $container = (docker ps --filter 'publish=1521' --format '{{.Names}}' | Select-Object -First 1) };" ^
  "  if (-not $container) { throw 'Neither sqlplus nor a running Oracle Docker container on port 1521 was found. Install sqlplus or set ORACLE_DOCKER_CONTAINER.' };" ^
  "  Write-Host ('Executing seed scripts (target schema: ' + $hdbUser + ') via Docker container: ' + $container);" ^
  "  $payload | docker exec -i $container sqlplus -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "}"

exit /b %ERRORLEVEL%
