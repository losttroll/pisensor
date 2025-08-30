#!/bin/sh

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

##############################################################
### Copy over environmental variables from environment.txt ###
##############################################################

ENV_FILE="environment.txt"
SYSTEM_ENV="/etc/environment"
TMP_FILE="$(mktemp)"

# Ensure the source file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "File $ENV_FILE not found. Exiting."
    exit 1
fi

cp "$SYSTEM_ENV" "$TMP_FILE"

while IFS= read -r line; do
    # Skip empty lines or comments
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac

    key=$(echo "$line" | cut -d= -f1)

    if grep -q "^${key}=" "$TMP_FILE"; then
        echo "Updating $key"
        # Replace the line with the new definition
        sed -i "s|^${key}=.*|${line}|" "$TMP_FILE"
    else
        echo "Adding $key"
        echo "$line" >> "$TMP_FILE"
    fi
done < "$ENV_FILE"

# Overwrite the system environment file
cp "$TMP_FILE" "$SYSTEM_ENV"
rm "$TMP_FILE"

echo "Update complete."


# Update variables into current shell
while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    eval "export $line"
done < /etc/environment

. /etc/environment


#############################
#### Create run directory ###
#############################

# Make sure RUNUSER is defined
if [ -z "$RUNUSER" ]; then
    echo "RUNUSER is not set. Exiting."
    exit 1
fi

# Create the path
FULL_PATH="$MOTIONDIR/media"

echo "Creating $FULL_PATH..."
mkdir -p "$FULL_PATH"

# Set ownership
echo "Setting ownership to $RUNUSER:$RUNUSER"
chown -R "$RUNUSER:$RUNUSER" "$MOTIONDIR"

echo "Done."

##################################
### Install Dependent Software ###
##################################

# List of required packages
REQUIRED_PACKAGES="motion"

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt-get"
    UPDATE_CMD="apt-get update -y"
    INSTALL_CMD="apt-get install -y"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    UPDATE_CMD="dnf makecache"
    INSTALL_CMD="dnf install -y"
elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
    UPDATE_CMD="yum makecache"
    INSTALL_CMD="yum install -y"
else
    echo "No supported package manager found (apt, dnf, yum). Exiting."
    exit 1
fi

echo "Using package manager: $PKG_MGR"

# Update package index
echo "Updating package index..."
$UPDATE_CMD

# Install required packages
for pkg in $REQUIRED_PACKAGES; do
    echo "Checking for $pkg..."
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        $INSTALL_CMD "$pkg"
    else
        echo "$pkg is already installed."
    fi
done

echo "All required packages installed."

###########################################
### Fix Motion - Setup User for Logging ###
###########################################

echo "Ensuring log directory exists..."
mkdir -p "$LOG_DIR"

echo "Setting ownership to motion:motion..."
chown -R motion:motion "$LOG_DIR"

echo "Adding $RUN_AS_USER to motion group..."
usermod -aG motion "$RUN_AS_USER"

echo "Enabling motion service..."
systemctl enable motion

echo "Restarting motion service..."
systemctl restart motion

echo "Motion service is fixed and running."

##########################
### Download Web Files ###
##########################

URL="${CONFIGSERVER}${UNIQUEID}/"
DEST="$MOTIONDIR"

echo "Downloading files from $URL to $DEST ..."

# Ensure destination directory exists
mkdir -p "$DEST"

# Download files from open directory (recursive, overwrite existing)
wget -r -np -nH --cut-dirs=1 -P "$DEST" -N "$URL" -R "index.html*"

# Ensure correct ownership
chown -R "motion:motion" "$DEST"

echo "Download complete."

########################
### Install Cronjobs ###
########################

RUN_AS_USER="${RUNUSER:RUNUSER}"
CRON_FILE="${MOTIONDIR}/${UNIQUEID}/cron.txt"


# Check if cron file exists
if [ ! -f "$CRON_FILE" ]; then
    echo "Cron file $CRON_FILE not found. Exiting."
    exit 1
fi

echo "Installing cron jobs for user $RUN_AS_USER from $CRON_FILE..."

# Install crontab for user
crontab -u "$RUN_AS_USER" "$CRON_FILE"

echo "Crontab installed for $RUN_AS_USER."

# Show the new crontab
echo "Current crontab for $RUN_AS_USER:"
crontab -u "$RUN_AS_USER" -l
