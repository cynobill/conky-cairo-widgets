require 'Class'
require 'cairo'

local Graph = Class(function(a, name, args)
	a.data = {}

	if name then
		a.name = name
	else 
		a.name = 'unnamed'
	end
	-- if no args create empty list so we assign default
	if args == nil then args = {} end
	
	if args.x then
		a.x = args.x
	else
		a.x = 0
	end

	if args.y then      	
		a.y = args.y
	else
		a.y = 0
	end

	if args.w and args.w > 0 then      	
		a.w = args.w
	else
		a.w = 200
	end

	if args.h and args.h > 0 then      	
		a.h = args.h
	else
		a.h = 60
	end

	if args.data_points and args.data_points > 0 then
		a.data_points = args.data_points
	else
		a.data_points = 10
	end

	if args.max_data_value then
		a.max_data_value = args.max_data_value
		a.calc_max_value = false
	else
		a.max_data_value = 0
		a.calc_max_value = true         		
	end

	if args.draw_to_right ~= nil and type(args.draw_to_right) == 'boolean' then
 		a.draw_to_right= args.draw_to_right
 	else
 		a.draw_to_right = true
 	end

	if args.draw_upward ~= nil and type(args.draw_upward) == 'boolean' then
		a.draw_upward= args.draw_upward
 	else
 		a.draw_upward = true
 	end

	if args.line_caps then
       		a.line_caps= args.line_caps
       	else
       		a.line_caps = 0 
       	end

	if args.fade_start and args.fade_start >= 0 and  args.fade_start <= 1.0 then
		a.fade_start = args.fade_start
	else
		a.fade_start = 0.7 
	end

	if args.bar_spacing and args.bar_spacing >= 0 then
		a.bar_spacing = args.bar_spacing 
	else
		a.bar_spacing = 0.25 
	end

	if args.border_width and args.border_width >= 0 then
		a.border_width = args.border_width 
	else
		print(":::::::"..args.border_width)
		a.border_width = 1 
	end

	if args.border_color and type(args.border_color) == 'table' then
       		a.border_color = args.border_color 
       	else
       		a.border_color = {1.0,1.0,1.0,1.0}
       	end

	if args.bar_colors and type(args.bar_colors) == 'table' then
      		a.bar_colors = args.bar_colors 
        else
	      	a.bar_colors = {{0.0,0.0,1.0,0.0,1.0},
				{0.5,1.0,1.0,0.0,1.0},
				{1.0,1.0,0.0,0.0,1.0}}
	end

	if args.conky_var then
		a.conky_var = args.conky_var
	else
		print("No conky variable provided, this widget will do nothing")
		a.conky_var = "" 
	end
end)         

Graph.NONE = 0
Graph.TOP = 1   	
Graph.BOTTOM = 2
Graph.BOTH = 3

function Graph:toString()
      	print("Graph: "..self.name)
	print("  x: "..self.x)
	print("  y: "..self.y)
	print("  w: "..self.w)
	print("  h: "..self.h)
	print("  max_data_value: "..self.max_data_value)
	print("  calc_max_value: "..tostring(self.calc_max_value))
	print("  draw_to_right: "..tostring(self.draw_to_right))
	print("  draw_upward: "..tostring(self.draw_upward))
	print("  line_caps: "..self.line_caps)
	print("  fade_start: "..self.fade_start)
	print("  bar_spacing: "..self.bar_spacing)
	
	print("  bar_colors: ")
	local cnt = #self.bar_colors
	for k,v in pairs(self.bar_colors) do
		local cnt2 = #v
		local colors = "\t\t{"
		for k2, v2 in pairs(v) do
			colors = colors.."["..v2.."]"
			if k2 < cnt2 then
				colors = colors..", "
			end
		end
		colors = colors.."}"
		print(colors)
	end

	print("  border_width: "..self.border_width)

	local colors = "{"
	local cnt = #self.border_color
	for k,v in pairs(self.border_color) do
		colors = colors.."["..v.."]"
		if k < cnt then
			colors = colors..", "
		end
	end
	colors = colors.."}"
	print("  border_color: "..colors)
	
	print("  conky_var: "..self.conky_var)

end


function Graph:_update()
	if #self.data >= self.data_points then
		local value = table.remove(self.data,#self.data)

		if self.calc_max_value == true and value >= self.max_data_value then
			self.max_data_value = self:_calculate_max_data_value()
		end
	end

	local new_value = tonumber(conky_parse("${cpu}"))
	table.insert(self.data, 1, new_value)

	if self.calc_max_value and new_value > self.max_data_value then
		self.max_data_value = new_value
		print("new_max="..self.max_data_value)
	end
end


function Graph:_calculate_max_data_value()
	local max = 0
	for k,v in pairs(self.data) do
		if v > max then max = v end
	end
	return max
end

function Graph:_dump_data()
	local data = "{"
	local len = #data
	for k,v in pairs(self.data) do
		data = data.."["..v.."]"
		if k < len then data = data..", " end
	end
	data = data.."}, \t\tmax: "..self.max_data_value
	print(data)
end


function Graph:_get_source(context)
	if self.pattern == nil then
	print("Creating pattern")
	local pattern = cairo_pattern_create_linear(0.5,0.0,0.5,1.0)
	for k,color in pairs(self.bar_colors) do
		cairo_pattern_add_color_stop_rgba(pattern, color[1],color[2],color[3],color[4],color[5])
	end

	local mask = cairo_pattern_create_linear(0.0,0.5,1.0,0.5)
	cairo_pattern_add_color_stop_rgba(mask, 0.0,		1.0,1.0,1.0,1.0)
	cairo_pattern_add_color_stop_rgba(mask, self.fade_start,1.0,1.0,1.0,1.0)
	cairo_pattern_add_color_stop_rgba(mask, 1.0,		1.0,1.0,1.0,0.0)
	
	cairo_push_group(context)
	cairo_set_source(context, pattern)
	cairo_mask(context, mask)

	self.pattern = cairo_pop_group(context)
	end
	return self.pattern
end


function Graph:_calculate_bar_width()
	return 1.0 / ( self.data_points + (self.data_points - 1) * self.bar_spacing)
end		

function Graph:_setup_context(context)

	if self.line_caps ~= Graph.NONE then
		cairo_set_line_cap(context, CAIRO_LINE_CAP_ROUND)
	end

	cairo_translate(context, self.x, self.y)

	cairo_scale(context, self.w, self.h)

	if self.draw_upward then
		cairo_scale(context, 1.0,-1.0)
		cairo_translate(context,0.0,-1.0)
	end

	if not self.draw_to_right then
		cairo_scale(context, -1.0,1.0)
		cairo_translate(context,-1.0,0.0)
	end

	cairo_rectangle(context, 0.0, 0.0, 1.0, 1.0)
	cairo_clip(context)

	local line_w = self:_calculate_bar_width()	

	if self.line_caps == Graph.BOTTOM or self.line_caps == Graph.BOTH  then
		cairo_translate(context, 0.0, (line_w / 2.0))
	end

	if self.line_caps == Graph.BOTTOM or self.line_caps == Graph.TOP  then
		cairo_scale(context,1.0, 1.0 - (line_w / 2.0))
	elseif self.line_caps == Graph.BOTH then
		cairo_scale(context,1.0, 1.0 - line_w )
	end
end

function Graph:draw(context)
	cairo_save(context)

	if self.border_width > 0 then
		cairo_set_source_rgba(	context,
					self.border_color[1],
					self.border_color[2],
					self.border_color[3],
					self.border_color[4])
		cairo_set_line_width( context, self.border_width)
		cairo_rectangle( context, self.x, self.y, self.w, self.h)
		cairo_stroke(context)
	end


	self:_setup_context(context)
	self:_update()

	local line_w = self:_calculate_bar_width()
	local spacer = (1.0 - line_w * self.data_points) / (self.data_points - 1)
	local inc = line_w + spacer
	local start = line_w / 2.0


	--avoid divide by zero shit
	if self.max_data_value == 0 then return end

	for index,value in pairs(self.data) do
		local x = start + (index-1) * inc
		local h = value / self.max_data_value
		cairo_move_to(context, x, 0)
		cairo_line_to(context, x, h)
	end	
	
	cairo_set_line_width(context, line_w)
	cairo_set_source(context, self:_get_source(context))
	cairo_stroke(context)
	cairo_restore(context)

	cairo_destroy(cr)
	cairo_surface_destroy(cs)
	cr=nil
end

return Graph
