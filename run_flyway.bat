@echo off
setlocal DisableDelayedExpansion

:: Check if .env file exists
if exist .env (
    echo Loading variables from .env...
    :: Read lines that don't start with '#' and set them as variables
    for /f "usebackq tokens=1,* delims==" %%i in (`findstr /v "^#" .env`) do (
        set "%%i=%%j"
    )
) else (
    echo WARNING: .env file not found. Please copy .env.example to .env and configure it.
)

:: Run flyway with arguments passed to the script
flyway_tool\flyway-9.22.3\flyway.cmd -configFiles="flyway_migration\conf\flyway.conf" %*

endlocal
