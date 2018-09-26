#!/bin/bash

INSTALLER_VERSION=0.1
halt_installation() {
  echo ""
  echo "===== INSTALLATION HALTED ====="
  echo $1
  echo ""
  dump_variables
  exit 1
}

dump_variables() {
    echo "Installer Version: $INSTALLER_VERSION"
    echo "Operating System: $OS"
    echo "Architecture: $ARCHITECTURE"
    echo "Data Path: $DATA_PATH"
    echo "License Key: $LICENSE_KEY"
    echo "Image Name: $IMAGE_NAME"
    echo "Device Registration URL: $URL_DEVICE_REGISTRATION"
    echo "Docker Binary Path: $DOCKER_BINARY_PATH"
    echo "Network Identifier: $NETWORK_IDENTIFIER"
    echo "Device Profile: $DEVICE_PROFILE"
    echo "Private Key: $PRIVATE_KEY"
    echo "Public Key: $PUBLIC_KEY"
    echo "Wallet Address: $ADDRESS"
}

display_usage() {
  echo "This script sets up your device as a Node on the AEN Chain network"
  echo ""
  echo "--- Basic Usage"
  echo ""
  echo " -p, --dataPath          Output path for configuration and block data"
  echo " -l, --licenseKey        Your AENCoin License key"
  echo " -n, --networkIdentifier Key Used to identify the block chain network"
  echo " -d, --deviceProfile     Type of node that we are setting up"
  echo " --useDefaults           Run the setup using default options"
  echo " --help                  Display this message"
  echo ""
  echo "--- Advanced ---"
  echo ""
  echo " -u, --registrationUrl   The endpoint the script will use to validate license"
  echo " -i, --imageName         Use an alternative Docker image"
  echo " -b, --dockerPath        Path within the container to expected binaries"

  exit 1
}

HOME_PATH=$HOME
DATA_PATH=$HOME/.local/aen
LICENSE_KEY=""
IMAGE_NAME="aenco/master-node:latest"
URL_DEVICE_REGISTRATION="http://localhost:8080/device/register"
URL_DEVICE_CONFIGURATION="http://localhost:8080/device/###id###/configuration"
URL_DEVICE_DATA="http://localhost:8080/device/###id###/data"
DOCKER_BINARY_PATH="/usr/local/bin/"
NETWORK_IDENTIFIER="public-test"
NETWORK_CONFIGURATION="public-test"
DEVICE_PROFILE="peer"
PRIVATE_KEY=""
PUBLIC_KEY=""
ADDRESS=""
TITLE="default_device"

if [[ $# -eq 0 ]] ; then
    halt_installation "No parameters supplied. If you are sure you want to run with no options, use --useDefaults"
fi

# Script parameter assignemnt
while [ $# -gt 0 ]; do
  case "$1" in
    --help)
      display_usage
      ;;
    --dataPath|-p=*)
      DATA_PATH="${1#*=}"
      ;;
    --useDefaults)
      echo "--- Running with default parameters ---"
      ;;
    --licenseKey=*)
      LICENSE_KEY="${1#*=}"
      ;;
    --imageName|-i=*)
      IMAGE_NAME="${1#*=}"
      ;;
    --registrationUrl|-u=*)
      URL_DEVICE_REGISTRATION="${1#*=}"
      ;;
    --dockerPath|-b=*)
      DOCKER_BINARY_PATH="${1#*=}"
      ;;
    --networkIdentifier|-n=*)
      NETWORK_IDENTIFIER="${1#*=}"
      ;;
    --networkConfiguration=*)
      NETWORK_CONFIGURATION="${1#*=}"
      ;;
    --deviceSpec|-d=*)
      DEVICE_SPEC="${1#*=}"
      ;;
    --title|-t=*)
      TITLE="${1#*=}"
      ;;
    *)
      halt_installation "Unrecognized parameter used $1"
  esac
  shift
done

echo "--=== Aen Chain Install ($INSTALLER_VERSION) ===--"

if [[ $LICENSE_KEY = "000000-000000-000000-000000-000000" ]]; then
  echo "Starting up unlicensed node"
fi

if [ ! -d "$DATA_PATH" ]; then
  mkdir -p $DATA_PATH &>/dev/null
  echo $DATA_PATH
  if [ ! -d "$DATA_PATH" ]; then
    halt_installation "Could not create data path: $DATA_PATH"
  fi
  mkdir -p $DATA_PATH/data
  mkdir -p $DATA_PATH/config
fi


if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

ARCHITECTURE=$(uname -m)

# Check architecture is compatible
if [[ $ARCHITECTURE != "x86_64" ]]; then
  halt_installation "Incompatible architecture detected"
fi

# Check for required packages
echo "=== Checking Package Dependencies ==="
case "$OS" in
  ("Ubuntu")
    echo 'Using Ubuntu'
    PKGS="docker* jq curl"
    for pkg in $PKGS; do
        if dpkg-query -W -f'${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            echo "$pkg detected"
        else
            halt_installation "Please install $pkg and rerun the installer"
        fi
    done
    ;;
  ("Cent")
    echo 'Using CentOS'
    ;;
esac

# Check whether ports are available
echo "=== Checking Port Availability ==="
PORTS="7900 7901"
for port in $PORTS; do
  PORT_RESULT="$(lsof -i:${port})"
  if [ -z "$PORT_RESULT"]; then
    echo "Port $port available"
  else
    halt_installation "Port $port already in use"
  fi
done

echo "=== Fetching runtime ==="
# docker pull ${IMAGE_NAME} 2>/dev/null
if [ -z $(docker images -q ${IMAGE_NAME}) ]; then
  halt_installation "Could not download Docker image: $IMAGE_NAME"
fi

echo "=== Generating an address ==="
docker run -it ${IMAGE_NAME} ${DOCKER_BINARY_PATH}catapult.tools.address -g 1 -n ${NETWORK_IDENTIFIER} > /tmp/network_address
while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
  POSSIBLE_VALUE=$(echo "$LINE" | sed 's/.*\://' | xargs )
  if [[ "$LINE" =~ "private key"* ]]; then
    PRIVATE_KEY="$POSSIBLE_VALUE"
  elif [[ "$LINE" =~ "public key"* ]];then
    PUBLIC_KEY=$POSSIBLE_VALUE
  elif [[ "$LINE" =~ "address"* ]]; then
    ADDRESS=$POSSIBLE_VALUE
  fi
done < /tmp/network_address

echo "=== Register the node ==="

OUTPUT_PATH=$DATA_PATH/config.tar

CURL_REGISTER_OUTPUT=$(curl -k -s --request POST $URL_DEVICE_REGISTRATION \
  --data "blockchainAddress=$ADDRESS" \
  --data "title=$TITLE" \
  --data "licenseKey=$LICENSE_KEY" \
  --data "deviceSpec=$DEVICE_SPEC" \
  --data "blockchainPublicKey=$PUBLIC_KEY" \
  --data "networkConfiguration=$NETWORK_CONFIGURATION")

echo $CURL_REGISTER_OUTPUT
DEVICE_ID=$( jq '.deviceId' <<< "${CURL_REGISTER_OUTPUT}" )
echo "Device ID: $DEVICE_ID"

URL_DEVICE_CONFIGURATION=$(sed -e "s/###id###/$DEVICE_ID/g" <<< $URL_DEVICE_CONFIGURATION)
echo "Downloading configuration from: $URL_DEVICE_CONFIGURATION"
curl -k -s -o $DATA_PATH/config.tar.gz --request GET $URL_DEVICE_CONFIGURATION
tar xf $DATA_PATH/config.tar.gz --directory $DATA_PATH/config

URL_DEVICE_DATA=$(sed -e "s/###id###/$DEVICE_ID/g" <<< $URL_DEVICE_DATA)
echo "Downloading initial network data from: $URL_DEVICE_DATA"
curl -k -s -o $DATA_PATH/data.tar.gz --request GET $URL_DEVICE_DATA
tar xf $DATA_PATH/data.tar.gz --directory $DATA_PATH/data

#
# # TODO Implement this
# # echo -n "Do you want to create a shortcut [Y/n]: (Currently inoperable)"
# # read SHORTCUT_ANSWER
# # if [ $SHORTCUT_ANSWER = "Y"]; then
# #   echo 'Creating a shortcut'
# # fi
#
# echo "=== Starting up Network Node ==="
# # TODO Edit this run command once Docker image updated
# docker run -it -d -v $DATA_PATH/config:/var/aen/config -v $DATA_PATH/data:/var/aen/data aenco/master-node:latest /var/app/src/_build/bin/aen.server /var/aen/config

echo "=== Installation Complete"
# docker ps
dump_variables
