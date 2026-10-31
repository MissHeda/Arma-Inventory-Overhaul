#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a container can take what a tile stands for: it has a free spot for it in one of its
 * compartments (fnc_hasSpace) and it is not a backpack going into a backpack (fnc_backpackIntoBackpack).
 * Free cells are the only limit - what the items weigh decides nothing here, it only slows the soldier who
 * carries them (einv_weight). The cargo commands add whatever they are given, so a window, a mission or a
 * mod has to ask this before it puts anything in. The ground takes everything.
 *
 * The window asks it for moves that do not say where (einv_gui_fnc_quickMove, einv_gui_fnc_quickUnequip,
 * the context menu); a drag only drops on free cells (einv_gui_fnc_updateDrag). fnc_moveEntry and
 * fnc_unequip ask when they are given no cell, so a mission or mod calling them cannot overfill a
 * container either - except on the server or a body's machine, which only carry out what a window already
 * checked.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Entry <HASHMAP>
 *
 * Return Value:
 * Room enough <BOOL>
 *
 * Example:
 * [vestContainer player, _entry] call einv_storage_fnc_hasRoom;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]]];

!([_container, _entry] call FUNC(backpackIntoBackpack)) && {[_container, _entry] call FUNC(hasSpace)}
