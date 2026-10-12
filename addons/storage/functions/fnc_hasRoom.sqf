#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a container can take what a tile stands for, by mass: what it holds plus the entry must stay
 * within its maximumLoad. The cargo commands add whatever they are given, so this is the only check.
 * The ground takes everything; a backpack takes no backpack. The rule itself, with the numbers behind the
 * yes or no, is fnc_roomByWeight - this keeps the answer only.
 *
 * With einv_storage_gridOnly on, volume counts instead of mass: this always says yes and the
 * compartments alone decide what goes in, so whoever calls this has to ask the grid as well. The
 * window does: a drag only drops on free cells (einv_gui_fnc_updateDrag), and moves that do not say
 * where ask fnc_hasSpace first (einv_gui_fnc_quickMove, einv_gui_fnc_quickUnequip, the context menu).
 * fnc_moveEntry and fnc_unequip ask fnc_hasSpace themselves when they are given no cell, so a mission
 * or mod calling them cannot overfill a container either - except on the server or a body's machine,
 * which only carry out what a window already checked.
 * The engine does not mind: items still weigh what they weigh for the soldier carrying them.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Entry <HASHMAP>
 * 2: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 *
 * Return Value:
 * Room enough <BOOL>
 *
 * Example:
 * [vestContainer player, _entry] call einv_storage_fnc_hasRoom;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]]];

([_container, _entry, _count] call FUNC(roomByWeight)) get "fits"
