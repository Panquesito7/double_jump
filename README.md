# Double Jump!

[![Build status](https://github.com/Panquesito7/double_jump/workflows/build/badge.svg)](https://github.com/Panquesito7/double_jump/actions)

Adds the ability to **double+ jump** in Minetest!\
This can ultimately improve your experience in a few ways. Here are some:

- Exploring: This will make it easier to reach areas with a double jump.
- Parkour: Level your parkour skills and play on extreme parkour maps!
- PvP: Dodge your enemies' attacks and have intense battles.

![Double Jump](https://github.com/Panquesito7/double_jump/assets/51391473/bc6442d5-4a4f-4a6e-b44e-db81f1fda74f)

You can see a video of it in action: <https://youtu.be/VTFYnTzhvro>

## Settings

- `double_jump.max_jump`: The maximum number of **extra** jumps. This does NOT count the builtin jump. Default is `1`.
- `double_jump.max_height`: Maximum height gained on each jump. Default is `6.5`. This is the value used on a builtin jump.
- `double_jump.privilege_required`: Whether a privilege is required for the double jump. This is given to administrators automatically. Default is `false`.

## Known bugs

- Sometimes, you randomly get a jump boost that sets you very high.
- The jumps after the builtin jump might not sometimes work. This can also happen if you're standing on 3/4 of a node, where the node the player is standing on is not detected, and detecting `air` instead.

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

See [`LICENSE.md`](LICENSE.md) for full details.
