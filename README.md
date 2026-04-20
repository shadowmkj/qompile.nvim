
# qompile.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/Lua-5.1%2B-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

`qompile` is a minimal Neovim plugin that lets you save a shell command per file and run it with a keybind. Output is displayed in a terminal buffer (bottom split or floating window).

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quickstart](#quickstart)
- [Usage](#usage)
- [Configuration](#configuration)
- [Persistence](#persistence)
- [API](#api)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- Per-file commands keyed by absolute path
- Run the current file's command via a configurable keymap
- Output in a terminal buffer (split or float)
- Simple persistence to a JSON file under `stdpath("data")`

## Requirements

- Neovim 0.8+ (uses `vim.api.nvim_create_user_command` and `vim.fn.jobstart`)

## Installation

### lazy.nvim

```lua
{
  "shadowmkj/qompile.nvim",
  config = function()
    require("qompile").setup()
  end,
}
```

### packer.nvim

```lua
use({
  "shadowmkj/qompile.nvim",
  config = function()
    require("qompile").setup()
  end,
})
```

## Quickstart

1. Open a file.
2. Set a command for that file:

```vim
:CC gcc main.c && ./a.out
```

3. Run it with the default keybind: `<leader>cc`.

Note: commands are stored per absolute path (see [Persistence](#persistence)).

## Usage

### Command: `:CC {command...}`

Saves the command for the current file.

- The buffer must be a real file on disk (not an unsaved/scratch buffer).
- The command is saved exactly as typed and executed via `jobstart()`.

Examples:

```vim
" Build a single file
:CC zig run /absolute/path/to/main.zig

" Run tests
:CC pytest -q

" Call a project build
:CC make -j
```

### Run

Press `<leader>cc` (configurable) to run the saved command for the current file.

If no command is saved for the file, qompile will notify you to set one via `:CC ...`.

### Toggle Output Window

Press `<leader>co` (configurable) to show/hide the last output window.

Inside the output window:

- `q`, `<CR>`, `<Esc>` close the window
- In terminal-mode, `<Esc>` switches back to normal-mode

### Defaults

| Action | Default | Notes |
| --- | --- | --- |
| Set per-file command | `:CC ...` | Current buffer must be a saved file |
| Run command | `<leader>cc` | Runs the command for the current file |
| Toggle output | `<leader>co` | Shows/hides last output window |

## Configuration

```lua
require("qompile").setup({
  keybind = "<leader>cc",        -- run saved command
  toggle_keybind = "<leader>co", -- toggle output window
  layout = "split",              -- "split" or "float"
  split_height = 10,              -- only used for "split"
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `keybind` | `string` | `<leader>cc` | Run the saved command for the current file |
| `toggle_keybind` | `string` | `<leader>co` | Toggle the output window |
| `layout` | `"split" \| "float"` | `split` | Where to display output |
| `split_height` | `number` | `10` | Split height when `layout = "split"` |

### Layouts

- `layout = "split"`: opens a bottom split (`botright {split_height}split`). Line numbers are disabled in the output window.
- `layout = "float"`: opens a centered-ish floating window near the bottom with a rounded border and title.

## Persistence

Commands are persisted to:

- `vim.fn.stdpath("data") .. "/qompile_memory.json"`

This file stores a JSON map of:

- key: absolute file path
- value: command string

Notes:

- If you rename/move a file, it will be treated as a different file (new absolute path).
- To clear all saved commands, delete `qompile_memory.json`.
- qompile runs whatever command you save. Treat saved commands as code.

## API

If you want to call it yourself:

- `require("qompile").run()`
- `require("qompile").toggle()`
- `require("qompile").set_command(cmd)`

## Troubleshooting

- "Cannot set command for an unsaved/scratch buffer": save the file first.
- "No command saved for this file": run `:CC ...` while in that file.
- Output window disappears immediately: the command finished quickly; check `:messages` for the success/fail notification (exit code is shown on failure).

## Contributing

Issues and pull requests are welcome. If you change behavior, please update this README to match.

## License

MIT.
