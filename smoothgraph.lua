require 'Class'
require 'graph'
require 'cairo'

SmoothGraph = Class(Graph)

function compute_control_points(knots)
	p1 = {}
	p2 = {}
	n = #knots
	
	-- rhs vector
	a = {}
	b = {}
	c = {}
	r = {}
	
	-- left most segment
	a[1] = 0
	b[1] = 2
	c[1] = 1
	r[1] = knots[1] + 2 * knots[2]

	-- internal segments
	for i = 2, n-2, 1 do
		a[i] = 1
		b[i] = 4
		c[i] = 1
		r[i] = 4 * knots[i] + 2 * knots[i+1]
	end

	-- right segment
	a[n-1]=2
	b[n-1]=7
	c[n-1]=0
	r[n-1]=8 * knots[n-1]+knots[n]

	-- all the magic mumbo jumbo happen after here
	for i = 2, n-1, 1 do
		m = a[i]/b[i - 1]
		b[i] = b[i] - m * c[i - 1]
		r[i] = r[i] - m * r[i - 1]
	end

	-- calc p1
	p1[n-1] = r[n-1]/b[n-1]
	for i = n-2, 1, -1 do
		p1[i] = (r[i] -c[i] * p1[i+1]) / b[i]
	end

	-- calc p2
	for i = 1, n-2, 1 do
		p2[i] = 2 * knots[i+1] - p1[i+1]
	end
	p2[n-1] = 0.5 * (knots[n] + p1[n-1])

	return {p1 = p1, p2 = p2}
end


function SmoothGraph:_get_points()
 	local p = {x={},y={}}
	local inc = self.w / (self.data_points-1)
	for index, value in pairs(self.data) do
		p.x[index] = inc * (index-1)
		p.y[index] = self.h * (value / self.max_data_value)
	end
	return p
end

function SmoothGraph:_draw_graph(context)
	-- we need at least 3 datapoints
	if #self.data < 3 then return end

	local p = self:_get_points()
	cairo_save(context)

	px = compute_control_points(p.x)
	py = compute_control_points(p.y)	
	
	local x1
	for index=1, #self.data, 1 do
		if index == 1 then
			cairo_move_to(context, p.x[1], p.y[1])
		else
			x0 = p.x[index-1]
			y0 = p.y[index-1]
			x1 = p.x[index]
			y1 = p.y[index]
			x2 = p.x[index+1]
			y2 = p.y[index+1]
						
			cx0= px.p1[index-1]
			cy0 = py.p1[index-1]
			cx1 = px.p2[index-1]
			cy1 = py.p2[index-1]
			cairo_curve_to(context, cx0, cy0, cx1, cy1, x1, y1)
		end
	end
	local line_path = cairo_copy_path(context)

	if true then --self.fill then
		cairo_set_source(context, self:_get_source(context))
		cairo_line_to(context, x1, 0)
		cairo_line_to(context, 0, 0)
		cairo_close_path(context)
		cairo_fill(context)
	end

	cairo_set_line_width( context, self.line_size)
	cairo_set_source_rgba(	context,
        			self.line_color[1],	
        			self.line_color[2],	
        			self.line_color[3],
        			self.line_color[4])
	cairo_append_path(context, line_path)
	cairo_stroke(context)	

	for index=1, #self.data, 1 do
		cairo_move_to(context, p.x[index], p.y[index])
		cairo_arc(context, p.x[index], p.y[index], self.point_size, 0, 2 * math.pi)
	end
	cairo_set_source_rgba(	context,
				self.point_color[1],	
				self.point_color[2],	
				self.point_color[3],
				self.point_color[4])
	cairo_fill(context)

	cairo_restore(context)
end
