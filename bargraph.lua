require 'Class'
require 'cairo'
require 'graph'

BarGraph = Class(Graph, function(a, name, args)
	print("BarGraph.__init()")
	Graph.init(a, name, args)

	if args.line_caps then
       		a.line_caps= args.line_caps
       	else
       		a.line_caps = 0 
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
	print("  line_caps: "..self.line_caps)
	print("  bar_spacing: "..self.bar_spacing)
end


function BarGraph:_calculate_bar_width()
	return self.w / ( self.data_points + (self.data_points - 1) * self.bar_spacing)
end		


function BarGraph:_setup_context(context)
	Graph._setup_context(self, context)

	if self.line_caps ~= BarGraph.NONE then
		cairo_set_line_cap(context, CAIRO_LINE_CAP_ROUND)
	end
end


function BarGraph:_draw_graph(context)
	--avoid divide by zero shit
	if self.max_data_value == 0 then return end

	cairo_save(context)
	cairo_push_group(context)

	local line_w = self:_calculate_bar_width()
	local spacer = (self.w - line_w * self.data_points) / (self.data_points - 1)
	local inc = line_w + spacer
	local start = line_w / 2.0
	local base = 0
	local bar_height = self.h

	if self.line_caps == self.LINECAP_BOTTOM or self.line_caps == self.LINECAP_BOTH then
		base = base + line_w / 2.0
	end

	if self.line_caps == self.LINECAP_BOTTOM or self.line_caps == self.LINECAP_TOP then
		bar_height = bar_height - line_w / 2.0
	end
                                                                             
	if self.line_caps == self.LINECAP_BOTH then
		bar_height = bar_height - line_w
	end
                                                                             
	for index,value in pairs(self.data) do
		local x = start + (index-1) * inc
		local h = (value / self.max_data_value) * bar_height
		cairo_move_to(context, x, base)
		cairo_line_to(context, x, base + h)
	end	
	
	cairo_set_line_width(context, line_w)
	cairo_set_source(context, self:_get_source(context))
	cairo_stroke(context)
	
	cairo_pop_group_to_source(context)
	cairo_mask(context, self:_get_mask(context))
	cairo_restore(context)
end


--function BarGraph:draw(context) end

