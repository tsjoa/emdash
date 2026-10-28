#!/bin/bash
# setup.sh - Configures Windows 11-style en-dash and em-dash shortcuts in KDE Plasma 6.
#
# Shortcuts added:
#   Win + -         -> En Dash (–)
#   Win + Shift + - -> Em Dash (—)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"

echo "=== Setting up En Dash and Em Dash shortcuts for KDE Plasma ==="

# 1. Check dependencies
if [ "${XDG_SESSION_TYPE:-x11}" = "x11" ]; then
    if ! command -v xdotool >/dev/null 2>&1; then
        echo "--> Installing missing dependency: xdotool"
        if command -v sudo >/dev/null 2>&1; then
            sudo apt-get update -qq && sudo apt-get install -y xdotool
        else
            echo "Error: 'xdotool' is required on X11. Please install it using: apt install xdotool" >&2
            exit 1
        fi
    fi
else
    if ! command -v wtype >/dev/null 2>&1 && ! command -v ydotool >/dev/null 2>&1; then
        echo "--> Note: On Wayland, 'wtype' or 'ydotool' is required."
        if command -v sudo >/dev/null 2>&1; then
            sudo apt-get update -qq && sudo apt-get install -y wtype
        fi
    fi
fi

# 2. Install executable helper
mkdir -p "${BIN_DIR}" "${APP_DIR}"
cp -f "${SCRIPT_DIR}/insert-dash" "${BIN_DIR}/insert-dash"
chmod +x "${BIN_DIR}/insert-dash"
echo "--> Installed helper to ${BIN_DIR}/insert-dash"

# 3. Resolve KWin conflict: KWin defaults Meta+- to 'Zoom Out'
echo "--> Checking for KWin shortcut conflicts (Meta+- for Zoom Out)..."
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" --key "view_zoom_out" "none,none,Zoom Out"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "view_zoom_out" "none,none,Zoom Out"
fi

# If kglobalaccel is running on DBus, unbind view_zoom_out live
python3 -c "
import dbus
try:
    bus = dbus.SessionBus()
    obj = bus.get_object('org.kde.kglobalaccel', '/kglobalaccel')
    iface = dbus.Interface(obj, 'org.kde.KGlobalAccel')
    action_kwin = ['kwin', 'view_zoom_out', '', '']
    iface.setForeignShortcut(action_kwin, dbus.Array([], signature='i'))
except Exception:
    pass
" 2>/dev/null || true

# 4. Create Desktop Action file for KDE shortcuts
cat << EOF > "${APP_DIR}/insert-dash.desktop"
[Desktop Entry]
Type=Application
Name=Dash Shortcuts
Exec=${BIN_DIR}/insert-dash
NoDisplay=true
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
Actions=en-dash;em-dash;

[Desktop Action en-dash]
Name=Insert En Dash (–)
Exec=${BIN_DIR}/insert-dash en
X-KDE-Shortcuts=Meta+-

[Desktop Action em-dash]
Name=Insert Em Dash (—)
Exec=${BIN_DIR}/insert-dash em
X-KDE-Shortcuts=Meta+Shift+-,Meta+_
EOF

echo "--> Created shortcut definition: ${APP_DIR}/insert-dash.desktop"

# 5. Rebuild application sycoca cache
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1
fi

# 6. Reload kglobalacceld daemon so shortcuts become active immediately
if systemctl --user is-active --quiet plasma-kglobalaccel.service 2>/dev/null; then
    systemctl --user restart plasma-kglobalaccel.service
fi

echo ""
echo "=== Success! Shortcuts are active ==="
echo "• Win + -         -> En Dash (–)"
echo "• Win + Shift + - -> Em Dash (—)"
echo ""
echo "You can view or reconfigure them anytime in KDE System Settings -> Shortcuts -> Dash Shortcuts."
