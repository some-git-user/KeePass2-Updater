#!/bin/bash

# Define the name of the KeePass executable file (including the extension).
keepass2Exe="KeePass.exe"

# Use the same variable for the KeePass configuration file name by appending ".config".
keepass2Config="${keepass2Exe}.config"

# Define the keepass2 command
keepass2Command="keepass2"

# URL to the SourceForge page containing the releases of KeePass 2.x
keepass2VersionURL="https://sourceforge.net/projects/keepass/files/KeePass%202.x/"

# Raw URL template for downloading the KeePass 2.x zip file, with a placeholder for the version
keepass2DownloadURLRaw="$keepass2VersionURL!VERSION!/KeePass-!VERSION!.zip/download"

# Fetch newest Keepass2 version
newKeepass2Version=$(curl -s "$keepass2VersionURL" | grep -A 100 '<table id="files_list">' | grep -oE '<tr title="([^"]+)"' | sed -n '1{p;q}' | cut -d '"' -f 2)

# Determine the keepass2TargetDir dynamically using the output of whereis
potentialDirs=($(whereis "$keepass2Command" | awk '{for(i=2; i<=NF; ++i) print $i}'))

# Check each potential directory for validity and the presence of KeePass.exe
keepass2TargetDir=""
for dir in "${potentialDirs[@]}"; do
  if [ -d "$dir" ] && [ -e "$dir/$keepass2Exe" ]; then
    keepass2TargetDir="$dir"
    break
  fi
done

# Extract the current installed version from the configuration file
currentKeepass2Version=$(grep -Po '(?<=newVersion=")[^"]*' "$keepass2TargetDir/$keepass2Config")

# Check if a valid directory is found
if [ -z "$keepass2TargetDir" ]; then
  echo "Error: Unable to determine a valid directory for KeePass2. Please check your installation."
  exit 1
fi

# Function to check command execution
check_command() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Aborting."
    cleanup
    exit 1
  fi
}

# Function to check for root access
check_root_access() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script requires superuser (root) privileges. Aborting."
    cleanup
    exit 1
  fi
}

# Function to clean up temporary directory
cleanup() {
    if [ -n "$tmpDir" ] && [ -d "$tmpDir" ]; then
        rm -rf "$tmpDir"
        if [ $? -eq 0 ]; then
            echo "Temporary directory '$tmpDir' has been cleaned up."
        else
            echo "Error: Failed to clean up temporary directory '$tmpDir'. Please remove it manually."
        fi
    fi
}

# Function to install KeePass2 using apt
install_keepass2() {
  read -p "KeePass2 is not found. Do you want to install it now? (yes/y/no/n): " install_answer
  install_answer="${install_answer,,}"
  
  # Check if apt is available
  if command -v apt &> /dev/null; then
    if [[ "$install_answer" == "yes" || "$install_answer" == "y" ]]; then
      apt update
      apt install -y "$keepass2Command"
    else
      echo "User chose not to install KeePass2. Exiting."
      cleanup
      exit 0
    fi
  else
    echo "Error: 'apt' command not found. Unable to install KeePass2. Please install it manually."
    cleanup
    exit 1
  fi
}

# Check for root access
check_root_access

# Check if keepass2 is present
if [ -z "$keepass2TargetDir" ]; then
    install_keepass2
fi

# Create a temporary directory in the system's temporary folder
tmpDir=$(mktemp -d)
cd "$tmpDir" || (echo "Error: Unable to change to temporary directory. Aborting." && exit 1)

# Check if the directory exists
if [ ! -d "$keepass2TargetDir" ]; then
  echo "Error: The directory '$keepass2TargetDir' does not exist."
  exit 1
fi

# Check if unzip, wget, and curl are available
for command_name in unzip wget curl; do
  if ! command -v "$command_name" &> /dev/null; then
    echo "Error: '$command_name' command not found."
    exit 1
  fi
done

# Create and use a temporary directory
mkdir -p "$tmpDir" || (echo "Error: Unable to create temporary directory. Aborting." && exit 1)
cd "$tmpDir" || (echo "Error: Unable to change to temporary directory. Aborting." && exit 1)

# Check if the version is determined
if [ -z "$newKeepass2Version" ]; then
  echo "Error: Could not determine the newest Keepass2 version"
  cleanup
  exit 1
fi

# Compare the versions
if [[ "$(printf '%s\n' "$currentKeepass2Version" "$newKeepass2Version" | sort -V | head -n1)" != "$newKeepass2Version" ]]; then
    echo "The current installed version ($currentKeepass2Version) is lower than the desired version ($newKeepass2Version)."
else
    echo "The current installed version is up to date."
fi

# Prompt user for confirmation
read -p "Do you want to proceed with updating to Keepass2 version $newKeepass2Version? (yes/y/no/n): " answer
answer="${answer,,}"

# Check the user's response
if [[ "$answer" != "yes" && "$answer" != "y" ]]; then
  echo "User chose not to proceed. Exiting."
  cleanup
  exit 0
fi

# Download the newest Keepass2 version
keepass2DownloadURL="${keepass2DownloadURLRaw//!VERSION!/$newKeepass2Version}"
wget -q --show-progress -O "KeePass-$newKeepass2Version.zip" "$keepass2DownloadURL"
check_command "Downloading the newest Keepass2 version"

# Unzip and update to the newest Keepass2 version
unzip -p "KeePass-$newKeepass2Version.zip" "$keepass2Exe" > "$keepass2Exe" &&
unzip -p "KeePass-$newKeepass2Version.zip" "$keepass2Config" > "$keepass2Config"
check_command "Unzipping and updating to the newest Keepass2 version"

# Move files to the target directory
cp -f "$keepass2Exe" "$keepass2TargetDir/$keepass2Exe" &&
cp -f "$keepass2Config" "$keepass2TargetDir/$keepass2Config"
check_command "Moving files to the target directory"

# Set permissions for the moved files
chown root:root "$keepass2TargetDir/$keepass2Exe" &&
chown root:root "$keepass2TargetDir/$keepass2Config" &&
chmod 755 "$keepass2TargetDir/$keepass2Exe" &&
chmod 644 "$keepass2TargetDir/$keepass2Config"
check_command "Setting permissions for the moved files"

# Cleanup temporary files
cleanup

# Success message
echo "Update of KeePass $newKeepass2Version was successful."
