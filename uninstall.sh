#!/bin/bash
# uninstall.sh - Removes en-dash and em-dash shortcuts and restores default KWin shortcuts.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"

echo "=== Removing En Dash and Em Dash shortcuts ==="

# 1. Remove files
rm -f "${BIN_DIR}/insert-dash"
rm -f "${APP_DIR}/insert-dash.desktop"
echo "--> Removed ${BIN_DIR}/insert-dash and ${APP_DIR}/insert-dash.desktop"

# 2. Restore KWin Zoom Out shortcut (Meta+-)
echo "--> Restoring KWin Zoom Out shortcut to Meta+-..."
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" --key "view_zoom_out" "Meta+-,Meta+-,Zoom Out"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file kglobalshortcutsrc --group "kwin" --key "view_zoom_out" "Meta+-,Meta+-,Zoom Out"
fi

python3 -c "
import dbus
try:
    bus = dbus.SessionBus()
    obj = bus.get_object('org.kde.kglobalaccel', '/kglobalaccel')
    iface = dbus.Interface(obj, 'org.kde.KGlobalAccel')
    action_kwin = ['kwin', 'view_zoom_out', '', '']
    iface.setForeignShortcut(action_kwin, dbus.Array([0x1000002d], signature='i'))
except Exception:
    pass
" 2>/dev/null || true

# 3. Rebuild sycoca cache
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1
fi

# 4. Restart kglobalacceld
if systemctl --user is-active --quiet plasma-kglobalaccel.service 2>/dev/null; then
    systemctl --user restart plasma-kglobalaccel.service
fi

echo "=== Uninstallation Complete ==="
