# Neorg Worklog
[![LuaRocks](https://img.shields.io/luarocks/v/bottd/neorg-worklog?logo=lua&color=purple)](https://luarocks.org/modules/bottd/neorg-worklog)

Log the files you worked on in your daily journal automatically. When a `.norg` file is written to the following will be added to your journal:

```norg
* Worklog
** workspace-name
   - {:$workspace-name/path/to/file.norg:}[metadata title]
** journal
   - {:$journals/daily/2024-07-29:}[2024-07-29]
** config.default_workspace_title (.norg files not within a workspace)
   - {:/Absolute/path/to/file.norg:}[title]
```

Worklog entries are separated by [dirman](https://github.com/nvim-neorg/neorg/wiki/Dirman) workspace name.

## Installing

Rocks.nvim 🗿

`:Rocks install neorg-worklog`

<details>
  <summary>Lazy.nvim</summary>

```lua
-- neorg.lua
{
    "nvim-neorg/neorg",
    lazy = false,
    version = "*",
    config = true,
    dependencies = {
        { "bottd/neorg-worklog" }
    }
}
```
</details>

## Config

```
["external.worklog"] = {
    -- default config
    config = {
        -- (Optional) Title for worklog in journal
        heading = "Worklog",
        -- (Optional) Title for "default" workspace
        default_workspace_title = "default"
    }
},
```

## Known Issues

- Notification of today's journal being written in status line

## Feature Ideas

- Sort workspace headings
- Sort file links
- Separate files created and files modified
