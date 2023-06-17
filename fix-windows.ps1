$ErrorActionPreference = "Stop"
$storageBlobUrl = "storage-blob-path-to-install.wim"
$wimFileName = "install.wim"
$outputDir = "C:\Temp"
$appsToAdd = @(
    "AppUp.IntelGraphicsExperience",
    "Clipchamp.Clipchamp",
    "DolbyLaboratories.DolbyAccess",
    "E046963F.LenovoSettingsforEnterprise",
    "ELANMicroelectronicsCorpo.ELANTrackPointforThinkpa",
    "Microsoft.549981C3F5F10",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.CompanyPortal",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.HEIFImageExtension",
    "Microsoft.HEVCVideoExtension",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.Paint",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.RawImageExtension",
    "Microsoft.ScreenSketch",
    "Microsoft.SecHealthUI",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Todos",
    "Microsoft.VP9VideoExtensions",
    "Microsoft.WebMediaExtensions",
    "Microsoft.WebpImageExtension",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsNotepad",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.WindowsStore",
    "Microsoft.WindowsTerminal",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "MicrosoftCorporationII.QuickAssist",
    "MicrosoftWindows.Client.WebExperience",
    "RealtekSemiconductorCorp.RealtekAudioControl",
    "SynapticsIncorporated.SynapticsUtilities"
)

$logDirectory = Join-Path $env:APPDATA "fixWindowsInstall"
$logFile = Join-Path $logDirectory "error.log"
$verboseLogFile = Join-Path $logDirectory "verbose.log"

try {
    # Create log directory if it doesn't exist
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }

    # Clear previous log files if they exist
    if (Test-Path $logFile) {
        Clear-Content -Path $logFile | Out-Null
    }
    if (Test-Path $verboseLogFile) {
        Clear-Content -Path $verboseLogFile | Out-Null
    }

    # Function to log errors to the file
    function Write-ErrorLog {
        param([string]$ErrorMessage)
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogEntry = "[$Timestamp] ERROR: $ErrorMessage"
        Add-Content -Path $logFile -Value $LogEntry
    }

    # Function to log verbose messages to the file
    function Write-VerboseLog {
        param([string]$Message)
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogEntry = "[$Timestamp] VERBOSE: $Message"
        Add-Content -Path $verboseLogFile -Value $LogEntry
    }

    # Create the output directory if it doesn't exist
    if (!(Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    # Download the WIM file from Azure Storage using the SAS token
    Write-Host "Downloading the WIM file..."
    Write-VerboseLog "Downloading the WIM file..."
    Invoke-WebRequest -Uri $storageBlobUrl -OutFile "$outputDir\$wimFileName" -UseBasicParsing

    # Replace the existing WIM file in the recovery partition
    Write-Host "Copying the WIM file to the recovery partition..."
    Write-VerboseLog "Copying the WIM file to the recovery partition..."
    $recoveryPartition = Get-Partition | Where-Object { $_.Type -eq 'de94bba4-06d1-4d40-a16a-bfd50179d6ac' }
    if ($null -eq $recoveryPartition) {
        throw "Could not find the recovery partition."
    }
    $recoveryDriveLetter = ($recoveryPartition | Get-Volume).DriveLetter
    $recoveryDrive = "${recoveryDriveLetter}:"

    Copy-Item -Path "$outputDir\$wimFileName" -Destination "$recoveryDrive\Recovery\WindowsRE\$wimFileName" -Force

    # Remove registry items
    Write-Host "Removing registry items..."
    Write-VerboseLog "Removing registry items..."
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\DeprovisionedApps" -Recurse -Force

    # Mount the WIM
    $mountPath = "C:\Temp\WIM"
    $imagePath = "$recoveryDrive\Recovery\WindowsRE\$wimFileName"
    $imageIndex = 1
    DISM /Mount-Wim /WimFile:$imagePath /Index:$imageIndex /MountDir:$mountPath

    # Install the Microsoft Store app
    Write-Host "Installing the Microsoft Store app..."
    Write-VerboseLog "Installing the Microsoft Store app..."
    $storeAppFolder = (Get-ChildItem "$mountPath\Program Files\WindowsApps" -Filter Microsoft.WindowsStore* -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1).FullName
    $manifestPath = "$storeAppFolder\AppxManifest.xml"
    Add-AppxPackage -Path $manifestPath -ErrorAction Stop

    # Install the remaining apps
    foreach ($app in $appsToAdd) {
        $appFolder = (Get-ChildItem "$mountPath\Program Files\WindowsApps" -Filter $app* -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1).FullName
        $manifestPath = "$appFolder\AppxManifest.xml"

        if (Test-Path $manifestPath) {
            Write-Host "Installing $app..."
            Write-VerboseLog "Installing $app..."
            Add-AppxPackage -Path $manifestPath -ErrorAction Stop
        }
        else {
            Write-Host "Cannot find the manifest for $app. Attempting to install from the Microsoft Store for all users..."
            Write-VerboseLog "Cannot find the manifest for $app. Attempting to install from the Microsoft Store for all users..."
            Add-AppxPackage -AllUsers -Online -Name $app -ErrorAction SilentlyContinue
        }
    }

    # Unmount the WIM
    Write-Host "Unmounting the WIM..."
    Write-VerboseLog "Unmounting the WIM..."
    DISM /Unmount-Wim /MountDir:$mountPath /Commit

    Write-Host "Script execution completed successfully."
    Write-VerboseLog "Script execution completed successfully."
}
catch {
    $errorMessage = $_.Exception.Message
    Write-ErrorLog -ErrorMessage $errorMessage
    Write-Host "An error occurred: $errorMessage"
    exit 1
}
