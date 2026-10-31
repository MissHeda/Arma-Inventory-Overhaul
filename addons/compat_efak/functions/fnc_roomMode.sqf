#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a kit's room is: Enhanced First Aid Kits' capacity, or the cells of a grid of its own. A kit gets
 * a grid only by someone's word for it - a rule of the rules text (class=efak_IFAK+ > grid=4x3, kind=kit,
 * a group, everything else, the older container table) or its own config key (einv_grid = "4x3";, the
 * older keys too): then its cells are all its room, and that mod's capacity counts for nothing in the
 * window, the Arsenal and every move into it. Without one - what the preset or the built-in answer gives
 * it - everything stays that mod's: its capacity limits what goes in, and its window's grid is an open
 * one that grows. Who set the grid is read off the source the rules engine notes for it
 * (einv_items_fnc_setBy).
 *
 * Asked by everything that decides what goes into a kit (fnc_canPack, fnc_kitBlocks, fnc_fillState,
 * fnc_canPackNew) and by the setup wizard, which passes its draft.
 *
 * Arguments:
 * 0: Kit class, prototype or instance <STRING>
 * 1: Compiled rules to ask instead of the rules in effect - the setup wizard's draft <HASHMAP>
 *    (default: the rules in effect)
 * 2: Cache for those (einv_items_fnc_getInfo) <HASHMAP> (default: none)
 *
 * Return Value:
 * "capacity" or "cells"; "capacity" for anything that is no kit <STRING>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_roomMode;
 *
 * Public: Yes
 */

params [["_kit", "", [""]], "_compiled", "_cache"];

if (_kit isEqualTo "") exitWith {"capacity"};

private _info = if (isNil "_compiled") then {
    [_kit] call EFUNC(items,getInfo)
} else {
    [_kit, _compiled, _cache] call EFUNC(items,getInfo)
};

if ((_info getOrDefault ["kind", ""]) isNotEqualTo "kit") exitWith {"capacity"};

["capacity", "cells"] select (([_info, "grid"] call EFUNC(items,setBy)) in ["rule", "config"])
