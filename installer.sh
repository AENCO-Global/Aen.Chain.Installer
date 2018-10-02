#!/bin/bash

# Show variables used and defined throughout script
dump_variables() {
    echo "Installer Version: $INSTALLER_VERSION"
    if [[ $DEBUG_MODE = "true" ]]; then
      echo "Operating System: $OS"
      echo "Architecture: $ARCHITECTURE"
      echo "Image Name: $IMAGE_NAME"
      echo "Device Registration URL: $URL_DEVICE_REGISTRATION"
      echo "Docker Binary Path: $DOCKER_BINARY_PATH"
      echo "Device Profile: $DEVICE_PROFILE"
    fi
    echo "Device ID: $DEVICE_ID"
    echo "License Key: $LICENSE_KEY"
    echo "Data Path: $DATA_PATH"
    echo "Network Identifier: $NETWORK_IDENTIFIER"
    echo "Private Key: $PRIVATE_KEY"
    echo "Public Key: $PUBLIC_KEY"
    echo "Wallet Address: $ADDRESS"
    echo "Harvester Private Key: $HARVESTER_PRIVATE_KEY"
    echo "Harvester Public Key: $HARVESTER_PUBLIC_KEY"
    echo "Harvester Wallet Address: $HARVESTER_ADDRESS"
}

# Friendly stop
halt_installation() {
  echo ""
  echo "${red}===== INSTALLATION HALTED =====${reset}"
  echo ""
  echo $1
  echo ""
  dump_variables
  exit 1
}

# Check whether script is being run without any parameters and ask user to be sure
if [[ $# -eq 0 ]] ; then
    halt_installation "No parameters supplied. If you are sure you want to run with no options, use --useDefaults"
fi

INSTALLER_VERSION=0.2

logo() {
  echo << EOF "
  MMMMMMMMMMMMMMMMMMMIMMMMMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMMMMMIIIMMMMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMMMMIIIIIMMMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMMMMIIIIIMMMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMMMIIIIIIIMMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMMIIIIIIIIIMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMMIIIIIIIIIMMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMIIIIIIIIIIIMMMMMMMMMMMMMMM
  MMMMMMMMMMMMMMIIIIIIIIIIIDMMMMMMMMMMMMMM
  MMMMMMMMMMMMMIIII8MMMMIIIIMMMMMMMMMMMMMM
  MMMMMMMMMMMMIIIMMMMMMMMMDI7MMMMMMMMMMMMM
  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
  MMMMMMMMMIIMMMMMMMMMMMMMMMMMIIMMMMMMMMMM
  MMMMMM?IIIMMMMMMMMMMMMMMMMMMMIII7MMMMMMM
  MMMM7IIIIMMMMMMMMMD?IMMMMMMMMMIIIIIMMMMM
  MMIIIIIIMMMMMMMMM7???+MMMMMMMMMIIIIIIMMM
  IIIIIIIIMMMMMMMM???????MMMMMMMMIIIIIIII?
  MMIIIIIIMMMMMMM$????????MMMMMMMIIIIIIZMM
  MMMMIIIIIMMMMMN??????????MMMMMIIIIIMMMMM
  MMMMMMNIIIMMMN???7MMMO????MMMIII8MMMMMMM
  MMMMMMMMMIIMD?+MMMMMMMMM+?+MIIMMMMMMMMMM
  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
EOF
}

# Color modifiers
red=`tput setaf 1`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`

create_shortcut_request() {
  echo ""
  echo "A shortcut (in the form of an alias) can be created for you so that when"
  echo "you want to start up the Node again, you can by typing just 'aenchain'"

  if grep -q aenchain "$HOME_PATH/.profile"; then
    echo "${green}Shortcut already exists${reset}"
  else
    echo "Would you like this shortcut to be created for you? [Y/n]"
    read SHORTCUT_ANSWER
    SHORTCUT_ANSWER=$(echo "$SHORTCUT_ANSWER"|tr '/a-z/' '/A-Z/')
    if [ -z $SHORTCUT_ANSWER ];
    then
        SHORTCUT_ANSWER="Y"
    fi
    if [[ $SHORTCUT_ANSWER = "Y" ]]; then


      echo "alias aenchain='docker start aen.server'" >> $HOME_PATH/.profile
      echo "Node can now be started up by typing 'aenchain' in to terminal"
      source $HOME_PATH/.profile
    fi
  fi
}

run_node() {
  echo -ne "Startup Node"
  docker run -it -d --name aen.server -p 7900:7900 -p 7901:7901 -p 7902:7902 -p 3000:3000 -v $DATA_PATH/resources:/var/aen/resources -v $DATA_PATH/data:/var/aen aenco/master-node:latest &>/dev/null
  ok
}

ok() {
  echo " ${green}OK${reset}"
}
# Command help
display_usage() {
  echo "This script sets up your device as a Node on the AEN Chain network"
  echo ""
  echo "--- Basic Usage ---"
  echo ""
  echo " --dataPath          Output path for configuration and block data"
  echo " --licenseKey        Your AENCoin License key"
  echo " --networkIdentifier Key Used to identify the block chain network"
  echo " --deviceProfile     Type of node that we are setting up"
  echo " --useDefaults       Run the setup using default options"
  echo " --help              Display this message"
  echo ""
  echo "--- Advanced ---"
  echo ""
  echo " --registrationUrl   The endpoint the script will use to validate license"
  echo " --imageName         Use an alternative Docker image"
  echo " --dockerPath        Path within the container to expected binaries"
  echo " --bypassArch        Skip the operating system compatibility test"
  echo " --debug             Causes script to be more verbose about output"

  exit 1
}

DEBUG_MODE="false"
HOME_PATH=$HOME
DATA_PATH=$HOME/.local/aen
LICENSE_KEY="000000-000000-000000-000000-000000"
IMAGE_NAME="aenco/master-node:latest"

# Local Development
# URL_BASE="http://192.168.56.1:8080/api"
# Live
URL_BASE="http://configurator.aencoin.io"

URL_DEVICE_REGISTRATION="$URL_BASE/device/register"
URL_DEVICE_CONFIGURATION="$URL_BASE/device/###id###/configuration"
URL_DEVICE_DATA="$URL_BASE/device/###id###/data"

BYPASS_ARCH="false"
NETWORK_IDENTIFIER="public-test"
NETWORK_CONFIGURATION="public-test"
DEVICE_PROFILE="peer"
PRIVATE_KEY=""
PUBLIC_KEY=""
ADDRESS=""
HARVESTER_PRIVATE_KEY=""
HARVESTER_PUBLIC_KEY=""
HARVESTER_ADDRESS=""
TITLE="default_device"

# Script parameter assignemnt
while [ $# -gt 0 ]; do
  case "$1" in
    --help)
      display_usage
      ;;
    --dataPath=*)
      DATA_PATH="${1#*=}"
      ;;
    --useDefaults)
      echo "--- Running with default parameters ---"
      ;;
    --debugInfo)
      DEBUG_MODE="true"
      ;;
    --bypassArch)
      BYPASS_ARCH="true"
      ;;
    --licenseKey=*)
      LICENSE_KEY="${1#*=}"
      ;;
    --imageName=*)
      IMAGE_NAME="${1#*=}"
      ;;
    --registrationUrl=*)
      URL_DEVICE_REGISTRATION="${1#*=}"
      ;;
    --dockerPath=*)
      DOCKER_BINARY_PATH="${1#*=}"
      ;;
    --networkIdentifier=*)
      NETWORK_IDENTIFIER="${1#*=}"
      ;;
    --networkConfiguration=*)
      NETWORK_CONFIGURATION="${1#*=}"
      ;;
    --deviceSpec=*)
      DEVICE_SPEC="${1#*=}"
      ;;
    --title=*)
      TITLE="${1#*=}"
      ;;
    *)
      halt_installation "Unrecognized parameter used $1"
  esac
  shift
done

########################
# MAIN WORKFLOW BEGINS #
########################

# Show introduction
logo
echo "${green}--=== Aen Chain Install ($INSTALLER_VERSION) ===--${reset}"
echo ""



# Check if installation has already been done with local file check
if [ -f $DATA_PATH/device_id ]; then
  echo "${red}Device has already been configured${reset}"
  echo "Would you like to reset this device? [y/N]"
  read SHORTCUT_ANSWER
  SHORTCUT_ANSWER=$(echo "$SHORTCUT_ANSWER"|tr '/a-z/' '/A-Z/')
  if [ -z $SHORTCUT_ANSWER ];
  then
      SHORTCUT_ANSWER="N"
  fi
  if [[ $SHORTCUT_ANSWER = "Y" ]]; then
      rm -R $DATA_PATH/*
  else
    create_shortcut_request
    run_node
    exit
  fi

fi

# If using default parameters, remind user status of node installation
if [[ $LICENSE_KEY = "000000-000000-000000-000000-000000" ]]; then
  echo "${red}Starting up unlicensed node${reset}"
fi

echo -ne "Create paths"
mkdir -p $DATA_PATH &>/dev/null
if [ ! -d "$DATA_PATH" ]; then
  halt_installation "Could not create data path: $DATA_PATH"
fi
mkdir -p $DATA_PATH/data
mkdir -p $DATA_PATH/resources
ok

echo -ne "Check Architecture"
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
ok

# Check for required packages
echo -ne "Checking Dependencies"
case "$OS" in
  Ubuntu)
    PKGS="docker* curl sed"
    for pkg in $PKGS; do
        if dpkg-query -W -f'${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            echo -ne "."
        else
            halt_installation "Please install $pkg and rerun the installer"
        fi
    done
    ;;
  "Arch Linux")
    PKGS="docker curl sed"
    for pkg in $PKGS; do
        if pacman -Qs $pkg > /dev/null ; then
            echo -ne "."
        else
            halt_installation "Please install $pkg and rerun the installer"
        fi
    done
    ;;
  Cent*)
    PKGS="docker-ce curl sed lsof"
    for pkg in $PKGS; do
        if yum list installed $pkg > /dev/null 2>&1 ; then
            echo -ne "."
        else
            halt_installation "Please install $pkg and rerun the installer"
        fi
    done
    ;;
  *)
    if [[ $BYPASS_ARCH != "true" ]]; then
      halt_installation "$OS not officially support. At your own risk, rerun this script with the '--bypassArch' option to proceed"
    fi
    ;;
esac
ok

# Check whether ports are available
echo -ne "Checking Connectivity"
PORTS="7900 7901"
for port in $PORTS; do
  PORT_RESULT="$(lsof -i:${port})"
  if [ -z "$PORT_RESULT"]; then
    echo -ne "."
  else
    halt_installation "Port $port already in use"
  fi
done
ok

echo -ne "Download Runtime (200MB - Please be patient)"
docker pull ${IMAGE_NAME} > /dev/null 2>&1
if [ -z $(docker images -q ${IMAGE_NAME}) ]; then
  halt_installation "Could not download Docker image: $IMAGE_NAME"
fi
ok

echo -ne "Generate Personal address"
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
docker run -it ${IMAGE_NAME} ${DOCKER_BINARY_PATH}catapult.tools.address -g 1 -n ${NETWORK_IDENTIFIER} > /tmp/network_address
while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
  POSSIBLE_VALUE=$(echo "$LINE" | sed 's/.*\://' | xargs )
  if [[ "$LINE" =~ "private key"* ]]; then
    HARVESTER_PRIVATE_KEY="$POSSIBLE_VALUE"
  elif [[ "$LINE" =~ "public key"* ]];then
    HARVESTER_PUBLIC_KEY=$POSSIBLE_VALUE
  elif [[ "$LINE" =~ "address"* ]]; then
    HARVESTER_ADDRESS=$POSSIBLE_VALUE
  fi
done < /tmp/network_address
ok

echo -ne "Register Device with AEN"
CURL_REGISTER_STATUS=$(curl -k -s -w %{http_code} -o $DATA_PATH/register_log --request POST $URL_DEVICE_REGISTRATION \
  --data "blockchainAddress=$ADDRESS" \
  --data "title=$TITLE" \
  --data "licenseKey=$LICENSE_KEY" \
  --data "deviceSpec=$DEVICE_SPEC" \
  --data "blockchainPublicKey=$PUBLIC_KEY" \
  --data "networkConfiguration=$NETWORK_CONFIGURATION")

# If the output contains anything except ok as status, something went wrong
if [[ $CURL_REGISTER_STATUS != "200" ]]; then
  halt_installation ${CURL_REGISTER_OUTPUT}
fi

# Parse the device ID from output and store for possible future use
CURL_REGISTER_OUTPUT=$(cat $DATA_PATH/register_log)
DEVICE_ID=${CURL_REGISTER_OUTPUT##*:}
DEVICE_ID="$(echo $DEVICE_ID | sed 's/[^0-9A-Za-z_-]*//g')"
echo "$DEVICE_ID" > $DATA_PATH/device_id

# Get the configuration and data files for bootstrapping
URL_DEVICE_CONFIGURATION=$(sed -e "s/###id###/$DEVICE_ID/g" <<< $URL_DEVICE_CONFIGURATION)
curl -k -s -o $DATA_PATH/config.tar.gz --request GET $URL_DEVICE_CONFIGURATION
tar xf $DATA_PATH/config.tar.gz --directory $DATA_PATH/resources

URL_DEVICE_DATA=$(sed -e "s/###id###/$DEVICE_ID/g" <<< $URL_DEVICE_DATA)
curl -k -s -o $DATA_PATH/data.tar.gz --request GET $URL_DEVICE_DATA
tar xf $DATA_PATH/data.tar.gz --directory $DATA_PATH
ok

echo -ne "Personalise build with private keys"
# Find and replace private key details
sed -i "s/###USER_PRIVATE_KEY###/$PRIVATE_KEY/g" $DATA_PATH/resources/config-user.properties
if [ -e "$DATA_PATH/resources/config-harvesting.properties" ]; then
    sed -i "s/###HARVESTER_PRIVATE_KEY###/$HARVESTER_PRIVATE_KEY/g" $DATA_PATH/resources/config-harvesting.properties
fi
ok

create_shortcut_request
run_node

dump_variables > $DATA_PATH/installation.log
dump_variables
echo ""
echo "${green}=== Installation Complete ===${reset}"
echo ""
echo "A copy of the above parameters have been saved in to $DATA_PATH/installation.log"
echo "${red}The private keys used are only known on this device and you should keep them safe${reset}"
echo ""
echo "To see network activity, now run 'docker attach aen.server'."
echo "If you attach your terminal to session and close it, your node will shutdown"
echo ""
echo "For more information, please see our documentation at aencoin.io"
echo "- The Aenco Team"
