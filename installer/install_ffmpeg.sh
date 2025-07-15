#!/bin/bash

# --- FFmpeg (Static Build) Installation Script ---
# Installs a static build of FFmpeg, a complete, cross-platform solution to record, convert and stream audio and video.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/ffmpeg_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting FFmpeg installation."
log_to_file "FFmpeg installer started."

if command -v ffmpeg &>/dev/null; then
    say "FFmpeg appears to be installed already."
    log_to_file "FFmpeg command found, skipping installation."
else
    say "FFmpeg is not found. Downloading a static build. This may take a moment."
    log_to_file "Downloading FFmpeg static build from johnvansickle.com."
    
    # Using a known good source for static builds
    FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    
    curl -L -o ffmpeg.tar.xz "$FFMPEG_URL"
    log_to_file "Download complete. Extracting files."
    
    # Extract the archive
    tar -xf ffmpeg.tar.xz
    
    # The extracted folder name is dynamic, so we find it
    EXTRACTED_DIR=$(tar -tf ffmpeg.tar.xz | head -1 | cut -f1 -d"/")
    
    say "Installing FFmpeg and ffprobe to the local bin directory."
    log_to_file "Moving ffmpeg and ffprobe to /usr/local/bin."
    
    sudo mv "$EXTRACTED_DIR/ffmpeg" /usr/local/bin/
    sudo mv "$EXTRACTED_DIR/ffprobe" /usr/local/bin/
    
    log_to_file "Installation complete. Cleaning up downloaded files."
    # Clean up the downloaded archive and extracted folder
    rm -rf ffmpeg.tar.xz "$EXTRACTED_DIR"
    
    say "FFmpeg has been installed."
fi

say "FFmpeg installation is complete."
log_to_file "FFmpeg installer finished successfully."
