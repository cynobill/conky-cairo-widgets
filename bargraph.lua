require 'Class'
Graph = require 'graph'
require 'cairo'

local BarGraph = Class(Graph)
--[[
function BarGraph:draw(context)
	cairo_set_source_rgb(context, 1.0,1.0,1.0)
	cairo_paint(context)	
end
]]--
return BarGraph
