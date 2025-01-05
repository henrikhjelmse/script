@echo off
setlocal enabledelayedexpansion

:check_unrar
REM Kontrollera om WinRAR är installerat på standardplatsen
set "UNRAR_PATH=C:\Program Files\WinRAR\unrar.exe"
if not exist "%UNRAR_PATH%" (
    set "UNRAR_PATH=C:\Program Files (x86)\WinRAR\unrar.exe"
)

REM Verifiera att unrar.exe finns
if not exist "%UNRAR_PATH%" (
    echo Error: Could not find unrar.exe
    echo Please install WinRAR or verify the installation path
    pause
    exit /b 1
)

:start
cls
echo RAR Extraction Tool
echo ------------------
echo.
echo Current directory: %~dp0
echo.
set /p "CONFIRM=Do you want to extract all RAR files in this directory and subdirectories? (Y/N): "
if /i not "%CONFIRM%"=="Y" exit /b 0

:extract_choice
echo.
echo Choose extraction method:
echo 1. Extract to same folder as RAR files
echo 2. Extract to 'extracted' subfolder in each RAR location
echo.
set /p "EXTRACT_CHOICE=Enter your choice (1 or 2): "

:extract
echo.
echo Starting extraction process...
echo ----------------------------
echo.

set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

REM Skapa en logfil
set "LOG_FILE=%~dp0extraction_log.txt"
echo Extraction Log - %date% %time% > "%LOG_FILE%"
echo -------------------------------- >> "%LOG_FILE%"

for /r "%~dp0" %%f in (*.rar) do (
    set "CURRENT_FILE=%%f"
    echo Processing: !CURRENT_FILE!
    echo Processing: !CURRENT_FILE! >> "%LOG_FILE%"
    
    if "%EXTRACT_CHOICE%"=="2" (
        REM Skapa och extrahera till extracted-mapp
        set "EXTRACT_PATH=%%~dpfextracted"
        if not exist "!EXTRACT_PATH!" mkdir "!EXTRACT_PATH!"
        "%UNRAR_PATH%" x -o+ "%%f" "!EXTRACT_PATH!" >nul 2>&1
    ) else (
        REM Extrahera till samma mapp som RAR-filen
        "%UNRAR_PATH%" x -o+ "%%f" "%%~dpf" >nul 2>&1
    )
    
    if errorlevel 1 (
        echo [ERROR] Failed to extract: %%f
        echo [ERROR] Failed to extract: %%f >> "%LOG_FILE%"
        set /a "ERROR_COUNT+=1"
    ) else (
        echo [SUCCESS] Extracted: %%f
        echo [SUCCESS] Extracted: %%f >> "%LOG_FILE%"
        
        REM Ta bort original RAR-filer efter lyckad extrahering
        del /q "%%f"
        if exist "%%~dpnf.r*" del /q "%%~dpnf.r*"
        set /a "SUCCESS_COUNT+=1"
    )
    echo. >> "%LOG_FILE%"
)

:summary
echo.
echo ===============================
echo Extraction Summary
echo ===============================
echo Successful extractions: %SUCCESS_COUNT%
echo Failed extractions: %ERROR_COUNT%
echo Log file created: %LOG_FILE%
echo.

echo Summary >> "%LOG_FILE%"
echo ======= >> "%LOG_FILE%"
echo Successful extractions: %SUCCESS_COUNT% >> "%LOG_FILE%"
echo Failed extractions: %ERROR_COUNT% >> "%LOG_FILE%"

pause
exit /b 0