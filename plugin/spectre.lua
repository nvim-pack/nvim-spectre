local spectre = require("spectre")

local function get_arg(str)
	local key, value = str:match([=[^([^%s]*)=([^%s]*)$]=])

	-- translate string 'true' and 'false' to boolen type
	value = value == "true" or value
	value = (value == "false" and { false } or { value })[1]

	return key, value
end

vim.api.nvim_create_user_command("Spectre", function(ctx)
	local args = {}
	local user_args
	if #ctx.fargs == 1 or vim.tbl_isempty(ctx.fargs) then
		user_args = ctx.fargs[1] and ctx.fargs or { "" }
	elseif #ctx.fargs > 1 then
		user_args = ctx.fargs
	end

	for _, user_arg in ipairs(user_args) do
		if user_arg == "%" then
			args["path"] = vim.fn.expand("%")
		elseif get_arg(user_arg) == nil then
			args["path"] = user_arg
		elseif get_arg(user_arg) then
			local key, value = get_arg(user_arg)
			args[key] = value
		end
	end

	spectre.open(args)
end, {
	nargs = "*",
	complete = "file",
})
