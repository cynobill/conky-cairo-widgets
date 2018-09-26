require 'Class'
require 'cairo'


--- Class constructor.
-- @param name The tag that will be used to Id this widget in debug messages.
-- @param args Table of arguments to initialize the class with.
Widget = Class(function(a, name, args)
	print("Widget:__init()")
	a.data = {}

	if type(name) == 'string' then
		a.name = name
	else 
		a.name = 'unnamed'
	end

	-- if no args create empty list so we can assign defaults
	if args == nil then args = {} end
	
	if type(args.x) == 'number' then
		a.x = args.x
	else
		a.x = 0
	end

	if type(args.y) == 'number' then
		a.y = args.y
	else
		a.y = 0
	end

	if type(args.w) == 'number' and args.w > 0 then      	
		a.w = args.w
	else
		a.w = 200
	end

	if type(args.h) == 'number' and args.h > 0 then      	
		a.h = args.h
	else
		a.h = 60
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


	if type(args.background) == 'string' then
		a.background = args.background
	else
		a.background = false
	end
end)         


--- Debug output the objects state
function Widget:toString()
      	print(self.name.."----Widget----")
	print("  x: "..self.x)
	print("  y: "..self.y)
	print("  w: "..self.w)
	print("  h: "..self.h)
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


function Widget:_get_source(context)
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


function Widget:_get_mask(context)
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


function Widget:_setup_context(context)

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


function Widget:_draw_border(context)
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

function Widget:_update()
	return
end


function Widget:draw(context)
	cairo_save(context)

	self:_update()
	self:_setup_context(context)
	self:_draw_graph(context)
	self:_draw_border(context)
	cairo_restore(context)
end
