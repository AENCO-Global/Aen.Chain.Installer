#!/bin/bash
echo "--=== Incoming Paramters (This script hould be reusable) ===--"
echo "[P1] Version Number is :$1 "
echo "[P2] Target Server is :$2 "
echo "[P3] Target Folder is :$3 "
echo "-------------------------------------------"

echo "----==== Identify the target server =====---"
ssh -p 22 $2 "sudo /home/ubuntu/role.sh"
ssh -p 22 $2 "sudo whoami"
echo "-------------------------------------------"

echo "---=== Run local Tests on Deployment ===---"
echo "No tests yet Defined"
echo "-------------------------------------------"

echo "--=== Modify Version Information ===--"
# Change the version number
if [ -e "installer.sh" ]; then
    sed -i "s/###INSTALLER_VERSION###/$1/g" installer.sh
fi
echo "-------------------------------------------"

# Replace the URL with live version

echo "--=== Transfer files to Remote Server ===--"
echo "scp installer.sh jenkins@$2:$3/installer.sh"
scp installer.sh jenkins@$2:$3/installer.sh
echo "-------------------------------------------"

echo "----====== Verify Deployments-List from Remote ======----"
ssh -p 22 $2 "ls -al $3"
echo "---------------------------------------------------------"

echo "------------The-End-------------------------------------------------------"
