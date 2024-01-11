--[[
    A Minetest mod that allows the player to jump twice or more times.
    Copyright (C) 2023-2024 David Leal (halfpacho@gmail.com)

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--]]

local S = minetest.get_translator(minetest.get_current_modname())

double_jump = {
    jump_number = { },
    is_jumping = { },
    has_jumped = { }
}

---------------
-- Settings --
---------------

local max_jump_number = tonumber(minetest.settings:get("double_jump.max_jump")) or 1 -- Builtin jump doesn't count!
local max_jump_height = tonumber(minetest.settings:get("double_jump.max_height")) or 6.5 -- 6.5 is the default jump height.
local infinite_jump = minetest.settings:get_bool("double_jump.infinite_jumps") or false

if max_jump_number <= 0 then
    minetest.settings:set("double_jump.max_jump", 1)
end

----------------
-- Privileges --
----------------
minetest.register_privilege("double_jump", {
    description = S("Allows the player to jump twice or more times!"),
    give_to_singleplayer = false,
    give_to_admin = false
})

---------------
-- Functions --
---------------

--- @brief Exactly the same as `find_nodes_in_area_under_air`,
--- except that the nodes do not need to be specified.
---
--- Taken from https://gist.github.com/Panquesito7/06bce0063a73de6d40fe0c8c8f3485a4/
--- Thanks!
--- @param minp table The minimum position.
--- @param maxp table The maximum position.
--- @return table positions The positions of the nodes (if found).
local function find_all_nodes_in_area_under_air(minp, maxp)
    local positions = { }
    local i = 1

    -- Adjust the positions.
    -- This might need to be adjusted to your own specific case.
    minp.x = math.floor(minp.x + 0.5)
    minp.z = math.floor(minp.z + 0.5)

    maxp.x = math.ceil(maxp.x - 0.5)
    maxp.z = math.ceil(maxp.z - 0.5)

    for x = minp.x, maxp.x do
        for z = minp.z, maxp.z do
            local y = minp.y
            local pos = vector.new(x, y, z)

            if minetest.get_node(pos).name ~= "air" and minetest.get_node(vector.new(pos.x, pos.y + 1, pos.z)).name == "air" then
                positions[i] = pos
                i = i + 1
            end
        end
    end

    return positions
end

--- @brief Initializes the necessary variables for the double+ jump.
--- @param player userdata The player object.
--- @return nil
local function initialize(player)
    if double_jump.jump_number[player] == nil then
        double_jump.jump_number[player] = 0
    end

    if double_jump.is_jumping[player] == nil then
        double_jump.is_jumping[player] = false
    end

    if double_jump.has_jumped[player] == nil then
        double_jump.has_jumped[player] = false
    end
end

--- @brief Resets the jumping values of the player
--- once the player touches any node, except airlike nodes.
--- @param player userdata The player object.
--- @return nil
function double_jump.reset(player, always_reset)
    always_reset = always_reset or false

    -- Reset values once the player touches any node.
    local pos = player:get_pos()
    local minp = vector.new(pos.x - 0.3, pos.y - 0.1, pos.z - 0.3)
    local maxp = vector.new(pos.x + 0.3, pos.y, pos.z + 0.3)
    local nodes = find_all_nodes_in_area_under_air(minp, maxp)

    for i = 1, #nodes do
        local node = minetest.get_node(nodes[i])
        local node_def = node and minetest.registered_nodes[node.name]

        if (node_def and node_def.drawtype ~= "airlike") or always_reset then
            double_jump.jump_number[player] = 0
            double_jump.has_jumped[player] = false
        end
    end

    double_jump.is_jumping[player] = false
end

--- @brief Called every time the player uses the double jump.
--- Useful for other mods to add specific callbacks.
--- @param player userdata The player object.
--- @return nil
function double_jump.on_jump(player)
    return
end

--- @brief The basic function that allows the player to jump twice or more times.
--- Holding the jump button won't work, and jumps more than `max_jump_number` won't be triggered.
--- @param player userdata The player object.
--- @param jump_value number The value of the player's jump.
--- @return nil
function double_jump.jump(player, jump_value)
    local control = player:get_player_control()

    if control.jump then
        if not double_jump.is_jumping[player] then -- Needed so that the player doesn't jump multiple times while holding jump.
            -- If the player drops midair, let the player use the double jump.
            if player:get_velocity().y < 0 then
                double_jump.has_jumped[player] = true
            end

            -- The first jump shouldn't be counted, thus, the need of `has_jumped`.
            if double_jump.has_jumped[player] then
                if infinite_jump ~= true and double_jump.jump_number[player] >= max_jump_number then
                    return
                end

                -- `on_jump` callback.
                double_jump.on_jump(player)

                double_jump.jump_number[player] = double_jump.jump_number[player] + 1
                local vel = player:get_velocity()

                -- After jumping, the Y speed of the player will be negative and causing the
                -- next jump not to achieve its full height. This adds the falling speed and the extra jump speed.
                if vel.y < 0 and vel.y ~= 0 then
                    player:add_velocity(vector.new(0, math.abs(vel.y) + 0.2, 0))
                end

                -- Add the jump value to the player's velocity.
                -- `jump_value` is used so that it can easily be called by other mods.
                player:add_velocity(vector.new(0, jump_value, 0))

                -- Play the `player_jump` sound.
                -- This is originally played on each jump.
                minetest.sound_play({ name = "player_jump" }, { pos = player:get_pos(), to_player = player:get_player_name() })
            else
                double_jump.has_jumped[player] = true
            end
        end
        double_jump.is_jumping[player] = true
    else
        -- Reset variables in case the player has stopped jumping.
        double_jump.reset(player)
    end
end

--- @brief The main globalstep function for the extra jump code.
--- Very useful to be overriden by other mods.
--- @return nil
function double_jump.globalstep()
    local players = minetest.get_connected_players()
    for i = 1, #players do
        local player = players[i]

        local physics = player:get_physics_override()
        local speed = physics and physics.jump
        local jump_height = max_jump_height * speed

        local pos = player:get_pos()
        local minp = vector.new(pos.x - 0.3, pos.y - 0.1, pos.z - 0.3)
        local maxp = vector.new(pos.x + 0.3, pos.y, pos.z + 0.3)
        local nodes = find_all_nodes_in_area_under_air(minp, maxp)

        if minetest.check_player_privs(player, { double_jump = true }) == false then
            return
        end

        -- Is the player flying? If so, don't allow the player to double+ jump.
        if #nodes == 0 and player:get_velocity().y >= 0 then
            double_jump.reset(player)
            return
        end

        -- Is the player underwater? If so, we shouldn't trigger the double+ jump.
        for j = 1, #nodes do
            local water = minetest.get_node_level(nodes[j])
            if water > 0 then
                double_jump.reset(player, true)
                return
            end
        end

        -- A jump boost happens if the player jumped normally, falls on a block and
        -- instantly does the double jump, which results in a very high jump.
        if player:get_velocity().y >= math.floor(2) or player:get_velocity().y == math.floor(0) then
            double_jump.reset(player)
            return
        end

        double_jump.jump(player, jump_height)
    end
end

minetest.register_on_joinplayer(function(player)
    initialize(player)
end)

minetest.register_globalstep(function(_)
    double_jump.globalstep()
end)

if minetest.settings:get_bool("log_mods") then
    minetest.log("action", "[MOD] Double Jump loaded!")
end
