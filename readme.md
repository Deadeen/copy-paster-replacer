# Batch Code Replacer

A lightweight, purely client-side HTML application designed for high-efficiency, multi-chunk code refactoring. Built specifically to handle sequential updates (such as those provided by LLMs or complex refactoring workflows), this tool allows you to map out multiple find-and-replace blocks, verify their existence across single files or entire directories, and execute them simultaneously with surgical precision.

Operating entirely in the browser using the modern File System Access API, it processes local files securely without requiring backend servers, dependencies, or uploads.

## Core Features

* **Directory-Wide Batch Processing:** Load an entire project folder. The app recursively indexes readable files and instantly highlights which files contain your target code chunks.
* **Dual-Layer Editor Preview:** Features a VS Code-style syntax highlighter (powered by highlight.js) layered beneath precise, color-coded exact match overlays, complete with custom scrollbar indicators.
* **Dynamic Ghost Chunks:** Starts with a single block. The moment you paste code, the app auto-spawns a new faded chunk below it, infinitely scaling to your needs.
* **Smart Validation:** Calculates line-by-line difference percentages between your "Find" and "Replace" inputs, detects accidental duplicate chunks, and confirms target existence in real time.
* **Direct File System Saving:** Writes modifications directly back to the original local files/folders without standard browser download prompts.

---

## JavaScript Function Reference

The application logic is driven by a suite of modular functions designed to manage DOM state, file system operations, and text parsing.

### Text & Parsing Utilities

* **`normalizeText(text)`**
Standardizes line endings by converting `\r\n` (Windows) and `\r` (Classic Mac) to standard `\n` (Unix) formats. This prevents invisible whitespace mismatches that commonly cause find-and-replace operations to fail.
* **`escapeHTML(str)`**
Converts special characters (`&`, `<`, `>`, `'`, `"`) into HTML entities. Required for rendering raw code safely inside the dual-layer preview panel without it executing as actual HTML.
* **`calculateDiffPercentage(str1, str2)`**
Performs a fast, line-by-line comparison between the Find and Replace fields. Returns an approximate difference percentage, or exactly `0` if the strings are perfectly identical, allowing for instant user validation.

### File System & Directory Management

* **`loadFile()`**
Triggers the single-file `showOpenFilePicker()` API. Loads the selected file into memory, updates the UI location badge, resets directory mode, and executes an initial syntax highlight pass.
* **`scanDirectoryRecursive(dirHandle, currentPath)`**
An asynchronous generator that walks the loaded directory tree. It actively ignores heavy/binary directories (e.g., `.git`, `node_modules`, `dist`) to maintain performance, parsing and caching all readable text files into the `loadedDirectoryFiles` array.
* **`loadDirectory()`**
Triggers the `showDirectoryPicker()` API. Initializes the recursive scan, updates the UI to reflect the total indexed file count, and renders the directory sidebar pane.
* **`selectDirectoryFile(index)`**
An event handler that fires when a file is clicked in the directory sidebar. Updates the active `fileContent` and re-runs the highlight parser to display the selected file in the main preview pane.
* **`renderDirectoryFilesList()`**
Generates the HTML for the left-hand directory list. It evaluates all currently active search blocks against the content of every loaded file and dynamically injects color-coded dot markers next to file names that contain exact matches.
* **`downloadFile()`**
Manages saving. In Single File mode, it attempts to use `showSaveFilePicker()` to overwrite the original file directly. In Directory mode, it iterates through `loadedDirectoryFiles`, identifies any marked as `modified`, and writes the changes directly back to disk. Includes a `Blob` fallback for browsers that lack File System Access API support.
* **`copyWholeFile()`**
Writes the entire current state of `fileContent` directly to the OS clipboard.

### Chunk Logic & State Management

* **`addBlock()`**
Generates and injects a new HTML replacement block into the DOM. Automatically assigns the block a unique ID and a sequential accent color from the `chunkColors` array, starting it in a faded "ghost" state.
* **`removeBlock(blockId)`**
Deletes a specific chunk from the DOM. Includes a safety mechanism that prevents the user from deleting the very last remaining block on the page, forcing them to clear its text instead.
* **`updateBlockState(blockId)`**
The core UI state engine triggered by `oninput`.
* Un-fades the chunk when text is entered.
* Calculates and displays the diff percentage.
* Scans prior blocks to display a warning if the user pastes duplicate "Find" text.
* Checks if the active block is the last one in the list, and if so, calls `addBlock()` to spawn a new one, immediately utilizing `scrollIntoView()` to keep the UI perfectly framed.


* **`pasteClipboard(targetTextarea, blockId)`**
Bypasses the `Ctrl+V` requirement by utilizing the `navigator.clipboard` API to read the OS clipboard directly into the target box. Triggers `updateBlockState` and `updateHighlights` immediately after.
* **`applyChanges()`**
The execution engine.
* **Single Mode:** Iterates through every block sequentially against the active file string, executing `.split().join()` replacements and updating success/fail badges.
* **Directory Mode:** Evaluates the chunk list against every single file cached in memory. If any matches are found, it performs the replacements, sets the file's `modified` flag to `true`, and updates the directory list UI to show a `[Modified]` tag.



### Visual Preview Engine

* **`updateHighlights(activeBlockId)`**
Manages the complex dual-layer editor preview.
1. Sends the raw code to the `syntaxLayer` for parsing by Highlight.js.
2. Wraps exact matches of the user's "Find" text in `<mark>` tags and renders them on the completely transparent `highlightLayer` resting precisely above the syntax text.
3. Calculates the vertical offset of every `<mark>` and draws custom CSS indicator lines inside the `markerTrack` scrollbar overlay.
4. If an `activeBlockId` is provided (via pasting or typing), executes a smooth scroll calculation to pan the preview window directly to that chunk's physical location in the code.



### Utilities

* **`logMsg(msg, className)`**
Appends messages to the status log console at the bottom right of the UI, automatically scrolling to the newest entry.
* **`clearLog()`**
Empties the status log console prior to a new batch execution.
* **`window.onload`**
Initializes the application. Spawns the very first "ghost" block and attaches custom `dragover`, `dragleave`, and `drop` event listeners to the "Load File" button to support seamless drag-and-drop file loading.