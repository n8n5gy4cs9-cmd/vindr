# vindR User Manual

## System Requirements

- macOS 13 or newer
- A Mac whose CPU architecture matches the app build; `build-app.sh` produces a native build for the Mac running it

## Install and Open

1. Extract `vindR-macOS.zip`.
2. Move `vindR.app` to the Applications folder, or run it from the extracted folder.
3. Open `vindR.app`.

The local build script does not apply a Developer ID signature or notarize vindR. If macOS blocks the first launch, Control-click the app, choose **Open**, and confirm only when you trust the ZIP's source.

## Browse and Search

- Enter a full URL or a search phrase in the location field and press Return.
- Use Back, Forward, Stop, and Reload beside the location field.
- Choose DuckDuckGo, Google, or Bing under Settings.
- Use the chevron at the right of the toolbar to hide it. Press Command-Shift-T to show it again.

## Tabs

- Click **+** or press Command-T to create a tab.
- Click a tab title to select it.
- Click **×** or press Command-W to close the selected tab when another tab is available.
- Links using `target="_blank"` and pages using `window.open` open in a vindR tab.
- Background tabs freeze after the interval selected in Settings. A frozen tab restores its last URL, but temporary page state such as forms, media position, and history may be lost.
- If WebKit's content process stops, vindR recreates the affected tab automatically.

## Downloads

1. Click a download link.
2. Choose a filename and destination in the macOS save dialog.
3. Follow activity, completion, or failure in the colored download indicator on the toolbar.

Downloads continue when switching tabs. Click a completed status to dismiss it.

## Privacy and Site Access

Open the shield menu in the toolbar for quick privacy controls.

- **Block ads and trackers** enables vindR's native WebKit content rules.
- **Private session** uses non-persistent website storage for the current session.
- **Enable JavaScript** controls page JavaScript.
- **Darken pages** applies vindR's reversible dark-page styling.

Settings also provides **Unrestricted browsing**. It permits HTTP pages, accepts invalid HTTPS certificates, and disables WebKit's fraudulent-site warning. Enable it only when you understand the risk and trust the destination.

Use **Clear Website Data** in Settings to remove cookies, caches, local storage, history, and other WebKit website data. This signs websites out but does not remove vindR notes or sketches.

vindR has no telemetry.

## Reader View

Click the document button or press Command-Shift-R to enter Reader view. vindR extracts the page's main article, removes active elements, and renders it locally. Toggle Reader again to restore the original page.

Reader view requires JavaScript and works best on pages containing an article or main-content region.

## Notes and Sketchpad

Open Notes with the pencil button or Command-Shift-N.

- **Text** is an automatically saved local notebook.
- **Sketch** supports pointer drawing, Undo, and Clear.

Notes are stored at `~/Library/Application Support/vindR/Notes.json` and remain intact when website data is cleared.

## Developer Tools

Open Developer Tools with the tools button or Command-Option-I.

### Console

The Console is disabled by default. Enable it in Settings or inside the Console view.

- Captures log, info, warning, error, and debug messages.
- Captures uncaught errors and unhandled promise rejections.
- Evaluates JavaScript commands in the current page.
- Filters by level or text.
- Recalls command history with the arrow buttons.
- Preserves messages across reloads and redirects until cleared.

Console capture adds page hooks only while enabled. Changing the setting reloads open tabs.

### Network

The Network inspector is disabled by default. When enabled, it displays document, Fetch, XHR, script, stylesheet, image, and other resource requests with method, status, type, duration, and URL. Search filters the list; Clear removes the selected tab's entries.

Network capture adds page hooks only while enabled. It is a compact request overview and does not capture complete HAR files or response bodies.

### Application

The Application inspector is disabled by default. When enabled, it reads the selected page's script-visible cookies, local storage, and session storage. Use search to filter keys and values and Refresh to update the snapshot. HTTP-only cookies remain unavailable because web pages cannot read them.

### Terminal

Terminal access begins disabled and requires explicit session permission. Commands run through `/bin/zsh` with the current macOS user's privileges and can read, modify, or delete data available to vindR. Review commands before running them.

- **Run** starts a command.
- **Stop** terminates the active command.
- **Clear** removes displayed output.
- **Disable** revokes permission and clears command state and output.

### Processes

Process inspection begins disabled and requires explicit session permission. It displays a read-only snapshot of PID, CPU use, memory use, and command paths. Refresh updates the snapshot; Disable clears it.

## Settings

Settings includes:

- Ad and tracker blocking
- JavaScript
- Unrestricted browsing
- Dark-page styling
- Search-engine selection
- Background-tab freeze timing
- JavaScript Console, Network, and Application inspector toggles
- Website-data clearing
- Keyboard-shortcut reference

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| Command-L | Focus the location field |
| Command-K | Clear and focus quick search |
| Command-T | Create a tab |
| Command-W | Close the selected tab |
| Command-Shift-C | Copy the current URL |
| Command-Shift-R | Toggle Reader view |
| Command-Option-I | Open Developer Tools |
| Command-Shift-N | Open Notes and Sketchpad |
| Command-Comma | Open Settings |
| Command-Shift-T | Show or hide the toolbar |

## Troubleshooting

- If a page is blank or broken, enable JavaScript and reload it.
- If a site is missing content, temporarily disable ad and tracker blocking and reload.
- If a development site uses an invalid certificate, enable Unrestricted browsing only for the time needed.
- If a tab stops responding, switch tabs and return; vindR recreates terminated WebKit content automatically.
- If Console or Network misses initial activity, enable the feature and reload the page.
