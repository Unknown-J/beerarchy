-- stairs/init.lua

-- Minetest 0.4 mod: stairs
-- See README.txt for licensing and other information.


-- Global namespace for functions

stairs = {}

-- Load support for MT game translation.
local S = minetest.get_translator("stairs")


-- Register aliases for new pine node names

minetest.register_alias("stairs:stair_pinewood", "stairs:stair_pine_wood")
minetest.register_alias("stairs:slab_pinewood", "stairs:slab_pine_wood")


-- Get setting for replace ABM

local replace = minetest.settings:get_bool("enable_stairs_replace_abm")

local function rotate_and_place(itemstack, placer, pointed_thing)
	local p0 = pointed_thing.under
	local p1 = pointed_thing.above
	local param2 = 0

	if placer then
		local placer_pos = placer:get_pos()
		if placer_pos then
			param2 = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
		end

		local finepos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
		local fpos = finepos.y % 1

		if p0.y - 1 == p1.y or (fpos > 0 and fpos < 0.5)
				or (fpos < -0.5 and fpos > -0.999999999) then
			param2 = param2 + 20
			if param2 == 21 then
				param2 = 23
			elseif param2 == 23 then
				param2 = 21
			end
		end
	end
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

local function warn_if_exists(nodename)
	if minetest.registered_nodes[nodename] then
		minetest.log("warning", "Overwriting stairs node: " .. nodename)
	end
end


-- Register stair
-- Node will be called stairs:stair_<subname>

function stairs.register_stair(subname, recipeitem, groups, images, description,
		sounds, worldaligntex, alpha, light)
	-- Set backface culling and world-aligned textures
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	local new_groups = table.copy(groups)
	new_groups.stair = 1
	warn_if_exists("stairs:stair_" .. subname)
	minetest.register_node(":stairs:stair_" .. subname, {
		description = description,
		drawtype = "nodebox",
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		use_texture_alpha = alpha or false,	-- mm added for alpha texture stair / slab
		light_source = light or 0, -- mm added for lighted stair / slab
		groups = new_groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
				{-0.5, 0.0, 0.0, 0.5, 0.5, 0.5},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			return rotate_and_place(itemstack, placer, pointed_thing)
		end,
	})

	-- for replace ABM
	if replace then
		minetest.register_node(":stairs:stair_" .. subname .. "upside_down", {
			replace_name = "stairs:stair_" .. subname,
			groups = {slabs_replace = 1},
		})
	end

	if recipeitem then
		-- Recipe matches appearence in inventory
		minetest.register_craft({
			output = "stairs:stair_" .. subname .. " 8",
			recipe = {
				{"", "", recipeitem},
				{"", recipeitem, recipeitem},
				{recipeitem, recipeitem, recipeitem},
			},
		})

		-- Use stairs to craft full blocks again (1:1)
		minetest.register_craft({
			output = recipeitem .. " 3",
			recipe = {
				{"stairs:stair_" .. subname, "stairs:stair_" .. subname},
				{"stairs:stair_" .. subname, "stairs:stair_" .. subname},
			},
		})

		-- Fuel
		local baseburntime = minetest.get_craft_result({
			method = "fuel",
			width = 1,
			items = {recipeitem}
		}).time
		if baseburntime > 0 then
			minetest.register_craft({
				type = "fuel",
				recipe = "stairs:stair_" .. subname,
				burntime = math.floor(baseburntime * 0.75),
			})
		end
	end
end


-- Register slab
-- Node will be called stairs:slab_<subname>

function stairs.register_slab(subname, recipeitem, groups, images, description,
		sounds, worldaligntex, alpha, light)
	-- Set world-aligned textures
	local slab_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			slab_images[i] = {
				name = image,
			}
			if worldaligntex then
				slab_images[i].align_style = "world"
			end
		else
			slab_images[i] = table.copy(image)
			if worldaligntex and image.align_style == nil then
				slab_images[i].align_style = "world"
			end
		end
	end
	local new_groups = table.copy(groups)
	new_groups.slab = 1
	warn_if_exists("stairs:slab_" .. subname)
	minetest.register_node(":stairs:slab_" .. subname, {
		description = description,
		drawtype = "nodebox",
		tiles = slab_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		use_texture_alpha = alpha or false,	-- mm added for alpha texture stair / slab
		light_source = light or 0, -- mm added for lighted stair / slab
		groups = new_groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
		on_place = function(itemstack, placer, pointed_thing)
			local under = minetest.get_node(pointed_thing.under)
			local wield_item = itemstack:get_name()
			local player_name = placer and placer:get_player_name() or ""
			local creative_enabled = (creative and creative.is_enabled_for
					and creative.is_enabled_for(player_name))

			if under and under.name:find("^stairs:slab_") then
				-- place slab using under node orientation
				local dir = minetest.dir_to_facedir(vector.subtract(
					pointed_thing.above, pointed_thing.under), true)

				local p2 = under.param2

				-- Placing a slab on an upside down slab should make it right-side up.
				if p2 >= 20 and dir == 8 then
					p2 = p2 - 20
				-- same for the opposite case: slab below normal slab
				elseif p2 <= 3 and dir == 4 then
					p2 = p2 + 20
				end

				-- else attempt to place node with proper param2
				minetest.item_place_node(ItemStack(wield_item), placer, pointed_thing, p2)
				if not creative_enabled then
					itemstack:take_item()
				end
				return itemstack
			else
				return rotate_and_place(itemstack, placer, pointed_thing)
			end
		end,
	})

	-- for replace ABM
	if replace then
		minetest.register_node(":stairs:slab_" .. subname .. "upside_down", {
			replace_name = "stairs:slab_".. subname,
			groups = {slabs_replace = 1},
		})
	end

	if recipeitem then
		minetest.register_craft({
			output = "stairs:slab_" .. subname .. " 6",
			recipe = {
				{recipeitem, recipeitem, recipeitem},
			},
		})

		-- Use 2 slabs to craft a full block again (1:1)
		minetest.register_craft({
			output = recipeitem,
			recipe = {
				{"stairs:slab_" .. subname},
				{"stairs:slab_" .. subname},
			},
		})

		-- Fuel
		local baseburntime = minetest.get_craft_result({
			method = "fuel",
			width = 1,
			items = {recipeitem}
		}).time
		if baseburntime > 0 then
			minetest.register_craft({
				type = "fuel",
				recipe = "stairs:slab_" .. subname,
				burntime = math.floor(baseburntime * 0.5),
			})
		end
	end
end


-- Optionally replace old "upside_down" nodes with new param2 versions.
-- Disabled by default.

if replace then
	minetest.register_abm({
		label = "Slab replace",
		nodenames = {"group:slabs_replace"},
		interval = 16,
		chance = 1,
		action = function(pos, node)
			node.name = minetest.registered_nodes[node.name].replace_name
			node.param2 = node.param2 + 20
			if node.param2 == 21 then
				node.param2 = 23
			elseif node.param2 == 23 then
				node.param2 = 21
			end
			minetest.set_node(pos, node)
		end,
	})
end


-- Register inner stair
-- Node will be called stairs:stair_inner_<subname>

function stairs.register_stair_inner(subname, recipeitem, groups, images,
		description, sounds, worldaligntex, full_description, alpha, light)
	-- Set backface culling and world-aligned textures
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	local new_groups = table.copy(groups)
	new_groups.stair = 1
	if full_description then
		description = full_description
	else
		description = "Inner " .. description
	end
	warn_if_exists("stairs:stair_inner_" .. subname)
	minetest.register_node(":stairs:stair_inner_" .. subname, {
		description = description,
		drawtype = "nodebox",
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		use_texture_alpha = alpha or false,	-- mm added for alpha texture stair / slab
		light_source = light or 0, -- mm added for lighted stair / slab
		groups = new_groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
				{-0.5, 0.0, 0.0, 0.5, 0.5, 0.5},
				{-0.5, 0.0, -0.5, 0.0, 0.5, 0.0},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			return rotate_and_place(itemstack, placer, pointed_thing)
		end,
	})

	if recipeitem then
		minetest.register_craft({
			output = "stairs:stair_inner_" .. subname .. " 7",
			recipe = {
				{"", recipeitem, ""},
				{recipeitem, "", recipeitem},
				{recipeitem, recipeitem, recipeitem},
			},
		})

		-- Fuel
		local baseburntime = minetest.get_craft_result({
			method = "fuel",
			width = 1,
			items = {recipeitem}
		}).time
		if baseburntime > 0 then
			minetest.register_craft({
				type = "fuel",
				recipe = "stairs:stair_inner_" .. subname,
				burntime = math.floor(baseburntime * 0.875),
			})
		end
	end
end


-- Register outer stair
-- Node will be called stairs:stair_outer_<subname>

function stairs.register_stair_outer(subname, recipeitem, groups, images,
		description, sounds, worldaligntex, full_description, alpha, light)
	-- Set backface culling and world-aligned textures
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	local new_groups = table.copy(groups)
	new_groups.stair = 1
	if full_description then
		description = full_description
	else
		description = "Outer " .. description
	end
	warn_if_exists("stairs:stair_outer_" .. subname)
	minetest.register_node(":stairs:stair_outer_" .. subname, {
		description = description,
		drawtype = "nodebox",
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		use_texture_alpha = alpha or false,	-- mm added for alpha texture stair / slab
		light_source = light or 0, -- mm added for lighted stair / slab
		groups = new_groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
				{-0.5, 0.0, 0.0, 0.0, 0.5, 0.5},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			return rotate_and_place(itemstack, placer, pointed_thing)
		end,
	})

	if recipeitem then
		minetest.register_craft({
			output = "stairs:stair_outer_" .. subname .. " 6",
			recipe = {
				{"", recipeitem, ""},
				{recipeitem, recipeitem, recipeitem},
			},
		})

		-- Fuel
		local baseburntime = minetest.get_craft_result({
			method = "fuel",
			width = 1,
			items = {recipeitem}
		}).time
		if baseburntime > 0 then
			minetest.register_craft({
				type = "fuel",
				recipe = "stairs:stair_outer_" .. subname,
				burntime = math.floor(baseburntime * 0.625),
			})
		end
	end
end

--mm added thin slabs and slopes
-- Node will be called stairs:slab1<subname>
function stairs.register_slab1(subname, recipeitem, groups, images,
		description, sounds, worldaligntex, alpha, light)
	-- Set world-aligned textures
	local slab_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			slab_images[i] = {
				name = image,
			}
			if worldaligntex then
				slab_images[i].align_style = "world"
			end
		else
			slab_images[i] = table.copy(image)
			if worldaligntex and image.align_style == nil then
				slab_images[i].align_style = "world"
			end
		end
	end
	local new_groups = table.copy(groups)
	new_groups.slab = 1
	warn_if_exists("stairs:slab1_" .. subname)
	minetest.register_node(":stairs:slab1_" .. subname, {
		description = description,
		drawtype = "nodebox",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		use_texture_alpha = alpha or false,	-- mm added for alpha texture stair / slab
		light_source = light or 0, -- mm added for lighted stair / slab
		groups = new_groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, (1/16)-0.5, 0.5},
		},
		on_place = minetest.rotate_node
	})

	-- slab recipe
	minetest.register_craft({
		output = 'stairs:slab1_' .. subname .. ' 3',
		recipe = {
			{"stairs:slab_" .. subname},
		},
	})
--[[
	minetest.register_craft({
		output = 'stairs:slab_' .. subname .. ' 1',
		recipe = {
			{"stairs:slab1_" .. subname ..' 3'},
		},
	})
	]]
			-- Use 3 thin slabs to craft a half-slab again (1:1)
		minetest.register_craft({
			output = "stairs:slab_" .. subname,
			recipe = {
				{"stairs:slab1_" .. subname},
				{"stairs:slab1_" .. subname},
				{"stairs:slab1_" .. subname},
			},
		})
end

-- Node will be called stairs:slope_<subname>
function stairs.register_slope(subname, recipeitem, groups, images,
		description, sounds, worldaligntex, alpha, light)
	-- Set backface culling and world-aligned textures
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	local new_groups = table.copy(groups)
	new_groups.stair = 1
	warn_if_exists("stairs:slope_" .. subname)
	minetest.register_node(":stairs:slope_" .. subname, {
		description = description,
		drawtype = "mesh",
		mesh = "stairs_slope.obj",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		use_texture_alpha = alpha or false,	-- mm added for alpha texture stair / slab
		light_source = light or 0, -- mm added for lighted stair / slab
		groups = groups,
		sounds = sounds,
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		on_place = minetest.rotate_node
	})

	-- slope recipe
	minetest.register_craft({
		output = 'stairs:slope_' .. subname .. ' 6',
		recipe = {
			{recipeitem, "", ""},
			{recipeitem, recipeitem, ""},
		},
	})

	-- slope to original material recipe
	minetest.register_craft({
		type = "shapeless",
		output = recipeitem,
		recipe = {"stairs:slope_" .. subname, "stairs:slope_" .. subname}
	})
end


-- Stair/slab registration function.
-- Nodes will be called stairs:{stair,slab}_<subname>

function stairs.register_stair_and_slab(subname, recipeitem, groups, images,
		desc_stair, desc_slab, sounds, worldaligntex, alpha, light)
	stairs.register_stair(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex, alpha, light)
	stairs.register_stair_inner(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex, alpha, light)
	stairs.register_stair_outer(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex, alpha, light)
	stairs.register_slab(subname, recipeitem, groups, images, desc_slab,
		sounds, worldaligntex, alpha, light)
--mm added slopes and thin slabs (panels)
--[[	stairs.register_slab1(subname, recipeitem, groups, images, desc_slab,
		sounds, worldaligntex, alpha, light)

	stairs.register_slope(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex, alpha, light)
]]
end

-- Local function so we can apply translations
local function my_register_stair_and_slab(subname, recipeitem, groups, images,
		desc_stair, desc_slab, sounds, worldaligntex, alpha, light)
	stairs.register_stair(subname, recipeitem, groups, images, S(desc_stair),
		sounds, worldaligntex, alpha, light)
	stairs.register_stair_inner(subname, recipeitem, groups, images, "",
		sounds, worldaligntex, S("Inner " .. desc_stair), alpha, light)
	stairs.register_stair_outer(subname, recipeitem, groups, images, "",
		sounds, worldaligntex, S("Outer " .. desc_stair), alpha, light)
	stairs.register_slab(subname, recipeitem, groups, images, S(desc_slab),
		sounds, worldaligntex, alpha, light)
--mm added slopes and thin slabs (panels)
	stairs.register_slab1(subname, recipeitem, groups, images, S(subname.. " Panel"),
		sounds, worldaligntex, alpha, light)
	stairs.register_slope(subname, recipeitem, groups, images, S(subname .. " Slope"),
		sounds, worldaligntex, alpha, light)
end



-- Register default stairs and slabs

my_register_stair_and_slab(
	"wood",
	"default:wood",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	{"default_wood.png"},
	"Wooden Stair",
	"Wooden Slab",
	default.node_sound_wood_defaults(),
	false
)

my_register_stair_and_slab(
	"junglewood",
	"default:junglewood",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	{"default_junglewood.png"},
	"Jungle Wood Stair",
	"Jungle Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

my_register_stair_and_slab(
	"pine_wood",
	"default:pine_wood",
	{choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_pine_wood.png"},
	"Pine Wood Stair",
	"Pine Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

my_register_stair_and_slab(
	"acacia_wood",
	"default:acacia_wood",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	{"default_acacia_wood.png"},
	"Acacia Wood Stair",
	"Acacia Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

my_register_stair_and_slab(
	"aspen_wood",
	"default:aspen_wood",
	{choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_aspen_wood.png"},
	"Aspen Wood Stair",
	"Aspen Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

my_register_stair_and_slab(
	"stone",
	"default:stone",
	{cracky = 3},
	{"default_stone.png"},
	"Stone Stair",
	"Stone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"cobble",
	"default:cobble",
	{cracky = 3},
	{"default_cobble.png"},
	"Cobblestone Stair",
	"Cobblestone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"mossycobble",
	"default:mossycobble",
	{cracky = 3},
	{"default_mossycobble.png"},
	"Mossy Cobblestone Stair",
	"Mossy Cobblestone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"stonebrick",
	"default:stonebrick",
	{cracky = 2},
	{"default_stone_brick.png"},
	"Stone Brick Stair",
	"Stone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"stone_block",
	"default:stone_block",
	{cracky = 2},
	{"default_stone_block.png"},
	"Stone Block Stair",
	"Stone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"desert_stone",
	"default:desert_stone",
	{cracky = 3},
	{"default_desert_stone.png"},
	"Desert Stone Stair",
	"Desert Stone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"desert_cobble",
	"default:desert_cobble",
	{cracky = 3},
	{"default_desert_cobble.png"},
	"Desert Cobblestone Stair",
	"Desert Cobblestone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"desert_stonebrick",
	"default:desert_stonebrick",
	{cracky = 2},
	{"default_desert_stone_brick.png"},
	"Desert Stone Brick Stair",
	"Desert Stone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"desert_stone_block",
	"default:desert_stone_block",
	{cracky = 2},
	{"default_desert_stone_block.png"},
	"Desert Stone Block Stair",
	"Desert Stone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"sandstone",
	"default:sandstone",
	{crumbly = 1, cracky = 3},
	{"default_sandstone.png"},
	"Sandstone Stair",
	"Sandstone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"sandstonebrick",
	"default:sandstonebrick",
	{cracky = 2},
	{"default_sandstone_brick.png"},
	"Sandstone Brick Stair",
	"Sandstone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"sandstone_block",
	"default:sandstone_block",
	{cracky = 2},
	{"default_sandstone_block.png"},
	"Sandstone Block Stair",
	"Sandstone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"desert_sandstone",
	"default:desert_sandstone",
	{crumbly = 1, cracky = 3},
	{"default_desert_sandstone.png"},
	"Desert Sandstone Stair",
	"Desert Sandstone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"desert_sandstone_brick",
	"default:desert_sandstone_brick",
	{cracky = 2},
	{"default_desert_sandstone_brick.png"},
	"Desert Sandstone Brick Stair",
	"Desert Sandstone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"desert_sandstone_block",
	"default:desert_sandstone_block",
	{cracky = 2},
	{"default_desert_sandstone_block.png"},
	"Desert Sandstone Block Stair",
	"Desert Sandstone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"silver_sandstone",
	"default:silver_sandstone",
	{crumbly = 1, cracky = 3},
	{"default_silver_sandstone.png"},
	"Silver Sandstone Stair",
	"Silver Sandstone Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"silver_sandstone_brick",
	"default:silver_sandstone_brick",
	{cracky = 2},
	{"default_silver_sandstone_brick.png"},
	"Silver Sandstone Brick Stair",
	"Silver Sandstone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"silver_sandstone_block",
	"default:silver_sandstone_block",
	{cracky = 2},
	{"default_silver_sandstone_block.png"},
	"Silver Sandstone Block Stair",
	"Silver Sandstone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"obsidian",
	"default:obsidian",
	{cracky = 1, level = 2},
	{"default_obsidian.png"},
	"Obsidian Stair",
	"Obsidian Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"obsidianbrick",
	"default:obsidianbrick",
	{cracky = 1, level = 2},
	{"default_obsidian_brick.png"},
	"Obsidian Brick Stair",
	"Obsidian Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"obsidian_block",
	"default:obsidian_block",
	{cracky = 1, level = 2},
	{"default_obsidian_block.png"},
	"Obsidian Block Stair",
	"Obsidian Block Slab",
	default.node_sound_stone_defaults(),
	true
)

my_register_stair_and_slab(
	"brick",
	"default:brick",
	{cracky = 3},
	{"default_brick.png"},
	"Brick Stair",
	"Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

my_register_stair_and_slab(
	"steelblock",
	"default:steelblock",
	{cracky = 1, level = 2},
	{"default_steel_block.png"},
	"Steel Block Stair",
	"Steel Block Slab",
	default.node_sound_metal_defaults(),
	true
)

my_register_stair_and_slab(
	"tinblock",
	"default:tinblock",
	{cracky = 1, level = 2},
	{"default_tin_block.png"},
	"Tin Block Stair",
	"Tin Block Slab",
	default.node_sound_metal_defaults(),
	true
)

my_register_stair_and_slab(
	"copperblock",
	"default:copperblock",
	{cracky = 1, level = 2},
	{"default_copper_block.png"},
	"Copper Block Stair",
	"Copper Block Slab",
	default.node_sound_metal_defaults(),
	true
)

my_register_stair_and_slab(
	"bronzeblock",
	"default:bronzeblock",
	{cracky = 1, level = 2},
	{"default_bronze_block.png"},
	"Bronze Block Stair",
	"Bronze Block Slab",
	default.node_sound_metal_defaults(),
	true
)

my_register_stair_and_slab(
	"goldblock",
	"default:goldblock",
	{cracky = 1},
	{"default_gold_block.png"},
	"Gold Block Stair",
	"Gold Block Slab",
	default.node_sound_metal_defaults(),
	true
)

my_register_stair_and_slab(
	"ice",
	"default:ice",
	{cracky = 3, cools_lava = 1, slippery = 3},
	{"default_ice.png"},
	"Ice Stair",
	"Ice Slab",
	default.node_sound_glass_defaults(),
	true
)

my_register_stair_and_slab(
	"snowblock",
	"default:snowblock",
	{crumbly = 3, cools_lava = 1, snowy = 1},
	{"default_snow.png"},
	"Snow Block Stair",
	"Snow Block Slab",
	default.node_sound_snow_defaults(),
	true
)

--Extreme Survival Extra Nodes and more custom default nodes
--============================
--============================
--trees
my_register_stair_and_slab(
	"tree",
	"default:tree",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_tree_top.png"},
	"Apple Tree Stair",
	"Apple Tree Slab",
	default.node_sound_wood_defaults(),
	true
)

my_register_stair_and_slab(
	"jungletree",
	"default:jungletree",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_jungletree_top.png"},
	"Jungle Tree Stair",
	"Jungle Tree Slab",
	default.node_sound_wood_defaults(),
	true
)

my_register_stair_and_slab("pine_tree", "default:pine_tree",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_pine_tree_top.png"},
	"Pine Tree Stair",
	"Pine Tree Slab",
	default.node_sound_wood_defaults(),
	true
)

my_register_stair_and_slab("acacia_tree", "default:acacia_tree",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_acacia_tree_top.png"},
	"Acacia Tree Stair",
	"Acacia Tree Slab",
	default.node_sound_wood_defaults(),
	true
)

my_register_stair_and_slab("aspen_tree", "default:aspen_tree",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_aspen_tree_top.png"},
	"Aspen Tree Stair",
	"Aspen Tree Slab",
	default.node_sound_wood_defaults(),
	true
)

--dirts
my_register_stair_and_slab(
	"dirt",
	"default:dirt",
	{crumbly = 3, soil = 1},
	{"default_dirt.png"},
	"Dirt Stair",
	"Dirt Slab",
	default.node_sound_dirt_defaults(),
	true
)

my_register_stair_and_slab(
	"dry_dirt",
	"default:dry_dirt",
	{crumbly = 3, soil = 0},
	{"default_dry_dirt.png"},
	"Dry Dirt Stair",
	"Dry Dirt Slab",
	default.node_sound_dirt_defaults(),
	true
)

my_register_stair_and_slab(
	"dirt_with_grass",
	"default:dirt_with_grass",
	 {crumbly = 3, soil = 1, spreading_dirt_type = 0},
	{"default_grass.png", "default_dirt.png", "default_dirt.png^default_grass_side.png"},
	"Dirt With Grass Stair",
	"Dirt With Grass Slab",
	default.node_sound_dirt_defaults(),
	true
)

my_register_stair_and_slab(
	"dirt_with_snow",
	"default:dirt_with_snow",
	 {crumbly = 3, soil = 1, spreading_dirt_type = 0},
	{"default_snow.png", "default_dirt.png", "default_dirt.png^default_snow_side.png"},
	"Dirt With Grass With Snow Stair",
	"Dirt With Grass With Snow Slab",
	default.node_sound_dirt_defaults(),
	true
)

my_register_stair_and_slab(
	"dirt_with_dry_grass",
	"default:dirt_with_dry_grass",
	{crumbly = 3, soil = 1, spreading_dirt_type = 0},
	{"default_dry_grass.png", "default_dirt.png", "default_dirt.png^default_dry_grass_side.png"},
	"Dirt With Dry Grass Stair",
	"Dirt With Dry Grass Slab",
	default.node_sound_dirt_defaults(),
	true
)

my_register_stair_and_slab(
	"dirt_with_rainforest_litter",
	"default:dirt_with_rainforest_litter",
	{crumbly = 3, soil = 1, spreading_dirt_type = 0},
	{"default_rainforest_litter.png", "default_dirt.png", "default_dirt.png^default_rainforest_litter_side.png"},
	"Dirt W/ Rainforest Litter Stair",
	"Dirt W/ Rainforest Litter Slab",
	default.node_sound_dirt_defaults(),
	true
)

my_register_stair_and_slab(
	"dirt_with_coniferous_litter",
	"default:dirt_with_coniferous_litter",
	{crumbly = 3, soil = 1, spreading_dirt_type = 0},
	{"default_coniferous_litter.png", "default_dirt.png", "default_dirt.png^default_coniferous_litter_side.png"},
	"Dirt W/ Coniferous Litter Stair",
	"Dirt W/ Coniferous Litter Slab",
	default.node_sound_dirt_defaults(),
	true
)

--colours for nodes
--========================

--= Coloured Blocks Mod
if minetest.global_exists("cblocks") then
	local colours = cblocks.colours

	for i = 1, #colours do
		-- stonebrick / clay / wood / glass /  -stair, slab, thin slab, slope
		my_register_stair_and_slab(
			colours[i][1] .. "_stonebrick",
			"cblocks:stonebrick_" .. colours[i][1],
			{cracky = 2},
			--{"default_stone_brick.png^[colorize:" .. colours[i][3]},
			{"default_stone_brick.png^[colorize:" .. colours[i][3]},
			colours[i][2] .. " Stonebrick Stair",
			colours[i][2] .. " Stonebrick Slab",
			default.node_sound_stone_defaults(),
			true
		)

		my_register_stair_and_slab(
			colours[i][1] .. "_stone",
			"cblocks:stone_" .. colours[i][1],
			{cracky = 2},
			--{"default_stone.png^[colorize:" .. colours[i][3]},
			{"default_stone.png^[colorize:" .. colours[i][3]},
			colours[i][2] .. " Stone Stair",
			colours[i][2] .. " Stone Slab",
			default.node_sound_stone_defaults(),
			true
		)

		my_register_stair_and_slab(
			colours[i][1] .. "_clay",
			"cblocks:clay_" .. colours[i][1],
			{crumbly = 2, oddly_breakable_by_hand = 2},
			--{"default_clay.png^[colorize:" .. colours[i][3]},
			{"default_clay.png^[colorize:" .. colours[i][3]},
			colours[i][2] .. " Clay Stair",
			colours[i][2] .. " Clay Slab",
			default.node_sound_dirt_defaults(),
			true
		)

		my_register_stair_and_slab(
			colours[i][1] .. "_wood",
			"cblocks:wood_" .. colours[i][1],
			{choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},
			--{"default_wood.png^[colorize:" .. colours[i][3]},
			{"default_wood.png^[colorize:" .. colours[i][3]},
			colours[i][2] .. " Wood Stair",
			colours[i][2] .. " Wood Slab",
			default.node_sound_wood_defaults(),
			true
		)

		my_register_stair_and_slab(
			colours[i][1] .. "_cobble",
			"cblocks:cobble_" .. colours[i][1],
			{cracky = 2},
			--{"default_wood.png^[colorize:" .. colours[i][3]},
			{"default_cobble.png^[colorize:" .. colours[i][3]},
			colours[i][2] .. " Cobble Stair",
			colours[i][2] .. " Cobble Slab",
			default.node_sound_stone_defaults(),
			true
		)

		my_register_stair_and_slab(
			colours[i][1] .. "_glass",
			"cblocks:glass_" .. colours[i][1],
			{cracky = 3, oddly_breakable_by_hand = 3},
			--{"cblocks.png^[colorize:" .. colours[i][3]},
			{"default_glass.png^default_glass_detail.png^[colorize:" .. colours[i][3]},
			--{"default_glass.png^default_glass_detail.png^" .. colours[i][3]},
			--drawtype = "glasslike",
			--paramtype = "light",
			--alpha = 160,
			--drawtype = "glasslike_framed_optional",
			--paramtype2 = "glasslikeliquidlevel",
			colours[i][2] .. " Glass Stair",
			colours[i][2] .. " Glass Slab",
			default.node_sound_glass_defaults(),
			true
			--"0,0,0",
			--default.LIGHT_MAX-14
		)

		my_register_stair_and_slab(
			colours[i][1] .. "_meselamp",
			"cblocks:meselamp_" .. colours[i][1],
			{cracky = 3, oddly_breakable_by_hand = 3},
			--{"default_meselamp.png^[colorize:" .. colours[i][3]},
			{"default_meselamp.png^[colorize:" .. colours[i][3]},
			colours[i][2] .. " Mese Lamp Stair",
			colours[i][2] .. " Mese Lamp Slab",
			default.node_sound_glass_defaults(),
			true
			-- "0,0,0",
			-- default.LIGHT_MAX
		)
	end
end


--= Wool Mod

if minetest.get_modpath("wool") and minetest.global_exists("dye") then
	local colours = dye.dyes
	for i = 1, #colours do
		my_register_stair_and_slab(
			"wool_" .. colours[i][1],
			"wool:" .. colours[i][1],
			{snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, flammable = 3},
			{"wool_" .. colours[i][1] .. ".png"},
			colours[i][2] .. " Wool Stair",
			colours[i][2] .. " Wool Slab",
			default.node_sound_stone_defaults(),
			true
		)
	end
end


--= Es Mod
if minetest.get_modpath("es") then
	--es grass
	my_register_stair_and_slab(
		"dry_dirt",
		"es:dry_dirt",
		{crumbly = 2, soil = 0, spreading_dirt_type = 0},
		{"default_dry_dirt.png"},
		"Some dry dirt Stair",
		"Some dry dirt Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_grass",
		"es:strange_grass",
		{crumbly = 3, soil = 1, spreading_dirt_type = 1, es_grass = 1},
		{"strange_grass.png", "default_clay.png", "default_clay.png^strange_grass_side.png"},
		"Strange Grass Stair",
		"Strange Grass Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"aiden_grass",
		"es:aiden_grass",
		{crumbly = 3, soil = 1, spreading_dirt_type = 1, es_grass = 1},
		{"aiden_grass.png", "default_clay.png", "default_clay.png^aiden_grass_side.png"},
		"Aiden Grass Stair",
		"Aiden Grass Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	--ES Technic marble / Granite
	my_register_stair_and_slab(
		"granite",
		"es:granite",
		{cracky = 3},
		{"technic_granite.png"},
		--{"mcl_core_granite.png"},
		"Granite Block Stair",
		"Granite Block Slab",
		default.node_sound_stone_defaults(),
		true
	)

	my_register_stair_and_slab(
		"marble",
		"es:marble",
		{cracky = 3},
		{"technic_marble.png"},
		--{"mcl_core_diorite.png"},
		"Marble Block Stair",
		"Marble Block Slab",
		default.node_sound_stone_defaults(),
		true
	)

	my_register_stair_and_slab(
		"granite_bricks",
		"es:granite_bricks",
		{cracky = 3},
		{"technic_granite_bricks.png"},
		--{"mcl_core_granite_smooth.png"},
		"Granite Bricks Block Stair",
		"Granite Bricks Block Slab",
		default.node_sound_stone_defaults(),
		true
	)

	my_register_stair_and_slab(
		"marble_bricks",
		"es:marble_bricks",
		{cracky = 3},
		{"technic_marble_bricks.png"},
		--{"mcl_core_diorite_smooth.png"},
		"Marble Bricks Block Stair",
		"Marble Bricks Block Slab",
		default.node_sound_stone_defaults(),
		true
	)

	--Es Strange Clay
	my_register_stair_and_slab(
		"strange_clay_blue",
		"es:strange_clay_blue",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_blue.png"},
		"Strange Clay Blue Stair",
		"Strange Clay Blue Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_clay_red",
		"es:strange_clay_red",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_red.png"},
		"Strange Clay Red Stair",
		"Strange Clay Red Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_clay_maroon",
		"es:strange_clay_maroon",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_maroon.png"},
		"Strange Clay Maroon Stair",
		"Strange Clay Maroon Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_clay_brown",
		"es:strange_clay_brown",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_brown.png"},
		"Strange Clay Brown Stair",
		"Strange Clay Brown Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_clay_orange",
		"es:strange_clay_orange",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_orange.png"},
		"Strange Clay Orange Stair",
		"Strange Clay Orange Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_clay_black",
		"es:strange_clay_black",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_black.png"},
		"Strange Clay Black Stair",
		"Strange Clay Black Slab",
		default.node_sound_dirt_defaults(),
		true
	)

	my_register_stair_and_slab(
		"strange_clay_grey",
		"es:strange_clay_grey",
		{crumbly = 3,oddly_breakable_by_hand=1},
		{"strange_clay_grey.png"},
		"Strange Clay Grey Stair",
		"Strange Clay Grey Slab",
		default.node_sound_dirt_defaults(),
		true
	)


	--Es Jewels
	my_register_stair_and_slab(
		"emerald",
		"es:emeraldblock",
		{cracky = 3},
		{"emerald_block.png"},
		"Emerald Block Stair",
		"Emerald Block Slab",
		default.node_sound_glass_defaults(),
		true
	)

	my_register_stair_and_slab(
		"ruby",
		"es:rubyblock",
		{cracky = 3},
		{"ruby_block.png"},
		"Ruby Block Stair",
		"Ruby Block Slab",
		default.node_sound_glass_defaults(),
		true
	)

	my_register_stair_and_slab(
		"aikerum",
		"es:aikerumblock",
		{cracky = 3},
		{"aikerum_block.png"},
		"Aikerum Block Stair",
		"Aikerum Block Slab",
		default.node_sound_glass_defaults(),
		true
	)

	my_register_stair_and_slab(
		"infinium",
		"es:infiniumblock",
		{cracky = 3},
		{"infinium_block.png"},
		"Infinium Block Stair",
		"Infinium Block Slab",
		default.node_sound_stone_defaults(),
		true
	)

	my_register_stair_and_slab(
		"purpellium",
		"es:purpelliumblock",
		{cracky = 3},
		{"purpellium_block.png"},
		"Purpellium Block Stair",
		"Purpellium Block Slab",
		default.node_sound_glass_defaults(),
		true
	)

		my_register_stair_and_slab(
		"unobtanium",
		"es:unobtaniumblock",
		{cracky = 3},
		{"unobtainium_block.png"},
		"Unobtanium Block Stair",
		"Unobtanium Block Slab",
		default.node_sound_stone_defaults(),
		true
	)

		my_register_stair_and_slab(
		"depleted_uranium",
		"es:depleted_uraniumblock",
		{cracky = 3},
		{"depleted_uranium_block.png"},
		"Depleted Uranium Block Stair",
		"Depleted Uranium Block Slab",
		default.node_sound_glass_defaults(),
		true
	)

	my_register_stair_and_slab(
		"boneblock",
		"es:boneblock",
		{crumbly = 2,oddly_breakable_by_hand=1},
		{"bones_front.png"},
		"Bone Block Stair",
		"Bone Block Slab",
		default.node_sound_gravel_defaults(),
		true
	)

	my_register_stair_and_slab(
		"messymese",
		"es:messymese",
		{crumbly = 2,oddly_breakable_by_hand=1},
		{"default_clay.png^bubble.png^mese_cook_mese_crystal.png"},
		"Messymese Stair",
		"Messymese Slab",
		default.node_sound_stone_defaults(),
		true
	)
end
--[[
--lighted nodes
my_register_stair_and_slab(
	"meselamp",
	"default:meselamp",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"default_meselamp.png"},
	"Meselamp Stair",
	"Meselamp Slab",
	default.node_sound_glass_defaults(),
	true
	-- "0,0,0",
	-- default.LIGHT_MAX
)
--]]
my_register_stair_and_slab(
	"meselamp",
	"default:meselamp",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"default_meselamp.png"},
	"Meselamp Stair",
	"Meselamp Slab",
	default.node_sound_glass_defaults(),
	true
	-- "0,0,0",
	-- default.LIGHT_MAX
)

--============================
--============================

-- Glass stair nodes need to be registered individually to utilize specialized textures.

stairs.register_stair(
	"glass",
	"default:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"stairs_glass_split.png", "default_glass.png",
	"stairs_glass_stairside.png^[transformFX", "stairs_glass_stairside.png",
	"default_glass.png", "stairs_glass_split.png"},
	S("Glass Stair"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_slab(
	"glass",
	"default:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"default_glass.png", "default_glass.png", "stairs_glass_split.png"},
	S("Glass Slab"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair_inner(
	"glass",
	"default:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"stairs_glass_stairside.png^[transformR270", "default_glass.png",
	"stairs_glass_stairside.png^[transformFX", "default_glass.png",
	"default_glass.png", "stairs_glass_stairside.png"},
	"",
	default.node_sound_glass_defaults(),
	false,
	S("Inner Glass Stair")
)

stairs.register_stair_outer(
	"glass",
	"default:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"stairs_glass_stairside.png^[transformR90", "default_glass.png",
	"stairs_glass_outer_stairside.png", "stairs_glass_stairside.png",
	"stairs_glass_stairside.png^[transformR90","stairs_glass_outer_stairside.png"},
	"",
	default.node_sound_glass_defaults(),
	false,
	S("Outer Glass Stair")
)

stairs.register_slab1(
	"glass",
	"default:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"default_glass.png", "default_glass.png", "stairs_glass_split.png"},
	S("Glass Panel"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_slope(
	"glass",
	"default:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"default_glass.png", "default_glass.png", "stairs_glass_split.png"},
	S("Glass Slope"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"stairs_obsidian_glass_split.png", "default_obsidian_glass.png",
	"stairs_obsidian_glass_stairside.png^[transformFX", "stairs_obsidian_glass_stairside.png",
	"default_obsidian_glass.png", "stairs_obsidian_glass_split.png"},
	S("Obsidian Glass Stair"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_slab(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"default_obsidian_glass.png", "default_obsidian_glass.png", "stairs_obsidian_glass_split.png"},
	S("Obsidian Glass Slab"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair_inner(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"stairs_obsidian_glass_stairside.png^[transformR270", "default_obsidian_glass.png",
	"stairs_obsidian_glass_stairside.png^[transformFX", "default_obsidian_glass.png",
	"default_obsidian_glass.png", "stairs_obsidian_glass_stairside.png"},
	"",
	default.node_sound_glass_defaults(),
	false,
	S("Inner Obsidian Glass Stair")
)

stairs.register_stair_outer(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"stairs_obsidian_glass_stairside.png^[transformR90", "default_obsidian_glass.png",
	"stairs_obsidian_glass_outer_stairside.png", "stairs_obsidian_glass_stairside.png",
	"stairs_obsidian_glass_stairside.png^[transformR90","stairs_obsidian_glass_outer_stairside.png"},
	"",
	default.node_sound_glass_defaults(),
	false,
	S("Outer Obsidian Glass Stair")
)

stairs.register_slab1(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"default_obsidian_glass.png", "default_obsidian_glass.png", "stairs_obsidian_glass_split.png"},
	S("Obsidian Glass Panel"),
	default.node_sound_glass_defaults(),
	false
)

stairs.register_slope(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"default_obsidian_glass.png", "default_obsidian_glass.png", "stairs_obsidian_glass_split.png"},
	S("Obsidian Glass Slope"),
	default.node_sound_glass_defaults(),
	false
)

-- Dummy calls to S() to allow translation scripts to detect the strings.
-- To update this add this code to my_register_stair_and_slab:
-- for _,x in ipairs({"","Inner ","Outer "}) do print(("S(%q)"):format(x..desc_stair)) end
-- print(("S(%q)"):format(desc_slab))

--[[
S("Wooden Stair")
S("Inner Wooden Stair")
S("Outer Wooden Stair")
S("Wooden Slab")
S("Jungle Wood Stair")
S("Inner Jungle Wood Stair")
S("Outer Jungle Wood Stair")
S("Jungle Wood Slab")
S("Pine Wood Stair")
S("Inner Pine Wood Stair")
S("Outer Pine Wood Stair")
S("Pine Wood Slab")
S("Acacia Wood Stair")
S("Inner Acacia Wood Stair")
S("Outer Acacia Wood Stair")
S("Acacia Wood Slab")
S("Aspen Wood Stair")
S("Inner Aspen Wood Stair")
S("Outer Aspen Wood Stair")
S("Aspen Wood Slab")
S("Stone Stair")
S("Inner Stone Stair")
S("Outer Stone Stair")
S("Stone Slab")
S("Cobblestone Stair")
S("Inner Cobblestone Stair")
S("Outer Cobblestone Stair")
S("Cobblestone Slab")
S("Mossy Cobblestone Stair")
S("Inner Mossy Cobblestone Stair")
S("Outer Mossy Cobblestone Stair")
S("Mossy Cobblestone Slab")
S("Stone Brick Stair")
S("Inner Stone Brick Stair")
S("Outer Stone Brick Stair")
S("Stone Brick Slab")
S("Stone Block Stair")
S("Inner Stone Block Stair")
S("Outer Stone Block Stair")
S("Stone Block Slab")
S("Desert Stone Stair")
S("Inner Desert Stone Stair")
S("Outer Desert Stone Stair")
S("Desert Stone Slab")
S("Desert Cobblestone Stair")
S("Inner Desert Cobblestone Stair")
S("Outer Desert Cobblestone Stair")
S("Desert Cobblestone Slab")
S("Desert Stone Brick Stair")
S("Inner Desert Stone Brick Stair")
S("Outer Desert Stone Brick Stair")
S("Desert Stone Brick Slab")
S("Desert Stone Block Stair")
S("Inner Desert Stone Block Stair")
S("Outer Desert Stone Block Stair")
S("Desert Stone Block Slab")
S("Sandstone Stair")
S("Inner Sandstone Stair")
S("Outer Sandstone Stair")
S("Sandstone Slab")
S("Sandstone Brick Stair")
S("Inner Sandstone Brick Stair")
S("Outer Sandstone Brick Stair")
S("Sandstone Brick Slab")
S("Sandstone Block Stair")
S("Inner Sandstone Block Stair")
S("Outer Sandstone Block Stair")
S("Sandstone Block Slab")
S("Desert Sandstone Stair")
S("Inner Desert Sandstone Stair")
S("Outer Desert Sandstone Stair")
S("Desert Sandstone Slab")
S("Desert Sandstone Brick Stair")
S("Inner Desert Sandstone Brick Stair")
S("Outer Desert Sandstone Brick Stair")
S("Desert Sandstone Brick Slab")
S("Desert Sandstone Block Stair")
S("Inner Desert Sandstone Block Stair")
S("Outer Desert Sandstone Block Stair")
S("Desert Sandstone Block Slab")
S("Silver Sandstone Stair")
S("Inner Silver Sandstone Stair")
S("Outer Silver Sandstone Stair")
S("Silver Sandstone Slab")
S("Silver Sandstone Brick Stair")
S("Inner Silver Sandstone Brick Stair")
S("Outer Silver Sandstone Brick Stair")
S("Silver Sandstone Brick Slab")
S("Silver Sandstone Block Stair")
S("Inner Silver Sandstone Block Stair")
S("Outer Silver Sandstone Block Stair")
S("Silver Sandstone Block Slab")
S("Obsidian Stair")
S("Inner Obsidian Stair")
S("Outer Obsidian Stair")
S("Obsidian Slab")
S("Obsidian Brick Stair")
S("Inner Obsidian Brick Stair")
S("Outer Obsidian Brick Stair")
S("Obsidian Brick Slab")
S("Obsidian Block Stair")
S("Inner Obsidian Block Stair")
S("Outer Obsidian Block Stair")
S("Obsidian Block Slab")
S("Brick Stair")
S("Inner Brick Stair")
S("Outer Brick Stair")
S("Brick Slab")
S("Steel Block Stair")
S("Inner Steel Block Stair")
S("Outer Steel Block Stair")
S("Steel Block Slab")
S("Tin Block Stair")
S("Inner Tin Block Stair")
S("Outer Tin Block Stair")
S("Tin Block Slab")
S("Copper Block Stair")
S("Inner Copper Block Stair")
S("Outer Copper Block Stair")
S("Copper Block Slab")
S("Bronze Block Stair")
S("Inner Bronze Block Stair")
S("Outer Bronze Block Stair")
S("Bronze Block Slab")
S("Gold Block Stair")
S("Inner Gold Block Stair")
S("Outer Gold Block Stair")
S("Gold Block Slab")
S("Ice Stair")
S("Inner Ice Stair")
S("Outer Ice Stair")
S("Ice Slab")
S("Snow Block Stair")
S("Inner Snow Block Stair")
S("Outer Snow Block Stair")
S("Snow Block Slab")
--]]
