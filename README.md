# Double Jump

[![LuaCheck status](https://github.com/Panquesito7/minetest-double_jump/workflows/luacheck/badge.svg)](https://github.com/Panquesito7/minetest-double_jump/actions)
[![ContentDB](https://content.minetest.net/packages/Panquesito7/double_jump/shields/downloads/)](https://content.minetest.net/packages/Panquesito7/double_jump/)

Adds the ability to **double+ jump** in Minetest!\
This can ultimately improve your experience in a few ways. Here are some:

- Exploring: This will make it easier to reach areas with a double jump.
- Parkour: Level your parkour skills and play on extreme parkour maps!
- PvP: Dodge your enemies' attacks and have intense battles.

In order to perform the extra jump, the player must have the `double_jump` privilege.

![Double Jump GIF](https://raw.githubusercontent.com/Panquesito7/minetest-double_jump/main/double_jump.gif)

Here's a video showcasing the mod in action.

[![Double Jump showcase](https://markdown-videos-api.jorgenkh.no/url?url=https%3A%2F%2Fyoutu.be%2FVTFYnTzhvro)](https://youtu.be/VTFYnTzhvro)

## Settings

These settings can be customized by modifying [`minetest.conf`](https://wiki.minetest.net/Minetest.conf) or directly in the Minetest settings.

- `double_jump.max_jump`: The maximum number of **extra** jumps. This does NOT count the builtin jump. Default is `1`.
- `double_jump.infinite_jumps`: Whether to have infinite jumps or not. Disabled (`false`) by default.
- `double_jump.max_height`: Maximum height gained on each jump. Default is [`movement_speed_jump`](https://github.com/minetest/minetest/blob/2b99dabdac823fee3ea843a9ded8bbe7718c3b44/builtin/settingtypes.txt#L935) (or `6.5`).

## Installation

- Unzip the archive, rename the folder to `double_jump` and
place it in `..minetest/mods/`

- GNU/Linux: If you use a system-wide installation place
    it in `~/.minetest/mods/`.

- If you only want this to be used in a single world, place
    the folder in `..worldmods/` in your world directory.

For further information or help, see:\
<https://wiki.minetest.net/Installing_Mods>

## License

See [`LICENSE.txt`](LICENSE.txt) for full license information and [`AUTHORS.md`](AUTHORS.md) for all the contributors.
