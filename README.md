# vindR

vindR is a small, native macOS browser built with SwiftUI and WebKit. It uses the
system browser engine, includes no third-party packages, collects no telemetry,
and keeps its notes on your Mac.

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer

## Build and run

From the project directory:

```sh
swift build
swift run
```

The first build may take a moment while SwiftPM prepares its local cache.

## User guide

### Browse and search

Enter a URL or search phrase in the location field and press Return. Text that
does not look like a URL is sent to the search engine selected in Settings.

The compact toolbar provides Back, Forward, Stop/Reload, Reader, Privacy,
Developer Tools, Notes, Settings, and Hide Toolbar controls.

### Tabs

- Select a tab by clicking its title.
- Create a tab with the **+** button or Command-T.
- Close a tab with its **×** button or Command-W.
- Links and scripts that request a new browser window (`target="_blank"` or
  `window.open`) open in a new vindR tab.
- Background tabs freeze after the interval selected in Settings (five minutes
  by default). Freezing releases WebKit content to reduce resource use.

A frozen tab restores its last URL when selected. Page history, form contents,
media position, and other temporary in-page state are not restored.

If a WebKit content process terminates unexpectedly, vindR recreates that tab
and reloads its last URL.

### Downloads

Click a page's download link normally. vindR also recognizes server attachments
and file types that WebKit cannot display. A native macOS save dialog lets you
choose the filename and destination before the transfer begins.

The colored download indicator in the toolbar shows active transfers and the
latest success or failure. Click a completed status to dismiss it. Downloads
continue when you switch tabs.

### Privacy controls

Open the shield menu in the toolbar to control:

- **Block ads and trackers:** enables the native WebKit content blocker.
- **Private session:** uses a non-persistent WebKit data store. This setting is
  session-only and is never remembered.
- **Enable JavaScript:** recreates tabs with page JavaScript enabled or disabled.
- **Darken pages:** injects reversible dark-page styling.

Changing the content blocker, private session, or JavaScript setting recreates
open web views, so temporary page state may be lost.

vindR has no telemetry. It does not send notes, settings, terminal output, or
process information anywhere.

### Reader view

Click the document button or press Command-Shift-R. Reader view extracts the
current page's main article content, removes active and distracting elements,
and renders it locally with readable typography.

Reader view requires JavaScript and works best on pages containing an
`article`, `main`, or main-content region. Toggle Reader again to reload the
original page.

### Notes and sketchpad

Open Notes with the pencil button or Command-Shift-N.

- **Text:** a plain local notebook.
- **Sketch:** draw with the pointer; Undo removes the newest stroke and Clear
  removes the sketch.

Changes save automatically to:

```text
~/Library/Application Support/vindR/Notes.json
```

Website-data clearing does not remove this file.

### Developer Tools

Open Developer Tools with the tools button or Command-Option-I.

#### Console

The JavaScript console is off by default. Enable it in Settings or directly in
the Console view. It captures `log`, `info`, `warn`, `error`, `debug`, uncaught
page errors, and unhandled promise rejections. Enter JavaScript in the command
field to evaluate it in the current page; results and exceptions appear inline.

Use the level picker and text search to filter output, the arrow buttons to
recall command history, and Clear to discard the selected tab's log. Each tab
keeps at most 500 messages, and its messages and command history survive page
reloads and redirects.

#### Network

The opt-in Network inspector records page documents, Fetch, XHR, scripts,
stylesheets, images, and other resource loads. It shows method, status, resource
type, duration, and URL with searchable filtering and status coloring. Entries
survive reloads and redirects until cleared. This intentionally remains a
compact request overview rather than a full HAR or response-body inspector.

#### Application

The opt-in Application inspector reads the selected page's script-visible
cookies, local storage, and session storage. Values are searchable and grouped
by storage type. Refresh updates the snapshot; HTTP-only cookies are correctly
not exposed because pages cannot read them.

Console, Network, and Application are independently persisted settings. When
Console and Network are disabled, vindR installs no capture scripts or message
handlers. Application performs work only while enabled and refreshing.

#### Terminal

Terminal access starts disabled. After choosing **Allow for This Session**,
commands run through `/bin/zsh` with your macOS user privileges. Commands can
read, modify, or delete any data available to vindR, so review commands before
running them.

Use Stop to terminate the active command. Disable revokes access and clears the
terminal command and output from memory.

#### Processes

Process inspection also starts disabled. When allowed, the viewer runs a
read-only `ps` snapshot showing PID, CPU, memory, and command path. It refreshes
only when opened or when you click Refresh. Disable clears the snapshot.

### Settings

Open Settings with the gear button or Command-Comma.

Settings include:

- ad/tracker blocking;
- JavaScript;
- unrestricted browsing for HTTP pages, invalid HTTPS certificates, and sites
  flagged by WebKit's fraudulent-site protection;
- dark-page styling;
- DuckDuckGo, Google, or Bing search;
- background-tab freezing after 1, 5, 15, or 30 minutes, or never;
- independent JavaScript Console, Network, and Application inspector toggles;
- website-data clearing.

Unrestricted browsing is off by default. Enabling it recreates open web views
and deliberately removes WebKit's certificate and fraudulent-site safeguards;
use it only for development sites you trust.

**Clear Website Data** removes cookies, caches, local storage, history, and
other WebKit website data after confirmation. Websites will sign out and open
tabs will reload. Notes and sketches remain intact.

### Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| Command-L | Focus the location field |
| Command-K | Clear and focus quick search |
| Command-T | New tab |
| Command-W | Close tab when more than one is open |
| Command-Shift-C | Copy current URL |
| Command-Shift-R | Toggle Reader view |
| Command-Option-I | Open Developer Tools |
| Command-Shift-N | Open Notes and Sketchpad |
| Command-Comma | Open Settings |
| Command-Shift-T | Show or hide the toolbar |

## Architecture

vindR is intentionally dependency-free:

- SwiftUI supplies the application shell and panels.
- WebKit supplies browsing, downloads, private data stores, content blocking,
  and page scripting.
- AppKit supplies macOS integration such as the clipboard and application icon.
- Foundation supplies local notes, shell commands, and process snapshots.

No Chromium runtime or analytics SDK is included.
