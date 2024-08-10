local neorg = require("neorg.core")
local modules, lib, log = neorg.modules, neorg.lib, neorg.log

local treesitter ---@type core.integrations.treesitter
local dirman ---@type core.dirman
local journal ---@type core.journal

local module = modules.create("external.worklog")

module.config.public = {
	-- Title content for worklog in journal
	heading = "Worklog",
	-- Title content for "default" workspace
	default_workspace_title = "default",
}

module.setup = function()
	return {
		success = true,
		requires = {
			"core.dirman",
			"core.integrations.treesitter",
			"core.journal",
		},
	}
end

module.load = function()
	dirman = module.required["core.dirman"]
	treesitter = module.required["core.integrations.treesitter"]
	journal = module.required["core.journal"]

	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*.norg",
		callback = module.log_norg_file,
	})
end

module.get_workspace_relative_path = function(path, workspace)
	if workspace == "default" then
		return path
	end

	local workspace_path = dirman.get_workspace(workspace)
	return path:gsub("^" .. workspace_path, "$" .. workspace)
end

module.log_norg_file = function(event)
	local workspace = dirman.get_workspace_match()
	local workspace_title = workspace == "default" and module.config.public.default_workspace_title or workspace
	local meta = treesitter.get_document_metadata()

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = 10,
		height = 10,
		row = 1,
		col = 1,
		hide = true,
	})

	vim.api.nvim_win_call(win, function()
		local ok = pcall(vim.api.nvim_command, ":Neorg journal today")

		if not ok then
			return
		end

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
			string.format(worklog_title_tmpl, module.config.public.heading),
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
				string.format(workspace_title_tmpl, workspace_title),
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
			-- Escape special characters in file name for search
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
				bufnr
			)

			if file_in_worklog then
				-- Early return, no insert needed
				vim.api.nvim_buf_delete(bufnr, {})
				return
			end
		end

		local lines = {
			"   - {:"
				.. module.get_workspace_relative_path(event.file, workspace)
				.. ":}["
				.. (meta.title or event.file)
				.. "]",
		}

		if workspace_title_line == nil then
			table.insert(lines, 1, "** " .. workspace_title)
		end

		if worklog_title_line == nil then
			table.insert(lines, 1, "* " .. module.config.public.heading)
		end

		if workspace_title_line ~= nil then
			vim.api.nvim_buf_set_lines(bufnr, workspace_title_line + 1, workspace_title_line + 1, false, lines)
		elseif worklog_title_line ~= nil then
			vim.api.nvim_buf_set_lines(bufnr, worklog_title_line + 1, worklog_title_line + 1, false, lines)
		else
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
		end

		vim.cmd("silent! write")
		vim.api.nvim_buf_delete(bufnr, {})
	end)
end

return module
