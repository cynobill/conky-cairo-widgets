function Class(base, init)
	-- new class instance
	local c = {}

	-- base class
	if not init and type(base) == 'function' then
		init = base
		base = nil

	-- new class is child of a base class
	elseif type(base) == 'table' then
		for i, v in pairs(base) do
			c[i] = v			
		end
		c._base = base
	end

	-- class is metatable for its objects
	c.__index = c

	-- expose constructor
	local mt = {}
	mt.__call = function(class_tbl, ...)
		local obj = {}
		setmetatable(obj,c)
		if init then
			init(obj, ...)
		else
			--initialize the base class
			if base and base.init then
				base.init(obj,...)
			end
		end
		return obj
	end

	c.init = init
	c.is_a = function(self, klass)
		local m = getmetatable(self)
		while m do
			if m == klass then return true end
			m = m.base
		end
		return false
	end
	setmetatable(c, mt)
	return c
end


	
