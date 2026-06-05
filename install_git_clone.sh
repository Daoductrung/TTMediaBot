#!/bin/bash

# ================================================================= #
# Auto Installer & Cloner - TTMediaBot
# ================================================================= #

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo)."
  exit 1
fi

REPO_URL="https://github.com/daoductrung/TTMediaBot.git"
REPO_OWNER_NAME="daoductrung/TTMediaBot"

echo "--- Detecting Package Manager ---"
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="dnf install -y"
    PKG_UPDATE="dnf check-update"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    PKG_INSTALL="yum install -y"
    PKG_UPDATE="yum check-update"
elif command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    PKG_INSTALL="apt-get install -y"
    PKG_UPDATE="apt-get update"
else
    echo "Unsupported package manager. Please install git and unzip manually."
    exit 1
fi

echo "--- Checking for Git ---"
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    $PKG_UPDATE && $PKG_INSTALL git
else
    echo "Git is already installed."
fi

echo "--- Checking for unzip (ZIP extractor) ---"
if ! command -v unzip &> /dev/null; then
    echo "unzip not found. Installing..."
    $PKG_INSTALL unzip
else
    echo "unzip is already installed."
fi

# Detect if we are already inside the repository
if [ -d ".git" ] && git remote get-url origin 2>/dev/null | grep -q "TTMediaBot"; then
    echo "--- Already inside TTMediaBot repository. Skipping clone. ---"
    CURRENT_IS_REPO=true
else
    CURRENT_IS_REPO=false
fi

DIR_NAME="TTMediaBot"

if [ "$CURRENT_IS_REPO" = false ]; then
    if [ -d "$DIR_NAME" ]; then
        echo "Directory '$DIR_NAME' already exists. Updating..."
        cd "$DIR_NAME" || exit
        git pull
    else
        echo "--- Cloning Repository ---"
        if command -v gh &> /dev/null; then
            echo "gh CLI detected. Cloning using gh..."
            gh repo clone "$REPO_OWNER_NAME"
        else
            git clone "$REPO_URL"
        fi
        
        if [ $? -ne 0 ]; then
            echo "Error cloning repository. Check your internet connection."
            exit 1
        fi
        cd "$DIR_NAME" || exit
    fi
fi

# Enter directory and set permissions
# Set permissions and ownership
echo "--- Setting Permissions and Ownership ---"

REAL_USER=${SUDO_USER:-$USER}

# Ensure permissions are correct for the current folder and everything inside
chown -R "$REAL_USER":"$REAL_USER" .
chmod -R 777 .
chmod +x *.sh

echo "Ownership and permissions set for user: $REAL_USER"

echo "========================================="
echo "--- Checking TeamTalk_DLL ---"
echo "========================================="

DLL_URL="https://github.com/JoaoDEVWHADS/TTMediaBot/releases/download/downloadttdll/TeamTalk_DLL.zip"
DLL_FILE="TeamTalk_DLL.zip"

if [ -d "TeamTalk_DLL" ] && [ -f "TeamTalk_DLL/libTeamTalk5.so" ]; then
    echo "✅ TeamTalk_DLL folder and library already exist. Skipping download and extraction."
else
    if [ -f "$DLL_FILE" ]; then
        echo "📦 TeamTalk_DLL.zip already exists. Skipping download."
    else
        echo "📥 Downloading TeamTalk_DLL.zip..."
        wget "$DLL_URL" -O "$DLL_FILE"
        if [ $? -ne 0 ]; then
            echo "❌ Error downloading TeamTalk_DLL.zip."
            exit 1
        fi
        echo "✅ Download complete!"
    fi

    echo "--- Extracting TeamTalk_DLL.zip ---"
    unzip -o "$DLL_FILE"
    if [ $? -ne 0 ]; then
        echo "❌ Error extracting TeamTalk_DLL.zip."
        exit 1
    fi
    echo "✅ Extraction complete!"

    echo "--- Removing TeamTalk_DLL.zip ---"
    rm -f "$DLL_FILE"
    echo "✅ ZIP file removed."
fi

if [ ! -d "TeamTalk_DLL" ]; then
    echo "❌ ERROR: TeamTalk_DLL folder not found!"
    exit 1
fi
echo "✅ TeamTalk_DLL folder is ready!"

    
    echo "--- Setting permissions for TeamTalk_DLL ---"
    chown -R "$REAL_USER":"$REAL_USER" TeamTalk_DLL || true
    chmod -R 777 TeamTalk_DLL
    echo "Permissions set for TeamTalk_DLL folder."
    
    echo "========================================="
    echo "--- Final Verification ---"
    echo "========================================="
    
    ls -la | grep TeamTalk_DLL
    
    if [ -d "TeamTalk_DLL" ]; then
        echo "✅ All checks passed!"
        echo "✅ TeamTalk_DLL folder exists"
        echo "✅ Ownership and permissions are set"
        echo "========================================="
        echo "--- Checking Docker Installation ---"
        echo "========================================="

        if ! command -v docker &> /dev/null; then
            echo "Docker not found. Installing automatically..."
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [[ "$ID" == "almalinux" || "$ID" == "centos" || "$ID" == "rhel" || "$ID" == "rocky" ]]; then
                    echo "RedHat-based OS detected ($ID). Using dnf/yum..."
                    if command -v dnf &> /dev/null; then
                        dnf install -y dnf-plugins-core
                        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                    else
                        yum install -y yum-utils
                        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                    fi
                else
                    curl -fsSL https://get.docker.com | sh
                fi
            else
                curl -fsSL https://get.docker.com | sh
            fi
        else
            echo "Docker is already installed."
        fi

        echo "--- Ensuring Docker service is running ---"
        if command -v systemctl &> /dev/null; then
            systemctl enable docker
            systemctl start docker
        fi

        if command -v docker &> /dev/null && ! docker info &> /dev/null; then
            echo "--- Adding user to docker group ---"
            usermod -aG docker "$REAL_USER" || true
            echo "Please log out and log back in for docker group changes to take effect."
        fi

        echo "Docker is ready."
        echo "========================================="
        echo "Setup Complete! Starting Docker Manager..."
        echo "========================================="
        sleep 2

        if [ -f "./ttbotdocker.sh" ]; then
            chmod +x ./ttbotdocker.sh
            exec ./ttbotdocker.sh
        else
            echo "ERROR: ttbotdocker.sh not found!"
            exit 1
        fi
    else
        echo "ERROR: Verification failed. Please check manually."
        exit 1
    fi