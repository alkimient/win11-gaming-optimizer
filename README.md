# Windows 11 Gaming ISO Customizer

A professional PowerShell script to generate a minimal Windows 11 installation for maximum gaming performance by modifying the `install.wim` offline.

## 🚀 Features
- **Bloatware Removal**: Removes pre-installed provisioned Appx packages.
- **Telemetry Disable**: Kills data collection and reporting to reduce background CPU/Disk usage.
- **Consumer Experience Disable**: Prevents automatic installation of "suggested" apps.
- **Performance Tuning**: Sets power-related registry flags for high performance.
- **Offline Servicing**: Modifies the image before installation, ensuring a clean OS from boot.

## 🛠️ Requirements
- **Windows 11 ISO**: Mount the ISO or extract `sources\install.wim`.
- **Administrator Privileges**: Required for `DISM` and Registry hive loading.
- **Disk Space**: ~20GB free space for the mounting directory.

## 📖 Usage
1. **Configure Paths**: Open `optimize-win11.ps1` and update:
   - `$IsoSource`: Path to your `install.wim`.
   - `$MountDir`: Where you want the image mounted (e.g., `C:\Win11Mount`).
   - `$ImageIndex`: The index of your preferred edition (use `dism /Get-WimInfo /WimFile:path` to find the index for Pro/Home).
2. **Run as Admin**:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\optimize-win11.ps1
   ```
3. **Create Media**: Replace the `install.wim` in your ISO or USB source with the modified version.

## ⚠️ Warning
This script modifies system-level image files. Always keep a backup of your original `install.wim` before running.
