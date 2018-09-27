#!/bin/bash

INSTALLER_VERSION=0.1

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

logo() {
  echo << EOF
  .............................=..............................
  ............................===.............................
  ...........................=====............................
  ...........................=====............................
  ..........................=======...........................
  .........................=========..........................
  .........................=========..........................
  ........................===========.........................
  .......................=============........................
  .......................=============........................
  ......................===============.......................
  .....................,===============~......................
  .....................=================......................
  ....................=========.=========.....................
  ....................======:......======.....................
  ...................====~............====....................
  ...................=:..................=....................
  ............................................................
  ...............==.........................==................
  ............~===...........................===~.............
  ..........=====.............................=====...........
  .......,=======..............+=.............,======,........
  .....=========.............=++++.............=========......
  ...==========.............=++++++.............==========....
  ============.............+++++++++.............============.
  ~===========............+++++++++++............============.
  ...==========..........~++++++++++++..........==========~...
  .....=========........:+++++++++++++=........=========......
  .......,=======......~+++++++:+++++++=......~======:........
  ..........=====......+++++=.....:++++++.....=====...........
  .............===...:++++...........~+++~...===..............
  ...............==.+++.................+++.==................
  ............................................................
EOF

}
# Color modifiers
red=`tput setaf 1`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`

create_shortcut_request() {
  echo ""
  echo "Do you want to create an shortcut for running the Node[Y/n]"
  read SHORTCUT_ANSWER
  SHORTCUT_ANSWER=$(echo "$SHORTCUT_ANSWER"|tr '/a-z/' '/A-Z/')
  if [ -z $SHORTCUT_ANSWER ];
  then
      SHORTCUT_ANSWER="Y"
  fi
  if [[ $SHORTCUT_ANSWER = "Y" ]]; then
    echo "alias aenchain='docker run -it -d -p 7900:7900 -p 7901:7901 -p 7902:7902 -p 3000:3000 -v $DATA_PATH/config:/var/aen/resources -v $DATA_PATH/data:/var/aen/data aenco/master-node:latest'" >> $HOME_PATH/.profile
    echo "Node can now be started up by typing 'aenchain' in to terminal"
    source $HOME_PATH/.profile
  fi
}

run_node() {
  echo -ne "Startup Node"
  docker run -it -d -p 7900:7900 -p 7901:7901 -p 7902:7902 -p 3000:3000 -v $DATA_PATH/resources:/var/aen/resources -v $DATA_PATH/data:/var/aen aenco/master-node:latest &>/dev/null
  ok
}

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
    echo "Data Path: $DATA_PATH"
    echo "License Key: $LICENSE_KEY"
    echo "Network Identifier: $NETWORK_IDENTIFIER"
    echo "Private Key: $PRIVATE_KEY"
    echo "Public Key: $PUBLIC_KEY"
    echo "Wallet Address: $ADDRESS"
    echo "Harvester Private Key: $HARVESTER_PRIVATE_KEY"
    echo "Harvester Public Key: $HARVESTER_PUBLIC_KEY"
    echo "Harvester Wallet Address: $HARVESTER_ADDRESS"
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
LICENSE_KEY=""
IMAGE_NAME="aenco/master-node:latest"
URL_DEVICE_REGISTRATION="http://configurator.aencoin.io/device/register"
URL_DEVICE_CONFIGURATION="http://configurator.aencoin.io/device/###id###/configuration"
URL_DEVICE_DATA="http://configurator.aencoin.io/device/###id###/data"
BYPASS_ARCH="false"
DOCKER_BINARY_PATH="/usr/local/bin/"
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

if [[ $# -eq 0 ]] ; then
    halt_installation "No parameters supplied. If you are sure you want to run with no options, use --useDefaults"
fi

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

echo "${blue}--=== Aen Chain Install ($INSTALLER_VERSION) ===--${reset}"
logo
echo ""

if [ -f $DATA_PATH/device_id ]; then
  echo "${red}Device has already been configured, skipping installation${reset}"
  create_shortcut_request
  run_node
  exit
fi

if [[ $LICENSE_KEY = "000000-000000-000000-000000-000000" ]]; then
  echo "Starting up unlicensed node"
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
  ("Ubuntu")
    PKGS="docker* jq curl sed"
    for pkg in $PKGS; do
        if dpkg-query -W -f'${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            echo -ne "."
        else
            halt_installation "Please install $pkg and rerun the installer"
        fi
    done
    ;;
  ("Cent")
    if [[ $BYPASS_ARCH != "true" ]]; then
      halt_installation "CentOS is not currently officially supported and we cannot guarantee operation. If you would like to proceed, please relaunch the installer with the '--bypassArch' option"
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

echo -ne "Download Runtime"
docker pull ${IMAGE_NAME} 2>/dev/null
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
CURL_REGISTER_OUTPUT=$(curl -k -s --request POST $URL_DEVICE_REGISTRATION \
  --data "blockchainAddress=$ADDRESS" \
  --data "title=$TITLE" \
  --data "licenseKey=$LICENSE_KEY" \
  --data "deviceSpec=$DEVICE_SPEC" \
  --data "blockchainPublicKey=$PUBLIC_KEY" \
  --data "networkConfiguration=$NETWORK_CONFIGURATION")

DEVICE_ID=$( jq -r '.deviceId' <<< "${CURL_REGISTER_OUTPUT}" )
# Store the device ID in storage for future usage
echo "$DEVICE_ID" > $DATA_PATH/device_id

URL_DEVICE_CONFIGURATION=$(sed -e "s/###id###/$DEVICE_ID/g" <<< $URL_DEVICE_CONFIGURATION)
curl -k -s -o $DATA_PATH/resources/config.tar.gz --request GET $URL_DEVICE_CONFIGURATION
tar xf $DATA_PATH/resources/config.tar.gz --directory $DATA_PATH/resources

URL_DEVICE_DATA=$(sed -e "s/###id###/$DEVICE_ID/g" <<< $URL_DEVICE_DATA)
curl -k -s -o $DATA_PATH/data.tar.gz --request GET $URL_DEVICE_DATA
tar xf $DATA_PATH/data.tar.gz --directory $DATA_PATH/data
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
echo ""
echo "${blue}=== Installation Complete ===${reset}"
echo ""
echo "A copy of the following parameters have been saved in to $DATA_PATH/installation.log"
echo "${red}The private keys used are only known on this device and you should keep them safe${reset}"
echo ""
dump_variables
