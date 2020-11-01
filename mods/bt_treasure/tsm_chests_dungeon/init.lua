-- Preciousness scaling numbers
local h_min = -256	-- Minimum height. At this height and below, the preciousness is at its peak
local h_max = -20	-- Max. height. At this height and above, the preciousness is at its lowest level

minetest.set_gen_notify("dungeon")
minetest.register_on_generated(function(minp, maxp, seed)
	local g = minetest.get_mapgen_object("gennotify")
	if g and g.dungeon and #g.dungeon > 3 then
		minetest.after(3, function(d)
			if d == nil or #d < 1 then
				return
			end
			for i=1,2 do
				local p = d[math.random(1, #d)]
				if minetest.get_node({x=p.x, y =p.y-1, z=p.z}).name ~= "air" then
					minetest.set_node(p, {name = "default:chest"})

					-- calculate preciousness of treasures based on height. higher = more precious
					local height = math.abs(h_min) - math.abs(h_max)
					local y_norm = (p.y+1) - h_min
					local scale = 1 - (y_norm/height)

					-- We will select randomly 1-2 out of 5 possible treasure groups: light, crafting component, building block, and melee weapon
--					local groups = {
--						{ 4, 0, scale*2+3, "light" }, -- precousness: 0..5
--						{ 6, 0, 2, "crafting_component" }, -- 0..2
--						{ 6, 0, 5, "building_block" }, -- 0..5
--						{ 1, scale*2, scale*5, "melee_weapon" }, -- 0..5
--						{ 3, 0, 3, "food" }, -- 0..3
--					}

					local meta = minetest.get_meta(p)
					local inv = meta:get_inventory()
					local treasures_added = 0
					local my_max_precious = math.ceil(math.abs(minp.y) / 100) + 1
					local number_of_stacks = math.ceil(math.abs(minp.y) / 200) + 1
					if my_max_precious > 10 then
						my_max_precious = 10
					end
					local my_min_precious = my_max_precious - 5
					if my_min_precious < 0 then
						my_min_precious = 0
					end
					if number_of_stacks > 32 then
						number_of_stacks = 32
					end
					for j=1, math.random(math.ceil(number_of_stacks / 4), number_of_stacks) do
--						local r = math.random(1, #groups)
--						local treasures = treasurer.select_random_treasures(groups[r][1], groups[r][2], groups[r][3], { groups[r][4] })
						local treasures = treasurer.select_random_treasures(1, my_min_precious, my_max_precious, nil)
						treasures_added = treasures_added + #treasures
						for t=1,#treasures do
							inv:add_item("main", treasures[t])
						end
					end
					-- No treasures found? Maybe add one random treasure from default group
--					if treasures_added <= 0 then
--						if math.random(1,2) then
--							local treasures = treasurer.select_random_treasures(1, 0, 4)
--							for t=1,#treasures do
--								inv:add_item("main", treasures[t])
--							end
--						end
--					end
				end
			end
		end, table.copy(g.dungeon))
	end
end)

