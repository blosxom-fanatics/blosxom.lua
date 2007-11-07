#!/usr/bin/env lua
-- vim:ft=lua:
-- POSIX かつ ruby がインストールされている前提
-- Lua 5.1

package.path = "./lib/?.lua"

require "Class"
require "List"

Entry = Class { super = nil,
	__tostring = function (self)
		return string.format(
			"#<Entry title=%q path=%q time=%s>",
			self.title,
			self.path,
			os.date("%Y-%m-%d %H:%M:%S", self.time)
		)
	end,

	initialize = function (self, filename, mtime)
		local f = io.open(filename)
		self.title = f:read()
		self.body  = f:read("*a")
		self.time  = mtime
		self.path  = filename
	end,
}

ELua = Class { super = nil,
	initialize = function (self, template)
		self.template = template
		self.src      = self.compile(template)
	end,

	compile = function (template)
		ret = "local ret = [===["
		pos = 1
		for s, e in (function () return string.find(template, "<%", pos, true) end) do
			local pre    = string.sub(template, pos, s-1)
			local ss, ee = string.find(template, "%>", e, true)
			local code   = string.sub(template, e + 1, ss - 1)
			ret = ret .. pre
			if     string.match(code, "^==") then
				ret = ret .. "]===] .. tostring(" .. string.sub(code, 3) .. ") .. [===["
			elseif string.match(code, "^=") then
				ret = ret .. "]===] .. htmlescape(" .. string.sub(code, 2) .. ") .. [===["
			else
				ret = ret .. "]===]\n" .. code .. "\nret = ret .. [===["
			end
			pos = ee + 1
		end
		ret = ret .. string.sub(template, pos) .. "]===]; return ret;"
		return ret
	end,

	htmlescape = function (str)
		local m = {["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;"}
		return string.gsub(tostring(str), "[<>&]", function (s)
			return m[s]
		end)
	end,

	result = function (self, context)
		local f = loadstring(self.src, "ELua")
		-- グローバル環境を context にコピー
		-- うわがきされる。
		for k, v in pairs(_G) do
			context[k] = v
		end
		context.htmlescape = self.htmlescape
		setfenv(f, context)
		return f()
	end,

	run = function (filename, context)
		local f = io.open(filename)
		local tmpl = f:read("*a")
		f:close()
		print(ELua.new(tmpl):result(context))
	end,
}

Bluasxom = Class { super = nil,
	initialize = function (self, config)
		self.config = config
	end,

	run = function (self)
		path_info = os.getenv("PATH_INFO") or "/"
		flavour   = string.match(path_info, "(%..+)$") or ".html"
		path_info = string.gsub(path_info, "%..+$", "")
		path_info = string.gsub(path_info, "index$", "")

		local entries = self.get_entries(self.config.datadir, self.config.dataext):sort(function (a, b)
			return a.time > b.time
		end)

		local year, month, day
		for i, v in ipairs({"^/(%d+)/(%d+)/(%d+)", "^/(%d+)/(%d+)", "^/(%d+)"}) do
			year, month, day = string.match(path_info, v)
			if year then break end
		end
		if year then
			entries = entries:select(function (e)
				local ret = true
				for i, v in ipairs({{m = "%Y", v = year}, {m = "%m", v = month}, {m = "%d", v = day}}) do
					if v.v and not(os.date(v.m, e.time) == v.v) then
						ret = false
					end
				end
				return ret
			end)
		else
			entries = entries:select(function (e)
				return string.match(e.name, "^"..path_info)
			end)
		end

		ELua.run("template"..flavour, {
			title    = self.config.title,
			home     = os.getenv("SCRIPT_NAME"),
			server   = "http://" .. tostring(os.getenv("SERVER_NAME")),
			entries  = entries,
			debugObj = "aaa",
		})

	end,

	get_entries = function (dir, ext)
		local ret = List.new()
		local tf = os.tmpname()
		-- ruby++
		os.execute('ruby -rpathname -e "Pathname.glob(%|'..dir..'/**/*'..ext..'|){|f|puts %|#{f.mtime.to_i} #{f}|}" > ' .. tf)
		for line in io.lines(tf) do
			local time, filename = string.match(line, "(%d+) (.+)")
			local e = Entry.new(filename, tonumber(time, 10))
			e.name = string.gsub(string.gsub(filename, "%.%w+$", ""), "^"..dir, "")
			ret:push(e)
		end
		return ret
	end,
}

Bluasxom.new({
	title   = "Bluasxom",
	author  = "jitensya",
	dataext = ".txt",
	datadir = "data",
}):run()

