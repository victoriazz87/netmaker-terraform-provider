#!/bin/bash
set -euo pipefail

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
BOLD=$(tput bold)

echo "${YELLOW}${BOLD}Uninstalling Netmaker Terraform Provider$RESET"
echo "-----------------------------------------"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_PATH="$HOME/.terraform.d/plugins/registry.terraform.io/local/netmaker/1.0.0/linux_amd64"
WORKDIR="$HOME/netmaker_gui"

# 1. Reminder about terraform destroy
echo "${YELLOW}💡 Tip: If resources are still active, run: ${BOLD}terraform destroy${RESET}"
echo

# 2. Ask if user wants to back up the project
read -rp "📦 Do you want to back up the current project folder? (y/n): " BACKUPANSWER
if [[ "$BACKUPANSWER" =~ ^[yYkKjJ]$ ]]; then
  BACKUPFILE="$WORKDIR/netmaker_gui-backup-$(date +%Y%m%d%H%M%S).tar.gz"
  echo "${YELLOW}📦 Creating backup archive: $BACKUPFILE $RESET"
  tar -czf "$BACKUPFILE" -C "$(dirname "$WORKDIR")" "$(basename "$WORKDIR")"
  echo "${GREEN}✅ Backup complete: $BACKUPFILE$RESET"
else
  echo "${YELLOW}⏩ Skipping backup.$RESET"
fi

# 3. Remove provider plugin
if [[ -d "$PLUGIN_PATH" ]]; then
  echo "${YELLOW}🧹 Removing provider plugin: $PLUGIN_PATH $RESET"
  rm -rf "$PLUGIN_PATH"
fi

# 4. Remove Terraform state and module files
echo "${YELLOW}🧼 Removing Terraform files and state...$RESET"
rm -f "$SCRIPT_DIR"/go.mod "$SCRIPT_DIR"/go.sum "$SCRIPT_DIR"/go.work 2>/dev/null || true
rm -f "$SCRIPT_DIR"/.terraform.lock.hcl "$SCRIPT_DIR"/terraform.tfstate "$SCRIPT_DIR"/terraform.tfstate.backup
rm -rf "$SCRIPT_DIR/.terraform"

# 5. Remove working directory
if [[ -d "$WORKDIR" ]]; then
  echo "${YELLOW}🧹 Removing working directory: $WORKDIR $RESET"
  rm -rf "$WORKDIR"
fi

echo
echo "${GREEN}✅ Uninstall complete!$RESET"

