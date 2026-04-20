local M = {}

M.commands = {}
M.win_id = nil
M.buf_id = nil

M.config = {
    keybind = "<leader>cc",
    toggle_keybind = "<leader>co",
    layout = "split", -- float or split
    split_height = 10,
}

local memory_file = vim.fn.stdpath("data") .. "/qompile_memory.json"

local function load_memory()
    local f = io.open(memory_file, "r")
    if f then
        local content = f:read("*a")
        f:close()
        local ok, parsed = pcall(vim.fn.json_decode, content)
        if ok and type(parsed) == "table" then
            M.commands = parsed
        end
    end
end

local function save_memory()
    local f = io.open(memory_file, "w")
    if f then
        f:write(vim.fn.json_encode(M.commands))
        f:close()
    end
end

local function close_window()
    if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
        vim.api.nvim_win_close(M.win_id, true)
    end
end

local function open_window()
    if M.config.layout == "float" then
        local ui = vim.api.nvim_list_uis()[1]
        local width = math.floor(ui.width * 0.85)
        local height = math.floor(ui.height * 0.35)
        local col = math.floor((ui.width - width) / 2)
        local row = ui.height - height - 3

        M.win_id = vim.api.nvim_open_win(M.buf_id, true, {
            relative = "editor",
            width = width,
            height = height,
            col = col,
            row = row,
            style = "minimal",
            border = "rounded",
            title = " Qompile ",
            title_pos = "center",
        })
    else
        vim.cmd("botright " .. M.config.split_height .. "split")
        M.win_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M.win_id, M.buf_id)
        vim.api.nvim_set_option_value("number", false, { win = M.win_id })
        vim.api.nvim_set_option_value("relativenumber", false, { win = M.win_id })
    end
end

function M.set_command(cmd)
    if cmd == "" or not cmd then
        vim.notify("Qompile: Please provide a command.", vim.log.levels.ERROR)
        return
    end

    local current_file = vim.fn.expand("%:p")
    if current_file == "" then
        vim.notify("Qompile: Cannot set command for an unsaved/scratch buffer.", vim.log.levels.ERROR)
        return
    end

    -- Save it to the table using the file path as the key, then persist to disk
    M.commands[current_file] = cmd
    save_memory()

    local filename = vim.fn.expand("%:t")
    vim.notify("Qompile memory saved for [" .. filename .. "] -> " .. cmd, vim.log.levels.INFO)
end

function M.toggle()
    if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
        close_window()
        return
    end

    if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
        open_window()
    else
        vim.notify("Qompile: No active compilation to show.", vim.log.levels.WARN)
    end
end

function M.run()
    local current_file = vim.fn.expand("%:p")
    local cmd = M.commands[current_file]

    if not cmd then
        vim.notify("Qompile: No command saved for this file! Use :CC <command>", vim.log.levels.WARN)
        return
    end

    close_window()

    if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
        vim.api.nvim_buf_delete(M.buf_id, { force = true })
    end

    M.buf_id = vim.api.nvim_create_buf(false, true)
    open_window()

    local map_opts = { buffer = M.buf_id, silent = true }
    vim.keymap.set("n", "q", close_window, map_opts)
    vim.keymap.set("n", "<CR>", close_window, map_opts)
    vim.keymap.set("n", "<Esc>", close_window, map_opts)
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", map_opts)

    vim.fn.jobstart(cmd, {
        term = true,
        on_exit = function(_, exit_code)
            local escape_keys = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
            vim.api.nvim_feedkeys(escape_keys, "n", false)

            local msg = exit_code == 0 and "Success" or ("Failed (Code: " .. exit_code .. ")")
            local level = exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
            vim.notify("Qompile: " .. msg, level)
        end
    })

    vim.cmd("startinsert")
end

function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)

    load_memory()

    vim.api.nvim_create_user_command("CC", function(ctx)
        M.set_command(ctx.args)
    end, {
        nargs = "+",
        complete = "shellcmd",
        desc = "Set the qompile execution command"
    })

    vim.keymap.set("n", M.config.keybind, M.run, { desc = "Run Qompile command" })
    vim.keymap.set("n", M.config.toggle_keybind, M.toggle, { desc = "Toggle Qompile window" })
end

return M
