@echo off
setlocal EnableDelayedExpansion

title Aptly MCP Server - Installing...

echo.
echo   ===================================
echo     Aptly MCP Server for Claude
echo     Windsor Management
echo   ===================================
echo.

:: -------------------------------------------------------------------
:: CONFIG — Admin: replace the value below with your base64-encoded key
:: To encode:  powershell -c "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('your-key'))"
:: -------------------------------------------------------------------
set "B64KEY=REPLACE_WITH_BASE64_ENCODED_KEY"
:: -------------------------------------------------------------------

set "REPO=WindsorPM/aptly-mcp"
set "BRANCH=main"
set "INSTALL_DIR=%USERPROFILE%\.aptly-mcp"
set "CONFIG_PATH=%APPDATA%\Claude\claude_desktop_config.json"

:: --- Check Node.js ---
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] Node.js is not installed.
    echo.
    echo   You need Node.js to run the Aptly server.
    echo   Download it here:  https://nodejs.org/
    echo   Pick the LTS version, install it, then run this file again.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('node -v') do set NODE_VER=%%v
echo   [OK] Found Node.js %NODE_VER%

:: --- Decode the API key ---
echo   [..] Preparing configuration...
for /f "tokens=*" %%k in ('powershell -NoProfile -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('%B64KEY%'))"') do set "API_KEY=%%k"

if "%API_KEY%"=="" (
    echo   [ERROR] Could not decode the API key.
    echo   Contact Jason or Tyler for an updated installer.
    echo.
    pause
    exit /b 1
)
echo   [OK] Configuration ready

:: --- Download from GitHub ---
echo   [..] Downloading server files from GitHub...

set "ZIP_URL=https://github.com/%REPO%/archive/refs/heads/%BRANCH%.zip"
set "ZIP_PATH=%TEMP%\aptly-mcp.zip"
set "EXTRACT_PATH=%TEMP%\aptly-mcp-extract"

:: Clean previous downloads
if exist "%ZIP_PATH%" del /f "%ZIP_PATH%"
if exist "%EXTRACT_PATH%" rmdir /s /q "%EXTRACT_PATH%"

powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing"

if not exist "%ZIP_PATH%" (
    echo   [ERROR] Download failed. Check your internet connection.
    echo.
    pause
    exit /b 1
)

:: Extract
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_PATH%' -Force"

:: GitHub zips into a subfolder like "aptly-mcp-main"
for /d %%d in ("%EXTRACT_PATH%\*") do set "EXTRACTED=%%d"

:: Copy to install directory (preserve node_modules if present)
if exist "%INSTALL_DIR%\node_modules" (
    if exist "%TEMP%\aptly-mcp-modules" rmdir /s /q "%TEMP%\aptly-mcp-modules"
    move "%INSTALL_DIR%\node_modules" "%TEMP%\aptly-mcp-modules" >nul
)
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
xcopy "%EXTRACTED%" "%INSTALL_DIR%\" /s /e /q /y >nul
if exist "%TEMP%\aptly-mcp-modules" (
    move "%TEMP%\aptly-mcp-modules" "%INSTALL_DIR%\node_modules" >nul
)

:: Clean up temp files
del /f "%ZIP_PATH%" >nul 2>nul
rmdir /s /q "%EXTRACT_PATH%" >nul 2>nul

echo   [OK] Server files installed to %INSTALL_DIR%

:: --- Install npm dependencies ---
echo   [..] Installing dependencies (this may take a moment)...
pushd "%INSTALL_DIR%"
call npm install --silent >nul 2>nul
if %errorlevel% neq 0 (
    echo   [ERROR] npm install failed.
    echo   Try running "npm install" manually in %INSTALL_DIR%
    echo.
    popd
    pause
    exit /b 1
)
popd
echo   [OK] Dependencies installed

:: --- Configure Claude Desktop ---
echo   [..] Configuring Claude Desktop...

set "SERVER_PATH=%INSTALL_DIR%\server.mjs"

:: configure.ps1 was downloaded from GitHub into INSTALL_DIR — call it
powershell -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_DIR%\configure.ps1" -ServerPath "%SERVER_PATH%" -ApiKey "%API_KEY%"

echo   [OK] Claude Desktop configured

:: --- Done ---
echo.
echo   ===================================
echo     Setup Complete!
echo   ===================================
echo.
echo   Restart Claude Desktop to connect.
echo.
echo   Once restarted, try asking Claude:
echo     "Show me the open work orders"
echo.
pause
