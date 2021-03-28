local utils = require("spectre.utils")

local eq = assert.are.same
local esc_test_data={
  {[[ \( ]],  [[ \\( ]], " slash"},
  {[[ \\( ]],  [[ \\( ]], " slash"}
}

describe('[utils ]', function()
 it("should escape special chars",function()
    for _, value in pairs(esc_test_data) do
      eq(value[2], utils.escape_chars(value[1]), "ERROR:" .. value[3])
    end
  end)
end)


local hl_diffrent_text = {
  {
    " data1 data2 data 3", "noob1 noob2 noob3",
    {
      input = {{1, 4},{0,}},
      output={{}}
    }
  },
  -- {" data1 data2 data 3\\", " wdata_1 wdata2 wdata_3 \\"},

}
describe('[utils ]', function()
 it("should escape special chars",function()
     for _, value in pairs(hl_diffrent_text) do
      local result = utils.hl_different_text(value[1], value[2])
      print(vim.inspect(result))
    end
  end)
end)
