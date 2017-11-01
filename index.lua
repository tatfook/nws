-- 将mod放lua搜索路径中
package.path = package.path .. ";/root/workspace/npl/nplproject/nws/npl_mod/?.lua;"

-- 加载框架
local nws = require("nws.loader")
-- 加载配置文件
local config = require("config")
-- 初始化矿建
nws.init(config)
-- 导出日志对象
--local log = nws.log

nws.router("/", function(ctx)
	ctx.response:send("<div>hello npl webserver</div>")
end)


nws.log("启动服务器...")
-- 启动服务器
nws.start()
