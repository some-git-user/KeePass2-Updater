# KeePass2 Updater

This Bash script automates the process of updating KeePass 2.x to the latest version. It checks the installed version, compares it with the latest release on SourceForge, and offers to update if a newer version is available.  
  
**_Root privileges are required._**

## Prerequisites

- Bash (Bourne Again SHell) is required to execute this script.
- The script uses `curl`, `wget`, and `unzip` commands, so ensure they are installed on your system.

## Installation

1. Open a terminal window.

2. Download the update script from this repository using `wget`:

    ```console
    wget https://raw.githubusercontent.com/some-git-user/KeePass2-Updater/main/update_keepass2.sh
    ```

3. Make the script executable with the following command:

    ```console
    chmod +x update_keepass2.sh
    ```

## Usage

1. Run the script:

```console
    sudo ./update_keepass2.sh
```

## Configuration

- The script is configured with the default name of the KeePass executable (KeePass.exe) and its configuration file (KeePass.exe.config).
- The SourceForge URL for KeePass 2.x releases is set as keepass2VersionURL.

## Automatic Installation

- If KeePass 2.x is not found on the system, the script prompts the user to install it using apt package manager (Debian/Ubuntu).

## Notes

- The script dynamically determines the installation directory of KeePass 2.x by searching for KeePass.exe in potential directories.
- It extracts the current installed version from the configuration file.
- Temporary files are created in the system's temporary folder during the update process and cleaned up afterward.

## Disclaimer

This script assumes a Debian/Ubuntu environment for package management and may need modifications for other distributions.
License

This script is provided under the MIT License. Feel free to modify and distribute it as needed.
