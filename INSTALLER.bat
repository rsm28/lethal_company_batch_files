@echo off
SETLOCAL EnableDelayedExpansion

REM version 1.1.0
REM shoot me there was no 1.0.0

REM Pull the original RUNME filepath from the parameters (all parameters to handle spaces)
SET ORIG_RUNME=%*
IF EXIST "!ORIG_RUNME!" (
   SET /A ORIG_RUNME_EXISTS=1
)

REM HOLY FUCK WHY IS %2 "COMPANY.EXE/RUNME.BAT"
REM WHY DOES THIS EAT THE NEXT VARIABLE
REM ?????????
ECHO The selected modpack is: %3

REM Read mods from passed modpack variable
SET "MODPACK=%~3"
SET /A MOD_INDEX=0

FOR /F "tokens=*" %%A IN (.\modpacks\!MODPACK!.txt) DO (
    SET "MODS[!MOD_INDEX!]=%%A"
    SET /A MOD_INDEX+=1
)

IF NOT EXIST "Lethal Company.exe" (
    ECHO Lethal Company.exe not found in current directory.
    ECHO Run this script from the same folder as Lethal Company.exe.
    TIMEOUT /t 5 >nul
    PAUSE
    EXIT
)

ECHO Removing existing mod files...
REM Step -1: Remove all existing mod files if they exist!
IF EXIST "doorstop_config.ini" DEL /q "doorstop_config.ini"
IF EXIST "winhttp.dll" DEL /q "winhttp.dll"
IF EXIST "BepInEx\" RMDIR /s /q "BepInEx"
IF EXIST "Local_Downloads\" RMDIR /s /q "Local_Downloads"

ECHO Creating Local_Downloads directory...
REM Step 0: Create a directory called "Local_Downloads"
MKDIR Local_Downloads

ECHO Downloading BepInExPack...
REM Step 1: Download BepInExPack and extract it
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2100/' -OutFile '.\Local_Downloads\BepInExPack_5.4.2100.zip'}"

ECHO Extracting BepInExPack...
REM Step 2: Extract the zip file into "Local_Downloads\Extract"
powershell.exe -Command "& {Expand-Archive -Path '.\Local_Downloads\BepInExPack_5.4.2100.zip' -DestinationPath '.\Local_Downloads\Extract'}"

ECHO Moving BepInEx contents to root folder...
REM Step 3: Move contents of BepInExPack to root folder
XCOPY ".\Local_Downloads\Extract\BepInExPack" . /E /I /Y /q

ECHO Launching LC to install BepInEx...
REM Step 4: Launch and close Lethal Company.exe
START "" /B "Lethal Company.exe"
TIMEOUT /t 5 >nul
TASKKILL /im "Lethal Company.exe" /f

ECHO Cleaning up Extract directory for plugin extraction...
REM Step 5: Delete Local_Downloads\Extract for clean plugin extraction
RMDIR /s /q "Local_Downloads\Extract"

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
IF EXIST ".\Local_Downloads\Extract\icon.png" DEL /q ".\Local_Downloads\Extract\icon.png" 2>nul
IF EXIST ".\Local_Downloads\Extract\manifest.json" DEL /q ".\Local_Downloads\Extract\manifest.json" 2>nul
DEL /q ".\Local_Downloads\Extract\*.md" 2>nul
DEL /q ".\Local_Downloads\Extract\*.zip" 2>nul

ECHO Moving contents from .\Local_Downloads\Extract\BepInEx to .\BepInEx...
REM this for loop just moves errant files from shit mod authors into the correct folder
FOR /R ".\Local_Downloads\Extract\" %%G IN (*.dll) DO (
    MOVE "%%G" ".\Local_Downloads\Extract\BepInEx\plugins\" >nul 2>&1
)
FOR /R ".\Local_Downloads\Extract\" %%G IN (*) DO (
    IF "%%~xG"=="" (
        MOVE /Y "%%G" ".\Local_Downloads\Extract\BepInEx\plugins\" >nul 2>&1
    )
)

REM instead of moving .dlls, we now just merge the two folders - now we can use mods that have additional files (like cosmetic suit mods or whatever)
XCOPY ".\Local_Downloads\Extract\BepInEx\*" ".\BepInEx\" /E /Y /Q >nul 2>&1

REM this is a shitty fix for the MoreEmotes mod files issue
if exist ".\BepInEx\plugins\MoreEmotes\" (
    if exist ".\BepInEx\plugins\animationsbundle" move /Y ".\BepInEx\plugins\animationsbundle" ".\BepInEx\plugins\MoreEmotes\"
    if exist ".\BepInEx\plugins\animatorbundle" move /Y ".\BepInEx\plugins\animatorbundle" ".\BepInEx\plugins\MoreEmotes\"
)

REM this is a shitty fix for the Coroner mod files issue
if exist ".\Local_Downloads\Extract\Strings_en.xml" move /Y ".\Local_Downloads\Extract\Strings_en.xml" ".\BepInEx\plugins\" 

REM download custom config files from github repo, extract them, and copy them to BepInEx config directory
ECHO Downloading and applying custom config files...
MKDIR Local_Downloads\config-temp
powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://github.com/rsm28/lethal_company_batch_files/archive/refs/heads/main.zip' -OutFile '.\Local_Downloads\config-temp\main.zip'}"
powershell.exe -Command "& {Expand-Archive -Path '.\Local_Downloads\config-temp\main.zip' -DestinationPath '.\Local_Downloads\config-temp'}"
XCOPY ".\Local_Downloads\config-temp\lethal_company_batch_files-main\config\*" ".\BepInEx\config" /E /Y /Q >nul 2>&1
RMDIR /s /q "Local_Downloads\config-temp"

REM because i know not everyone will update their RUNME.bat file
IF EXIST "RUNME.bat" DEL "RUNME.bat"

REM Handle edge case where user ran the RUNME from inside the Lethal Company install folder
IF NOT EXIST "!ORIG_RUNME!" (
   SET /A ORIG_RUNME_EXISTS=0
)

powershell.exe -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rsm28/lethal_company_batch_files/main/RUNME.bat' -OutFile '.\RUNME.bat'}"

REM Copy updated RUNME to original location to keep it updated
IF "!ORIG_RUNME_EXISTS!"=="1" (
   ECHO Copying updated RUNME to original location: !ORIG_RUNME!
   COPY /Y "RUNME.bat" "!ORIG_RUNME!" >nul 2>&1
)

ECHO ---
ECHO ---
ECHO ---
ECHO You can run the game now!
ECHO Take a drink! 
ECHO ---
ECHO ---
ECHO ---
PAUSE
EXIT


:::::::::::::::::::::::::::::::
:DOWNLOAD_AND_PROCESS_MOD
SET MOD_INFO=%1
FOR /F "tokens=1-3 delims=-" %%A IN ("%MOD_INFO%") DO (
    SET MOD_AUTHOR=%%A
    SET MOD_NAME=%%B
    SET VERSION=%%C
)

ECHO ---
IF "%MOD_NAME%" == "LC_API" (
    SET VERSION=2.2.0
)
ECHO Downloading !MOD_NAME! version !VERSION! from author !MOD_AUTHOR!...
SET WEBREQUEST_URL=https://thunderstore.io/package/download/!MOD_AUTHOR!/!MOD_NAME!/!VERSION!/
ECHO !WEBREQUEST_URL!
powershell.exe -Command "& {Invoke-WebRequest -Uri '!WEBREQUEST_URL!' -OutFile '.\Local_Downloads\!MOD_NAME!_!VERSION!.zip'}"

ECHO Extracting !MOD_NAME! version !VERSION!...
powershell.exe -Command "& {Expand-Archive -Path '.\Local_Downloads\!MOD_NAME!_!VERSION!.zip' -DestinationPath '.\Local_Downloads\Extract' -Force}"
GOTO :EOF
:::::::::::::::::::::::::::::::
