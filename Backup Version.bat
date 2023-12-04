@echo off
setlocal enabledelayedexpansion

REM --------------------------------------------------------------------------------
REM Define array of mods to download and their respective versions.
SET MODS[0]=2018-LC_API-2.0.0
SET MODS[1]=notnotnotswipez-MoreCompany-1.6.0
SET MODS[2]=anormaltwig-LateCompany-1.0.4
SET MODS[3]=x753-Mimics-1.0.0
REM Add more mods here as needed under the following format:
REM SET MODS[n]=[author]-[name]-[ver]
REM --------------------------------------------------------------------------------

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

:: Initialize the counter.
SET /A MOD_INDEX=0

:: Loop through each mod in the array using a dynamic approach.
:MOD_LOOP
IF NOT DEFINED MODS[%MOD_INDEX%] GOTO :END_MOD_LOOP
SET CURRENT_MOD=!MODS[%MOD_INDEX%]!
CALL :DOWNLOAD_AND_PROCESS_MOD !CURRENT_MOD!
SET /A MOD_INDEX+=1
GOTO :MOD_LOOP
:END_MOD_LOOP


ECHO Moving .dll files from extracted plugins to final destination...
FOR /R ".\Local_Downloads\Extract\" %%G IN (*.dll) DO xcopy "%%G" ".\BepInEx\plugins\" /Y /Q

pause
GOTO :EOF


:: Function for downloading a mod, extracting it, cleaning up files, and moving plugins.
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
powershell.exe -Command "& {Expand-Archive -Path '.\Local_Downloads\%MOD_NAME%_%VERSION%.zip' -DestinationPath '.\Local_Downloads\Extract' -Force}"

ECHO Cleaning up unnecessary files from !MOD_NAME!'s folder after extraction...
del /q ".\Local_Downloads\Extract\!MOD_NAME!\icon.png" 2>nul
del /q ".\Local_Downloads\Extract\!MOD_NAME!\manifest.json" 2>nul
del /q ".\Local_Downloads\Extract\!MOD_NAME!\README.md" 2>nul

GOTO :EOF

