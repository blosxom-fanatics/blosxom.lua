#!/usr/bin/env lua
-- vim:ft=lua:
-- POSIX かつ ruby がインストールされている前提

package.path = "./lib/?.lua"

require "Class"
require "List"

Entry = Class { super = nil,
	__tostring = function (self)
		return string.format(
			"#<Entry title=%q path=%q time=%d>",
			self.title,
			self.path,
			self.time
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

function get_entries(dir, ext)
	local ret = List.new()
	local tf = os.tmpname()
	os.execute('ruby -rpathname -e "Pathname.glob(%|'..dir..'/**/*'..ext..'|){|f|puts %|#{f.mtime.to_i} #{f}|}" > ' .. tf)
	for line in io.lines(tf) do
		local time, filename = string.match(line, "(%d+) (.+)")
		local e = Entry.new(filename, tonumber(time, 10))
		e.name = string.gsub(string.gsub(filename, "%.%w+$", ""), "^"..dir, "")
		ret:push(e)
	end
	return ret
end


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
				ret = ret .. "]===] .. " .. string.sub(code, 3) .. " .. [===["
			elseif string.match(code, "^=") then
				ret = ret .. "]===] .. " .. string.sub(code, 2) .. " .. [===["
			else
				ret = ret .. "]===]\n" .. code .. "\nret = ret .. [===["
			end
			pos = ee + 1
		end
		ret = ret .. string.sub(template, pos) .. "]===]; return ret;"
		return ret
	end,

	result = function (self, context)
		local f = loadstring(self.src, "ELua")
		-- グローバル環境を context のコピー
		-- うわがきされる。
		for k, v in pairs(_G) do
			context[k] = v
		end
		setfenv(f, context)
		return f()
	end,
}

local f = io.open("template.html")
tmpl = f:read("*a")
f:close()

local entries = get_entries("data", ".txt")

entries = entries:sort(function (a, b)
	return a.time > b.time
end)

local result = ELua.new(tmpl):result({
	title = "test",
	home  = "test",
	entries = entries,
	debugObj = "aaa",
	version = _VERSION,
})

print(result)
