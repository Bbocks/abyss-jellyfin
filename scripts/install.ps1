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
Write-Host "  Abyss Theme Installer" -ForegroundColor White
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

#  Authenticate 

$maxTries = 3
$authResponse = $null

for ($try = 1; $try -le $maxTries; $try++) {

    # Clear credential lines and reprint prompt cleanly
    if ($try -gt 1) {
        # Move cursor up 5 lines and clear them
        for ($i = 0; $i -lt 4; $i++) {
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

$token  = $authResponse.AccessToken
$userId = $authResponse.User.Id

$apiHeaders = @{
    "Content-Type"         = "application/json"
    "X-Emby-Authorization" = "MediaBrowser Client=`"Abyss Installer`", Device=`"Installer`", DeviceId=`"abyss-installer`", Version=`"1.0`", Token=`"$token`""
}

Write-Host ""
Write-Ok "Authenticated as: $($authResponse.User.Name)"
Write-Host ""

#  Apply Abyss CSS 

Write-Step "Applying Abyss CSS..."

try {
    $branding = Invoke-RestMethod `
        -Uri "$serverUrl/Branding/Configuration" `
        -Method Get -Headers $apiHeaders

    $branding.CustomCss = "@import url('https://cdn.jsdelivr.net/gh/AumGupta/abyss-jellyfin@main/abyss.css');`n/* Customise Abyss: https://aumgupta.github.io/abyss-jellyfin/ */"

    Invoke-RestMethod `
        -Uri "$serverUrl/System/Configuration/Branding" `
        -Method Post -Headers $apiHeaders `
        -Body ($branding | ConvertTo-Json -Depth 10) | Out-Null

    Write-Ok "Abyss CSS applied."
} catch {
    Write-Fail "Failed to apply CSS automatically."
    Write-Host "     Add this manually in Dashboard > General > Custom CSS:" -ForegroundColor DarkGray
    Write-Host "     @import url('https://cdn.jsdelivr.net/gh/AumGupta/abyss-jellyfin@main/abyss.css');" -ForegroundColor DarkGray
}

Write-Host ""

#  Set Dark Theme 

Write-Step "Setting dark theme..."
Write-Warn "Action required: After installation, go to Settings > Display > Theme and set it to Dark manually."
Write-Host "     The display theme cannot be set automatically as it is a client-side setting." -ForegroundColor DarkGray
Write-Host ""
try {
    $displayPrefs = Invoke-RestMethod `
        -Uri "$serverUrl/DisplayPreferences/usersettings?userId=$userId&client=emby" `
        -Method Get -Headers $apiHeaders

    $displayPrefs.CustomPrefs.dashboardTheme = "dark"

    Invoke-RestMethod `
        -Uri "$serverUrl/DisplayPreferences/usersettings?userId=$userId&client=emby" `
        -Method Post -Headers $apiHeaders `
        -Body ($displayPrefs | ConvertTo-Json -Depth 10) | Out-Null

    Write-Ok "Dashboard theme set to Dark."
} catch {
    Write-Warn "Could not set dashboard theme automatically."
    Write-Host "     Set it manually: Settings > Display > Server Dashboard Theme > Dark" -ForegroundColor DarkGray
}

#  Set home screen sections order 

Write-Step "Configuring home screen sections..."

try {
    $displayPrefs = Invoke-RestMethod `
        -Uri "$serverUrl/DisplayPreferences/usersettings?userId=$userId&client=emby" `
        -Method Get -Headers $apiHeaders

    $displayPrefs.CustomPrefs.homesection0 = "resume"
    $displayPrefs.CustomPrefs.homesection1 = "nextup"
    $displayPrefs.CustomPrefs.homesection2 = "smalllibrarytiles"
    $displayPrefs.CustomPrefs.homesection3 = "latestmedia"
    $displayPrefs.CustomPrefs.homesection4 = "none"
    $displayPrefs.CustomPrefs.homesection5 = "none"
    $displayPrefs.CustomPrefs.homesection6 = "none"
    $displayPrefs.CustomPrefs.homesection7 = "none"
    $displayPrefs.CustomPrefs.homesection8 = "none"
    $displayPrefs.CustomPrefs.homesection9 = "none"

    Invoke-RestMethod `
        -Uri "$serverUrl/DisplayPreferences/usersettings?userId=$userId&client=emby" `
        -Method Post -Headers $apiHeaders `
        -Body ($displayPrefs | ConvertTo-Json -Depth 10) | Out-Null

    Write-Ok "Home screen sections configured."
} catch {
    Write-Warn "Could not set home screen sections automatically."
    Write-Host "     Set manually: Settings > Home > arrange sections with My Media first." -ForegroundColor DarkGray
}

Write-Host ""

#  Install Spotlight 

$spotlightInstaller = Join-Path $scriptDir "scripts\spotlight\spotlight-install.bat"

if (Test-Path $spotlightInstaller) {
    Write-Step "Installing Spotlight add-on..."
    Write-Host ""

    $spotlightDir = Join-Path $scriptDir "scripts\spotlight"
    Push-Location $spotlightDir
    cmd /c "$spotlightInstaller"
    $exitCode = $LASTEXITCODE
    Pop-Location

    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Ok "Spotlight installed."
    } else {
        Write-Warn "Spotlight installer exited with code $exitCode."
        Write-Host "     Run spotlight\spotlight-install.bat manually if needed." -ForegroundColor DarkGray
    }
} else {
    Write-Skip "spotlight\spotlight-install.bat not found. Skipping."
}

Write-Host ""

#  Restart Jellyfin 

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

#  Done 

Write-Host ""
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Make sure to DELETE browser cache." -ForegroundColor Red
Write-Host "    2. Hard refresh your browser (Ctrl+F5)" -ForegroundColor Yellow
Write-Host "    3. Relaunch Jellyfin Media Player if using the desktop app" -ForegroundColor DarkGray

# Warn if display theme is not already dark
try {
    $displayPrefs = Invoke-RestMethod `
        -Uri "$serverUrl/DisplayPreferences/usersettings?userId=$userId&client=emby" `
        -Method Get -Headers $apiHeaders

    $currentTheme = $displayPrefs.CustomPrefs.appTheme
    if ($currentTheme -ne "dark" -and $currentTheme -ne "Dark") {
        Write-Host ""
        Write-Host "  Important:" -ForegroundColor Red
        Write-Host "    4. Go to Settings > Display > Theme and set it to Dark" -ForegroundColor Yellow
        Write-Host "       Abyss requires the Dark base theme to display correctly." -ForegroundColor DarkGray
    }
} catch {
    Write-Host ""
    Write-Host "  Important:" -ForegroundColor Red
    Write-Host "    4. Go to Settings > Display > Theme and set it to Dark" -ForegroundColor Yellow
    Write-Host "       Abyss requires the Dark base theme to display correctly." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Customise your theme:" -ForegroundColor White
Write-Host "    https://aumgupta.github.io/abyss-jellyfin/" -ForegroundColor Cyan
Write-Host ""
Read-Host " Press Enter to exit"