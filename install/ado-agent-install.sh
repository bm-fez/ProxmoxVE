#!/usr/bin/env bash

# An Azure DevOPs Pipelines version of MickLesk (CanbiZ) GitHub Action script for Proxmox
# Original https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/github-runner.sh

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  gh
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

msg_info "Creating agent user (no sudo)"
useradd -m -s /bin/bash runner
msg_ok "Runner user ready"

# fetch_and_deploy_gh_release "ado-agent" "microsoft/azure-pipelines-agent" "prebuild" "latest" "/opt/ado-agent" "vsts-agent-linux-x64-4.271.0.tar.gz"

msg_info "Get tar.gz package"
curl -fsSL https://download.agent.dev.azure.com/agent/4.272.0/vsts-agent-linux-x64-4.272.0.tar.gz -o ~/vsts-agent-linux-x64-4.272.0.tar.gz

msg_info "Create agent folder"
mkdir -p /opt/ado-agent
cd /opt/ado-agent
msg_info "Extract agent folder"
tar zxvf ~/vsts-agent-linux-x64-4.272.0.tar.gz

msg_info "Setting ownership for runner user"
chown -R runner:runner /opt/ado-agent
msg_ok "Ownership set"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ado-agent.service
[Unit]
Description=Azure DevOps Pipelines Self-hosted Agent
Documentation=https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=yaml%2Cbrowser#install
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=runner
WorkingDirectory=/opt/ado-agent
ExecStart=/opt/ado-agent/run.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q ado-agent
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc

