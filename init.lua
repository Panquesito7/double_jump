--[[
    A Minetest mod that allows the player to jump twice or more times.
    Copyright (C) 2023-2024 David Leal (halfpacho@gmail.com) and contributors

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
local max_jump_height = tonumber(minetest.settings:get("double_jump.max_height")) or (tonumber(minetest.settings:get("movement_speed_jump")) or 6.5)
local infinite_jump = minetest.settings:get_bool("double_jump.infinite_jumps", false)

if max_jump_number <= 0 then
    minetest.settings:set("double_jump.max_jump", 1)
end

local feat_player_velocity = minetest.features and minetest.features.direct_velocity_on_players

if not feat_player_velocity then
    minetest.log("warning",
        "[DOUBLE JUMP] Your current Minetest version (MT < 5.4.0) does not support the latest player velocity features." ..
        "Deprecated callbacks and methods will be used instead to retain compatibility."
    )
end

----------------
-- Privileges --
----------------
minetest.register_privilege("double_jump", {
    description = S("Allows the player to jump twice or more times!"),
    give_to_singleplayer = false,
    give_to_admin = false
})

-------------
-- Helpers --
-------------

--- @brief Exactly the same as `find_nodes_in_area_under_air`,
--- except that the nodes do not need to be specified.
---
--- Taken and slightly modified from https://gist.github.com/Panquesito7/06bce0063a73de6d40fe0c8c8f3485a4/
--- Thanks!
--- @param minp table the minimum position
--- @param maxp table the maximum position
--- @return table positions the positions of the nodes (if found)
local function find_all_nodes_in_area_under_air(minp, maxp)
    local positions = { }
    local i = 1

    -- Adjust the positions.
    -- This might need to be adjusted to your own specific case.
    minp.x = math.floor(minp.x + 0.3)
    minp.z = math.floor(minp.z + 0.3)

    maxp.x = math.ceil(maxp.x - 0.3)
    maxp.z = math.ceil(maxp.z - 0.3)

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
--- @param player userdata the player object
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

--- @brief Checks if there is any node under the player.
--- @param player userdata the player object
--- @return boolean nodes whether there is a node under the player or not
local function is_node_under_player(player)
    local pos = player:get_pos()
    local minp = vector.new(pos.x - 0.3, pos.y - 0.5, pos.z - 0.3)
    local maxp = vector.new(pos.x + 0.3, pos.y, pos.z + 0.3)
    local nodes = find_all_nodes_in_area_under_air(minp, maxp)
    local node = minetest.get_node_or_nil(vector.new(pos.x, pos.y - 0.5, pos.z))

    return #nodes > 0 or (node and node.name ~= "air")
end

--- @brief Access the player's velocity using modern or deprecated methods.
--- This is to provide full compatibility with MT < 5.4.0 versions.
--- @param player userdata the player object
--- @return table velocity the player speed in a table
local function get_vel(player)
    return feat_player_velocity and player:get_velocity() or player:get_player_velocity()
end

--- @brief Adds the given velocity to the player using modern or deprecated methods.
--- This is to provide full compatibility with MT < 5.4.0 versions.
--- @param player userdata the player object
--- @param vec table the velocity vector to be added to the player
--- @return nil
local function add_vel(player, vec)
    if feat_player_velocity then
       player:add_velocity(vec)
    else
        player:add_player_velocity(vector.new(vec.x, vec.y / 1.03, vec.z))
    end
end

----------------
-- Functions --
----------------

--- @brief Resets the jumping values of the player
--- once the player touches any node, except airlike nodes.
--- @param player userdata the player object
--- @return nil
function double_jump.reset(player, always_reset)
    always_reset = always_reset or false

    -- Reset values once the player touches any node.
    local node = is_node_under_player(player)

    if node or always_reset then
        double_jump.jump_number[player] = 0
        double_jump.has_jumped[player] = false
        return
    end
end

--- @brief Called every time the player uses the double jump.
--- Useful for other mods to add specific callbacks.
--- @param player userdata the player object
--- @return nil
function double_jump.on_jump(player)
    return
end

--- @brief The basic function that allows the player to jump twice or more times.
--- Holding the jump button won't work, and jumps more than `max_jump_number` won't be triggered.
--- @param player userdata the player object
--- @param jump_value number the value of the player's jump
--- @return nil
function double_jump.jump(player, jump_value)
    local control = player:get_player_control()
    local vel = get_vel(player)

    if control.jump then
        if not double_jump.is_jumping[player] then -- Needed so that the player doesn't jump multiple times while holding jump.
            -- If the player drops midair, let the player use the double jump.
            if vel.y < 0 then
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

                -- After jumping, the Y speed of the player will be negative and causing the
                -- next jump not to achieve its full height. This adds the falling speed and the extra jump speed.
                if vel.y < 0 and vel.y ~= 0 then
                    add_vel(player, vector.new(0, math.abs(vel.y) + 0.2, 0))
                end

                -- Add the jump value to the player's velocity.
                -- `jump_value` is used so that it can easily be called by other mods.
                add_vel(player, vector.new(0, jump_value, 0))

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
        double_jump.is_jumping[player] = false -- This should only be resetted here.
    end
end

--- @brief The main globalstep function for the extra jump code.
--- Very useful to be overriden by other mods.
--- @param dtime number the delta time accessed from the globalstep callback
--- @return nil
function double_jump.globalstep(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local privs = minetest.get_player_privs(player:get_player_name())
        local physics = player:get_physics_override()
        local speed = physics and physics.jump
        local jump_height = max_jump_height * speed

        local pos = player:get_pos()
        local node = minetest.get_node_or_nil(vector.new(pos.x, pos.y - 0.1, pos.z))
        local node_under = is_node_under_player(player)

        if minetest.check_player_privs(player, { double_jump = true }) == false then
            return
        end

        -- Is the player flying? If so, don't allow the player to double+ jump.
        if (node_under and player:get_velocity().y >= 0 and not minetest.is_singleplayer()) or
            (minetest.is_singleplayer() and minetest.settings:get_bool("free_move")) and privs.fly then

            double_jump.reset(player)
            return
        end

        -- Is the player underwater? If so, we shouldn't trigger the double+ jump.
        local node_def = node and minetest.registered_nodes[node.name]

        if node_def and (node_def.drawtype == "liquid" or node_def.drawtype == "flowingliquid") then
            double_jump.reset(player, true)
            return
        end

        -- A jump boost happens if the player jumped normally, falls on a block and
        -- instantly does the double jump, which results in a very high jump.
        local vel = get_vel(player)
        if vel.y >= math.floor(2) or vel.y == math.floor(0) then
            double_jump.reset(player)
            return
        end

        double_jump.jump(player, jump_height)
    end
end

minetest.register_on_joinplayer(function(player)
    initialize(player)
end)

minetest.register_globalstep(function(dtime)
    double_jump.globalstep(dtime)
end)

if minetest.settings:get_bool("log_mods") then
    minetest.log("action", "[MOD] Double Jump loaded!")
end
