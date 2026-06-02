-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- =========================
-- C build / run workflow
-- =========================

-- Build-only
map("n", "<leader>mb", function()
  vim.cmd("!cc % -g -O0 -o %:r")
end, { desc = "[M]ake [B]uffer (build only)" })

-- Build & Run
map("n", "<leader>mr", function()
  local file = vim.fn.expand("%")
  local output = vim.fn.expand("%:r")
  local stem = vim.fn.fnamemodify(output, ":t")
  vim.cmd(string.format("!cc %s -g -O0 -o %s && ./%s", file, output, stem))
end, { desc = "[M]ake and [R]un current buffer" })

-- Quickfix
map("n", "]q", "<cmd>cnext<CR>", { desc = "Quickfix next" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "Quickfix prev" })
map("n", "<leader>qq", "<cmd>copen<CR>", { desc = "Quickfix open" })

-- Clangd header/source switch
map("n", "<leader>oh", "<cmd>ClangdSwitchSourceHeader<CR>", {
  desc = "[O]pen header/source (clangd)",
})

-- Toggle diagnostics virtual text
map("n", "<leader>tv", function()
  local vt = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not vt })
end, { desc = "[T]oggle diagnostics [V]irtual text" })

-- Format + save
map("n", "<leader>fs", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ lsp_fallback = true, quiet = true })
  else
    pcall(vim.lsp.buf.format, { async = false })
  end
  vim.cmd("write")
end, { desc = "[F]ormat and [S]ave" })

-- Save file
map("n", "<leader>ww", function()
  vim.cmd("write")
end, { desc = "[W]rite file" })

-- =========================
-- Wiki / Notes workflow
--
-- Git root:  ~/dev/cs
-- Wiki root: ~/dev/cs/wiki
-- =========================

-- Better gf navigation for markdown/wiki files
vim.opt.path:append("**")
vim.opt.suffixesadd:append(".md")

local GIT_ROOT = vim.fn.expand("~/dev/cs")
local WIKI_ROOT = vim.fn.expand("~/dev/cs/wiki")

local function path_join(...)
  return table.concat({ ... }, "/")
end

local function wiki_path(...)
  return path_join(WIKI_ROOT, ...)
end

local function make_current_buffer_normal()
  -- Fixes cases where a command is run from a terminal/dashboard/picker/special buffer.
  -- Without this, :write can fail with:
  -- E382: Cannot write, 'buftype' option is set
  vim.bo.buftype = ""
  vim.bo.bufhidden = ""
  vim.bo.swapfile = true
  vim.bo.modifiable = true
  vim.bo.readonly = false
end

local function open_wiki_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  make_current_buffer_normal()
end

local function read_template(template_path, at_top)
  local full_path = wiki_path(template_path)

  if vim.fn.filereadable(full_path) == 0 then
    vim.notify("Template not found: " .. full_path, vim.log.levels.ERROR)
    return
  end

  make_current_buffer_normal()

  if at_top then
    vim.cmd("0read " .. vim.fn.fnameescape(full_path))
  else
    vim.cmd("read " .. vim.fn.fnameescape(full_path))
  end
end

local function ensure_parent_dir(file_path)
  local dir = vim.fn.fnamemodify(file_path, ":h")

  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function create_note_with_template(prompt_label, base_dir, template_path)
  local input = vim.fn.input(prompt_label .. " inside " .. base_dir .. "/: ", "", "file")

  if input == nil or input == "" then
    vim.notify("Cancelled note creation", vim.log.levels.WARN)
    return
  end

  if not input:match("%.md$") then
    input = input .. ".md"
  end

  local note_path = wiki_path(base_dir, input)
  ensure_parent_dir(note_path)

  local is_new = vim.fn.filereadable(note_path) == 0

  open_wiki_file(note_path)

  if is_new then
    read_template(template_path, true)
    vim.notify("Created note: " .. base_dir .. "/" .. input)
  else
    vim.notify("Opened existing note: " .. base_dir .. "/" .. input)
  end
end

local function create_problem_note()
  local input = vim.fn.input("New problem note inside notes/algorithms/problems/: ", "", "file")

  if input == nil or input == "" then
    vim.notify("Cancelled problem note creation", vim.log.levels.WARN)
    return
  end

  if not input:match("%.md$") then
    input = input .. ".md"
  end

  local note_path = wiki_path("notes/algorithms/problems", input)
  ensure_parent_dir(note_path)

  local is_new = vim.fn.filereadable(note_path) == 0

  open_wiki_file(note_path)

  if is_new then
    read_template("notes/templates/problem_note_template.md", true)
    vim.notify("Created problem note: notes/algorithms/problems/" .. input)
  else
    vim.notify("Opened existing problem note: notes/algorithms/problems/" .. input)
  end
end

local function create_anki_file_with_template(prompt_label, template_path)
  local input = vim.fn.input(prompt_label .. " inside anki/: ", "", "file")

  if input == nil or input == "" then
    vim.notify("Cancelled Anki file creation", vim.log.levels.WARN)
    return
  end

  if not input:match("%.tsv$") then
    input = input .. ".tsv"
  end

  local anki_path = wiki_path("anki", input)
  ensure_parent_dir(anki_path)

  local is_new = vim.fn.filereadable(anki_path) == 0

  open_wiki_file(anki_path)

  if is_new then
    read_template(template_path, true)
    vim.notify("Created Anki file: anki/" .. input)
  else
    vim.notify("Opened existing Anki file: anki/" .. input)
  end
end

local function telescope_find_notes()
  local ok, builtin = pcall(require, "telescope.builtin")

  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  builtin.find_files({
    prompt_title = "Find Wiki Files",
    cwd = WIKI_ROOT,
    search_dirs = {
      wiki_path("notes"),
      wiki_path("active"),
      wiki_path("anki"),
      wiki_path("daily"),
      wiki_path("weekly_reviews"),
      wiki_path("monthly_reviews"),
    },
  })
end

local function telescope_grep_notes()
  local ok, builtin = pcall(require, "telescope.builtin")

  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  builtin.live_grep({
    prompt_title = "Grep Wiki",
    cwd = WIKI_ROOT,
    search_dirs = {
      wiki_path("notes"),
      wiki_path("active"),
      wiki_path("anki"),
      wiki_path("daily"),
      wiki_path("weekly_reviews"),
      wiki_path("monthly_reviews"),
    },
  })
end

local function git_stage_and_commit()
  local msg = vim.fn.input("Commit message: ")

  if msg == nil or msg == "" then
    vim.notify("Commit cancelled: empty message", vim.log.levels.WARN)
    return
  end

  local add_output = vim.fn.system({ "git", "-C", GIT_ROOT, "add", "-A" })

  if vim.v.shell_error ~= 0 then
    vim.notify("git add failed:\n" .. add_output, vim.log.levels.ERROR)
    return
  end

  local commit_output = vim.fn.system({ "git", "-C", GIT_ROOT, "commit", "-m", msg })

  if vim.v.shell_error ~= 0 then
    vim.notify("git commit failed:\n" .. commit_output, vim.log.levels.ERROR)
    return
  end

  vim.notify("Committed repo: " .. msg)
end

local function open_lazygit()
  -- If you have a LazyGit plugin command, use it.
  if vim.fn.exists(":LazyGit") == 2 then
    vim.cmd("LazyGit")
    return
  end

  -- Fallback: open lazygit in terminal split at Git root.
  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("terminal cd " .. vim.fn.fnameescape(GIT_ROOT) .. " && lazygit")
  vim.cmd("startinsert")
end

local function create_daily_note()
  local date = os.date("%Y-%m-%d")
  local note_path = wiki_path("daily", date .. ".md")

  ensure_parent_dir(note_path)

  local is_new = vim.fn.filereadable(note_path) == 0

  open_wiki_file(note_path)

  if is_new then
    read_template("notes/templates/daily_note_template.md", true)

    -- Replace placeholder date safely
    vim.cmd("%s/YYYY-MM-DD/" .. date .. "/ge")

    make_current_buffer_normal()
    vim.cmd("write")

    vim.notify("Created daily note: daily/" .. date .. ".md")
  else
    vim.notify("Opened daily note: daily/" .. date .. ".md")
  end
end

local function create_generic_note()
  local input = vim.fn.input("New generic note inside notes/: ", "", "file")

  if input == nil or input == "" then
    vim.notify("Cancelled generic note creation", vim.log.levels.WARN)
    return
  end

  if not input:match("%.md$") then
    input = input .. ".md"
  end

  local note_path = wiki_path("notes", input)
  ensure_parent_dir(note_path)

  local is_new = vim.fn.filereadable(note_path) == 0

  open_wiki_file(note_path)

  if is_new then
    read_template("notes/templates/generic_note_template.md", true)
    vim.notify("Created generic note: notes/" .. input)
  else
    vim.notify("Opened existing generic note: notes/" .. input)
  end
end

local function generate_weekly_review()
  local script = vim.fn.expand("~/dev/cs/wiki/scripts/generate_weekly_review.sh")
  local output = vim.fn.systemlist(script)

  if vim.v.shell_error ~= 0 then
    vim.notify("Weekly review generation failed:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR)
    return
  end

  local review_path = output[#output]

  if review_path == nil or review_path == "" then
    vim.notify("No weekly review path returned", vim.log.levels.ERROR)
    return
  end

  open_wiki_file(review_path)
  vim.notify("Opened weekly review: " .. review_path)
end

local function generate_monthly_review()
  local script = vim.fn.expand("~/dev/cs/wiki/scripts/generate_monthly_review.sh")
  local output = vim.fn.systemlist(script)

  if vim.v.shell_error ~= 0 then
    vim.notify("Monthly review generation failed:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR)
    return
  end

  local review_path = output[#output]

  if review_path == nil or review_path == "" then
    vim.notify("No monthly review path returned", vim.log.levels.ERROR)
    return
  end

  open_wiki_file(review_path)
  vim.notify("Opened monthly review: " .. review_path)
end

local function open_script_terminal(script_path, title)
  local full_path = vim.fn.expand(script_path)

  if vim.fn.filereadable(full_path) == 0 then
    vim.notify(title .. " script not found: " .. full_path, vim.log.levels.ERROR)
    return
  end

  vim.cmd("botright split")
  vim.cmd("resize 20")
  vim.cmd("terminal " .. vim.fn.fnameescape(full_path))
  vim.cmd("startinsert")
end

-- =========================
-- User commands
-- =========================

vim.api.nvim_create_user_command("WikiRoot", function()
  open_wiki_file(wiki_path("index.md"))
end, {})

vim.api.nvim_create_user_command("NoteTemplate", function()
  read_template("notes/templates/study_note_template.md", false)
end, {})

vim.api.nvim_create_user_command("AtomicTemplate", function()
  read_template("notes/templates/atomic_note_template.md", false)
end, {})

vim.api.nvim_create_user_command("BookNoteTemplate", function()
  read_template("notes/templates/book_note_template.md", false)
end, {})

vim.api.nvim_create_user_command("TopicIndexTemplate", function()
  read_template("notes/templates/topic_index_template.md", false)
end, {})

vim.api.nvim_create_user_command("AnkiBasicTemplate", function()
  read_template("anki/templates/basic_template.tsv", false)
end, {})

vim.api.nvim_create_user_command("AnkiClozeTemplate", function()
  read_template("anki/templates/cloze_template.tsv", false)
end, {})

vim.api.nvim_create_user_command("NewStudyNote", function()
  create_note_with_template("New study note", "notes", "notes/templates/study_note_template.md")
end, {})

vim.api.nvim_create_user_command("NewAtomicNote", function()
  create_note_with_template("New atomic note", "notes", "notes/templates/atomic_note_template.md")
end, {})

vim.api.nvim_create_user_command("NewBookNote", function()
  create_note_with_template("New book note", "notes/books", "notes/templates/book_note_template.md")
end, {})

vim.api.nvim_create_user_command("NewTopicIndex", function()
  create_note_with_template("New topic index", "notes", "notes/templates/topic_index_template.md")
end, {})

vim.api.nvim_create_user_command("NewAnkiBasic", function()
  create_anki_file_with_template("New basic Anki file", "anki/templates/basic_template.tsv")
end, {})

vim.api.nvim_create_user_command("NewAnkiCloze", function()
  create_anki_file_with_template("New cloze Anki file", "anki/templates/cloze_template.tsv")
end, {})

vim.api.nvim_create_user_command("ProblemNoteTemplate", function()
  read_template("notes/templates/problem_note_template.md", false)
end, {})

vim.api.nvim_create_user_command("NewProblemNote", function()
  create_problem_note()
end, {})

vim.api.nvim_create_user_command("DailyNote", function()
  create_daily_note()
end, {})

vim.api.nvim_create_user_command("NewGenericNote", function()
  create_generic_note()
end, {})

vim.api.nvim_create_user_command("DailyNoteTemplate", function()
  read_template("notes/templates/daily_note_template.md", false)
end, {})

vim.api.nvim_create_user_command("GenericNoteTemplate", function()
  read_template("notes/templates/generic_note_template.md", false)
end, {})

vim.api.nvim_create_user_command("WikiFind", telescope_find_notes, {})
vim.api.nvim_create_user_command("WikiGrep", telescope_grep_notes, {})
vim.api.nvim_create_user_command("WikiCommit", git_stage_and_commit, {})
vim.api.nvim_create_user_command("WikiLazyGit", open_lazygit, {})

vim.api.nvim_create_user_command("GenerateWeeklyReview", function()
  generate_weekly_review()
end, {})

vim.api.nvim_create_user_command("GenerateMonthlyReview", function()
  generate_monthly_review()
end, {})

-- =========================
-- Leader+n keymaps
-- =========================

map("n", "<leader>nn", function()
  create_note_with_template("New study note", "notes", "notes/templates/study_note_template.md")
end, { desc = "[N]ew study [N]ote" })

map("n", "<leader>na", function()
  create_note_with_template("New atomic note", "notes", "notes/templates/atomic_note_template.md")
end, { desc = "[N]ew [A]tomic note" })

map("n", "<leader>nb", function()
  create_note_with_template("New book note", "notes/books", "notes/templates/book_note_template.md")
end, { desc = "[N]ew [B]ook note" })

map("n", "<leader>ni", function()
  create_note_with_template("New topic index", "notes", "notes/templates/topic_index_template.md")
end, { desc = "[N]ew topic [I]ndex" })

map("n", "<leader>nt", function()
  read_template("notes/templates/study_note_template.md", false)
end, { desc = "[N]ote insert study [T]emplate" })

map("n", "<leader>nA", function()
  read_template("notes/templates/atomic_note_template.md", false)
end, { desc = "[N]ote insert [A]tomic template" })

map("n", "<leader>nB", function()
  read_template("notes/templates/book_note_template.md", false)
end, { desc = "[N]ote insert [B]ook template" })

map("n", "<leader>nI", function()
  read_template("notes/templates/topic_index_template.md", false)
end, { desc = "[N]ote insert topic [I]ndex template" })

map("n", "<leader>nab", function()
  read_template("anki/templates/basic_template.tsv", false)
end, { desc = "[N]otes [A]nki [B]asic template" })

map("n", "<leader>nac", function()
  read_template("anki/templates/cloze_template.tsv", false)
end, { desc = "[N]otes [A]nki [C]loze template" })

map("n", "<leader>nfb", function()
  create_anki_file_with_template("New basic Anki file", "anki/templates/basic_template.tsv")
end, { desc = "[N]ew Anki [B]asic file" })

map("n", "<leader>nfc", function()
  create_anki_file_with_template("New cloze Anki file", "anki/templates/cloze_template.tsv")
end, { desc = "[N]ew Anki [C]loze file" })

map("n", "<leader>nf", telescope_find_notes, {
  desc = "[N]otes [F]ind",
})

map("n", "<leader>ng", telescope_grep_notes, {
  desc = "[N]otes [G]rep",
})

map("n", "<leader>nc", git_stage_and_commit, {
  desc = "[N]otes [C]ommit all",
})

map("n", "<leader>nl", open_lazygit, {
  desc = "[N]otes [L]azyGit",
})

map("n", "<leader>nx", function()
  open_wiki_file(wiki_path("index.md"))
end, { desc = "[N]otes inde[X]" })

map("n", "<leader>no", function()
  open_wiki_file(wiki_path("active/open_questions.md"))
end, { desc = "[N]otes [O]pen questions" })

map("n", "<leader>nw", function()
  open_wiki_file(wiki_path("active/weekly_review.md"))
end, { desc = "[N]otes [W]eekly review" })

map("n", "<leader>nin", function()
  open_wiki_file(wiki_path("active/inbox.md"))
end, { desc = "[N]otes [C]apture [I]nbox" })

map("n", "<leader>np", function()
  create_problem_note()
end, { desc = "[N]ew [P]roblem note" })

map("n", "<leader>nP", function()
  read_template("notes/templates/problem_note_template.md", false)
end, { desc = "[N]ote insert [P]roblem template" })

map("n", "<leader>nd", function()
  create_daily_note()
end, { desc = "[N]otes [D]aily note" })

map("n", "<leader>nq", function()
  create_generic_note()
end, { desc = "[N]otes [Q]uick/generic note" })

map("n", "<leader>nD", function()
  read_template("notes/templates/daily_note_template.md", false)
end, { desc = "[N]ote insert [D]aily template" })

map("n", "<leader>nQ", function()
  read_template("notes/templates/generic_note_template.md", false)
end, { desc = "[N]ote insert [Q]uick/generic template" })

map("n", "<leader>ns", function()
  open_script_terminal("~/dev/cs/wiki/scripts/wiki_stats.sh", "Wiki stats")
end, { desc = "[N]otes [S]tats" })

map("n", "<leader>nr", function()
  open_script_terminal("~/dev/cs/wiki/scripts/needs_review.sh", "Needs review")
end, { desc = "[N]otes [R]eview queue" })

map("n", "<leader>nu", function()
  open_script_terminal("~/dev/cs/wiki/scripts/unlinked_atomic_notes.sh", "Unlinked atomic notes")
end, { desc = "[N]otes [U]nlinked atomic notes" })

map("n", "<leader>nwr", function()
  generate_weekly_review()
end, { desc = "[N]otes [W]eekly [R]eview generate/open" })

map("n", "<leader>nmr", function()
  generate_monthly_review()
end, { desc = "[N]otes [M]onthly [R]eview generate/open" })
