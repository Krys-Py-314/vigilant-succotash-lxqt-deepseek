#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}
# ---------------------------------------------------------------------------
print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
# ---------------------------------------------------------------------------
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
# ---------------------------------------------------------------------------
# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root. Run as normal user with sudo privileges."
    exit 1
fi
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
banner() {
    print_status " "
    print_status " $1"
    print_status " "
}
# ---------------------------------------------------------------------------
note_fail() {
    FAILED_STEPS+=("$1")
    print_error "$1"
}
# ---------------------------------------------------------------------------
pkg_available() {
    local cand
    cand="$(apt-cache policy -- "$1" 2>/dev/null | awk -F': ' '/Candidate:/{print $2; exit}')"
    [ -n "$cand" ] && [ "$cand" != "(none)" ]
}
# ---------------------------------------------------------------------------
apt_install() {
    local want=("$@") ok=() miss=() p
    for p in "${want[@]}"; do
        if pkg_available "$p"; then ok+=("$p"); else miss+=("$p"); fi
    done
    if [ "${#miss[@]}" -gt 0 ]; then
        print_warning "Not offered by this release, skipping: ${miss[*]}"
        SKIPPED_PKGS+=("${miss[@]}")
    fi
    [ "${#ok[@]}" -eq 0 ] && return 0
    print_status "apt-get install: ${ok[*]}"
    if ! sudo apt-get install -y --no-install-recommends "${ok[@]}" >>"$LOGFILE" 2>&1; then
        note_fail "apt-get install failed for: ${ok[*]} (see $LOGFILE)"
        return 1
    fi
    return 0
}
# ---------------------------------------------------------------------------
confirm() {
    local prompt="$1"
    [ "$ASSUME_YES" = "1" ] && return 0
    [ -t 0 ] || return 0
    local reply=""
    read -r -p "$(echo -e "${YELLOW}[WARN]${NC} ${prompt} [Y/n] ")" reply
    case "$reply" in
        [nN]*) return 1 ;;
        *)     return 0 ;;
    esac
}
print_status "Starting Raspberry Pi 5 Minimal LXQt/Openbox Setup (Debian Trixie)..."

# Update package lists
print_status "Updating package lists..."
sudo apt update || { print_error "Failed to update package lists"; exit 1; }

# Install base X11 and Openbox

#removed below
    #xserver-xorg \
    #xinit \

print_status "Installing X11 and Openbox..."
sudo apt install -y --no-install-recommends \
    xserver-xorg-core \
    xserver-xorg-video-modesetting \
    xserver-xorg-input-libinput \
    x11-xserver-utils \
    xinit \
    openbox \
    obconf \
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
    || { print_error "Failed to install LXQt components"; exit 1; }

# Install lightweight tools
print_status "Installing lightweight tools (terminal, editor, browser, file manager, etc.)..."
sudo apt install -y --no-install-recommends \
    featherpad \
    qterminal \
    pcmanfm-qt \
    vimb \
    || { print_error "Failed to install lightweight tools"; exit 1; }

# REMOVED FROM AFTER LEAFPAD    
    # links2 \         NOT NEDDED (yet) cli txt mode web browser
    # feh \            NOT NEDDED (yet) cli wallpaper tool
    # mpv \            NOT NEDDED (yet) command-line media player         
    # mupdf \          NOT NEDDED (yet) PDF viewer
    #recordmydesktop \ NOT NEEDED capture audio-video data from desktop
    #alsa-utils \      NOT NEEDED sound utilities 


# Install development tools
print_status "Installing development tools..."
sudo apt install -y --no-install-recommends \
    build-essential \
    libgpiod-dev \
    gpiod \
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
# NOT NEDDED (yet)
# print_status "Installing Pi-Apps..."
# wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash || { print_error "Pi-Apps installation failed"; exit 1; }


# Run Pi-Apps commands to install additional software
# NOT NEDDED (yet)
# print_status "Installing additional software via Pi-Apps..."
# ~/pi-apps/manage install Min
# ~/pi-apps/manage install "Geany Dark Mode"

# Install Oh My Posh
# NOT NEDDED (yet)
# print_status "Installing Oh My Posh..."
# mkdir -p ~/.local/bin
# wget -qO ~/.local/bin/oh-my-posh https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64
# chmod +x ~/.local/bin/oh-my-posh
 
# Configure Oh My Posh in bashrc
#if ! grep -q 'oh-my-posh init bash' ~/.bashrc; then
#    echo 'eval "$(oh-my-posh init bash)"' >> ~/.bashrc
#fi

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

# Set fixed background color (NO WALLPAPER) to R:56 G:60 B:72 (#383C48)
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
text/plain=l3afpad.desktop
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


 ======================================================
banner "8. CONFIGURE OPENBOX (Square Windows with Arc-Dark)"
# ======================================================
print_status "Configuring Openbox with square windows and Arc-Dark theme..."

mkdir -p ~/.config/openbox
if [ -f /etc/xdg/openbox/rc.xml ]; then
    cp /etc/xdg/openbox/rc.xml ~/.config/openbox/rc.xml
else
    # Create default rc.xml if not exists
    sudo tee  ~/.config/openbox/rc.xml >/dev/null  << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Arc-Dark</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>Ubuntu Nerd Font</name>
      <size>10</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>Ubuntu Nerd Font</name>
      <size>10</size>
      <weight>normal</weight>
      <slant>normal</slant>
    </font>
  </theme>
</openbox_config>
EOF
fi

# Remove rounded corners (set border radius to 0) for square windows
if grep -q "<borderRadius>" ~/.config/openbox/rc.xml; then
    sed -i 's/<borderRadius>.*<\/borderRadius>/<borderRadius>0<\/borderRadius>/g' ~/.config/openbox/rc.xml
else
    # Add border radius setting if it doesn't exist
    sed -i '/<theme>/a\    <borderRadius>0</borderRadius>' ~/.config/openbox/rc.xml
fi

# Set Arc-Dark theme (remove any existing theme name and add new one)
if grep -q "<name>" ~/.config/openbox/rc.xml; then
    sed -i 's|<name>.*</name>|<name>Arc-Dark</name>|g' ~/.config/openbox/rc.xml
else
    # If no theme name exists, add it
    sed -i '/<theme>/a\    <name>Arc-Dark</name>' ~/.config/openbox/rc.xml
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