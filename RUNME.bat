

@echo off
setlocal enabledelayedexpansion
REM 1. see whether 'Lethal Company.exe' exists in the current directory
REM 2. if it doesn't, we do the registry things and backup installation finding
REM 3. after we verify we're in the right directory:
    REM 3.1. pull latest: modlist.txt, backup version.bat to the current directory
    REM 3.2. run backup version.bat

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

REM Pull latest modlist.txt and backup version.bat
ECHO Downloading latest modlist.txt and backup version.bat...
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/modlist.txt' -OutFile '!LC_PATH!\modlist.txt'}"
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/BackupVersion.bat' -OutFile '!LC_PATH!\backup_version.bat'}"

REM Run backup version.bat
ECHO Running backup version.bat...
call "!LC_PATH!\backup_version.bat"
