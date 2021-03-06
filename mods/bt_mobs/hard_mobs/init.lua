-- Hard Mobs init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

hard_mobs_mod = {
	version = "1.0",
	path = minetest.get_modpath(minetest.get_current_modname()),
	world = minetest.get_worldpath()
}

local maximum_multiplier = 3	  -- Set this to change the maximum difficulty.
local minimum_multiplier = 1	  -- Set this to change the minimum difficulty.
local speed_factor = 0.5		  -- Mob speed increases by n * difficulty (2.5).
local good_loot_chance = 10		  -- Chance = floor(difficulty - 1) / n
local hc_delay = 3				  -- Mobs are checked every n seconds.
local change_walk_velocity = true -- Make mobs walk faster.
local scale_upward = true		  -- Increase stats above ground level.

local good_loot_table = {
	'default:mese',
	'default:diamondblock',
	'default:mithril_block'
}

local extra_loot_on_die = function(self, pos)
	if self and pos and self.difficulty then
		local chance = math.floor(self.difficulty - 1)
		if math.random(good_loot_chance) <= chance then
			local loot = good_loot_table[math.random(#good_loot_table)]
			local num = 1
			local obj = minetest.add_item(pos, ItemStack(loot .. " " .. num))

			if obj and obj:get_luaentity() then
				obj:set_velocity({
					x = math.random(-10, 10) / 9,
					y = 6,
					z = math.random(-10, 10) / 9,
				})
				-- print('dropped ' .. loot)
			elseif obj then
				obj:remove() -- item does not exist
			end
		-- else
			-- print('rolled too high')
		end
	end

	if self.old_on_die then
		self:old_on_die(pos)
	end
end

local check_for_death = nil
if mobs and mobs.dw then
	check_for_death = mobs.check_for_death
else
	check_for_death = function(self, cause)
		self.old_health = self.health
	end
end

local hardness = (31000 / maximum_multiplier) / minimum_multiplier
local last_hc_check = 0
minetest.register_globalstep(function(dtime)
	if not (dtime and type(dtime) == 'number') then
		return
	end

	local time = minetest.get_gametime()
	if not (time and type(time) == 'number') then
		return
	end

	-- Execute only after an interval
	if last_hc_check and time - last_hc_check < hc_delay then
		return
	end

	-- Promote mobs based on spawn position
	for _, mob in pairs(minetest.luaentities) do
		if not mob.initial_promotion and not mob.hp then
			local pos = mob.object:get_pos()
			if pos and mob.hp_max and mob.health and mob.damage then
				local y = pos.y > 0 and 0 or pos.y
				local factor = 1 + (math.max(math.abs(pos.x), math.abs(y), math.abs(pos.z)) * minimum_multiplier / hardness)
				-- These all expect that a mob will never be promoted twice,
				--  which should never happen, though they must be promoted
				--  every time they're reloaded.
				mob.hp_max = math.floor(mob.hp_max * factor)
				mob.damage = math.floor(mob.damage * factor)
				mob.health = math.floor(mob.health * factor)
				if change_walk_velocity then
					mob.walk_velocity = mob.walk_velocity * math.max(1, speed_factor * factor)
				end
				mob.run_velocity = mob.run_velocity * math.max(1, speed_factor * factor)
				mob.difficulty = factor
				mob.old_on_die = mob.on_die
				mob.on_die = extra_loot_on_die
				mob.object:set_hp(mob.health)
				mob.initial_promotion = true
				check_for_death(mob)

				-- local ent = mob.object:get_luaentity()
				-- local name = ent and ent.name or ""
				-- minetest.chat_send_all('Promoting ' .. name .. ': ' .. mob.health .. ' health, ' .. mob.damage .. ' damage  (x' .. (math.floor(factor * 100) / 100) .. ')')
			end
		end
	end
	last_hc_check = minetest.get_gametime()
end)