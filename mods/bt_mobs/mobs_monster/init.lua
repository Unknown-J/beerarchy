local path = minetest.get_modpath("mobs_monster") .. "/"

-- Intllib
local S = minetest.get_translator("mobs_monster")
mobs.intllib = S

-- Monsters

dofile(path .. "dirt_monster.lua") -- PilzAdam
dofile(path .. "dungeon_master.lua")
dofile(path .. "oerkki.lua")
dofile(path .. "sand_monster.lua")
dofile(path .. "stone_monster.lua")
dofile(path .. "tree_monster.lua")
dofile(path .. "lava_flan.lua") -- Zeg9
dofile(path .. "mese_monster.lua")
dofile(path .. "spider.lua") -- AspireMint


print (S("[MOD] Mobs Redo Monsters loaded"))