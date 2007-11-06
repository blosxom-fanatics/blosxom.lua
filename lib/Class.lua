
function Class (obj)
	-- metatable も __index も同じにする (再帰参照)
	-- 演算子オーバーロードも直感的に書けるように
	obj.__index = obj
	if obj.super then
		-- superclass の設定
		setmetatable(obj, { __index = obj.super })
		-- 比較演算子はコピーする
		local events = {"eq", "lt", "le"}
		for i, v in ipairs(events) do
			local name = "__"..v
			if not rawget(obj, name) then rawset(obj, name, obj.super[name]) end
		end
	end
	return setmetatable({
		new = function(...)
			local newObj = {}
			setmetatable(newObj, obj)
			newObj:initialize(unpack(arg))
			return newObj
		end
	}, obj)
end


return true

