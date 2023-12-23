@echo off
setlocal enabledelayedexpansion
REM VER 1.1.0

REM Check if 'Lethal Company.exe' exists in the current directory.
IF EXIST "%~dp0\Lethal Company.exe" (
    SET "LC_PATH=%~dp0"
) ELSE (
    ECHO Looking for Steam installation folder...
    REM Find Steam installation.
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

   IF "!STEAMPATH:~-1!"=="\" SET "STEAMPATH=!STEAMPATH:~0,-1!"
   SET "STEAMPATH=!STEAMPATH:/=\!"
   SET "LC_PATH=!STEAMPATH!\steamapps\common\Lethal Company"

   IF NOT EXIST "!LC_PATH!\Lethal Company.exe" (
       ECHO Lethal Company installation not found. Exiting...
       TIMEOUT /t 5 >nul
       PAUSE
       EXIT
   )
)

REM Switch working directory to the Lethal Company installation folder
CD /D "!LC_PATH!"

ECHO Lethal Company installation found at !LC_PATH!.
ECHO Removing modlist.txt and INSTALLER.bat
IF EXIST "modlist.txt" DEL "modlist.txt"
REM TO REMOVE ONCE MODPACK IMPLEMENTATION IS DONE
REM IF EXIST "INSTALLER.bat" DEL "INSTALLER.bat"
IF NOT EXIST "%~dp0\modpacks" (
    mkdir "%~dp0\modpacks"
)

REM Pull list of modpacks from GitHub
ECHO Fetching list of modpacks...
ECHO ----------------------- MODPACKS -----------------------
powershell.exe -Command "& {$user='rsm28'; $repo='lethal_company_batch_files'; $response = Invoke-RestMethod -Uri \"https://api.github.com/repos/$user/$repo/contents/modpacks\"; $modpacks = $response | ForEach-Object { $_.name.Replace('.txt', '') }; $i=1; $modpacks | ForEach-Object { Write-Output (\"$i) $_\"); $i++ }}"
ECHO ----------------------- MODPACKS -----------------------
SET /P MODPACK="Enter the EXACT NAME of the modpack you want to install: "


REM Check if the modpack exists
powershell.exe -Command "& {$user='rsm28'; $repo='lethal_company_batch_files'; $response = Invoke-RestMethod -Uri \"https://api.github.com/repos/$user/$repo/contents/modpacks\"; $modpacks = $response | ForEach-Object { $_.name.Replace('.txt', '') }; if ($modpacks -contains '%MODPACK%') { exit 0 } else { exit 1 }}"
IF %ERRORLEVEL% EQU 0 (
    REM Download the selected modpack
    ECHO Downloading %MODPACK%...
    powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/modpacks/%MODPACK%.txt' -OutFile '.\modpacks\%MODPACK%.txt'}"
) ELSE (
    ECHO "Modpack '%MODPACK%' does not exist. Exiting..."
    TIMEOUT /t 5 >nul
    EXIT
)

REM Pull latest modlist.txt and INSTALLER.bat <<<LEGACY CODE>>>
REM ECHO Downloading latest modlist.txt and INSTALLER.bat...
REM powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/modlist.txt' -OutFile '.\modlist.txt'}"
REM powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/INSTALLER.bat' -OutFile '.\INSTALLER.bat'}"

REM Read the mods from the mods.txt file.
ECHO ---
SET /A MOD_INDEX=0
FOR /F "tokens=*" %%A IN (.\modpacks\%MODPACK%.txt) DO (
    SET "MODS[!MOD_INDEX!]=%%A"
    SET /A MOD_INDEX+=1
)

REM Go through each mod and...
FOR /L %%I IN (0,1,!MOD_INDEX!-1) DO (
    SET "MOD_INFO=!MODS[%%I]!"
    FOR /F "tokens=1,2 delims=-" %%A IN ("!MOD_INFO!") DO (
        SET "AUTHOR=%%A"
        SET "MODNAME=%%B"
        REM Call the API and parse the JSON respons.
        FOR /F "delims=" %%V IN ('powershell -Command "$response = Invoke-RestMethod -Uri 'https://thunderstore.io/api/experimental/package/!AUTHOR!/!MODNAME!/'; $response.latest.version_number"') DO (
            SET "LATEST_VERSION[%%I]=%%V"
        )
        ECHO !AUTHOR!-!MODNAME!-!LATEST_VERSION[%%I]! is the latest version.
    )
)

REM Update the modpack file with the latest version numbers.
COPY /Y NUL .\modpacks\%MODPACK%.tmp >nul 2>&1
FOR /L %%I IN (0,1,!MOD_INDEX!-1) DO (
    SET "MOD_INFO=!MODS[%%I]!"
    FOR /F "tokens=1,2 delims=-" %%A IN ("!MOD_INFO!") DO (
        SET "AUTHOR=%%A"
        SET "MODNAME=%%B"
        ECHO !AUTHOR!-!MODNAME!-!LATEST_VERSION[%%I]! >> .\modpacks\%MODPACK%.tmp
    )
)
MOVE /Y .\modpacks\%MODPACK%.tmp .\modpacks\%MODPACK%.txt >nul 2>&1

ECHO Modpack updated with the latest version numbers.
ECHO ---
ECHO Running installer...

REM Run backup version.bat
REM Run the installer in a separate terminal so this RUNME closes and can be updated safely from INSTALLER
START "Lethal Company Mod Installer" /D "!LC_PATH!" "INSTALLER.bat" %~f0 %MODPACK%
TIMEOUT /t 3 >nul
EXIT
