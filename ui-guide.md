# vindR UI Guide

## Direction

Native macOS 13+ dark browser: SwiftUI shell, WKWebView content, SF Pro, standard traffic lights, blur/vibrancy, 16:10 default window. No Chromium/Electron styling, bookmarks bar, extension bar, Windows controls, or embedded Google search bar.

## Layout

- Hideable compact toolbar above tabs: Back, Forward, Stop/Reload, Copy URL; centered capsule location/search field with HTTPS state, search-engine mark, and Reader control; PRIVATE status pill with green non-persistent/red persistent LED; hide chevron.
- Deep navy `#0A1B4D` tab strip. Active tab uses cyan `#22F5C5`; inactive tabs use muted `#1A2A5A`. Tabs show page glyph/title/close, loading state, frozen snowflake, and New Tab.
- WKWebView remains the main surface. Dark-page CSS is reversible; Reader output is sanitized and local.
- Notes/sketchpad and Settings retain their native sheet presentation. Developer Tools keep the original sheet as their default and can also use a resizable side panel or separate native window.
- Download activity stays compact and shows activity, completion, or failure.

## Tool Color

- Console: blue/cyan logs, white info, yellow warnings, red errors, muted debug; monospaced timestamps.
- Network: green success, orange redirect, red failure; Method, Status, Type, Duration, URL.
- Terminal: monospaced zsh output; cyan prompt/input, green success, yellow warning, red failure.
- Processes: read-only PID, CPU, memory, command table.

## Behavior

All sheets, panels, windows, and the toolbar must be dismissible. Developer Tools presentation is persistent and selectable without changing its shared selected-tab data. Console/network/application capture stays off by default and Settings-toggleable. Terminal/process access stays session-authorized. Prefer minimal background work and native frameworks only.
