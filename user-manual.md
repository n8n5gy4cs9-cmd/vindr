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
- Use Private/Personal, Back, Forward, Stop/Reload, and Copy URL from the left side of the top bar. Click **Go** or press Return to navigate.
- Use the sidebar button immediately after **Go** to open or close the Tools sidebar.
- Use Command-Shift-R or the Browser menu to toggle Reader view.
- Choose DuckDuckGo, Google, or Bing under Settings.
- Click the upward chevron in the top bar, use Command-Shift-T, or use the Browser menu to hide the browser chrome and expand the page. The compact bar remains visible with a downward chevron that restores the toolbar. By default hiding the toolbar also hides the tab strip.
- Click the leftmost Private/Personal pill to switch storage modes. The remaining privacy controls are in Settings.

## Tabs

- Click **+** or press Command-T to create a tab.
- Click a tab title to select it.
- Click **×** or press Command-W to close the selected tab when another tab is available.
- Links using `target="_blank"` and pages using `window.open` open in a vindR tab.
- Background tabs freeze after the interval selected in Settings. A frozen tab restores its last URL, but temporary page state such as forms, media position, and history may be lost.
- While a background tab is waiting to freeze, the optional status badge shows its real remaining time. The badge disappears when no freeze is scheduled.
- Settings can move tabs from the top row into the sidebar.
- If WebKit's content process stops, vindR recreates the affected tab automatically.

## Downloads

1. Click a download link.
2. Choose a filename and destination in the macOS save dialog.
3. Follow activity, completion, or failure in the colored download indicator on the tab/status row.

Downloads continue when switching tabs. Click a completed status to dismiss it.

## Privacy and Site Access

Click the leftmost Private/Personal pill in the top bar to switch between private and persistent website storage. Open Settings for the remaining privacy controls.

- **Block ads and trackers** enables vindR's native WebKit content rules.
- The **Private** state uses non-persistent website storage while green; **Personal** uses persistent storage.
- **Enable JavaScript** controls page JavaScript.
- **Darken pages** applies vindR's reversible dark-page styling.

Settings also provides **Unrestricted browsing**. It permits HTTP pages, accepts invalid HTTPS certificates, and disables WebKit's fraudulent-site warning. Enable it only when you understand the risk and trust the destination.

Use **Clear Website Data** in Settings to remove cookies, caches, local storage, history, and other WebKit website data. This signs websites out but does not remove vindR notes or sketches.

vindR has no telemetry.

## Reader View

Click the document button in the left browser rail or press Command-Shift-R to enter Reader view. vindR extracts the page's main article, removes active elements, and renders it locally. Toggle Reader again to restore the original page.

Reader view requires JavaScript and works best on pages containing an article or main-content region.

## Notes and Sketchpad

Open Notes from the left rail or with Command-Shift-N.

- **Text** is an automatically saved local notebook.
- **Sketch** supports pointer drawing, Undo, and Clear.

Notes are stored at `~/Library/Application Support/vindR/Notes.json` and remain intact when website data is cleared.

## In-App Help

Open **Help** from the TOOLS sidebar for a general vindR guide, privacy and safety notes, and the complete keyboard-shortcut reference.

## Developer Tools

Open Developer Tools from the left rail or with Command-Option-I.

Choose **Sheet**, **Side Panel**, or **Separate Window** under Settings → Developer Features. The existing sheet remains the default. Side Panel places a resizable tools area beside the current page, while Separate Window opens the same tools in their own native window. Both non-modal modes leave the browser toolbar and page usable, so you can reload or navigate while watching Console or Network output. The Browser menu also provides direct **Open Developer Tools In** commands for all three modes.

### Console

The Console is disabled by default. Enable it in Settings or inside the Console view.

- Captures the complete standard Console API: log/info/warn/error/debug/clear, assert/trace, dir/dirxml/table, count/countReset, time/timeLog/timeEnd, and group/groupCollapsed/groupEnd.
- Optionally captures WebKit's profile/profileEnd/timeStamp extensions.
- Captures uncaught errors and unhandled promise rejections.
- Evaluates JavaScript commands in the current page.
- Filters by level or text.
- Recalls command history with the arrow buttons.
- Preserves messages across reloads and redirects until cleared.

Console capture adds page hooks only while enabled. Changing the setting reloads open tabs.

Use **JavaScript Modules…** in Settings or the switch-controls button in the Console toolbar to configure every module independently. Command evaluation, message families, errors, diagnostics, objects, counters, timers, groups, and performance markers each have their own persistent toggle. A disabled capture module injects no hooks.

The same page controls native JavaScript dialogs independently:

- `alert()` shows an OK sheet.
- `confirm()` shows OK/Cancel and returns the choice.
- `prompt()` shows a text field and returns its text or `null` when cancelled.

If a dialog callback is disabled, alerts are silently acknowledged, confirmations return `false`, and prompts return `null`. Disable dialogs for sites that abuse modal prompts.

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
- Whether hiding the toolbar also hides the tab strip
- Sidebar visibility and optional sidebar tabs
- Freeze-countdown and JavaScript-status badge visibility
- Browser chrome font size and toolbar height, with Restore Chrome Defaults
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
| Command-Shift-T | Show or hide the browser chrome |

## Troubleshooting

- If a page is blank or broken, enable JavaScript and reload it.
- If a site is missing content, temporarily disable ad and tracker blocking and reload.
- If a development site uses an invalid certificate, enable Unrestricted browsing only for the time needed.
- If a tab stops responding, switch tabs and return; vindR recreates terminated WebKit content automatically.
- If Console or Network misses initial activity, enable the feature and reload the page.
