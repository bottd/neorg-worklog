local neorg = require("neorg.core")
local modules, lib, log = neorg.modules, neorg.lib, neorg.log

local treesitter ---@type core.integrations.treesitter
local dirman ---@type core.dirman
local journal ---@type core.journal
local metagen ---@type core.esupports.metagen

local module = modules.create("external.worklog")

module.public.config = {
  heading = "Worklog",
}

module.setup = function()
  return {
    success = true,
    requires = { 
      "core.dirman",
      "core.integrations.treesitter",
      "core.journal",
      "core.esupports.metagen"
    },
  }
end

module.load = function()
  dirman = module.required["core.dirman"]
  treesitter = module.required["core.integrations.treesitter"]
  journal = module.required["core.journal"]
  metagen = module.required["core.esupports.metagen"]

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.norg",
    callback = module.log_norg_file
  })
end

module.log_norg_file = function(event)
  dirman.set_closest_workspace_match()
  local workspace = dirman.get_workspace_match()
  local meta = treesitter.get_document_metadata()

  vim.api.nvim_command(":Neorg journal today")

  local bufnr = vim.api.nvim_get_current_buf()
  local journal_path = vim.api.nvim_buf_get_name(bufnr)

  -- do not log journal to it's own worklog
  if event.file == journal_path then
    return
  end

  local worklog_title_line = nil
  local workspace_title_line = nil

  local worklog_title_tmpl = [[
    ((heading1 title: (paragraph_segment) @title)
      (#eq? @title "%s"))
  ]]

  treesitter.execute_query(
    string.format(worklog_title_tmpl, module.public.config.heading),
    function(query, id, node, metadata)
      worklog_title_line = treesitter.get_node_range(node).row_start
    end,
    bufnr
  )

  if worklog_title_line ~= nil then
    local workspace_title_tmpl = [[
      ((heading2 title: (paragraph_segment) @workspace)
        (#eq? @workspace "%s"))
    ]]
    treesitter.execute_query(
      string.format(workspace_title_tmpl, workspace),
      function(query, id, node, metadata)
        local text = treesitter.get_node_text(node)
        workspace_title_line = treesitter.get_node_range(node).row_start
      end,
      bufnr
    )
  end

  -- Check if file already in worklog before insert lines
  if workspace_title_line ~= nil then
    local file_in_worklog = false
    -- escape special characters in file name for search
    local escaped_file = event.file:gsub("([^%w])", "%%%1")
    treesitter.execute_query(
      "(unordered_list1 content: (paragraph) @content)",
      function(query, id, node, metadata)
        local text = treesitter.get_node_text(node)
        if string.match(text, escaped_file) then
          file_in_worklog = true
          return true
        end
    end, 
    bufnr)

    if file_in_worklog then
      -- early return, no insert needed
      return
    end
  end



  local lines = {"   - [" .. (meta.title or event.file) .. "]{:" .. event.file .. ":}"}

  if workspace_title_line == nil then
    table.insert(lines, 1, "** " .. workspace)
  end

  if worklog_title_line == nil then
    table.insert(lines, 1, "* " .. module.public.config.heading)
  end


  if workspace_title_line ~= nil then
    vim.api.nvim_buf_set_lines(bufnr, workspace_title_line + 1, workspace_title_line + 1, false, lines)
  elseif worklog_title_line ~= nil then
    vim.api.nvim_buf_set_lines(bufnr, worklog_title_line + 1, worklog_title_line + 1, false, lines)
  else
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
  end

  vim.cmd('silent! write')
end

return module

