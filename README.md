# Windows-Style Dash Keyboard Shortcuts for KDE Plasma

Mimics the native Windows 11 en-dash and em-dash shortcuts on **Debian 13 (Trixie)** running **KDE Plasma 6** (and Plasma 5):

| Character | Name | Keyboard Shortcut | Unicode | Width | Typical Usage |
| :---: | :---: | :---: | :---: | :---: | :--- |
| **`-`** | **Hyphen** | `-` | `U+002D` | Short | Compound words (*mother-in-law*), phone numbers |
| **`–`** | **En Dash** (n-dash) | <kbd>Win</kbd> + <kbd>-</kbd> | `U+2013` | Medium (*width of 'N'*) | Number/date ranges (*1990–2000*, *pages 15–20*), connections (*London–Paris*) |
| **`—`** | **Em Dash** (m-dash) | <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>-</kbd> | `U+2014` | Long (*width of 'M'*) | Break in thought—like this—replacing parentheses, colons, or commas |

> **Reference:** [Windows 11 adds Win key shortcuts for en and em dashes](https://windowsforum.com/news/windows-11-adds-win-key-shortcuts-for-en-and-em-dashes.388252)

---

## Visual Comparison

```text
Hyphen:   -   (U+002D)  [Standard minus key]
En Dash:  –   (U+2013)  [Win + -]
Em Dash:  —   (U+2014)  [Win + Shift + -]
```

---

## How It Works in KDE Plasma 6

1. **Native Global Shortcut Registration:**
   In Plasma 6, custom command shortcuts are declared via XDG application desktop entries (`.desktop`) with `X-KDE-Shortcuts` and `X-KDE-GlobalAccel-CommandShortcut=true`.
   This repo installs `~/.local/share/applications/insert-dash.desktop`, registering the actions directly into KDE's `kglobalacceld` daemon. They appear under **System Settings → Shortcuts → Dash Shortcuts**.

2. **KWin Zoom Conflict Resolution:**
   In KDE Plasma, KWin's window manager binds `Meta + -` by default to "Zoom Out". To allow `Win + -` to type an En Dash, the setup script rebinds KWin's `view_zoom_out` to `none`.

3. **Character Injection Across Environments:**
   * **X11:** Uses `xdotool key --clearmodifiers <keysym>`. The script ensures the keysyms (`endash`, `emdash`) are mapped in the active X keymap and temporarily clears modifier masks during event delivery so applications don't receive stuck Super/Shift keys.
   * **Wayland:** Uses `wtype` or `ydotool` to inject the Unicode string directly into the focused Wayland surface.

---

## Exact System Amendments & Audit

When `setup.sh` is executed, the following modifications are applied to the system:

### 1. KDE Configuration (`~/.config/kglobalshortcutsrc`)
* **Group:** `[kwin]`
* **Previous Value:** `view_zoom_out=Meta+-,Meta+-,Zoom Out`
* **New Value:** `view_zoom_out=none,none,Zoom Out`
*(Restores cleanly upon running `uninstall.sh`)*.

### 2. User Files Installed
* **`/home/<user>/.local/bin/insert-dash`** (Mode `775`):
  Executable helper invoked by the shortcuts.
* **`/home/<user>/.local/share/applications/insert-dash.desktop`** (Mode `664`):
  XDG action definition defining `en-dash` (`Meta+-`) and `em-dash` (`Meta+Shift+-`, `Meta+_`).

### 3. Packages Installed (Debian / APT)
* **`xdotool`** and runtime dependency **`libxdo3`** (installed via `apt-get install -y xdotool`).

### 4. System Daemons Refreshed
* **KService Cache:** Rebuilt using `kbuildsycoca6 --noincremental`.
* **KGlobalAccel Daemon:** Reloaded using `systemctl --user restart plasma-kglobalaccel.service`.

### 5. Volatile Session Mapping (X11)
* Two unassigned keycodes (e.g. `8` and `202`) are dynamically mapped to `endash` and `emdash` via `xmodmap` for the running X11 session.

---

## Installation

To set up the shortcuts:

```bash
git clone https://github.com/tsjoa/emdash.git
cd emdash
./setup.sh
```

The shortcuts become active immediately without requiring a logout or reboot.

---

## Testing & Verification

Open any application (such as Kate, Konsole, Firefox, or LibreOffice):
* Press <kbd>Win</kbd> + <kbd>-</kbd> $\rightarrow$ Inserts **`–`** (En Dash)
* Press <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>-</kbd> $\rightarrow$ Inserts **`—`** (Em Dash)
* Press <kbd>-</kbd> $\rightarrow$ Inserts **`-`** (Regular Hyphen)

---

## Uninstallation / Complete Reversion

To remove the custom shortcuts and restore all original KDE settings:

```bash
cd emdash
./uninstall.sh
```

What `uninstall.sh` reverts:
1. Deletes `~/.local/bin/insert-dash` and `~/.local/share/applications/insert-dash.desktop`.
2. Restores KWin's `view_zoom_out` back to `Meta+-,Meta+-,Zoom Out`.
3. Rebuilds the KDE sycoca cache (`kbuildsycoca6`) and restarts `plasma-kglobalaccel.service`.

---

## License

This project is licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).

You are free to use, copy, modify, and distribute this software, provided that any derivative works or redistributions remain open under the same GNU GPLv3 license terms.
