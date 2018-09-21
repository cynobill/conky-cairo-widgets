require 'Class'
require 'graph'
require 'cairo'

SmoothGraph = Class(Graph)

function compute_control_points(knots)
	for index, coord in pairs{'x','y'} do
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
		r[1] = knots[1][coord] + 2 * knots[2][coord]

		-- internal segments
		for i = 2, n-2, 1 do
			a[i] = 1
			b[i] = 4
			c[i] = 1
			r[i] = 4 * knots[i][coord] + 2 * knots[i+1][coord]     
		end

		-- right segment
		a[n-1]=2
		b[n-1]=7
		c[n-1]=0
		r[n-1]=8 * knots[n-1][coord] + knots[n][coord]

		-- all the magic mumbo jumbo happen after here
		for i = 2, n-1, 1 do
			m = a[i]/b[i - 1]
			b[i] = b[i] - m * c[i - 1]
			r[i] = r[i] - m * r[i - 1]
		end

		-- create control point structures
		if knots[1].cp1 == nil then
			for i=1, #knots, 1 do
				knots[i].cp1 = {}
				knots[i].cp2 = {}
			end
		end

		-- calc p1
		knots[n-1].cp1[coord] = r[n-1]/b[n-1]
		for i = n-2, 1, -1 do
			knots[i].cp1[coord] = (r[i] -c[i] * knots[i+1].cp1[coord]) / b[i]
		end

		-- calc p2
		for i = 1, n-2, 1 do
			knots[i].cp2[coord] = 2 * knots[i+1][coord] - knots[i+1].cp1[coord]
		end
		knots[n-1].cp2[coord] = 0.5 * (knots[n][coord] + knots[n-1].cp1[coord])
	end
	return knots
end


function SmoothGraph:_get_points()
 	local p = {}
	local inc = self.w / (self.data_points-1)
	for index, value in pairs(self.data) do
		p[index] = {}
		p[index].x = inc * (index-1)
		p[index].y = self.h * (value / self.max_data_value)
	end
	return compute_control_points(p)
end

function SmoothGraph:_get_paths(context, p)
	local p = self:_get_points()
	local paths = {}
	cairo_save(context)

	print(">>>>>>>>1")
	
	local x1
	for index=1, #self.data, 1 do
		if index == 1 then
			cairo_move_to(context, p[1].x, p[1].y)
		else
			x0 = p[index-1].x
			y0 = p[index-1].y
			x1 = p[index].x
			y1 = p[index].y
			--x2 = p[index+1].x
			--y2 = p[index+1].y
						
			cx0 = p[index-1].cp1.x
			cy0 = p[index-1].cp1.y
			cx1 = p[index-1].cp2.x
			cy1 = p[index-1].cp2.y
			cairo_curve_to(context, cx0, cy0, cx1, cy1, x1, y1)
		end
	end
	paths[1] = cairo_copy_path(context)

	cairo_set_source(context, self:_get_source(context))
	cairo_line_to(context, x1, 0)
	cairo_line_to(context, 0, 0)
	cairo_close_path(context)
	paths[2] = cairo_copy_path(context)

	cairo_restore(context)
	return paths
end


function SmoothGraph:_draw_graph(context)
	-- we need at least 3 datapoints
	if #self.data < 3 then return end

	Graph._draw_graph(self, context)
	print(">>>>>>>>2")
end
