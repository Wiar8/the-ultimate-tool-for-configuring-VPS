# VPS Configurator

A CLI tool to simplify and automate common VPS configuration tasks.

## Overview

VPS Configurator streamlines the process of setting up and securing your Virtual Private Server. Instead of manually running dozens of commands and editing configuration files, this tool provides an interactive menu-driven interface to handle common tasks.

## Features

- **System Updates** - Automated system package updates
- **User Management** - Create users with sudo privileges and SSH setup
- **SSH Hardening** - Secure SSH configuration (disable root login, change port, key-only auth)
- **Firewall Setup** - Configure UFW with sensible defaults
- **Fail2ban** - Install and configure intrusion prevention for SSH
- **Web Servers** - Install and configure Nginx or Apache
- **Docker & Docker Compose** - Fast installation of the latest Docker engine and plugins
- **SSL Certificates** - Automated SSL setup via Certbot and Let's Encrypt

## Supported Systems

- Ubuntu 24.04 (Noble Numbat)

## Installation

```bash
git clone https://github.com/Wiar8/the-ultimate-tool-for-configuring-VPS.git
cd the-ultimate-tool-for-configuring-VPS
chmod +x vps-config.sh
sudo ./vps-config.sh
```

## Usage

Run the tool with root privileges:

```bash
sudo ./vps-config.sh
```

You'll be presented with an interactive menu:

```text
VPS Configurator
================
1) System Update
2) Create User
3) Configure SSH
4) Configure Firewall (UFW)
5) Install Fail2ban
6) Install Nginx
7) Install Apache
8) Install Docker & Docker Compose
9) Install Certbot & SSL
0) Exit
```

## Requirements

- Root or sudo access
- Bash 4.0+
- Internet connection

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Roadmap

### Core Features (Completed)
- [x] System Update module
- [x] User Management
- [x] SSH Hardening
- [x] Firewall Setup (UFW)
- [x] Fail2ban setup
- [x] Nginx installation
- [x] Apache installation
- [x] Docker & Docker Compose integration
- [x] SSL certificate automation (Certbot)

### Extended Features
- [ ] Database installation (MySQL, PostgreSQL)
- [ ] PHP installation (with common extensions)
- [ ] Monitoring tools (Netdata, Prometheus)
- [ ] Automated backup configuration
- [ ] Non-interactive mode (using config files)

### OS Support Expansion
- [ ] Ubuntu 22.04 support
- [ ] Debian 12 support
- [ ] CentOS/RHEL 9 support

## License

MIT License

## Disclaimer

Always review scripts before running them on production servers. Test in a staging environment first.
