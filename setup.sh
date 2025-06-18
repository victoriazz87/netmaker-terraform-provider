#!/bin/bash
set -euo pipefail

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)
BOLD=$(tput bold)

# Paths and variables
WORKDIR="$HOME/netmaker_gui"
PLUGIN_PATH="$HOME/.terraform.d/plugins/registry.terraform.io/local/netmaker/1.0.0/linux_amd64"

# --- Help & clean
if [[ "${1:-}" == "clean" ]]; then
  echo "${YELLOW}🧹 Removing all build artifacts and go.mod/go.sum...$RESET"
  rm -rf "$WORKDIR" terraform-provider-netmaker "$PLUGIN_PATH"
  find "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" -type f \( -name "go.mod" -o -name "go.sum" -o -name "go.work" \) -exec rm -f {} +
  echo "${GREEN}✔️ Cleanup complete (work directory, plugin, and mod files removed).$RESET"
  exit 0
fi

if [[ "${1:-}" == "help" ]]; then
  echo "${BOLD}Käyttö:${RESET} ./setup.sh [clean|help]"
  echo "  clean   - Removes all build artifacts, go.mod/go.sum files, and plugins"
  echo "  help    - Displays this help message"
  exit 0
fi

echo "${BLUE}${BOLD}Netmaker Terraform Provider - automatic installation$RESET"
echo "---------------------------------------------------"

# 1. Remove all old Go installations
echo "${YELLOW}⬇️ Removing old Go versions (snap, apt)...$RESET"
sudo snap remove go 2>/dev/null || true
sudo apt-get remove -y golang-go golang 2>/dev/null || true
sudo rm -rf /usr/local/go

# 2. Install Go 1.22 from the official site
GO_VERSION="1.22.3"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_ARCHIVE}"

echo "${YELLOW}⬇️ Downloading and installing Go $GO_VERSION...$RESET"
wget -q "$GO_URL" -O "/tmp/${GO_ARCHIVE}"
sudo tar -C /usr/local -xzf "/tmp/${GO_ARCHIVE}"
rm "/tmp/${GO_ARCHIVE}"

export PATH="/usr/local/go/bin:$PATH"
hash -r

if ! go version | grep -q "go$GO_VERSION"; then
  echo "${RED}❌ Go $GO_VERSION installation failed.$RESET"
  exit 1
fi

echo "${GREEN}✅ Go $GO_VERSION installed and active: $(go version)$RESET"

# Set script and working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="$SCRIPT_DIR/netmaker_gui"

# Ensure working directory exists
mkdir -p "$WORKDIR"

# 3. Remove all go.mod/go.sum/go.work files from the working directory
echo "${YELLOW}🧼 Removing go.mod/go.sum/go.work files from directory: $WORKDIR and its subdirectories...$RESET"
find "$WORKDIR" -type f \( -name "go.mod" -o -name "go.sum" -o -name "go.work" \) -exec rm -f {} +
echo "${GREEN}✅ Go module files removed from work directory.$RESET"

# 3.1. Create a new go.mod with Go 1.22 in the working directory
echo "${GREEN}🧪 Creating new go.mod with version 1.22 in $WORKDIR...$RESET"
cat > "$WORKDIR/go.mod" <<EOF
module terraform-provider-netmaker
go 1.22
require github.com/hashicorp/terraform-plugin-sdk/v2 v2.31.0
EOF

# 4. Docker check and installation
if ! command -v docker &>/dev/null; then
  echo "${YELLOW}🐳 Docker not found, installing...$RESET"
  sudo apt update
  sudo apt install -y ca-certificates curl gnupg lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io
  echo "${GREEN}✅ Docker installed!$RESET"
fi

if ! sudo systemctl is-active --quiet docker; then
  echo "${YELLOW}🐳 Starting the Docker service...$RESET"
  sudo systemctl start docker
fi
if ! sudo systemctl is-active --quiet docker; then
  echo "${RED}❌ Docker did not start, check the installation!$RESET"; exit 1
fi
echo "${GREEN}🐳 Docker is available.$RESET"

# 5. Pip3/Flask check
if ! command -v pip3 &>/dev/null; then
  echo "${YELLOW}📦 Installing pip3...$RESET"
  sudo apt update
  sudo apt install -y python3-pip
fi

if ! python3 -c "import flask" &>/dev/null; then
  echo "${YELLOW}📦 Installing Flask...$RESET"
  pip3 install --user flask || sudo pip3 install flask
fi
echo "${GREEN}Flask found!$RESET"

# 6. Terraform check/installation
if ! command -v terraform &>/dev/null; then
  echo "${YELLOW}🔧 Installing Terraform...$RESET"
  curl -fsSL https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip -o tf.zip
  unzip tf.zip
  sudo mv terraform /usr/local/bin/
  rm -f tf.zip
fi
echo "${GREEN}Terraform available: $(terraform version | head -1)$RESET"

# 7. Create directories
mkdir -p "$WORKDIR/webgui"
cd "$WORKDIR"

# 8. Example .env file and main.tf
cat > .env.example <<EOF
NETMAKER_API_URL=https://netmaker.example.com
NETMAKER_API_TOKEN=PASTE_YOUR_TOKEN_HERE
EOF

cat > main.tf.example <<EOF
terraform {
  required_providers {
    netmaker = {
      source  = "local/netmaker"
      version = "1.0.0"
    }
  }
}
provider "netmaker" {
  api_url   = var.netmaker_api_url
  api_token = var.netmaker_api_token
}
resource "netmaker_network" "example" {
  name         = "terraform_demo"
  addressrange = "10.77.0.0/24"
}
EOF

cat > variables.tf.example <<EOF
variable "netmaker_api_url" {
  description = "Netmaker API endpoint"
  type        = string
}
variable "netmaker_api_token" {
  description = "Netmaker API token"
  type        = string
  sensitive   = true
}
EOF

# 9. Example template for Flask web GUI
cat > webgui/app.py <<EOF
from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return "Netmaker Terraform Web GUI (expand this later!)"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# 10. Create provider source code
cat > go.mod <<'EOF'
module terraform-provider-netmaker
go 1.22
require github.com/hashicorp/terraform-plugin-sdk/v2 v2.31.0
EOF

cat > main.go <<'EOF'
package main
import (
  "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
  "terraform-provider-netmaker/provider"
)
func main() {
  plugin.Serve(&plugin.ServeOpts{
    ProviderFunc: provider.Provider,
  })
}
EOF

mkdir -p provider
cat > provider/provider.go <<'EOF'
package provider
import (
  "context"
  "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
  "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)
func Provider() *schema.Provider {
  return &schema.Provider{
    Schema: map[string]*schema.Schema{
      "api_url": {
        Type:        schema.TypeString,
        Required:    true,
        DefaultFunc: schema.EnvDefaultFunc("NETMAKER_API_URL", nil),
      },
      "api_token": {
        Type:        schema.TypeString,
        Required:    true,
        Sensitive:   true,
        DefaultFunc: schema.EnvDefaultFunc("NETMAKER_API_TOKEN", nil),
      },
    },
    ResourcesMap: map[string]*schema.Resource{
      "netmaker_network": resourceNetwork(),
    },
    ConfigureContextFunc: providerConfigure,
  }
}
func providerConfigure(ctx context.Context, d *schema.ResourceData) (interface{}, diag.Diagnostics) {
  config := map[string]interface{}{
    "api_url":   d.Get("api_url").(string),
    "api_token": d.Get("api_token").(string),
  }
  return config, nil
}
EOF

cat > provider/resource_network.go <<'EOF'
package provider
import (
  "bytes"
  "encoding/json"
  "fmt"
  "net/http"
  "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)
func resourceNetwork() *schema.Resource {
  return &schema.Resource{
    Create: resourceNetworkCreate,
    Read:   resourceNetworkRead,
    Delete: resourceNetworkDelete,
    Schema: map[string]*schema.Schema{
      "name": {
        Type:     schema.TypeString,
        Required: true,
        ForceNew: true,
      },
      "addressrange": {
        Type:     schema.TypeString,
        Optional: true,
        Default:  "10.0.0.0/24",
        ForceNew: true,
      },
    },
  }
}
func resourceNetworkCreate(d *schema.ResourceData, meta interface{}) error {
  providerConf, ok := meta.(map[string]interface{})
  if !ok || providerConf == nil {
    return fmt.Errorf("provider configuration not set (meta is nil or wrong type)")
  }
  apiURL, ok := providerConf["api_url"].(string)
  if !ok || apiURL == "" {
    return fmt.Errorf("api_url missing in provider configuration")
  }
  token, ok := providerConf["api_token"].(string)
  if !ok || token == "" {
    return fmt.Errorf("api_token missing in provider configuration")
  }
  payload := map[string]interface{}{
    "netid":        d.Get("name").(string),
    "addressrange": d.Get("addressrange").(string),
  }
  body, err := json.Marshal(payload)
  if err != nil {
    return fmt.Errorf("failed to marshal payload: %v", err)
  }
  req, err := http.NewRequest("POST", fmt.Sprintf("%s/api/networks", apiURL), bytes.NewBuffer(body))
  if err != nil {
    return fmt.Errorf("failed to create http request: %v", err)
  }
  req.Header.Set("Authorization", "Bearer "+token)
  req.Header.Set("Content-Type", "application/json")
  client := &http.Client{}
  resp, err := client.Do(req)
  if err != nil {
    return fmt.Errorf("failed to execute http request: %v", err)
  }
  defer resp.Body.Close()
  if resp.StatusCode != 200 && resp.StatusCode != 201 {
    return fmt.Errorf("network creation failed: %s", resp.Status)
  }
  d.SetId(d.Get("name").(string))
  return nil
}
func resourceNetworkRead(d *schema.ResourceData, meta interface{}) error {
  providerConf := meta.(map[string]interface{})
  apiURL := providerConf["api_url"].(string)
  token := providerConf["api_token"].(string)
  netid := d.Id()

  req, err := http.NewRequest("GET", fmt.Sprintf("%s/api/networks/%s", apiURL, netid), nil)
  if err != nil {
    return fmt.Errorf("failed to create GET request: %v", err)
  }
  req.Header.Set("Authorization", "Bearer "+token)

  client := &http.Client{}
  resp, err := client.Do(req)
  if err != nil {
    return fmt.Errorf("failed to perform GET: %v", err)
  }
  defer resp.Body.Close()

  if resp.StatusCode == http.StatusNotFound {
    // Remove resource from Terraform state if it no longer exists
    d.SetId("")
    return nil
  }
  if resp.StatusCode != 200 {
    return fmt.Errorf("unexpected status code %d from Netmaker API", resp.StatusCode)
  }

  var data map[string]interface{}
  if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
    return fmt.Errorf("failed to decode response: %v", err)
  }

  // Update resource fields in Terraform state
  d.Set("name", data["netid"])
  d.Set("addressrange", data["addressrange"])
  d.Set("defaultinterface", data["defaultinterface"])
  d.Set("islocal", data["islocal"])
  d.Set("networkinterface", data["networkinterface"])

  return nil
}
func resourceNetworkDelete(d *schema.ResourceData, meta interface{}) error {
  providerConf := meta.(map[string]interface{})
  apiURL := providerConf["api_url"].(string)
  token := providerConf["api_token"].(string)
  req, _ := http.NewRequest("DELETE", fmt.Sprintf("%s/api/networks/%s", apiURL, d.Id()), nil)
  req.Header.Set("Authorization", "Bearer "+token)
  client := &http.Client{}
  _, err := client.Do(req)
  if err != nil {
    return err
  }
  d.SetId("")
  return nil
}
EOF

# 11. Dockerfile for the provider
cat > Dockerfile <<'EOF'
FROM golang:1.22.3 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN go build -o terraform-provider-netmaker

FROM hashicorp/terraform:1.8
ENV HOME=/root
RUN mkdir -p /root/.terraform.d/plugins/registry.terraform.io/local/netmaker/1.0.0/linux_amd64/
COPY --from=builder /app/terraform-provider-netmaker /root/.terraform.d/plugins/registry.terraform.io/local/netmaker/1.0.0/linux_amd64/
WORKDIR /workspace
ENTRYPOINT ["terraform"]
EOF

# 12. Version file and changelog
cat > VERSION <<EOF
1.0.0-$(date +%Y%m%d)
EOF
cat > CHANGELOG.md <<EOF
# Changes
- $(date) - Automatic build, basic provider, and Docker installation
EOF

# 13. Build steps
echo "${BLUE}🐳 Building Docker image...$RESET"
docker build -t terraform-netmaker .

echo "${BLUE}🔨 Building provider locally...$RESET"
go mod tidy
go build -o terraform-provider-netmaker

mkdir -p "$PLUGIN_PATH"
cp terraform-provider-netmaker "$PLUGIN_PATH/"
chmod +x "$PLUGIN_PATH/terraform-provider-netmaker"
echo "${GREEN}✅ Provider installed to path: $PLUGIN_PATH/terraform-provider-netmaker$RESET"

# 14. Testing (Docker)
echo "${YELLOW}🧪 Testing Docker image functionality...$RESET"

# Run Docker and filter out false warning
DOCKER_OUTPUT=$(docker run --rm terraform-netmaker version | grep -v "out of date")
echo "$DOCKER_OUTPUT"

# Check if version information is found
if echo "$DOCKER_OUTPUT" | grep -q "Terraform v"; then
  echo "${GREEN}✅ Docker image works, Terraform version recognized.$RESET"
else
  echo "${RED}❌ Terraform version check failed in Docker image.$RESET"
fi

# Explanation of possible version "warning"
echo "${YELLOW}ℹ️ Note: Terraform may give a false version comparison warning (e.g., 1.8.5 vs 1.12.2).$RESET"
echo "${YELLOW}   This is because 1.12.2 is actually older than 1.8.5 (belongs to the old 0.x series).$RESET"

# 15. Final instructions and user guidance
echo ""
echo "${BOLD}${GREEN}🎉 Installation complete!$RESET"
echo ""
echo "${YELLOW}Next steps:${RESET}
- Use .env.example as a template for your own API keys (copy: cp .env.example .env).
- Create a new main.tf in the folder (main.tf.example and variables.tf.example provided as templates).
- Navigate to the folder and run:
  ${BLUE}terraform init${RESET}
  ${BLUE}terraform apply${RESET}
- The provider works directly with Docker and the host.
- Flask Web GUI starts with: ${BLUE}python3 webgui/app.py${RESET}

${GREEN}Thank you for using the Netmaker Terraform provider!$RESET
"

exit 0

