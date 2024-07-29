# Neorg Worklog

Log the files you worked on in your daily journal automatically. When a `.norg` file is written to the following will be added to your journal:

```norg
* Worklog
** workspace-name
   - [metadata title]{:/Absolute/path/to/file.norg:}
** journal
   - [2024-07-29]{:/journals/2024-07-29:}
```

Worklog entries are separated by [dirman](https://github.com/nvim-neorg/neorg/wiki/Dirman) workspace name.

## Config

```
["external.worklog"] = {
    -- default config
    config = {
        -- Title content for worklog in journal
        heading = "Worklog"
    }
},
```
