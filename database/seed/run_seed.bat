@echo off
setlocal EnableExtensions

REM ============================================================================
REM run_seed.bat - Populate local HDB Oracle database with sample seed data
REM Reads connection settings from repository .env (never prints credentials).
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
  "$ez = $url -replace '^jdbc:oracle:thin:@','';" ^
  "$files = @('00_preflight_and_prereqs.sql','01_core_lookup_reference.sql','02_sites_and_authorization.sql','03_external_hydromet_mappings.sql','04_models_ensembles_and_cp.sql','05_timeseries_real_and_model.sql','06_alarms_and_monitoring.sql','07_decodes_telemetry.sql');" ^
  "$validate = ('%1' -eq '--validate' -or '%1' -eq '-v');" ^
  "if ($validate) { $files += 'validate_seed_data.sql' };" ^
  "$sb = New-Object System.Text.StringBuilder;" ^
  "[void]$sb.AppendLine('WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK');" ^
  "[void]$sb.AppendLine('WHENEVER OSERROR EXIT FAILURE ROLLBACK');" ^
  "[void]$sb.AppendLine(('CONNECT ' + $user + '/\"' + $pass + '\"@' + $ez + ' AS SYSDBA'));" ^
  "[void]$sb.AppendLine('SET DEFINE OFF FEEDBACK OFF VERIFY OFF ECHO OFF SERVEROUTPUT ON SIZE UNLIMITED LINESIZE 220 PAGESIZE 500');" ^
  "foreach ($f in $files) { [void]$sb.AppendLine((Get-Content (Join-Path $seedDir $f) -Raw)); };" ^
  "[void]$sb.AppendLine('EXIT 0');" ^
  "$payload = $sb.ToString();" ^
  "$localSqlplus = Get-Command sqlplus -ErrorAction SilentlyContinue;" ^
  "if ($localSqlplus) {" ^
  "  Write-Host 'Executing seed scripts via local sqlplus...';" ^
  "  $payload | & $localSqlplus.Source -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "} else {" ^
  "  $container = $env:ORACLE_DOCKER_CONTAINER;" ^
  "  if (-not $container) { $container = (docker ps --filter 'publish=1521' --format '{{.Names}}' | Select-Object -First 1) };" ^
  "  if (-not $container) { throw 'Neither local sqlplus nor a running Oracle Docker container on port 1521 was found. Set ORACLE_DOCKER_CONTAINER or start Docker.' };" ^
  "  Write-Host ('Executing seed scripts via Docker container: ' + $container);" ^
  "  $payload | docker exec -i $container sqlplus -s /nolog;" ^
  "  exit $LASTEXITCODE;" ^
  "}"

exit /b %ERRORLEVEL%
