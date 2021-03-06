minetest.register_craftitem("throwing:arrow_mithril", {
	description = "Mithril Arrow",
	inventory_image = "throwing_arrow_mithril.png"
})

minetest.register_node("throwing:arrow_mithril_box", {
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- Shaft
			{-6.5/17, -1.5/17, -1.5/17, 6.5/17, 1.5/17, 1.5/17},
			-- Spitze
			{-4.5/17, 2.5/17, 2.5/17, -3.5/17, -2.5/17, -2.5/17},
			{-8.5/17, 0.5/17, 0.5/17, -6.5/17, -0.5/17, -0.5/17},
			-- Federn
			{6.5/17, 1.5/17, 1.5/17, 7.5/17, 2.5/17, 2.5/17},
			{7.5/17, -2.5/17, 2.5/17, 6.5/17, -1.5/17, 1.5/17},
			{7.5/17, 2.5/17, -2.5/17, 6.5/17, 1.5/17, -1.5/17},
			{6.5/17, -1.5/17, -1.5/17, 7.5/17, -2.5/17, -2.5/17},

			{7.5/17, 2.5/17, 2.5/17, 8.5/17, 3.5/17, 3.5/17},
			{8.5/17, -3.5/17, 3.5/17, 7.5/17, -2.5/17, 2.5/17},
			{8.5/17, 3.5/17, -3.5/17, 7.5/17, 2.5/17, -2.5/17},
			{7.5/17, -2.5/17, -2.5/17, 8.5/17, -3.5/17, -3.5/17}
		}
	},
	tiles = {
		"throwing_arrow_mithril.png",
		"throwing_arrow_mithril.png",
		"throwing_arrow_mithril_back.png",
		"throwing_arrow_mithril_front.png",
		"throwing_arrow_mithril_2.png",
		"throwing_arrow_mithril.png"
	},
	groups = {not_in_creative_inventory = 1}
})

local THROWING_ARROW_ENTITY = {
	physical = false,
	timer = 0,
	visual = "wielditem",
	visual_size = {x = 0.1,  y = 0.1},
	textures = {"throwing:arrow_mithril_box"},
	lastpos = {},
	collisionbox = {0, 0, 0, 0, 0, 0}
}

THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	local name = throwing.playerArrows[self.object]
	local node = minetest.get_node(pos)

	if self.timer > 0.2 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 2)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() then
				if obj:get_luaentity().name ~= "throwing:arrow_mithril_entity" and obj:get_luaentity().name ~= "__builtin:item" then
					local extra_damage = 0
					if name then
						extra_damage = ranking.playerXP[name] + math.random(-4, 4)
						if math.random(10) == 1 then
							extra_damage = extra_damage + 10
						end
					end
					local damage = 10 + extra_damage
					obj:punch(self.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = {fleshy = damage},
					}, nil)
					throwing.playerArrows[self.object] = nil
					self.object:remove()
				end
			else
				local extra_damage = 0
				if name then
					extra_damage = ranking.playerXP[name] + math.random(-4, 4)
					if math.random(10) == 1 then
						extra_damage = extra_damage + 10
					end
				end
				local damage = 10 + extra_damage
				obj:punch(self.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = {fleshy = damage},
				}, nil)
				throwing.playerArrows[self.object] = nil
				self.object:remove()
			end
		end
	end

	if self.lastpos.x then
		if node.name ~= "air" then
			throwing.playerArrows[self.object] = nil
			self.object:remove()
		end
	end
	self.lastpos = {x = pos.x, y = pos.y, z = pos.z}
end

minetest.register_entity("throwing:arrow_mithril_entity", THROWING_ARROW_ENTITY)

minetest.register_craft({
	output = 'throwing:arrow_mithril 4',
	recipe = {
		{'default:stick', 'default:stick', 'moreores:mithril_ingot'}
	}
})