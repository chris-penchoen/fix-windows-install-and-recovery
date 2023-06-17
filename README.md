# Fix Broken Windows Installation

This PowerShell script is designed to fix a broken Windows installation by performing several operations, including downloading a Windows Image (.wim) file, replacing the existing one in the recovery partition, and installing a list of specified apps.

## Detailed Breakdown

### Setting up the Environment

The script begins by setting the `$ErrorActionPreference` to "Stop". This is a built-in PowerShell variable that determines how the shell responds to a non-terminating error at the command line. By setting it to "Stop", the script is configured to halt execution whenever an error is encountered.

### Defining Variables

The script then defines several variables:

- `$storageBlobUrl`: This is the URL of the .wim file that will be downloaded. The .wim file is a Windows Image file, which is a file-based disk image format used by Windows.

- `$wimFileName`: The name of the .wim file.

- `$outputDir`: The directory where the .wim file will be saved after it's downloaded.

- `$appsToAdd`: An array of apps that will be installed once the .wim file has been mounted and the recovery partition has been prepared.

- `$logDirectory`, `$logFile`, and `$verboseLogFile`: These variables are used to set up logging for the script. The script will log errors and verbose messages to these files.

### Preparing the Log Files

The script checks if the log directory exists and creates it if it doesn't. It then checks if the log files exist and clears their content if they do.

### Downloading the .wim File

The script uses the `Invoke-WebRequest` cmdlet to download the .wim file from the `$storageBlobUrl` and save it to the `$outputDir` directory.

### Preparing the Recovery Partition

The script finds the recovery partition on the system and replaces the existing .wim file with the one that was downloaded. It does this by copying the .wim file to the recovery partition.

### Removing Registry Items

The script removes certain registry items related to deprovisioned apps. This is done to ensure that the new apps can be installed without any conflicts.

### Mounting the .wim File

The script mounts the .wim file to a temporary directory. This is done so that the script can access the files within the .wim file.

### Installing Apps

The script first installs the Microsoft Store app. It then iterates over the `$appsToAdd` array and installs each app. If the manifest for an app cannot be found, the script attempts to install the app from the Microsoft Store for all users.

### Unmounting the .wim File

After all the apps have been installed, the script unmounts the .wim file.

### Error Handling

The entire script is wrapped in a try-catch block. If any error occurs during the execution of the script, it is caught and logged to the error log file, and the script execution is stopped.

## Usage

To use this script, simply run it in a PowerShell environment. Ensure that you have the necessary permissions to perform actions such as downloading files, accessing the recovery partition, and installing apps.

Please note that the script is designed to stop if any error occurs. If you encounter any issues, check the error log file for more details.

## Requirements

- PowerShell
- Access to the internet to download the .wim file
- Necessary permissions to install apps and access the recovery partition

## Disclaimer

This script makes changes to the system's recovery partition and installs apps. Please use it with caution and ensure you understand
