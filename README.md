# VPS Configurator

A CLI tool to simplify and automate common VPS configuration tasks.

## Overview

VPS Configurator streamlines the process of setting up and securing your Virtual Private Server. Instead of manually running dozens of commands and editing configuration files, this tool provides an interactive menu-driven interface to handle common tasks.

## Features

- **Firewall Setup** - Configure UFW with sensible defaults
- **Web Servers** - Install and configure Nginx or Apache
- **SSH Hardening** - Secure SSH configuration (disable root login, change port, key-only auth)
- **Fail2ban** - Install and configure intrusion prevention
- **System Updates** - Automated system package updates
- **User Management** - Create users with sudo privileges
- **More tools** - Continuously adding new features

## Supported Systems

- Ubuntu 24.04

## Installation

```bash
git clone https://github.com/yourusername/vps-configurator.git
cd vps-configurator
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
0) Exit
```

## Requirements

- Root or sudo access
- Bash 4.0+
- curl or wget

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Roadmap

### Core Features (Priority)
- [ ] System Update module
- [ ] User Management
- [ ] SSH Hardening
- [ ] Firewall Setup (UFW)
- [ ] Fail2ban setup
- [ ] Nginx installation
- [ ] Apache installation

### Extended Features
- [ ] Docker & Docker Compose
- [ ] SSL certificate automation (Let's Encrypt)
- [ ] Database installation (MySQL, PostgreSQL)
- [ ] Monitoring tools (Netdata, Prometheus)
- [ ] Backup configuration
- [ ] Non-interactive mode with config files

### OS Support Expansion
- [ ] Ubuntu 22.04
- [ ] Debian 12
- [ ] CentOS/RHEL 9

## License

MIT License

## Disclaimer

Always review scripts before running them on production servers. Test in a staging environment first.
