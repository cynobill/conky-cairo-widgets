require 'Class'
require 'graph'
require 'cairo'

LineGraph = Class(Graph, function(a, name, args)
	print("LineGraph:__init()")
	Graph.init(a, name, args)

	if args.fill ~= nil and type(args.fill) == 'boolean' then
		a.fill= args.fill
	else
		a.fill = true
	end

	if args.point_size and args.point_size >= 0 then
		a.point_size = args.point_size
	else
		a.point_size = 0
	end

	if args.point_color and type(args.border_color) == 'table' then
       		a.point_color = args.point_color 
       	else
       		a.point_color = {1.0,1.0,1.0,1.0}
       	end
end)         


function LineGraph:toString()
	Graph.toString(self)
      	print(self.name.."----LineGraph----")
	print("  fill: "..tostring(self.fill))
	print("  point_size: "..self.point_size)

	local colors = "{"
	local cnt = #self.point_color
	for k,v in pairs(self.point_color) do
		colors = colors.."["..v.."]"
		if k < cnt then
			colors = colors..", "
		end
	end
	colors = colors.."}"
	print("  point_color: "..colors)
end


function LineGraph:_draw_graph(context)
	cairo_save(context)
	cairo_push_group(context)

	local points = self:_get_points()

	-- draw lines
	cairo_move_to(context, points[1].x, points[1].y)
	for index, p in pairs(points) do
		cairo_line_to(context,p.x,p.y)
	end
	
	cairo_set_source(context, self:_get_source(context))
	

	if self.fill then
		cairo_line_to(context, points[#points].x, 0)
		cairo_line_to(context, 0, 0)
		cairo_close_path(context)
		cairo_fill(context)
	else
		cairo_stroke(context)
	end

	-- draw data points
	for index, p in pairs(points) do
		cairo_move_to(context,p.x,p.y)                 	
		cairo_arc(context, p.x, p.y, self.point_size, 0, math.pi * 2)
	end
	cairo_set_source_rgba(context,	self.point_color[1],
					self.point_color[2],
					self.point_color[3],
					self.point_color[4])
	cairo_fill(context)

	cairo_pop_group_to_source(context)

	-- apply fade effect
	if self.fade_start < 1.0 then
		cairo_mask(context, self:_get_mask(context))
	else
		cairo_paint(context)
	end

	cairo_restore(context)
end


return LineGraph
