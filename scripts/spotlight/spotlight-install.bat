@echo off
setlocal EnableDelayedExpansion

set "JELLYFIN_WEB="

for %%P in (
    "C:\Program Files\Jellyfin\Server\jellyfin-web"
    "C:\Program Files (x86)\Jellyfin\Server\jellyfin-web"
    "C:\ProgramData\Jellyfin\Server\jellyfin-web"
) do (
    if exist %%P (
        set "JELLYFIN_WEB=%%~P"
        goto :found_web
    )
)

echo  [?] Could not auto-detect Jellyfin web directory.
echo      Enter the full path to your jellyfin-web folder:
echo      Example: C:\Program Files\Jellyfin\Server\jellyfin-web
set /p JELLYFIN_WEB="  Path: "

if not exist "!JELLYFIN_WEB!" (
    echo  [X] Directory not found: !JELLYFIN_WEB!
    exit /b 1
)

:found_web
echo  [+] Web directory: !JELLYFIN_WEB!

set "UI_DIR=!JELLYFIN_WEB!\ui"
if not exist "!UI_DIR!" (
    mkdir "!UI_DIR!"
    echo  [+] Created ui folder.
) else (
    echo  [-] ui folder exists.
)

echo  Copying files...

set "SRC=%~dp0"

if exist "!SRC!spotlight.html" (
    copy /y "!SRC!spotlight.html" "!UI_DIR!\spotlight.html" >nul
    echo  [+] spotlight.html
) else (
    echo  [X] spotlight.html not found. Aborting.
    exit /b 1
)

if exist "!SRC!spotlight.css" (
    copy /y "!SRC!spotlight.css" "!UI_DIR!\spotlight.css" >nul
    echo  [+] spotlight.css
) else (
    echo  [X] spotlight.css not found. Aborting.
    exit /b 1
)

echo  Patching home-html chunk...

set "CHUNK_NAME="
for %%F in ("!JELLYFIN_WEB!\home-html.*.chunk.js") do (
    set "CHUNK_NAME=%%~nxF"
)

if "!CHUNK_NAME!"=="" (
    echo  [?] Could not find home-html.*.chunk.js automatically.
    echo      Enter the exact filename:
    set /p CHUNK_NAME="  Filename: "
)

set "CHUNK_FILE=!JELLYFIN_WEB!\!CHUNK_NAME!"

if not exist "!CHUNK_FILE!" (
    echo  [X] Chunk file not found: !CHUNK_FILE!
    exit /b 1
)

echo  [+] Found: !CHUNK_NAME!

if not exist "!CHUNK_FILE!.bak" (
    copy /y "!CHUNK_FILE!" "!CHUNK_FILE!.bak" >nul
    echo  [+] Backup created.
) else (
    echo  [-] Backup already exists, skipping.
)

if exist "!SRC!home-html.chunk.js" (
    copy /y "!SRC!home-html.chunk.js" "!CHUNK_FILE!" >nul
    echo  [+] Chunk patched.
) else (
    echo  [X] home-html.chunk.js not found. Patch manually - see README.
    exit /b 1
)

exit /b 0