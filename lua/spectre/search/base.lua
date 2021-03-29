local function extend(engine)
    local BaseSearch = {}
    BaseSearch.__index = BaseSearch
    function BaseSearch:new(config, handler)
        handler = vim.tbl_extend('force', {
            on_tart = function()
            end,
            on_result = function()
            end,
            on_error = function()
            end,
            on_finish = function()
            end
        }, handler or {})
        local state = engine.init(config)
        return setmetatable({state = state, handler = handler, _search = engine.search}, BaseSearch)
    end

    function BaseSearch:search(query)
        query = vim.tbl_extend('force', {search_text = '', replace_text = '', path = ''}, query)
        if self._search then return self:_search(query) end
        vim.api.nvim_err_writeln("search is not defined")
    end

    return BaseSearch
end

return {extend = extend}
