--[[
List class
===========

DESCRIPTION
-----------

リストを扱うクラス


SYNOPSYS
--------

	l1 = List.new(1, 2, 3)
	l2 = List.new(4, 5, 6)
	l3 = l1 + l2

	print(l1:join())
	print(l2:join("\n"))
	print(l3:join(" "))

	print(l3:map(function (i)
		return i * i
	end))
]]

require "Class"

List = Class { super = nil,
	__tostring = function ()
		return "#<Class List>"
	end,

	__add = function (op1, op2)
		local ret = List.new()
		op1:each(function (i)
			ret:push(i)
		end)
		op2:each(function (i)
			ret:push(i)
		end)
		return ret
	end,

	__sub = function (op1, op2)
		local ret = List.new()
		op1:each(function (i)
			local exists = false
			op2:each(function(j)
				if i == j then exists = true end
			end)
			if not exists then ret:push(i) end
		end)
		return ret
	end,

	__eq = function (op1, op2)
		return op1:join() == op2:join()
	end,

	initialize = function (self, ...)
		self.n = 0
		for i, v in ipairs(arg) do self:push(v) end
	end,

	unshift = function (self, value)
		self.n = self.n + 1
		for i = self.n, 1, -1 do
			self[i+1] = self[i]
		end
		self[1] = value
		return self
	end,

	push = function (self, value)
		self.n = self.n + 1
		self[self.n] = value
		return self
	end,

	shift = function (self)
		local ret = self[1]
		for i = 2, self.n do
			self[i-1] = self[i]
		end
		self[self.n] = nil
		self.n = self.n - 1
		return ret
	end,

	pop = function (self)
		local ret = self[self.n]
		self[self.n] = nil
		self.n = self.n - 1
		return ret
	end,

	clear = function (self)
		for i, v in ipairs(self) do
			self[i] = nil
		end
		self.n = 0
	end,

	size  = function (self)
		return self.n
	end,

	first = function (self, n)
		if n then
			local ret = List.new()
			for i = 1, n do
				ret:push(self[i])
			end
			return ret
		else
			return self[1]
		end
	end,

	last = function (self, n)
		if n then
			local ret = List.new()
			for i = self.n - n + 1, self.n do
				ret:push(self[i])
			end
			return ret
		else
			return self[self.n]
		end
	end,

	join = function (self, sep)
		if not sep then sep = ", " end
		local ret = ""
		if self:size() > 0 then
			for i = 1, self.n - 1 do
				ret = ret .. tostring(self[i]) .. sep
			end
			ret = ret .. tostring(self[self.n])
		end
		return ret
	end,

	each = function (self, fun)
		for i = 1, self.n do
			fun(self[i])
		end
	end,

	eachWithIndex = function (self, fun)
		for i = 1, self.n do
			fun(self[i], i)
		end
	end,

	map = function (self, fun)
		local ret = List.new()
		self:each(function (i)
			ret:push(fun(i))
		end)
		return ret
	end,

	select = function (self, fun)
		local ret = List.new()
		self:each(function (i)
			if fun(i) then ret:push(i) end
		end)
		return ret
	end,

	min = function (self, fun)
		if not fun then fun = function (i) return i end end
		local tmp, ret, t
		self:each(function (i)
			if not tmp then
				tmp = fun(i)
				ret = i
			else
				t = fun(i)
				if t < tmp then
					tmp = t
					ret = i
				end
			end
		end)
		return ret
	end,

	max = function (self, fun)
		if not fun then fun = function (i) return i end end
		local tmp, ret, t
		self:each(function (i)
			if not tmp then
				tmp = fun(i)
				ret = i
			else
				t = fun(i)
				if t > tmp then
					tmp = t
					ret = i
				end
			end
		end)
		return ret
	end,

	sort = function (self, fun)
		if not fun then fun = function (a, b) return (a < b) end end

		-- based on http://nanto.asablo.jp/blog/2007/02/06/1167686
		local function qsort(data, start, finish, cont)
			if start >= finish then return cont(data) end

			local pivotPos = start
			local pivot    = data[pivotPos]

			local i = start + 1
			while i < finish + 1 do
				if fun(data[i], pivot) then
					local temp = data[i]
					data[i] = data[pivotPos + 1]
					data[pivotPos + 1] = data[pivotPos]
					data[pivotPos] = temp
					pivotPos = pivotPos + 1
				end
				i = i + 1
			end

			return qsort(data, start, pivotPos, function (partiallySortedData)
				return qsort(partiallySortedData, pivotPos + 1, finish, function (entirelySortedData)
					return cont(entirelySortedData);
				end);
			end)
		end

		local ret = List.new(unpack(self))
		return qsort(ret, 1, ret.n, function (data) return data end)
	end,
	
	sortBy = function (self, fun)
		return self:map(function (i)
			return { o = i, s = fun(i) }
		end):sort(function (a, b)
			return (a.s < b.s)
		end):map(function (i)
			return i.o
		end)
	end,

	isEmpty = function (self)
		return self.n == 0
	end,

	isInclude = function (self, value)
		local ret = false
		self:each(function (i)
			if i == value then ret = true end
		end)
		return ret
	end,

	deleteAt = function(self, index)
		if index < 0 or index > self.n then return nil end
		local ret = self[index]
		for i = index + 1, self.n do
			self[i-1] = self[i]
		end
		self.n = self.n - 1
		return ret
	end,

	delete = function (self, value)
		local ret
		for i = 1, self.n do
			if self[i] == value then
				ret = self:deleteAt(i)
			end
		end
		return ret
	end,
}
