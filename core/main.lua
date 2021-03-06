require 'cairo'
--require 'widgets.linegraph'
--require 'widgets.graph'
--require 'widgets.smoothgraph'
require 'widgets.widget'

local widgets = {}

function conky_resized()
	if win_h ~= conky_window.height or win_w ~= conky_window.width then
		print("Window resize detected")
		win_h = conky_window.height 
		win_w = conky_window.width
		return true
	end
	return false
end


function conky_startup_hook() 
	widget = Widget("TestWidget", {	x = 10, y = 10, w = 290, h = 60, 
					background='spiral1_src.png',
					mask_image='dot_mask.png'})
        widget:toString()
        table.insert(widgets, widget)
--[[

	graph = Graph("CPU Graph", {x = 10, y = 10, w = 290, h = 60, background='tenticle.png',border_width=2.0})
	graph:toString()
	table.insert(widgets, graph)
	
	graph = LineGraph("CPU LineGraph", {x= 30, y= 150, point_size= 2.0, fill= true, max_data_value= 100})
	--graph:toString()
	table.insert(widgets, graph)
}
	--graph = BarGraph("CPU BarGraph", {x= 30, y= 250, rounded_bars=true})
	graph = BarGraph("CPU BarGraph", {x= 30, y= 250, rounded_bars=false, max_data_value=100, bar_spacing=0.4})
	graph:toString()
 	table.insert(widgets, graph)

	graph = SmoothGraph("CPU SplineGraph", {x= 30, y= 350, border_width= 0})
 	--graph:toString()
 	table.insert(widgets, graph)
--]]
end


function conky_shutdown_hook() 
	cairo_destroy(cr)
	cairo_surface_destroy(cs)
	cr=nil
	print('Conky shutting down') 
end


local win_w = nil 
local win_h = nil
local cr = nil
local cs = nil

function conky_pre_draw_hook() 
	-- if no window yet do nothing
	if conky_window == nil then return end

	-- wait for 3 updates before doing anything
	local updates = tonumber(conky_parse("${updates}"))
	if updates < 3 then return end

	--print(conky_window.height)
	if conky_resized() then
		drawable = conky_window.drawable
		print("Creating cairo surface and context")
		-- preapare drawing surface
		cs = cairo_xlib_surface_create(	conky_window.display,
						conky_window.drawable,
						conky_window.visual,
						conky_window.width,
						conky_window.height)
	
		cr = cairo_create(cs)
	end

	for k,v in pairs(widgets) do
		v:draw(cr)
	end
end

function conky_post_draw_hook() end
