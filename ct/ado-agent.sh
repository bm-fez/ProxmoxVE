#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/bm-fez/ProxmoxVE/main/misc/build.func)

# An Azure DevOPs Pipelines version of MickLesk (CanbiZ) GitHub Action script for Proxmox
# Original https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/github-runner.sh

APP="Azure-DevOps-Agent"
var_tags="${var_tags:-ci}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/actions-runner/run.sh ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "ado-agent" "microsoft/azure-pipelines-agent"; then
    msg_info "Stopping Service"
    systemctl stop ado-agent
    msg_ok "Stopped Service"

    msg_info "Backing up agent configuration"
    BACKUP_DIR="/opt/ado-agent.backup"
    mkdir -p "$BACKUP_DIR"
    for f in .runner .credentials .credentials_rsaparams .env .path; do
      [[ -f /opt/ado-agent/$f ]] && cp -a /opt/ado-agent/$f "$BACKUP_DIR/"
    done
    msg_ok "Backed up configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ado-agent" "microsoft/azure-pipelines-agent" "prebuild" "latest" "/opt/ado-agent" "vsts-agent-linux-x64-*.tar.gz"

    msg_info "Restoring runner configuration"
    for f in .runner .credentials .credentials_rsaparams .env .path; do
      [[ -f "$BACKUP_DIR/$f" ]] && cp -a "$BACKUP_DIR/$f" /opt/ado-agent/
    done
    rm -rf "$BACKUP_DIR"
    msg_ok "Restored configuration"

    msg_info "Starting Service"
    systemctl start ado-agent
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} After first boot, run config.sh with your token and start the service.${CL}"
