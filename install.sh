#!/usr/bin/env bash
set -euo pipefail

REPO="Rommel96/lako-releases"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${1:-latest}"

echo "=========================================================="
echo "   Lako Configuration Platform Installer (Unix)           "
echo "=========================================================="

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${ARCH}" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;;
esac

ASSET_PATTERN="*${OS}-${ARCH}.tar.gz"
echo "-> Detected System: ${OS} (${ARCH})"
echo "-> Target Installation Directory: ${INSTALL_DIR}"

mkdir -p "${INSTALL_DIR}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

DOWNLOADED=false
ARCHIVE="${TMP_DIR}/lako.tar.gz"

# 1. Direct download from GitHub Releases (no gh CLI or token required)
TAG="${VERSION}"
if [ "${TAG}" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/lako-v1.0.0-${OS}-${ARCH}.tar.gz"
else
    case "${TAG}" in
        v*) ;;
        *) TAG="v${TAG}" ;;
    esac
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${TAG}/lako-${TAG}-${OS}-${ARCH}.tar.gz"
fi

echo "-> Downloading Lako for ${OS}-${ARCH} from GitHub Releases..."
if curl -fsSL "${DOWNLOAD_URL}" -o "${ARCHIVE}" 2>/dev/null && [ -s "${ARCHIVE}" ]; then
    DOWNLOADED=true
else
    echo "   (Direct download unavailable, trying fallback methods...)"
fi

# 2. Fallback: GitHub CLI (gh) if installed
if [ "${DOWNLOADED}" = "false" ] && command -v gh >/dev/null 2>&1; then
    echo "-> Downloading release using GitHub CLI (gh)..."
    if [ "${VERSION}" = "latest" ]; then
        gh release download --repo "${REPO}" --pattern "${ASSET_PATTERN}" --dir "${TMP_DIR}" --clobber 2>/dev/null || true
    else
        gh release download "${VERSION}" --repo "${REPO}" --pattern "${ASSET_PATTERN}" --dir "${TMP_DIR}" --clobber 2>/dev/null || true
    fi
    MATCHED="$(find "${TMP_DIR}" -name "*.tar.gz" ! -name "lako.tar.gz" | head -n 1)"
    if [ -n "${MATCHED}" ] && [ -f "${MATCHED}" ]; then
        ARCHIVE="${MATCHED}"
        DOWNLOADED=true
    fi
fi

# 3. Fallback: GitHub API with Token
if [ "${DOWNLOADED}" = "false" ]; then
    TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
    if [ -n "${TOKEN}" ]; then
        echo "-> Querying GitHub API with token..."
        if [ "${VERSION}" = "latest" ]; then
            API_URL="https://api.github.com/repos/${REPO}/releases/latest"
        else
            API_URL="https://api.github.com/repos/${REPO}/releases/tags/${VERSION}"
        fi

        RELEASE_JSON="$(curl -sSL -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github.v3+json" "${API_URL}")"
        ASSET_URL="$(echo "${RELEASE_JSON}" | grep -o '"url": "[^"]*"' | grep 'assets' | head -n 1 | cut -d'"' -f4 || true)"

        if [ -n "${ASSET_URL}" ]; then
            echo "-> Downloading binary archive..."
            if curl -sSL -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/octet-stream" "${ASSET_URL}" -o "${ARCHIVE}" && [ -s "${ARCHIVE}" ]; then
                DOWNLOADED=true
            fi
        fi
    fi
fi

if [ "${DOWNLOADED}" = "false" ]; then
    echo "Error: Failed to download Lako release. Please check your internet connection or visit https://github.com/${REPO}/releases."
    exit 1
fi

# 4. Extract and Install
echo "-> Extracting package..."
tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"
EXTRACTED_BIN="$(find "${TMP_DIR}" -name "lako" -type f | head -n 1)"
cp "${EXTRACTED_BIN}" "${INSTALL_DIR}/lako"
chmod +x "${INSTALL_DIR}/lako"

# Configure portable directory ~/.lako if needed
LAKO_HOME="${HOME}/.lako"
mkdir -p "${LAKO_HOME}"
MANIFEST_FILE="$(find "${TMP_DIR}" -name "manifest.json" -type f | head -n 1 || true)"
if [ -n "${MANIFEST_FILE}" ] && [ ! -f "${LAKO_HOME}/manifest.json" ]; then
    cp "${MANIFEST_FILE}" "${LAKO_HOME}/"
fi
PROFILES_DIR="$(find "${TMP_DIR}" -name "profiles" -type d | head -n 1 || true)"
if [ -n "${PROFILES_DIR}" ] && [ ! -d "${LAKO_HOME}/profiles" ]; then
    cp -r "${PROFILES_DIR}" "${LAKO_HOME}/"
fi

echo ""
echo "=========================================================="
echo "  ✅ Lako Configuration Platform installed successfully! "
echo "=========================================================="
echo "Binary installed at: ${INSTALL_DIR}/lako"
"${INSTALL_DIR}/lako" version || true
echo ""
echo "Ensure '${INSTALL_DIR}' is in your PATH:"
echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
echo ""
echo "To launch the UI server:"
echo "  lako ui --port 8080"
echo "=========================================================="
