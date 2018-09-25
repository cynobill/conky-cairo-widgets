require 'Class'
require 'cairo'
require 'graph'

BarGraph = Class(Graph, function(a, name, args)
	print("BarGraph.__init()")
	Graph.init(a, name, args)

	if args.rounded_bars then
       		a.rounded_bars= args.rounded_bars
       	else
       		a.rounded_bars = false 
       	end

	if args.bar_spacing and args.bar_spacing >= 0 then
		a.bar_spacing = args.bar_spacing 
	else
		a.bar_spacing = 0.25 
	end
end)         


BarGraph.LINECAP_NONE = 0
BarGraph.LINECAP_TOP = 1   	
BarGraph.LINECAP_BOTTOM = 2
BarGraph.LINECAP_BOTH = 3


function BarGraph:toString()
	Graph.toString(self)

      	print(self.name.."----BarGraph----")
	print("  rounded_bars: "..tostring(self.rounded_bars))
	print("  bar_spacing: "..self.bar_spacing)
end


function BarGraph:_calculate_bar_width()
	return self.w / ( self.data_points + (self.data_points - 1) * self.bar_spacing)
end		


function BarGraph:_setup_context(context)
	Graph._setup_context(self, context)

	if self.rounded_bars ~= BarGraph.NONE then
		cairo_set_line_cap(context, CAIRO_LINE_CAP_ROUND)
	end
end

function BarGraph:_get_points()
	local line_w = self:_calculate_bar_width()
	local spacer = (self.w - line_w * self.data_points) / (self.data_points - 1)
	local inc = line_w + spacer
	local start = line_w / 2.0
	local base = 0
	local bar_height = self.h

	if self.rounded_bars == self.LINECAP_BOTTOM or self.rounded_bars == self.LINECAP_TOP then
		bar_height = bar_height - line_w / 2.0
	end
                                                                             
	if self.rounded_bars == self.LINECAP_BOTH then
		bar_height = bar_height - line_w
	end
        local p = {}                                                                     
	for index,value in pairs(self.data) do
		p[index] = {}
		p[index].x = start + (index-1) * inc
		p[index].y = (value / self.max_data_value) * bar_height
	end	


	return p
end


function BarGraph:_draw_graph(context)
	--avoid divide by zero shit
	if self.max_data_value == 0 then return end

	--cairo_save(context)
	local base = 0
	local line_w = self:_calculate_bar_width()
	if self.rounded_bars then 
		base = base + line_w / 2.0
	end
	
	local points = self:_get_points()                                                   	
	for i, p in pairs(points) do    
		if self.rounded_bars == false then
			cairo_move_to(context, p.x + line_w / 2, p.y - base )
			cairo_line_to(context,	p.x - line_w / 2, p.y - base)
			cairo_line_to(context, p.x - line_w / 2, base)
			cairo_line_to(context,  p.x +  line_w / 2, base )
			cairo_close_path(context)
		elseif p.y > line_w then --dont draw smallbars to avoid graphical glitches
			cairo_move_to(context, p.x + line_w / 2, p.y - base )
			cairo_curve_to(context, p.x + line_w / 2, p.y,  
						p.x - line_w / 2, p.y,
						p.x - line_w / 2, p.y - base)
			cairo_line_to(context, p.x - line_w / 2, base)
			cairo_curve_to(context, p.x - line_w / 2, 0,  
						p.x + line_w / 2, 0,
						p.x +  line_w / 2, base )
			cairo_close_path(context)
		end
	end                                                                      
	
	cairo_push_group(context)
	cairo_set_source(context, self:_get_source(context))
	cairo_fill_preserve(context)

	cairo_set_source_rgba(context, 	self.line_color[1], 
					self.line_color[2], 
					self.line_color[3],
					self.line_color[4])
	cairo_set_line_width(context, self.line_size)
	cairo_stroke(context)

	cairo_pop_group_to_source(context)

	cairo_mask(context, self:_get_mask(context))

--	cairo_restore(context)
end
