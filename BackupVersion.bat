@echo off
setlocal enabledelayedexpansion

REM Read mods from modlist.txt
SET /A MOD_INDEX=0
FOR /F "tokens=*" %%A IN (modlist.txt) DO (
    SET "MODS[!MOD_INDEX!]=%%A"
    SET /A MOD_INDEX+=1
)

IF NOT EXIST "%~dp0\Lethal Company.exe" (
    ECHO Lethal Company.exe not found in current directory.
    ECHO Run this script from the same folder as Lethal Company.exe.
    timeout /t 5 >nul
    pause
    GOTO :EOF
)

ECHO Removing existing mod files...
REM Step -1: Remove all existing mod files if they exist!
if exist "doorstop_config.ini" del /q "doorstop_config.ini"
if exist "winhttp.dll" del /q "winhttp.dll"
if exist "BepInEx\" rmdir /s /q "BepInEx"
if exist "Local_Downloads\" rmdir /s /q "Local_Downloads"

ECHO Creating Local_Downloads directory...
REM Step 0: Create a directory called "Local_Downloads"
mkdir Local_Downloads

ECHO Downloading BepInExPack...
REM Step 1: Download BepInExPack and extract it
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2100/' -OutFile '.\Local_Downloads\BepInExPack_5.4.2100.zip'}"

ECHO Extracting BepInExPack...
REM Step 2: Extract the zip file into "Local_Downloads\Extract"
powershell.exe -Command "& {Expand-Archive -Path '.\Local_Downloads\BepInExPack_5.4.2100.zip' -DestinationPath '.\Local_Downloads\Extract'}"

ECHO Moving BepInEx contents to root folder...
REM Step 3: Move contents of BepInExPack to root folder
xcopy ".\Local_Downloads\Extract\BepInExPack" . /E /I /Y /q

ECHO Launching LC to install BepInEx...
REM Step 4: Launch and close Lethal Company.exe
start "" /B "Lethal Company.exe"
timeout /t 5 >nul
taskkill /im "Lethal Company.exe" /f

ECHO Cleaning up Extract directory for plugin extraction...
REM Step 5: Delete Local_Downloads\Extract for clean plugin extraction
rmdir /s /q "Local_Downloads\Extract"

REM Main mod loop
SET /A MOD_INDEX=0
:MOD_LOOP
IF NOT DEFINED MODS[%MOD_INDEX%] GOTO :END_MOD_LOOP
SET CURRENT_MOD=!MODS[%MOD_INDEX%]!
CALL :DOWNLOAD_AND_PROCESS_MOD !CURRENT_MOD!
SET /A MOD_INDEX+=1
GOTO :MOD_LOOP
:END_MOD_LOOP

ECHO ---

ECHO Cleaning up unnecessary files from Extract folder after extraction...
if exist ".\Local_Downloads\Extract\icon.png" del /q ".\Local_Downloads\Extract\icon.png" 2>nul
if exist ".\Local_Downloads\Extract\manifest.json" del /q ".\Local_Downloads\Extract\manifest.json" 2>nul
del /q ".\Local_Downloads\Extract\*.md" 2>nul
del /q ".\Local_Downloads\Extract\*.zip" 2>nul

ECHO Moving contents from .\Local_Downloads\Extract\BepInEx to .\BepInEx...
REM this for loop just moves errant .dlls from shit mod authors into the correct folder
FOR /R ".\Local_Downloads\Extract\" %%G IN (*.dll) DO (
    move "%%G" ".\Local_Downloads\Extract\BepInEx\plugins\" >nul 2>&1
)
REM instead of moving .dlls, we now just merge the two folders - now we can use mods that have additional files (like cosmetic suit mods or whatever)
xcopy ".\Local_Downloads\Extract\BepInEx\*" ".\BepInEx\" /E /Y /Q >nul 2>&1

ECHO ---
ECHO ---
ECHO ---
ECHO You can run the game now! Take a drink!
ECHO ---
ECHO ---
ECHO ---
pause
GOTO :EOF


:::::::::::::::::::::::::::::::
:DOWNLOAD_AND_PROCESS_MOD
SET MOD_INFO=%1
FOR /F "tokens=1-3 delims=-" %%A IN ("%MOD_INFO%") DO (
    SET MOD_AUTHOR=%%A
    SET MOD_NAME=%%B
    SET VERSION=%%C
)

ECHO ---
ECHO Downloading !MOD_NAME! version !VERSION! from author !MOD_AUTHOR!...
SET WEBREQUEST_URL=https://thunderstore.io/package/download/!MOD_AUTHOR!/!MOD_NAME!/!VERSION!/
ECHO !WEBREQUEST_URL!
powershell.exe -Command "& {Invoke-WebRequest -Uri '!WEBREQUEST_URL!' -OutFile '.\Local_Downloads\!MOD_NAME!_!VERSION!.zip'}"

ECHO Extracting !MOD_NAME! version !VERSION!...
powershell.exe -Command "& {Expand-Archive -Path '.\Local_Downloads\!MOD_NAME!_!VERSION!.zip' -DestinationPath '.\Local_Downloads\Extract' -Force}"
GOTO :EOF
:::::::::::::::::::::::::::::::
