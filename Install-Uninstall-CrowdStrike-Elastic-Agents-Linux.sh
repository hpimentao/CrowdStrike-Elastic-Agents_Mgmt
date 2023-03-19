#!/bin/bash
# ----------------------------------------------------------------------------
# NOTES
# ----------------------------------------------------------------------------
# Created on:       2023-03-16
# Created by:       Hugo Pimentao
# Organization:     
# Filename:         Install-Uninstall-CrowdStrike-Elastic-Agents-Linux.sh
# ----------------------------------------------------------------------------
# DESCRIPTION
# ----------------------------------------------------------------------------
# Script to install/uninstall CrowdStrike and Elastic agents on Linux machines
# ----------------------------------------------------------------------------

set -euo pipefail

# Set CrowdStrike CID and Elastic SIEM enrollment token
CID=""
ENROLLMENT_TOKEN=""

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Create log file with maximum verbosity
LOG_FILE="$SCRIPT_DIR/Manage-CrowdStrike-Elastic-Agents-Linux.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
if ! command_exists curl; then
  echo "Error: curl is not installed." >&2
  exit 1
fi

# Function to detect the OS
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  else
    echo "Error: Unable to detect OS." >&2
    exit 1
  fi
}

# Function to check if elastic agent is installed
check_elastic_agent_installed() {
  if [ -f "/etc/systemd/system/elastic-agent.service" ] || systemctl --quiet is-enabled elastic-agent 2>/dev/null; then
    echo "Elastic Agent installation detected."
    return 0
  else
    return 1
  fi
}

# Function to check if falcon agent is installed
check_falcon_installed() {
  if [ -f "/etc/systemd/system/falcon-sensor.service" ] || systemctl --quiet is-enabled falcon-sensor 2>/dev/null; then
    echo "CrowdStrike Falcon installation detected."
    return 0
  else
    return 1
  fi
}

# Function to check if both agents are installed
check_agents_installed() {
  if check_falcon_installed; then
    echo "CrowdStrike Falcon is installed."
  else
    echo "CrowdStrike Falcon is not installed."
  fi

  if check_elastic_agent_installed; then
    echo "Elastic Agent is installed."
  else
    echo "Elastic Agent is not installed."
  fi
}

# Function to install CrowdStrike Falcon on CentOS 7
install_crowdstrike_centos() {
  local rpm_file="falcon-sensor-6.51.0-14810.el7.x86_64.rpm"
  curl -LO "https://deployment.secaas.ch/app/CS/${rpm_file}"
  sudo yum install -y "./${rpm_file}"
  sudo /opt/CrowdStrike/falconctl -s -f --cid="$CID"
  sudo systemctl start falcon-sensor
}

# Function to install CrowdStrike Falcon on Ubuntu or Debian
install_crowdstrike_ubuntu_debian() {
  local deb_file="falcon-sensor_6.51.0-14810_amd64.deb"
  curl -LO "https://deployment.secaas.ch/app/CS/${deb_file}"
  sudo dpkg -i "./${deb_file}"
  sudo /opt/CrowdStrike/falconctl -s -f --cid="$CID"
  sudo systemctl start falcon-sensor
}

install_crowdstrike_agent() {
  detect_os

  if check_falcon_installed; then
    echo "CrowdStrike Falcon Agent is already installed. Skipping installation."
  else
    case $OS_ID in
    centos)
      install_crowdstrike_centos
      ;;
    ubuntu | debian)
      install_crowdstrike_ubuntu_debian
      ;;
    *)
      echo "Error: Unsupported OS." >&2
      exit 1
      ;;
    esac
  fi
}

install_elastic_agent() {
  detect_os

  ELASTIC_AGENT_ARCHIVE="elastic-agent-8.6.1-linux-x86_64.tar.gz"
  ELASTIC_AGENT_DIR="elastic-agent-8.6.1-linux-x86_64"

  if check_elastic_agent_installed; then
    echo "Elastic Agent is already installed. Skipping installation."
  elif [ -f "$SCRIPT_DIR/$ELASTIC_AGENT_ARCHIVE" ]; then
    echo "Using existing Elastic Agent binary: $SCRIPT_DIR/$ELASTIC_AGENT_ARCHIVE"
    tar xzvf "$SCRIPT_DIR/${ELASTIC_AGENT_ARCHIVE}" -C "$SCRIPT_DIR"
    sudo "$SCRIPT_DIR/${ELASTIC_AGENT_DIR}/elastic-agent" install --insecure -f --url=https://f8d96b1a213a45859fb3e483aa912760.fleet.eu-central-1.aws.cloud.es.io:443 --enrollment-token="${ENROLLMENT_TOKEN}"
  else
    echo "Downloading Elastic Agent"
    curl -L -O "https://artifacts.elastic.co/downloads/beats/elastic-agent/${ELASTIC_AGENT_ARCHIVE}"
    tar xzvf "${ELASTIC_AGENT_ARCHIVE}" -C "$SCRIPT_DIR"
    sudo "$SCRIPT_DIR/${ELASTIC_AGENT_DIR}/elastic-agent" install --insecure -f --url=https://f8d96b1a213a45859fb3e483aa912760.fleet.eu-central-1.aws.cloud.es.io:443 --enrollment-token="${ENROLLMENT_TOKEN}"
  fi
}

uninstall_crowdstrike_agent() {
  detect_os

  if check_falcon_installed; then
    case $OS_ID in
    centos)
      sudo systemctl stop falcon-sensor
      sudo yum remove -y falcon-sensor
      ;;
    ubuntu | debian)
      sudo systemctl stop falcon-sensor
      sudo dpkg -r falcon-sensor
      ;;
    *)
      echo "Error: Unsupported OS." >&2
      exit 1
      ;;
    esac
  else
    echo "CrowdStrike Falcon Agent is not installed. Skipping uninstallation."
  fi
}

uninstall_elastic_agent() {
  if check_elastic_agent_installed; then
    sudo elastic-agent uninstall -f
  else
    echo "Elastic Agent is not installed. Skipping uninstallation."
  fi
}

restart_agents() {
  # Restart CrowdStrike Falcon agent
  if check_falcon_installed; then
    echo "Restarting CrowdStrike Falcon agent..."
    sudo systemctl restart falcon-sensor
  else
    echo "CrowdStrike Falcon agent is not installed. Skipping restart."
  fi

  # Restart Elastic agent
  if check_elastic_agent_installed; then
    echo "Restarting Elastic agent..."
    sudo systemctl restart elastic-agent
  else
    echo "Elastic agent is not installed. Skipping restart."
  fi
}

restart_crowdstrike_agent() {
  if check_falcon_installed; then
    echo "Restarting CrowdStrike Falcon agent..."
    sudo systemctl restart falcon-sensor
    echo "CrowdStrike Falcon agent restarted successfully."    
  else
    echo "CrowdStrike Falcon agent is not installed. Skipping restart."
  fi
}

restart_elastic_agent() {
  if check_elastic_agent_installed; then
    echo "Restarting Elastic Agent. This may take a while..."
    sudo systemctl restart elastic-agent
    echo "Elastic Agent restarted successfully."
  else
    echo "Elastic Agent is not installed. Skipping restart."
  fi
}

# Show menu
while true; do
  clear
  echo "----------------------------------------"
  echo "CrowdStrike and Elastic Agent Management"
  echo "----------------------------------------"
  echo "1. Check if agents are installed"
  echo "2. Install CrowdStrike Falcon agent only"
  echo "3. Install Elastic agent only"
  echo "4. Install both agents"
  echo "5. Uninstall CrowdStrike Falcon agent only"
  echo "6. Uninstall Elastic agent only"
  echo "7. Uninstall both agents"
  echo "8. Quit"
  echo "----------------------------------------"
  read -p "Please choose an option [1-8]: " option

  case $option in
    1)
      check_agents_installed
      ;;
    2)
      install_crowdstrike_agent
      restart_crowdstrike_agent
      ;;
    3)
      install_elastic_agent
      restart_elastic_agent
      ;;
    4)
      install_crowdstrike_agent
      install_elastic_agent
      restart_agents
      ;;
    5)
      uninstall_crowdstrike_agent
      ;;
    6)
      uninstall_elastic_agent
      ;;
    7)
      uninstall_crowdstrike_agent
      uninstall_elastic_agent
      ;;
    8)
      echo "Exiting."
      break
      ;;
    *)
      echo "Invalid option. Please choose a valid option [1-8]."
      ;;
  esac

  echo "Press enter to continue."
  read -s -n 1
done
