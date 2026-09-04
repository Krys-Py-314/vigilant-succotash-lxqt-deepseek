#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root. Run as normal user with sudo privileges."
    exit 1
fi

print_status "Starting Raspberry Pi 5 Minimal LXQt/Openbox Setup..."

# Update package lists
print_status "Updating package lists..."
sudo apt update || { print_error "Failed to update package lists"; exit 1; }

# Install base X11 and Openbox
print_status "Installing X11 and Openbox..."
sudo apt install -y --no-install-recommends \
    xserver-xorg \
    xinit \
    openbox \
    obconf \
    x11-xserver-utils \
    || { print_error "Failed to install X11/Openbox"; exit 1; }

# Install LXQt core components (minimal)
print_status "Installing LXQt minimal components..."
sudo apt install -y --no-install-recommends \
    lxqt-session \
    lxqt-panel \
    lxqt-runner \
    lxqt-policykit \
    lxqt-powermanagement \
    lxqt-sudo \
    lxqt-notificationd \
    lxqt-globalkeys \
    lxqt-config \
    lxqt-qtplugin \
    lxqt-archiver \
    pcmanfm-qt \
    || { print_error "Failed to install LXQt components"; exit 1; }

# Install lightweight tools
print_status "Installing lightweight tools (terminal, editor, browser, file manager, etc.)..."
sudo apt install -y --no-install-recommends \
    sakura \
    leafpad \
    links2 \
    feh \
    mpv \
    mupdf \
    gtk-recordmydesktop \
    recordmydesktop \
    alsa-utils \
    || { print_error "Failed to install lightweight tools"; exit 1; }

# Install development tools
print_status "Installing development tools..."
sudo apt install -y --no-install-recommends \
    build-essential \
    libgpiod-dev \
    pigpio \
    libpigpio-dev \
    pkg-config \
    git \
    curl \
    wget \
    unzip \
    || { print_error "Failed to install development tools"; exit 1; }

# Install network and system utilities
print_status "Installing SSH (dropbear) and system utilities..."
sudo apt install -y --no-install-recommends \
    dropbear \
    fastfetch \
    numix-icon-theme-circle \
    || { print_error "Failed to install SSH/system utilities"; exit 1; }

# Remove openssh-server if present (dropbear replaces it)
if dpkg -l | grep -q openssh-server; then
    print_status "Removing openssh-server (replaced by dropbear)..."
    sudo apt purge -y openssh-server || print_warning "Could not purge openssh-server"
fi

# Enable dropbear
print_status "Enabling dropbear SSH server..."
sudo systemctl enable dropbear
sudo systemctl restart dropbear

# Configure X11 for Raspberry Pi 5 (vc4 driver)
print_status "Configuring X11 for Raspberry Pi 5..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-vc4.conf >/dev/null <<'EOF'
Section "OutputClass"
    Identifier "vc4"
    MatchDriver "vc4"
    Driver "modesetting"
    Option "PrimaryGPU" "true"
EndSection
EOF

# Install Pi-Apps (as normal user)
print_status "Installing Pi-Apps..."
wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash || { print_error "Pi-Apps installation failed"; exit 1; }

# Run Pi-Apps commands to install additional software
print_status "Installing additional software via Pi-Apps..."
~/pi-apps/manage install Min
~/pi-apps/manage install "Geany Dark Mode"

# Install Oh My Posh
print_status "Installing Oh My Posh..."
mkdir -p ~/.local/bin
wget -qO ~/.local/bin/oh-my-posh https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64
chmod +x ~/.local/bin/oh-my-posh

# Configure Oh My Posh in bashrc
if ! grep -q 'oh-my-posh init bash' ~/.bashrc; then
    echo 'eval "$(oh-my-posh init bash)"' >> ~/.bashrc
fi

# Install Ubuntu Nerd Font (regular)
print_status "Installing Ubuntu Nerd Font..."
mkdir -p ~/.local/share/fonts
cd /tmp
wget -qO ubuntu-nerd.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Ubuntu.zip
unzip -q ubuntu-nerd.zip -d ~/.local/share/fonts/
rm ubuntu-nerd.zip
fc-cache -f

# Set system-wide font to Ubuntu Nerd Font (regular, size 11)
print_status "Setting system-wide font to Ubuntu Nerd Font (size 11)..."
sudo tee /etc/fonts/local.conf >/dev/null <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match target="pattern">
        <test qual="any" name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Ubuntu Nerd Font</string></edit>
    </match>
    <match target="pattern">
        <test qual="any" name="family"><string>monospace</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Ubuntu Mono Nerd Font</string></edit>
    </match>
    <match target="font">
        <edit name="size" mode="assign"><double>11</double></edit>
    </match>
</fontconfig>
EOF

# Set icon theme to Numix-Circle system-wide
print_status "Setting Numix-Circle icon theme..."
gsettings set org.gnome.desktop.interface icon-theme 'Numix-Circle' 2>/dev/null || true
sudo tee /etc/xdg/lxqt/lxqt.conf >/dev/null <<'EOF'
[General]
icon_theme=Numix-Circle
EOF

# Set background color (no wallpaper) to R:56 G:60 B:72 (#383C48)
print_status "Configuring desktop background color..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/set-background.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Set Background
Exec=xsetroot -solid "#383C48"
X-GNOME-Autostart-enabled=true
EOF
chmod +x ~/.config/autostart/set-background.desktop

# Configure default applications (terminal, editor, browser, file manager)
print_status "Setting default applications..."
mkdir -p ~/.config
cat > ~/.config/mimeapps.list <<'EOF'
[Default Applications]
text/plain=leafpad.desktop
x-scheme-handler/http=links2.desktop
x-scheme-handler/https=links2.desktop
inode/directory=pcmanfm-qt.desktop
application/pdf=mupdf.desktop
image/*=feh.desktop
video/*=mpv.desktop
EOF

# Add ~/.local/bin to PATH in .bashrc
if ! grep -q 'export PATH=$PATH:$HOME/.local/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
fi

# Set up auto-start of X on login (console)
if ! grep -q 'startx' ~/.bash_profile; then
    echo 'if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then startx; fi' >> ~/.bash_profile
fi

# Final cleanup
print_status "Cleaning up packages..."
sudo apt autoremove -y
sudo apt clean

print_status "Installation complete. Please reboot to start using the minimal LXQt environment."
print_warning "After reboot, log in and type 'startx' or reboot to automatically start X on tty1 (if configured)."
print_warning "Dropbear SSH is active. Use port 22 (default) to connect."

exit 0