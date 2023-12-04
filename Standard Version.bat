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

REM Check if 'Lethal Company.exe' exists in the current directory.
IF EXIST "%~dp0\Lethal Company.exe" (
    SET "LC_PATH=%~dp0"
) ELSE (
    ECHO Looking for Steam installation folder...
    REM Find Steam installation - first check HKCU, then HKLM
    FOR /F "Tokens=1,2*" %%A IN ('Reg Query HKCU\Software\Valve\Steam') DO (
        IF "%%A" EQU "SteamPath" SET "STEAMPATH=%%C"
    )

    IF NOT DEFINED STEAMPATH (
        FOR /F "Tokens=1,2*" %%A IN ('Reg Query HKLM\SOFTWARE\WOW6432Node\Valve\Steam') DO (
            IF "%%A" EQU "InstallPath" SET "STEAMPATH=%%C"
        )
    )

    IF NOT DEFINED STEAMPATH (
        FOR /F "Tokens=1,2*" %%A IN ('Reg Query HKLM\SOFTWARE\Valve\Steam') DO (
            IF "%%A" EQU "InstallPath" SET "STEAMPATH=%%C"
        )
    )

    IF NOT DEFINED STEAMPATH (
        ECHO --------------
        SET /P "STEAMPATH=Enter the path to your Steam installation (the folder where Steam.exe is located, for your install of Lethal Company): "
        ECHO --------------
    )

    IF "!STEAMPATH:~-1!"=="\" SET "STEAMPATH=!STEAMPATH:~0,-1!"
    SET "STEAMPATH=!STEAMPATH:/=\!"
    SET "LC_PATH=!STEAMPATH!\steamapps\common\Lethal Company"

    IF NOT EXIST "!LC_PATH!\Lethal Company.exe" (
        ECHO Lethal Company installation not found in !LC_PATH!.
        timeout /t 1 >nul
        ECHO --------------
        SET /P "LC_PATH=Enter the path to your Lethal Company installation (where Lethal Company.exe is located): "
        IF "!LC_PATH:~-1!"=="\" SET "LC_PATH=!LC_PATH:~0,-1!"
        timeout /t 1 >nul
        ECHO --------------

        IF NOT EXIST "!LC_PATH!\Lethal Company.exe" (
            ECHO Lethal Company still not found at !LC_PATH!.
            ECHO Either: move this script to the same folder as Lethal Company.exe, or
            ECHO    properly enter the path to your Lethal Company installation.
            timeout /t 5 >nul
            pause
            GOTO :EOF
         )
     )
)

ECHO Lethal Company installation found at !LC_PATH!.
ECHO Removing existing mod files...
REM Step -1: Remove all existing mod files if they exist!
if exist "%LC_PATH%\doorstop_config.ini" del /q "%LC_PATH%\doorstop_config.ini"
if exist "%LC_PATH%\winhttp.dll" del /q "%LC_PATH%\winhttp.dll"
if exist "%LC_PATH%\BepInEx\" rmdir /s /q "%LC_PATH%\BepInEx"
if exist "%LC_PATH%\Local_Downloads\" rmdir /s /q "%LC_PATH%\Local_Downloads"

ECHO Creating Local_Downloads directory...
REM Step 0: Create a directory called "Local_Downloads"
mkdir "%LC_PATH%\Local_Downloads"

ECHO Downloading BepInExPack...
REM Step 1: Download BepInExPack and extract it
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2100/' -OutFile '%LC_PATH%\Local_Downloads\BepInExPack_5.4.2100.zip'}"

ECHO Extracting BepInExPack...
REM Step 2: Extract the zip file into "Local_Downloads\Extract"
powershell.exe -Command "& {Expand-Archive -Path '%LC_PATH%\Local_Downloads\BepInExPack_5.4.2100.zip' -DestinationPath '%LC_PATH%\Local_Downloads\ExtractBPEX' -Force}"

ECHO Moving BepInEx contents to root folder...
REM Step 3: Move contents of BepInExPack to root folder
xcopy "%LC_PATH%\Local_Downloads\ExtractBPEX\BepInExPack" "%LC_PATH%" /E /Y /Q

ECHO Launching LC to install BepInEx...
timeout /t 1 >nul
REM Step 4: Launch and close Lethal Company.exe
start "" /B "%LC_PATH%\Lethal Company.exe"
timeout /t 5 >nul
taskkill /im "Lethal Company.exe" /f

REM Initialize the counter.
SET /A MOD_INDEX=0

REM Loop through each mod in the array using a dynamic approach.
:MOD_LOOP
IF NOT DEFINED MODS[%MOD_INDEX%] GOTO :END_MOD_LOOP
SET CURRENT_MOD=!MODS[%MOD_INDEX%]!
CALL :DOWNLOAD_AND_PROCESS_MOD !CURRENT_MOD!
SET /A MOD_INDEX+=1
GOTO :MOD_LOOP
:END_MOD_LOOP


ECHO Moving .dll files from extracted plugins to final destination...
FOR /R "%LC_PATH%\Local_Downloads\Extract\" %%G IN (*.dll) DO xcopy "%%G" "%LC_PATH%\BepInEx\plugins\" /Y /Q

pause
GOTO :EOF


REM Function for downloading a mod, extracting it, cleaning up files, and moving plugins.
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
powershell.exe -Command "& {Invoke-WebRequest -Uri '!WEBREQUEST_URL!' -OutFile '%LC_PATH%\Local_Downloads\!MOD_NAME!_!VERSION!.zip'}"

ECHO Extracting !MOD_NAME! version !VERSION!...
powershell.exe -Command "& {Expand-Archive -Path '%LC_PATH%\Local_Downloads\%MOD_NAME%_%VERSION%.zip' -DestinationPath '%LC_PATH%\Local_Downloads\Extract' -Force}"

ECHO Cleaning up unnecessary files from !MOD_NAME!'s folder after extraction...
del /q "%LC_PATH%\Local_Downloads\Extract\!MOD_NAME!\icon.png" 2>nul
del /q "%LC_PATH%\Local_Downloads\Extract\!MOD_NAME!\manifest.json" 2>nul
del /q "%LC_PATH%\Local_Downloads\Extract\!MOD_NAME!\README.md" 2>nul

GOTO :EOF

