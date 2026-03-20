$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Write-Step { param($msg) Write-Host " $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host " [+] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host " [!] $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host " [X] $msg" -ForegroundColor Red }
function Write-Skip { param($msg) Write-Host " [-] $msg" -ForegroundColor DarkGray }

Clear-Host
Write-Host ""
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host "  Abyss Theme Uninstaller" -ForegroundColor White
Write-Host "  https://github.com/AumGupta/abyss-jellyfin" -ForegroundColor DarkGray
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host ""

#  Server URL 

Write-Host " Jellyfin server URL" -ForegroundColor Yellow
Write-Host " Press ENTER to use default (http://localhost:8096)" -ForegroundColor DarkGray
$inputUrl = Read-Host "  URL"
$serverUrl = if ($inputUrl.Trim() -eq "") { "http://localhost:8096" } else { $inputUrl.Trim().TrimEnd("/") }
Write-Ok "Server: $serverUrl"
Write-Host ""

#  Credentials 

$maxTries = 3
$authResponse = $null

for ($try = 1; $try -le $maxTries; $try++) {

    if ($try -gt 1) {
        for ($i = 0; $i -lt 5; $i++) {
            [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
            Write-Host (" " * [Console]::WindowWidth) -NoNewline
            [Console]::SetCursorPosition(0, [Console]::CursorTop)
        }
        Write-Host " [X] Invalid credentials. Attempt $($try - 1) of $maxTries" -ForegroundColor Red
        Write-Host ""
    }

    Write-Host " Jellyfin admin credentials" -ForegroundColor Yellow
    $username = Read-Host "  Username"
    $securePassword = Read-Host "  Password" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )

    $authBody = @{ Username = $username; Pw = $password } | ConvertTo-Json
    $authHeaders = @{
        "Content-Type"         = "application/json"
        "X-Emby-Authorization" = 'MediaBrowser Client="Abyss Installer", Device="Installer", DeviceId="abyss-installer", Version="1.0"'
    }

    try {
        $authResponse = Invoke-RestMethod `
            -Uri "$serverUrl/Users/AuthenticateByName" `
            -Method Post -Headers $authHeaders -Body $authBody
        break
    } catch {
        if ($try -eq $maxTries) {
            Write-Host ""
            Write-Host " [X] Authentication failed after $maxTries attempts." -ForegroundColor Red
            Write-Host ""
            Read-Host " Press Enter to exit"
            exit 1
        }
    }
}

$token = $authResponse.AccessToken

$apiHeaders = @{
    "Content-Type"         = "application/json"
    "X-Emby-Authorization" = "MediaBrowser Client=`"Abyss Installer`", Device=`"Installer`", DeviceId=`"abyss-installer`", Version=`"1.0`", Token=`"$token`""
}

Write-Host ""
Write-Ok "Authenticated as: $($authResponse.User.Name)"
Write-Host ""

#  Clear custom CSS 

Write-Step "Clearing custom CSS..."

try {
    $branding = Invoke-RestMethod `
        -Uri "$serverUrl/Branding/Configuration" `
        -Method Get -Headers $apiHeaders

    $branding.CustomCss = ""

    Invoke-RestMethod `
        -Uri "$serverUrl/System/Configuration/Branding" `
        -Method Post -Headers $apiHeaders `
        -Body ($branding | ConvertTo-Json -Depth 10) | Out-Null

    Write-Ok "Custom CSS cleared."
} catch {
    Write-Fail "Failed to clear CSS."
    Write-Host "     Clear it manually in Dashboard > General > Custom CSS." -ForegroundColor DarkGray
}

Write-Host ""

#  Uninstall Spotlight 

$spotlightUninstaller = Join-Path $scriptDir "scripts\spotlight\spotlight-uninstall.bat"

if (Test-Path $spotlightUninstaller) {
    Write-Step "Uninstalling Spotlight add-on..."
    Write-Host ""

    $spotlightDir = Join-Path $scriptDir "scripts\spotlight"
    Push-Location $spotlightDir
    cmd /c "$spotlightUninstaller"
    $exitCode = $LASTEXITCODE
    Pop-Location

    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Ok "Spotlight uninstalled."
    } else {
        Write-Warn "Spotlight uninstaller exited with code $exitCode."
        Write-Host "     Run spotlight\spotlight-uninstall.bat manually if needed." -ForegroundColor DarkGray
    }
} else {
    Write-Skip "spotlight\spotlight-uninstall.bat not found. Skipping."
}

Write-Host ""

# Restart Jellyfin

Write-Step "Restarting Jellyfin..."

try {
    Invoke-RestMethod `
        -Uri "$serverUrl/System/Restart" `
        -Method Post -Headers $apiHeaders | Out-Null
    Write-Ok "Jellyfin restart triggered via API."
    Write-Host "     Wait a few seconds then refresh your browser." -ForegroundColor DarkGray
} catch {
    Write-Warn "Could not restart Jellyfin automatically."
    Write-Host "     Please restart it manually." -ForegroundColor DarkGray
}

# Done

Write-Host ""
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host "  Uninstall complete!" -ForegroundColor Green
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Make sure to DELETE browser cache." -ForegroundColor Red
Write-Host "    2. Hard refresh your browser (Ctrl+F5)" -ForegroundColor Yellow
Write-Host "    3. Relaunch Jellyfin Media Player if using the desktop app" -ForegroundColor DarkGray
Write-Host ""
Read-Host " Press Enter to exit"