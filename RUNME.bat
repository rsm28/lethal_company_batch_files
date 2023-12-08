@echo off
setlocal enabledelayedexpansion
REM 1. see whether 'Lethal Company.exe' exists in the current directory
REM 2. if it doesn't, we do the registry things and backup installation finding
REM 3. after we verify we're in the right directory:
    REM 3.1. pull latest: modlist.txt, backup version.bat to the current directory
    REM 3.2. run backup version.bat

REM VER 1.0.0

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
       timeout /t 5 >nul
       pause
       GOTO :EOF
   )
)

ECHO Lethal Company installation found at !LC_PATH!.
ECHO Removing modlist.txt and INSTALLER.bat
if exist "!LC_PATH!\modlist.txt" del "!LC_PATH!\modlist.txt"
if exist "!LC_PATH!\INSTALLER.bat" del "!LC_PATH!\INSTALLER.bat"

REM Pull latest modlist.txt and INSTALLER.bat
ECHO Downloading latest modlist.txt and INSTALLER.bat...
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/modlist.txt' -OutFile '!LC_PATH!\modlist.txt'}"
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/INSTALLER.bat' -OutFile '!LC_PATH!\INSTALLER.bat'}"

REM Read the mods from the mods.txt file.
ECHO ---
SET /A MOD_INDEX=0
FOR /F "tokens=*" %%A IN (modlist.txt) DO (
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

REM Update the modlist.txt file with the latest version numbers.
COPY /Y NUL modlist.tmp >nul 2>&1
FOR /L %%I IN (0,1,!MOD_INDEX!-1) DO (
    SET "MOD_INFO=!MODS[%%I]!"
    FOR /F "tokens=1,2 delims=-" %%A IN ("!MOD_INFO!") DO (
        SET "AUTHOR=%%A"
        SET "MODNAME=%%B"
        ECHO !AUTHOR!-!MODNAME!-!LATEST_VERSION[%%I]!>> modlist.tmp
    )
)
MOVE /Y modlist.tmp modlist.txt >nul 2>&1

ECHO Modlist updated with the latest version numbers.
ECHO ---
ECHO Running installer...

REM Run backup version.bat
ECHO Running INSTALLER.bat...
call "!LC_PATH!\INSTALLER.bat"
