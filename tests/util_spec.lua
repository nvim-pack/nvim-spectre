local utils = require("spectre.utils")
local eq = assert.are.same
local esc_test_data={
  {[[ \( ]],  [[ \\( ]], " slash"},
  {[[ \\( ]],  [[ \\\( ]], " slash"}
}

describe('utils escape function ', function()
 it("should escape special chars",function()
    for _, value in pairs(esc_test_data) do
      eq(value[2], utils.escape_chars(value[1]), "ERROR:" .. value[3])
    end
  end)
end)


local fixtures_different = {
  {
    search_text="data",
    replace_text = "no\\0",
    search_line=" data1 data_2 data 3",
    replace_line = " nodata1 nodata_2 nodata 3",
    result = {
      input = {{1, 5},{7,11},{14,18}},
      output = {{1, 7},{9, 15},{18, 24}}
    }
  },
  {
    search_text="d\\S*a",
    replace_text = "no\\0",
    search_line=" data1 data_2 data 3",
    replace_line = " nodata1 nodata_2 nodata 3",
    result = {
      input = {{1, 5},{7,11},{14,18}},
      output = {{1, 7},{9, 15},{18, 24}}
    }
  },
  -- {" data1 data2 data 3\\", " wdata_1 wdata2 wdata_3 \\"},
}
describe('utils different test', function()
 it("should match 2 different text group",function()
    for _, value in pairs(fixtures_different) do
      eq(value.replace_line,
        utils.vim_replace_text(value.search_text, value.replace_text, value.search_line),
        'replace_text not match '..value.replace_line
      )
      local result = utils.different_text_col(value)
      eq(value.result.input, result.input, 'input  error :' .. value.search_line)
      eq(value.result.output, result.output, 'output error :' .. value.search_line)
    end
  end)
end)
