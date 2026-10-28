<#
.SYNOPSIS
    Windows 11 Gaming ISO Customizer
    Creates a stripped-down Windows 11 image for maximum gaming performance.
    
.DESCRIPTION
    - Mounts install.wim from a Windows 11 installation source.
    - Removes provisioned bloatware (Appx).
    - Disables telemetry and consumer features via registry hives.
    - Optimizes for performance.
#>

# --- CONFIGURATION ---
$IsoSource = "D:\sources\install.wim"       # Path to your install.wim
$MountDir = "C:\Win11Mount"                 # Directory where WIM will be mounted
$ImageIndex = 6                            # Index of the edition (e.g., 6 is often Win 11 Pro)
$LogFile = "C:\Win11Customization.log"

# List of Appx packages to remove (Bloatware)
$BloatwareList = @(
    "*Microsoft.ZuneVideo*",
    "*Microsoft.ZuneMusic*",
    "*Microsoft.WindowsCommunicationsApps*",
    "*Microsoft.People*",
    "*Microsoft.BingNews*",
    "*Microsoft.BingWeather*",
    "*Microsoft.YourPhone*",
    "*Microsoft.GetHelp*",
    "*Microsoft.Getstarted*",
    "*Microsoft.MicrosoftSolitaireCollection*",
    "*Microsoft.WindowsFeedbackHub*",
    "*Microsoft.XboxGameOverlay*", # Keep XboxApp, remove Overlay
    "*Microsoft.XboxGamingOverlay*",
    "*Microsoft.WindowsAlarms*",
    "*Microsoft.WindowsMaps*"
)

function Write-Log {
    param([string]$Message)
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append
    Write-Host "[$Stamp] $Message"
}

# 1. Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit
}

# 2. Prepare Environment
if (!(Test-Path $MountDir)) { New-Item -Path $MountDir -ItemType Directory | Out-Null }
Write-Log "Starting customization for Image Index $ImageIndex..."

try {
    # 3. Mount the WIM Image
    Write-Log "Mounting Windows Image... (This may take several minutes)"
    dism /Mount-Image /ImageFile:$IsoSource /Index:$ImageIndex /MountDir:$MountDir

    # 4. Remove Bloatware (Provisioned Appx)
    Write-Log "Removing provisioned bloatware packages..."
    foreach ($App in $BloatwareList) {
        Write-Log "Removing $App..."
        Get-AppxProvisionedPackage -Path $MountDir | Where-Object { $_.PackageName -like $App } | Remove-AppxProvisionedPackage -Path $MountDir
    }

    # 5. Registry Tweaks (Offline Hive Loading)
    Write-Log "Applying gaming performance registry tweaks..."
    $SoftwareHive = "$MountDir\Windows\System32\config\SOFTWARE"
    $SystemHive = "$MountDir\Windows\System32\config\SYSTEM"

    # Load Software Hive
    reg load HKLM\OFFLINE_SOFTWARE $SoftwareHive
    
    # Disable Telemetry & Data Collection
    reg add "HKLM\OFFLINE_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
    # Disable "Consumer Experience" (stops automatic installation of suggested apps)
    reg add "HKLM\OFFLINE_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
    
    reg unload HKLM\OFFLINE_SOFTWARE

    # Load System Hive
    reg load HKLM\OFFLINE_SYSTEM $SystemHive
    # Set Power Plan to High Performance (Standard)
    reg add "HKLM\OFFLINE_SYSTEM\CurrentControlSet\Control\Power" /v HiPerf /t REG_DWORD /d 1 /f
    
    reg unload HKLM\OFFLINE_SYSTEM

    # 6. Finalize and Unmount
    Write-Log "Saving changes and unmounting image..."
    dism /Unmount-Image /MountDir:$MountDir /Commit

    Write-Log "SUCCESS: Custom Windows 11 Image created."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    # Ensure we try to unmount even on failure to prevent locking the WIM
    dism /Unmount-Image /MountDir:$MountDir /Discard
}
