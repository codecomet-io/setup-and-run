#!/usr/bin/env bash
# Based on https://github.com/CircleCI-Public/github-cli-orb/blob/main/src/scripts/install.sh
set_sudo() {
    if [[ $EUID == 0 ]]; then
        echo ""
    else
        echo "sudo"
    fi
}

# Function to check if a version is greater than or equal to a given version
version_ge() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

# Function to check if a version is less than or equal to a given version
version_le() {
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"
}

detect_platform() {
    case "$(uname -s)-$(uname -m)" in
    "Linux-x86_64") echo "linux-x86_64" ;;
    "Darwin-x86_64") echo "osx-universal" ;;
    "Darwin-arm64") echo "osx-universal" ;;
    # "Linux-aarch64") echo "linux-arm64" ;;
    *) echo "unsupported" ;;
    esac
}

download_cc_cli() {
    local version=$1
    local platform=$2
    local file_extension=$3
    local download_url="https://github.com/codecomet-io/cli/releases/download/v${version}/codecomet-v${version}-${platform}.${file_extension}"
    echo "Downloading the CodeComet CLI from \"$download_url\"..."

    if ! curl -sSL "$download_url" -o "cc-cli.$file_extension"; then
        echo "Failed to download CodeComet CLI from $download_url" >&2
        return 1
    fi
}

install_cc_cli() {
    local platform=$1
    local file_extension=$2
    local file_path="cc-cli.$file_extension"

    if [ ! -f "$file_path" ]; then
        echo "Downloaded file $file_path does not exist." >&2
        return 1
    fi

    echo "Installing the CodeComet CLI..."
    set -x; $sudo unzip -d /usr/local/bin ./"$file_path" ; set +x

}

sudo=$(set_sudo)

# Check for required commands
for cmd in curl unzip; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is required. Please install it and try again." >&2
        exit 1
    fi
done

# Verify if the CLI is already installed. Exit if it is.
if command -v codecomet >/dev/null 2>&1; then
    echo "CodeComet CLI is already installed."
    exit 0
fi

version=$1

platform=$(detect_platform)
if [ "$platform" == "unsupported" ]; then
    echo "$(uname -a)-$(uname -m) is not supported. If you believe it should be, please consider opening an issue."
    exit 1
fi

file_extension="zip"

# Download and install CodeComet CLI
if ! download_cc_cli "$version" "$platform" "$file_extension"; then
    echo "Failed to download the CodeComet CLI."
    exit 1
fi

if ! install_cc_cli "$platform" "$file_extension"; then
    echo "Failed to install the CodeComet CLI."
    exit 1
fi

# Clean up
if ! rm "cc-cli.$file_extension"; then
    echo "Failed to remove the downloaded file."
fi

# Verify installation
if ! command -v codecomet >/dev/null 2>&1; then
    echo "Something went wrong installing the CodeComet CLI. Please try again or open an issue."
    exit 1
else
    codecomet -h
fi