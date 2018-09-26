require 'Class'
require 'cairo'


-- Initalize the object.
-- @param name 
Graph = Class(function(a, name, args)
	print("Graph:__init()")
	a.data = {}

	if name then
		a.name = name
	else 
		a.name = 'unnamed'
	end
	-- if no args create empty list so we assign default
	if args == nil then args = {} end
	
	if args.x then
		print("+"..args.x)
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

	if type(args.max_data_value) == 'number' then
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
	
	if args.fade_start and args.fade_start >= 0 and  args.fade_start <= 1.0 then
		a.fade_start = args.fade_start
	else
		a.fade_start = 0.25 
	end

	if type(args.border_width) == 'number' and args.border_width >= 0 then
		a.border_width = args.border_width 
	else
		a.border_width = 1 
	end

	if type(args.border_color) == 'table' and #args.border_color == 4 then
       		a.border_color = args.border_color 
       	else
       		a.border_color = {1.0,1.0,1.0,1.0}
       	end

	if type(args.pattern_colors) == 'table' then
      		a.pattern_colors = args.pattern_colors 
        else
	      	a.pattern_colors = {{0.0,0.0,1.0,0.0,1.0},
				{0.5,1.0,1.0,0.0,1.0},
				{1.0,1.0,0.0,0.0,1.0}}
	end

	if type(args.point_color) == 'table' and #args.point_color == 4 then
		a.point_color = args.point_color
	else
		a.point_color = {1.0,1.0,1.0,1.0}
	end

	if type(args.point_size) == 'number'  and args.point_size >= 0 then
		a.point_size = args.point_size
	else
		a.point_size = 1 
	end                                                 		

	if type(args.line_color) == 'table' and #args.line_color == 4 then
		a.line_color = args.line_color
	else
		a.line_color = {1.0,1.0,1.0,1.0}
	end

	if type(args.line_size) == 'number' and args.line_size >= 0 then
		a.line_size = args.line_size
	else
		a.line_size = 2 
	end                                                 		

	if type(args.background) == 'string' then
		a.background = args.background
	else
		a.background = false
	end

	if type(args.data_function) == 'function' then
		a.data_function = args.data_function
	else
		print("No data function provided, defaulting CPU monitor")
		a.data_function = function() return tonumber(conky_parse("${cpu}")) end 
	end
end)         

Graph.NONE = 0
Graph.TOP = 1   	
Graph.BOTTOM = 2
Graph.BOTH = 3

function Graph:toString()
      	print(self.name.."----Graph----")
	print("  x: "..self.x)
	print("  y: "..self.y)
	print("  w: "..self.w)
	print("  h: "..self.h)
	print("  max_data_value: "..self.max_data_value)
	print("  calc_max_value: "..tostring(self.calc_max_value))
	print("  draw_to_right: "..tostring(self.draw_to_right))
	print("  draw_upward: "..tostring(self.draw_upward))
	print("  fade_start: "..self.fade_start)
	print("  pattern_colors: ")
	local cnt = #self.pattern_colors
	for k,v in pairs(self.pattern_colors) do
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
	print(" background: "..tostring(self.background))
end


function Graph:_get_new_data()
 	return self.data_function()
end


function Graph:_update()
	if #self.data >= self.data_points then
		local value = table.remove(self.data,#self.data)

		if self.calc_max_value == true and value >= self.max_data_value then
			self.max_data_value = self:_calculate_max_data_value()
		end
	end

	local new_value = self:_get_new_data()
	table.insert(self.data, 1, new_value)

	if self.calc_max_value and new_value > self.max_data_value then
		self.max_data_value = new_value
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
		print("self.bg: "..tostring(self.background))
		if self.background == false then
			print("Creating pattern")
			local pattern = cairo_pattern_create_linear(0.0,0.0,0.0,self.h)
		
			for k,color in pairs(self.pattern_colors) do
				cairo_pattern_add_color_stop_rgba(pattern, color[1],color[2],color[3],color[4],color[5])
			end
			
			self.pattern = pattern
		else
			print('loading bg image: '..self.background)
			local surface = cairo_image_surface_create_from_png(self.background)
			print(cairo_status_to_string(cairo_surface_status(surface)))
			
			cairo_push_group(context)
			cairo_set_source_surface(context, surface,0,0)
			cairo_paint(context)
			self.pattern = cairo_pop_group(context)
		end

	end
	return self.pattern
end


function Graph:_get_mask(context)
	if self.mask == nil then
	
		print("Creating mask")
		if self.mask_image == false then 
			mask = cairo_pattern_create_linear(0.0,0.0,self.w,0.0)
			cairo_pattern_add_color_stop_rgba(mask, 0.0,		1.0,1.0,1.0,1.0)
			cairo_pattern_add_color_stop_rgba(mask, self.fade_start,1.0,1.0,1.0,1.0)
			cairo_pattern_add_color_stop_rgba(mask, 1.0,		1.0,1.0,1.0,0.0)
		
			self.mask = mask
		else
			print('loading mask image: '..self.mask_image)
			local surface = cairo_image_surface_create_from_png(self.mask_image)
			
			cairo_push_group(context)
			cairo_set_source_surface(context, surface,0,0)
			cairo_paint(context)
			self.mask = cairo_pop_group(context)
		end
	end
	return self.mask
end


function Graph:_setup_context(context)

	cairo_translate(context, self.x, self.y)

	if self.draw_upward then
		cairo_translate(context, 0.0,self.h)
		cairo_scale(context, 1.0,-1.0)
	end

	if not self.draw_to_right then
		cairo_translate(context,self.w,0.0)
		cairo_scale(context, -1.0,1.0)
	end

	cairo_rectangle(context, 0.0, 0.0, self.w, self.h)
	cairo_clip(context)
end


function Graph:_draw_border(context)
	cairo_save(context)
	if self.border_width > 0 then
		cairo_set_source_rgba(	context,
					self.border_color[1],
					self.border_color[2],
					self.border_color[3],
					self.border_color[4])
		cairo_set_line_width( context, self.border_width)
		cairo_rectangle( context, 0, 0, self.w, self.h)
		cairo_stroke(context)
	end
	cairo_restore(context)
end


function Graph:_get_points()
	local p = {}
	local inc = self.w / (self.data_points-1)

	for index, value in pairs(self.data) do
		p[index] = {}
		p[index].x = inc * (index - 1)
		p[index].y = self.h * (value / self.max_data_value)
	end
	return p
end

function Graph:_get_paths(context, p)
	local paths = {}
	cairo_save(context)
	cairo_new_path(context)
	cairo_move_to(context, p[1].x, p[1].y)
	for i =2, #p, 1 do
		cairo_line_to(context, p[i].x, p[i].y)
	end
	paths[1] = cairo_copy_path(context)
	
	cairo_line_to(context, p[#p].x, 0)
	cairo_line_to(context, 0, 0)
	cairo_close_path(context)
	paths[2] = cairo_copy_path(context)
	cairo_restore(context)
	return paths
end

function Graph:_draw_line(context, path)
	cairo_save(context)
	cairo_new_path(context)
	cairo_append_path(context, path)
	cairo_set_source_rgba(	context, 
				self.line_color[1],
				self.line_color[2],
				self.line_color[3],
				self.line_color[4])
	cairo_stroke(context)
	cairo_restore(context)
end

function Graph:_draw_points(context, points)
	cairo_save(context)
	for index, p in pairs(points) do
		cairo_move_to(context,p.x,p.y)                 	
		cairo_arc(context, p.x, p.y, 2, 0, math.pi * 2)
	end
	cairo_set_source_rgba(	context, 
				self.point_color[1],
				self.point_color[2],
				self.point_color[3],
				self.point_color[4])
	cairo_stroke(context)
	cairo_restore(context)
end


function Graph:_fill_graph(context,path)
	cairo_save(context)
	cairo_new_path(context)
	cairo_append_path(context, path)
	cairo_set_source(context, self:_get_source(context))
	cairo_fill(context)
	cairo_restore(context)
end


function Graph:_mask_graph(context)
	if self.fade_start < 1.0 then
		cairo_mask(context, self:_get_mask(context))
	else
		cairo_paint(context)
	end	
end


function Graph:_draw_graph(context)
	cairo_save(context)
	cairo_push_group(context)

	local points = self:_get_points()
	local paths = self:_get_paths(context,points)
	
	self:_fill_graph(context, paths[2])
	self:_draw_line(context, paths[1])
	self:_draw_points(context, points)

	cairo_pop_group_to_source(context)

	self:_mask_graph(context)

	cairo_restore(context)
end


function Graph:draw(context)
	cairo_save(context)

	self:_update()
	self:_setup_context(context)
	self:_draw_graph(context)
	self:_draw_border(context)
	cairo_restore(context)
end
