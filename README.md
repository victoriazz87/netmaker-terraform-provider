# 🌐 Netmaker Terraform Provider Installer (with Docker & GUI)

A fully automated installer and integration toolkit for using [Netmaker](https://www.netmaker.io) with [Terraform](https://www.terraform.io). Includes:

- ✅ Clean Bash installer script
- 🐳 Docker-based provider image
- 📦 Automatic Go environment setup (Go 1.22+)
- ⚙️ Terraform v1.8.5 provisioning
- 🌍 Example `.tf` configuration files
- 🧪 Flask Web GUI scaffold (under development)
- 🔐 MIT

> ⚠️ GUI is **not yet complete** — this repo serves as a development starter.  
> ✅ Installer and Terraform provider work flawlessly.

---

## 🚀 Features

- Installs latest Go and Terraform cleanly on Ubuntu-based systems
- Builds and installs a local Terraform provider for Netmaker
- Dockerfile for containerized provider build
- `.env`, `main.tf`, and `variables.tf` examples included
- Flask-based Web GUI scaffold (`webgui/app.py`)

---

## 🛠 Installation & Usage

```bash
git clone https://github.com/YOURNAME/netmaker-terraform-provider.git
cd netmaker-terraform-provider
chmod +x setup.sh uninstall.sh
./setup.sh

✅ Next Steps

    Copy and edit your API keys and environment values:

cp netmaker_gui/.env.example netmaker_gui/.env

Use the example templates to create Terraform configs:

cp netmaker_gui/main.tf.example netmaker_gui/main.tf
cp netmaker_gui/variables.tf.example netmaker_gui/variables.tf

Navigate to the Terraform folder:

cd netmaker_gui

Initialize and apply the provider:

    terraform init
    terraform apply

    ℹ️ The Terraform provider works directly with Docker and your local host environment.

🧪 (Optional) Launch the Flask Web GUI

python3 webgui/app.py

    🧪 The GUI is a development scaffold only and is not ready for production use.

📄 Example Terraform Configuration

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

resource "netmaker_network" "demo" {
  name         = "terraform_demo"
  addressrange = "10.77.0.0/24"
}

🧹 Uninstallation

You can remove the entire setup (with optional backup):

./uninstall.sh

    You'll be prompted to create a .tar.gz archive before deletion.

    Removes Go mod files, Terraform state, plugins, and build directory.

📂 Project Structure

.
├── .git/               # Git version control
├── .gitignore          # Ignore patterns
├── LICENSE             # MIT / Apache 2.0 license
├── README.md           # This file
├── setup.sh            # Main installer script
├── uninstall.sh        # Cleanup + backup tool
└── netmaker_gui/       # Terraform provider + GUI scaffold
    ├── main.go
    ├── Dockerfile
    ├── .env.example
    ├── main.tf.example
    ├── variables.tf.example
    ├── provider/
    ├── webgui/
    └── ...

📜 License

MIT
See the LICENSE file for details.

🧭 Roadmap

Working Terraform provider auto-installer

Clean uninstall script with backup

Docker-compatible build flow

GUI design & user interface

Multi-network visual management

    Secure credential storage via .env

⭐ Contribute & Share

If this project helped you:

    Star ⭐ the repository

    Fork 🍴 to build your own version

    Open PRs and issues to contribute

🧠 Thank you for using the Netmaker Terraform Provider!
### 🔍 Keywords

`netmaker` `terraform` `vpn` `installer` `automation` `infrastructure` `devops` `provider` `bash` `gui` `docker` `linux` `web-ui`
