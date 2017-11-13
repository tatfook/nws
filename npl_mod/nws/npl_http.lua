local handler = nws.import(nws.get_nws_path_prefix() .. "npl_handler")
local util = commonlib.gettable("nws.util")
local request = commonlib.gettable("nws.request")
local response = commonlib.gettable("nws.response")
local router = commonlib.gettable("nws.router")
local filter = commonlib.gettable("nws.filter")

--local log = import("log")

local http = {
	is_start = false,
}

http.request = request
http.response = response
http.router = router
http.util = util
http.filter = filter

function http:init(config)

end

-- 静态文件处理
function http:statics(req, resp)
	local url = req.url
	local path = url:match("([^?]+)")
	local ext = path:match('^.+%.([a-zA-Z0-9]+)$')
	
	if not ext then
		return false
	end

	resp:send_file(path, ext)

	return true
end

function http:start(config)
	if self.is_start then
		return 
	end

	-- 创建子线程
	handler:init_child_threads()

	local filename = nws.get_nws_path_prefix() .. "npl_handler.lua"
	local port = config.port or 8888

	NPL.AddPublicFile(filename, -10)
	NPL.StartNetServer("0.0.0.0", tostring(port))
end

function http:handle(msg)
	if not msg then
		return 
	end

	local req = request:new(msg)
	local resp = response:new(req)
	local ctx = {
		request = req,
		response = resp,
	}

	log(req.method .. " " .. req.url .. "\n")
	--log(req.path .. "\n")
	
	if self:statics(req, resp) then
		return
	end

	self:do_filter(ctx, http.filter, 1)
end
-- 注册过滤器
function http:register_filter(filter_func)
	table.insert(self.filter, filter_func)
end

-- 执行过滤器
function http:do_filter(ctx, filters, i)
	if not filters or i > #filters then
		self:do_handle(ctx)
		return 
	end

	(filters[i])(ctx, function()
		do_filter(ctx, filters, i+1)
	end)
end

-- 执行请求处理
function http:do_handle(ctx)
	local data, manual_send = router:handle(ctx)
	-- 确保成功发送
	if not manual_send then
		ctx.response:send(data)
	end
end

-- 是否是静态资源
function http:is_statics(url)
	local path = url:match("([^?]+)")
	local ext = path:match('^.+%.([a-zA-Z0-9]+)$')
	
	if not ext then
		return false
	end

	return true
end

return http
