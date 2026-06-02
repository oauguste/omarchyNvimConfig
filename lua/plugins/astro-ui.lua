return {
  "AstroNvim/astroui",
  lazy = false, -- disable lazy loading
  priority = 10000, -- load AstroUI first
  opts = {
    -- set configuration options  as described below
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = {},
    },
  },
}
