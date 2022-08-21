#!/bin/bash
# Name:         init
# Version:      1.0
# Description:  Init a RedHat 8 family service

# Variables
cRed="\e[31m" # Print string in red
cGreen="\e[32m" # Print string in green
cBlue="\e[34m" # Print string in blue
cYellow="\e[33m" # Print string in yellow
cNone="\e[39m" # Print string with standard foreground color

# Functions
printOk () {
  echo -e "[${cGreen}OK${cNone}] $*"
}

printInfo () {
  echo -e "[${cBlue}INFO${cNone}] $*"
}

printError () {
  echo -e "[${cRed}ERROR${cNone}] $*"
}

printErrorExit () {
  echo -e "[${cRed}ERROR${cNone}] $*"
  exit 1
}

printWarn () {
  echo -e "[${cYellow}WARNING${cNone}] $*"
}

welcomeScreen () {
  clear
  echo '
  IIIIIIIIII                  iiii          tttt          
  I::::::::I                 i::::i      ttt:::t          
  I::::::::I                  iiii       t:::::t          
  II::::::II                             t:::::t          
    I::::Innnn  nnnnnnnn    iiiiiiittttttt:::::ttttttt    
    I::::In:::nn::::::::nn  i:::::it:::::::::::::::::t    
    I::::In::::::::::::::nn  i::::it:::::::::::::::::t    
    I::::Inn:::::::::::::::n i::::itttttt:::::::tttttt    
    I::::I  n:::::nnnn:::::n i::::i      t:::::t          
    I::::I  n::::n    n::::n i::::i      t:::::t          
    I::::I  n::::n    n::::n i::::i      t:::::t          
    I::::I  n::::n    n::::n i::::i      t:::::t    tttttt
  II::::::IIn::::n    n::::ni::::::i     t::::::tttt:::::t
  I::::::::In::::n    n::::ni::::::i     tt::::::::::::::t
  I::::::::In::::n    n::::ni::::::i       tt:::::::::::tt
  IIIIIIIIIInnnnnn    nnnnnniiiiiiii         ttttttttttt  
  '
  echo ''
}

remoteExec () {
  welcomeScreen
  # Define ANSIBLE CONFIG file
  export ANSIBLE_CONFIG="./ansible/ansible.cfg"
  # Check if ansible and sshpass are installed
  if ! { which ansible > /dev/null; } 2>&1 || ! { which sshpass > /dev/null; } 2>&1; then
    printErrorExit 'Please install mandatory package on your  : ansible sshpass'
  fi
  # Define parameters IP, user, password
  echo -e 'Target remote host with custom port if needed'
  read -rep '(ex: 192.168.1.1, myserver.com, centos@myserver.com): ' REMOTE_FULL_HOST
  if [[ "$REMOTE_FULL_HOST" == *"@"* ]] && [[ "$REMOTE_FULL_HOST" == *":"* ]]; then
    REMOTE_HOST_PORT=$(echo "$REMOTE_FULL_HOST" | awk -F '@' '{print $2}')
    REMOTE_HOST=$(echo "$REMOTE_HOST_PORT" | awk -F ':' '{print $1}')
    REMOTE_PORT=$(echo "$REMOTE_HOST_PORT" | awk -F ':' '{print $2}')
    REMOTE_USER=$(echo "$REMOTE_FULL_HOST" | awk -F '@' '{print $1}')
  elif [[ "$REMOTE_FULL_HOST" == *"@"* ]] && [[ "$REMOTE_FULL_HOST" != *":"* ]]; then
    REMOTE_HOST=$(echo "$REMOTE_FULL_HOST" | awk -F '@' '{print $2}')
    REMOTE_USER=$(echo "$REMOTE_FULL_HOST" | awk -F '@' '{print $1}')
    REMOTE_PORT="22"
  else
    read -rep 'Remote user to use (ex: centos): ' REMOTE_USER
    # Check if IP address has a custom port else use default ssh port
    if [[ "$REMOTE_FULL_HOST" == *":"* ]]; then
      REMOTE_HOST=$(echo "$REMOTE_FULL_HOST" | awk -F ':' '{print $1}')
      REMOTE_PORT=$(echo "$REMOTE_FULL_HOST" | awk -F ':' '{print $2}')
      sed -i "s/REMOTE_PORT/$REMOTE_PORT/g" "./ansible/ansible.cfg"
    else
      REMOTE_HOST="$REMOTE_FULL_HOST"
      REMOTE_PORT="22"
      sed -i "s/REMOTE_PORT/$REMOTE_PORT/g" "./ansible/ansible.cfg"
    fi
  fi
  read -s -p "Remote user password: " REMOTE_PASSWORD
  echo ''
  # Check if main is configured for localhost, if true, then change by all - remote mode
  if grep -q "localhost" "./ansible/main.yaml"; then
    sed -i 's/localhost/all/g' "./ansible/main.yaml"
  fi
  # Check if user and password are not empty, if true change default value in ansible.cfg, else print an error and exit
  if [[ -n "$REMOTE_USER" ]] && [[ -n "$REMOTE_PASSWORD" ]] && [[ -n "$REMOTE_HOST" ]] && [[ -n "$REMOTE_PORT" ]]; then
    sed -i "s/REMOTE_USER/$REMOTE_USER/g" "./ansible/ansible.cfg"
    # Add previous parameter in inventory
    echo -e "[all]\n  $REMOTE_HOST\n[all:vars]\n  ansible_user=$REMOTE_USER\n  ansible_ssh_pass=$REMOTE_PASSWORD" > ./ansible/inventory.ini
  else
    printErrorExit 'Please enter your remote user and his password, host (IP or name)'
  fi
  # Define parameter disable user
  read -rep "Do you want disable remote user after running [Y/n]" REMOTE_DISABLE_USER
  # If empty or equal to Yy then update environment variable else set parameter to null
  if [[ "$REMOTE_DISABLE_USER" == "Y" ]] || [[ "$REMOTE_DISABLE_USER" == "y" ]] || [[ -z "$REMOTE_DISABLE_USER" ]] || [[ "$REMOTE_DISABLE_USER" == "" ]]; then
    DISABLE_USER="$REMOTE_USER"
    DISABLE_USER_STATUS="Yes"
  elif [ "$REMOTE_DISABLE_USER" == "N" ] || [ "$REMOTE_DISABLE_USER" == "n" ]; then
    DISABLE_USER="no"
    DISABLE_USER_STATUS="No"
  fi
  # Print informations
  echo ''
  echo -e "╔════════ Remote target informations ════════"
  echo -e "║ Remote host         : $REMOTE_HOST"
  echo -e "║ Remote port         : $REMOTE_PORT"
  echo -e "║ Remote user         : $REMOTE_USER"
  echo -e "║ Disable remote user : $DISABLE_USER_STATUS"
  echo -e "╚════════════════════════════════════════════"
  echo ''
  read -n 1 -s -r -p "Press any key to confirm these informations and continue"
  echo ''
}

localExec () {
  welcomeScreen
  # Print a warning message if is root use to execute this script
  if [[ "${EUID}" == "0" ]]; then
    printWarn "Please do not use root user"
  fi
  # Define disable user parameter
  read -rep "Do you want disable current user after running [Y/n]" LOCAL_DISABLE_USER
  # If root or Nn set parameter to null, if Yy set current user as disable user
  if [[ "${EUID}" == "0" ]]; then
    printError 'Disable user cannot be root, no user will be disabled'
    DISABLE_USER="Null"
  elif [[ "$LOCAL_DISABLE_USER" == "Y" ]] || [[ "$LOCAL_DISABLE_USER" == "y" ]] || [[ -z "$LOCAL_DISABLE_USER" ]] || [[ "$LOCAL_DISABLE_USER" == "" ]]; then
    printWarn "Current user will be disabled after script application"
    DISABLE_USER="$REMOTE_USER"
    DISABLE_USER_STATUS="Yes"
  elif [ "$LOCAL_DISABLE_USER" == "N" ] || [ "$LOCAL_DISABLE_USER" == "n" ]; then
    DISABLE_USER="no"
    DISABLE_USER_STATUS="No"
  fi
  # Remove useless parameter
  sed -i "/REMOTE_PORT/d" "./ansible/ansible.cfg"
  sed -i "/REMOTE_USER/d" "./ansible/ansible.cfg"
  # Set ansible host to localhost if all is selected
  if grep -q 'all' "./ansible/main.yaml"; then
    sed -i 's/all/localhost/g' "./ansible/main.yaml"
  fi
  # Update OS
  if ! sudo dnf --quiet update -y > /dev/null 2>&1 && sudo dnf --quiet upgrade -y > /dev/null 2>&1 && sudo dnf --quiet makecache > /dev/null 2>&1; then
    printErrorExit "OS cannot be updated"
    exit 1
  fi
  # Add EPEL
  if ! sudo dnf --quiet install epel-release -y > /dev/null 2>&1; then
    printError "Cannot be possible to install EPEL"
  fi
  # Update OS
  if ! sudo dnf --quiet update -y > /dev/null 2>&1; then
    printErrorExit "OS cannot be update after EPEL installation"
  fi
  # Install & upgrade Ansible package
  if ! sudo dnf install --quiet -y ansible > /dev/null 2>&1 && python3 -q -m pip install --upgrade --user ansible > /dev/null 2>&1; then
    printErrorExit "Cannot install ansible and python"
  fi
  # Print information
  echo ''
  echo -e "╔════════ Local target informations ═════════"
  echo -e "║ Current user        : $REMOTE_USER"
  echo -e "║ Disable current user: $DISABLE_USER_STATUS"
  echo -e "╚════════════════════════════════════════════"
  echo ''
  read -n 1 -s -r -p "Press any key to confirm these informations and continue"
}

helpMessage () {
  welcomeScreen
  echo 'Init of docker server with reverse proxy/loadbalancer for RedHat 8 OS family'
  echo 'Options available:'
  echo '  -d (debug) : Add debug logs'
  echo '  -h (help) : Print this message'
  echo '  -l (local) : Apply to localhost'
  echo '  -r (remote) : Apply to a remote host'
  echo ''
  echo 'Examples:'
  echo ''
  echo '  For remote usage:'
  echo '    ./init.sh -r'
  echo ''
  echo '  For local usage:'
  echo '    ./init.sh -l'
  echo ''
}

endScreen () {
  welcomeScreen
  printOk "Mandatory packages installed"
  printOk "Custom packages installed"
  printOk "Default bashrc installed"
  printOk "New SSH server config deployed"
  printOk "Docker service installed"
  printOk "Administrator group created : $NEW_GROUP_NAME"
  printOk "Administrator user created : $NEW_USER_NAME"
  printOk "Docker proxy installed"
  echo ''
  printOk 'OS from RedHat family v8 successfuly initializated'
  printWarn 'Your server will be restarted in 60 secondes'
  exit 0  
}

# Script
# Option management
while getopts "dhlr" Option; do
  case $Option in
    d)
      printWarn "Debug mode enabled"
      echo ''
      set -x
    ;;
    h)
      helpMessage
    ;;
    l)
      REMOTE_MODE="false"
      localExec
    ;;
    r) 
      REMOTE_MODE="true"
      remoteExec
    ;;
    *)
    ;;
  esac
done
# Check if option is defined, if not print help message and exit 0
if [[ -z "$REMOTE_MODE" ]]; then
  helpMessage
  exit 0
fi
# Summary
welcomeScreen
if [[ -f ./ansible/group_vars/all/main.yaml ]]; then
  NEW_USER_NAME=$(grep userName ./ansible/group_vars/all/main.yaml | awk '{print $2}')
  NEW_GROUP_NAME=$(grep groupName ./ansible/group_vars/all/main.yaml | awk '{print $2}')
  NEW_USER_PASSPHRASE=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20 ; echo '')
  NEW_USER_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20 ; echo '')
else
  printErrorExit 'Vars file not found'
fi
printWarn 'Please retrieve this information, as it will only be available once'
echo ''
echo -e "╔════════════ Users informations ═════════════"
echo -e "║ New user to created  : $NEW_USER_NAME"
echo -e "║ New user password    : ${cYellow}$NEW_USER_PASSWORD${cNone}"
echo -e "║ New user passphrase  : ${cYellow}$NEW_USER_PASSPHRASE${cNone}"
echo -e "║ New group to created : $NEW_GROUP_NAME"
echo -e "╚═════════════════════════════════════════════"
echo ''
read -n 1 -s -r -p "Press any key to continue"

welcomeScreen
printInfo 'Installation of Ansible Galaxy Collection'
if [ -f "./ansible/requirements.yaml" ]; then
  if ! ansible-galaxy collection install -r ./ansible/requirements.yaml > /dev/null 2>&1; then
    printError "Cannot install ansible galaxy requirements"
    exit 1
  fi
else
  printError 'Requirements file not found'
  exit 1
fi
printOk "Ansible Galaxy Collection downloaded"

printInfo 'Execution of Ansible playbook'
if [ -f "./ansible/main.yaml" ]; then
  if [ "$REMOTE_MODE" == "true" ]; then
    if ! ansible-playbook -i ./ansible/inventory.ini --extra-vars "readUserpassword=$NEW_USER_PASSWORD readUserpassphrase=$NEW_USER_PASSPHRASE readUserDisable=$DISABLE_USER" "./ansible/main.yaml"; then
      printError 'During Ansible execution'
      exit 1
    fi
  else
    if ! ansible-playbook --extra-vars "readUserpassword=$NEW_USER_PASSWORD readUserpassphrase=$NEW_USER_PASSPHRASE readUserDisable=$DISABLE_USER" "./ansible/main.yaml"; then
      printError 'During Ansible execution'
      exit 1
    fi
  fi
else
  printError 'Playbook file not found'
  exit 1
fi
endScreen
