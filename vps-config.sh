#!/bin/bash

#===============================================================================
# VPS Configurator
# A CLI tool to simplify and automate common VPS configuration tasks
# Supported: Ubuntu 24.04
#===============================================================================

set -e

#-------------------------------------------------------------------------------
# Colors and formatting
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Utility functions
#-------------------------------------------------------------------------------
print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                      VPS Configurator                         ║"
    echo "║              Ubuntu 24.04 Server Setup Tool                   ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

confirm() {
    local prompt="$1"
    local response
    echo -e -n "${YELLOW}${prompt} [y/N]:${NC} "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

press_enter() {
    echo ""
    echo -e -n "${CYAN}Press Enter to continue...${NC}"
    read -r
}

#-------------------------------------------------------------------------------
# System checks
#-------------------------------------------------------------------------------
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        echo "Please run: sudo $0"
        exit 1
    fi
}

check_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect operating system"
        exit 1
    fi

    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        print_error "This script only supports Ubuntu"
        print_info "Detected: $PRETTY_NAME"
        exit 1
    fi

    if [[ "$VERSION_ID" != "24.04" ]]; then
        print_warning "This script is designed for Ubuntu 24.04"
        print_info "Detected: Ubuntu $VERSION_ID"
        if ! confirm "Do you want to continue anyway?"; then
            exit 1
        fi
    fi
}

#-------------------------------------------------------------------------------
# Menu functions
#-------------------------------------------------------------------------------
show_menu() {
    print_header
    echo -e "${BOLD}Main Menu${NC}"
    echo ""
    echo "  1) System Update"
    echo "  2) Create User"
    echo "  3) Configure SSH"
    echo "  4) Configure Firewall (UFW)"
    echo "  5) Install Fail2ban"
    echo "  6) Install Nginx"
    echo "  7) Install Apache"
    echo "  8) Install Docker & Docker Compose"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -e -n "${CYAN}Select an option [0-8]:${NC} "
}

#-------------------------------------------------------------------------------
# Feature functions
#-------------------------------------------------------------------------------

# 1. System Update
system_update() {
    print_header
    echo -e "${BOLD}System Update${NC}"
    echo ""

    print_info "Updating package lists..."
    apt update
    echo ""

    print_info "Upgrading packages..."
    apt upgrade -y
    echo ""

    if confirm "Remove unused packages (autoremove)?"; then
        apt autoremove -y
        echo ""
    fi

    print_success "System update completed"
    press_enter
}

# 2. Create User
create_user() {
    print_header
    echo -e "${BOLD}Create User${NC}"
    echo ""

    # Get username
    echo -e -n "${CYAN}Enter username:${NC} "
    read -r username

    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty"
        press_enter
        return
    fi

    # Check if user exists
    if id "$username" &>/dev/null; then
        print_error "User '$username' already exists"
        press_enter
        return
    fi

    # Create user with home directory
    print_info "Creating user '$username'..."
    useradd -m -s /bin/bash "$username"

    # Set password
    print_info "Set password for '$username':"
    passwd "$username"

    # Add to sudo group
    if confirm "Add '$username' to sudo group?"; then
        usermod -aG sudo "$username"
        print_success "User added to sudo group"
    fi

    # Setup SSH directory
    if confirm "Create SSH directory for '$username'?"; then
        local ssh_dir="/home/$username/.ssh"
        mkdir -p "$ssh_dir"
        touch "$ssh_dir/authorized_keys"
        chmod 700 "$ssh_dir"
        chmod 600 "$ssh_dir/authorized_keys"
        chown -R "$username:$username" "$ssh_dir"
        print_success "SSH directory created at $ssh_dir"
        print_info "Add public keys to: $ssh_dir/authorized_keys"
    fi

    echo ""
    print_success "User '$username' created successfully"
    press_enter
}

# 3. Configure SSH
configure_ssh() {
    print_header
    echo -e "${BOLD}Configure SSH${NC}"
    echo ""

    local sshd_config="/etc/ssh/sshd_config"
    local backup_file="/etc/ssh/sshd_config.backup.$(date +%Y%m%d%H%M%S)"

    # Backup current config
    print_info "Backing up current SSH config..."
    cp "$sshd_config" "$backup_file"
    print_success "Backup saved to $backup_file"
    echo ""

    # Change SSH port
    if confirm "Change SSH port? (default: 22)"; then
        echo -e -n "${CYAN}Enter new SSH port:${NC} "
        read -r new_port

        if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
            sed -i "s/^#\?Port .*/Port $new_port/" "$sshd_config"
            print_success "SSH port changed to $new_port"
            print_warning "Remember to update firewall rules!"
        else
            print_error "Invalid port number"
        fi
        echo ""
    fi

    # Disable root login
    if confirm "Disable root login via SSH?"; then
        sed -i "s/^#\?PermitRootLogin .*/PermitRootLogin no/" "$sshd_config"
        print_success "Root login disabled"
        echo ""
    fi

    # Disable password authentication
    print_warning "Only disable password auth if you have SSH keys configured!"
    if confirm "Disable password authentication?"; then
        # Disable PasswordAuthentication
        sed -i "s/^#\?PasswordAuthentication .*/PasswordAuthentication no/" "$sshd_config"
        
        # Disable ChallengeResponseAuthentication (KBDInteractiveAuthentication in newer versions)
        if grep -q "KBDInteractiveAuthentication" "$sshd_config"; then
            sed -i "s/^#\?KBDInteractiveAuthentication .*/KBDInteractiveAuthentication no/" "$sshd_config"
        else
            sed -i "s/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/" "$sshd_config"
        fi

        # Disable UsePAM
        sed -i "s/^#\?UsePAM .*/UsePAM no/" "$sshd_config"
        
        print_success "Password authentication disabled"
        echo ""
    fi

    # Enable public key authentication
    sed -i "s/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/" "$sshd_config"

    # Restart SSH service
    if confirm "Restart SSH service to apply changes?"; then
        systemctl restart ssh
        print_success "SSH service restarted"
    else
        print_warning "Changes will apply after SSH service restart"
    fi

    echo ""
    print_success "SSH configuration completed"
    press_enter
}

# 4. Configure Firewall (UFW)
configure_firewall() {
    print_header
    echo -e "${BOLD}Configure Firewall (UFW)${NC}"
    echo ""

    # Install UFW if not present
    if ! command -v ufw &>/dev/null; then
        print_info "Installing UFW..."
        apt install -y ufw
        echo ""
    fi

    # Get current SSH port
    local ssh_port
    ssh_port=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    ssh_port=${ssh_port:-22}

    # Reset UFW to defaults
    if confirm "Reset UFW to default settings?"; then
        ufw --force reset
        print_success "UFW reset to defaults"
        echo ""
    fi

    # Set default policies
    print_info "Setting default policies..."
    ufw default deny incoming
    ufw default allow outgoing
    print_success "Default policies set"
    echo ""

    # Allow SSH
    print_info "Allowing SSH (port $ssh_port)..."
    ufw allow "$ssh_port/tcp" comment 'SSH'
    print_success "SSH allowed on port $ssh_port"
    echo ""

    # Allow HTTP
    if confirm "Allow HTTP (port 80)?"; then
        ufw allow 80/tcp comment 'HTTP'
        print_success "HTTP allowed"
    fi

    # Allow HTTPS
    if confirm "Allow HTTPS (port 443)?"; then
        ufw allow 443/tcp comment 'HTTPS'
        print_success "HTTPS allowed"
    fi
    echo ""

    # Enable UFW
    print_warning "Make sure SSH is allowed before enabling!"
    if confirm "Enable UFW now?"; then
        ufw --force enable
        print_success "UFW enabled"
    fi

    # Show status
    echo ""
    print_info "UFW Status:"
    ufw status verbose

    echo ""
    print_success "Firewall configuration completed"
    press_enter
}

# 5. Install Fail2ban
install_fail2ban() {
    print_header
    echo -e "${BOLD}Install Fail2ban${NC}"
    echo ""

    # Check if already installed
    if command -v fail2ban-client &>/dev/null; then
        print_warning "Fail2ban is already installed"
        if ! confirm "Reconfigure Fail2ban?"; then
            press_enter
            return
        fi
    else
        print_info "Installing Fail2ban..."
        apt install -y fail2ban
        print_success "Fail2ban installed"
    fi
    echo ""

    # Get current SSH port
    local ssh_port
    ssh_port=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    ssh_port=${ssh_port:-22}

    # Create jail.local configuration
    print_info "Creating Fail2ban configuration..."
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = $ssh_port
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF
    print_success "Configuration created at /etc/fail2ban/jail.local"
    echo ""

    # Configure ban settings
    if confirm "Customize ban settings?"; then
        echo -e -n "${CYAN}Max retry attempts (default 3):${NC} "
        read -r max_retry
        max_retry=${max_retry:-3}

        echo -e -n "${CYAN}Ban time (e.g., 1h, 30m, 1d):${NC} "
        read -r ban_time
        ban_time=${ban_time:-1h}

        sed -i "s/maxretry = 3/maxretry = $max_retry/" /etc/fail2ban/jail.local
        sed -i "s/bantime = 1h/bantime = $ban_time/g" /etc/fail2ban/jail.local
        print_success "Ban settings updated"
        echo ""
    fi

    # Start and enable service
    print_info "Starting Fail2ban service..."
    systemctl enable fail2ban
    systemctl restart fail2ban
    print_success "Fail2ban service started and enabled"

    # Show status
    echo ""
    print_info "Fail2ban Status:"
    fail2ban-client status

    echo ""
    print_success "Fail2ban installation completed"
    press_enter
}

# 6. Install Nginx
install_nginx() {
    print_header
    echo -e "${BOLD}Install Nginx${NC}"
    echo ""

    # Check if Apache is installed
    if systemctl is-active --quiet apache2 2>/dev/null; then
        print_warning "Apache is currently running!"
        print_info "Running both may cause port conflicts"
        if ! confirm "Continue anyway?"; then
            press_enter
            return
        fi
        echo ""
    fi

    # Check if already installed
    if command -v nginx &>/dev/null; then
        print_warning "Nginx is already installed"
        nginx -v
        if ! confirm "Reinstall Nginx?"; then
            press_enter
            return
        fi
    fi

    # Install Nginx
    print_info "Installing Nginx..."
    apt install -y nginx
    print_success "Nginx installed"
    echo ""

    # Start and enable service
    print_info "Starting Nginx service..."
    systemctl enable nginx
    systemctl start nginx
    print_success "Nginx service started and enabled"

    # Show status
    echo ""
    print_info "Nginx Status:"
    systemctl status nginx --no-pager -l

    # Configure UFW if active
    echo ""
    if ufw status | grep -q "Status: active"; then
        print_info "UFW is active"
        if confirm "Allow HTTP (port 80) in firewall?"; then
            ufw allow 80/tcp comment 'HTTP'
            print_success "HTTP allowed"
        fi
        if confirm "Allow HTTPS (port 443) in firewall?"; then
            ufw allow 443/tcp comment 'HTTPS'
            print_success "HTTPS allowed"
        fi
    else
        print_warning "UFW is not active. Remember to allow ports 80/443 if you enable it later"
    fi

    echo ""
    print_info "Default web root: /var/www/html"
    print_info "Config files: /etc/nginx/"

    echo ""
    print_success "Nginx installation completed"
    press_enter
}

# 7. Install Apache
install_apache() {
    print_header
    echo -e "${BOLD}Install Apache${NC}"
    echo ""

    # Check if Nginx is installed
    if systemctl is-active --quiet nginx 2>/dev/null; then
        print_warning "Nginx is currently running!"
        print_info "Running both may cause port conflicts"
        if ! confirm "Continue anyway?"; then
            press_enter
            return
        fi
        echo ""
    fi

    # Check if already installed
    if command -v apache2 &>/dev/null; then
        print_warning "Apache is already installed"
        apache2 -v
        if ! confirm "Reinstall Apache?"; then
            press_enter
            return
        fi
    fi

    # Install Apache
    print_info "Installing Apache..."
    apt install -y apache2
    print_success "Apache installed"
    echo ""

    # Start and enable service
    print_info "Starting Apache service..."
    systemctl enable apache2
    systemctl start apache2
    print_success "Apache service started and enabled"

    # Show status
    echo ""
    print_info "Apache Status:"
    systemctl status apache2 --no-pager -l

    # Configure UFW if active
    echo ""
    if ufw status | grep -q "Status: active"; then
        print_info "UFW is active"
        if confirm "Allow HTTP (port 80) in firewall?"; then
            ufw allow 80/tcp comment 'HTTP'
            print_success "HTTP allowed"
        fi
        if confirm "Allow HTTPS (port 443) in firewall?"; then
            ufw allow 443/tcp comment 'HTTPS'
            print_success "HTTPS allowed"
        fi
    else
        print_warning "UFW is not active. Remember to allow ports 80/443 if you enable it later"
    fi

    echo ""
    print_info "Default web root: /var/www/html"
    print_info "Config files: /etc/apache2/"

    echo ""
    print_success "Apache installation completed"
    press_enter
}

# 8. Install Docker & Docker Compose
install_docker() {
    print_header
    echo -e "${BOLD}Install Docker & Docker Compose${NC}"
    echo ""

    # Check if already installed
    if command -v docker &>/dev/null; then
        print_warning "Docker is already installed"
        docker --version
        if ! confirm "Reinstall Docker?"; then
            press_enter
            return
        fi
    fi

    # Cleanup conflicting packages
    print_info "Removing conflicting packages..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        apt-get remove -y $pkg 2>/dev/null || true
    done
    echo ""

    # Prerequisites
    print_info "Installing prerequisites..."
    apt update
    apt install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    echo ""

    # GPG Key
    print_info "Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo ""

    # Repository
    print_info "Adding Docker repository..."
    source /etc/os-release
    cat > /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    print_success "Repository added"
    echo ""

    # Install
    print_info "Installing Docker packages..."
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    print_success "Docker installed"
    echo ""

    # Enable and start
    systemctl enable docker
    systemctl start docker
    print_success "Docker service started and enabled"
    echo ""

    # Add user to group
    if confirm "Add a user to the 'docker' group? (allows running without sudo)"; then
        local target_user="${SUDO_USER:-$USER}"
        echo -e -n "${CYAN}Enter username (default: $target_user):${NC} "
        read -r input_user
        target_user="${input_user:-$target_user}"

        if id "$target_user" &>/dev/null; then
            usermod -aG docker "$target_user"
            print_success "User '$target_user' added to docker group"
            print_warning "User needs to log out and back in for this to take effect"
        else
            print_error "User '$target_user' does not exist"
        fi
        echo ""
    fi

    # Verify
    print_info "Verifying installation..."
    docker run hello-world
    
    echo ""
    print_success "Docker installation completed"
    press_enter
}

#-------------------------------------------------------------------------------
# Main loop
#-------------------------------------------------------------------------------
main() {
    check_root
    check_ubuntu

    while true; do
        show_menu
        read -r choice

        case $choice in
            1) system_update ;;
            2) create_user ;;
            3) configure_ssh ;;
            4) configure_firewall ;;
            5) install_fail2ban ;;
            6) install_nginx ;;
            7) install_apache ;;
            8) install_docker ;;
            0)
                print_header
                print_success "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

main "$@"
