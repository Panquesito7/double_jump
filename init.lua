--[[
    A Minetest mod that allows the player to jump twice or more times.
    Copyright (C) 2023 David Leal (halfpacho@gmail.com)

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

double_jump = {
    jump_number = { },
    is_jumping = { },
    has_jumped = { }
}

---------------
-- Settings --
---------------

local max_jump_number = tonumber(minetest.settings:get("double_jump.max_jump")) or 1
local max_jump_height = tonumber(minetest.settings:get("double_jump.max_height")) or 6.5
local privilege_required = minetest.settings:get_bool("double_jump.privilege_required") or false

----------------
-- Privileges --
----------------
if privilege_required then
    minetest.register_privilege({"double_jump",
        description = "Allows the player to jump twice or more times!",
        give_to_singleplayer = false,
        give_to_admin = true
    })

    minetest.log("info", "[DOUBLE JUMP] The `double_jump` privilege has been registered. Normal users cannot double+ jump.")
end

---------------
-- Functions --
---------------

--- @brief Resets the jumping values of the player
--- once the player touches any node, except `air`.
--- @todo Fix checks not being detected well when a player is on the very corner of the node.
--- @param player userdata The player object.
--- @return nil
function double_jump.reset(player)
    double_jump.is_jumping[player] = false
    -- Reset values once the player touches any node.
    local pos = player:get_pos()
    local node = minetest.get_node(vector.new(pos.x, pos.y - 0.5, pos.z))

    if node.name ~= "air" then
        double_jump.jump_number[player] = 0
        double_jump.has_jumped[player] = false
    end
end

--- @brief Initializes the necessary variables for the double+ jump.
--- @param player userdata The player object.
--- @return nil
function double_jump.initialize(player)
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

--- @brief The basic function that allows the player to jump twice or more times.
--- Holding the jump button won't work, and jumps more than `max_jump_number` won't be triggered.
--- @param player userdata The player object.
--- @return nil
function double_jump.jump(player)
    if privilege_required and minetest.check_player_privs(player, { double_jump = true }) == false then
        return
    end

    local control = player:get_player_control()
    double_jump.initialize(player)

    if control.jump then
        if not double_jump.is_jumping[player] then -- Needed so that the player doesn't jump multiple times while holding jump.
            -- If the player drops midair, let the player use the double jump.
            if player:get_velocity().y < 0 then
                double_jump.has_jumped[player] = true
            end

            -- The first jump shouldn't be counted, thus, the need of `has_jumped`.
            if double_jump.has_jumped[player] then
                if double_jump.jump_number[player] >= max_jump_number then
                    return
                end

                double_jump.jump_number[player] = double_jump.jump_number[player] + 1
                local old_vel = player:get_velocity()

                -- After jumping, the Y speed of the player will be negative and causing the
                -- next jump not to achieve its full height. This adds the falling speed and the extra jump speed.
                if old_vel.y < 0 and old_vel.y ~= 0 then
                    player:add_velocity(vector.new(0, math.abs(old_vel.y) + 0.2, 0))
                end

                -- 6.5 is the default height for a normal jump.
                player:add_velocity(vector.new(0, max_jump_height, 0))
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

minetest.register_globalstep(function(_)
    local players = minetest.get_connected_players()
    for i = 1, #players do
        local player = players[i]
        double_jump.jump(player)
    end
end)

minetest.log("info", "[DOUBLE JUMP] Loaded!")
