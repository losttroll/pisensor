#!/bin/sh

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

### Copy over environmental variables from environment.txt

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


#Create run directory

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
