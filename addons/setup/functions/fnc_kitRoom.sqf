#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a kit's room is by the draft, for the Containers step and the class lists: Enhanced First Aid
 * Kits' capacity while no rule and no config key of its own gives it a grid, else the cells of that grid
 * (aio_compat_efak_fnc_roomMode, asked with the draft). Where that addon is not loaded the same test is
 * made here on who set the grid (aio_items_fnc_setBy) - there are no kits then anyway.
 *
 * Arguments:
 * 0: The class, as aio_items_fnc_getInfo gives it with the draft <HASHMAP>
 *
 * Return Value:
 * "capacity" or "cells" for a kit, "" for anything else <STRING>
 *
 * Example:
 * [[_class, aio_setup_draftRules, aio_setup_draftCache] call aio_items_fnc_getInfo] call aio_setup_fnc_kitRoom;
 *
 * Public: No
 */

params [["_info", createHashMap, [createHashMap]]];

if ((_info getOrDefault ["kind", ""]) isNotEqualTo "kit") exitWith {""};

if (isNil QEFUNC(compat_efak,roomMode)) exitWith {
    ["capacity", "cells"] select (([_info, "grid"] call EFUNC(items,setBy)) in ["rule", "config"])
};

[_info getOrDefault ["class", ""], GVAR(draftRules), GVAR(draftCache)] call EFUNC(compat_efak,roomMode)
