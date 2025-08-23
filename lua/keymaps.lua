-- space bar leader key
vim.g.mapleader = " "

-- buffers
vim.keymap.set("n", "<leader>n", ":bn<cr>")
vim.keymap.set("n", "<leader>p", ":bp<cr>")
vim.keymap.set("n", "<leader>x", ":bd<cr>")

-- yank to clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])

-- black python formatting
vim.keymap.set("n", "<leader>fmp", ":silent !black %<cr>")

-- resize with arrows (depends on terminal support)
vim.keymap.set("n", "<C-Right>", ":vertical resize +5<CR>", { silent = true })
vim.keymap.set("n", "<C-Left>",  ":vertical resize -5<CR>", { silent = true })
vim.keymap.set("n", "<C-Up>",    ":resize +5<CR>",          { silent = true })
vim.keymap.set("n", "<C-Down>",  ":resize -5<CR>",          { silent = true })
