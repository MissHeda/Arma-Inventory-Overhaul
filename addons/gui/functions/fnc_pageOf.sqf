#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The page a compartment of a container is turned to (GVAR(pages), kept for the mission like the folds: a window opened
 * again on the same crate shows the page it was left on), or turns it.
 *
 * Arguments:
 * 0: Holder - the container <OBJECT or STRING>
 * 1: Compartment <NUMBER>
 * 2: The page to turn to, from 0 - left out, the page is only asked <NUMBER> (default: -1)
 *
 * Return Value:
 * The page it was or is now <NUMBER>
 *
 * Example:
 * [_crate, 0] call einv_gui_fnc_pageOf;
 * [_crate, 0, 2] call einv_gui_fnc_pageOf;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_block", 0, [0]], ["_set", -1, [0]]];

private _at = GVAR(pages) findIf {(_x select 0) isEqualTo _holder && {(_x select 1) == _block}};

if (_set < 0) exitWith {
    if (_at < 0) then {0} else {(GVAR(pages) select _at) select 2}
};

if (_at >= 0) then {
    (GVAR(pages) select _at) set [2, _set];
} else {
    // Containers that are gone go from the list.
    GVAR(pages) = GVAR(pages) select {(_x select 0) isEqualType "" || {!isNull (_x select 0)}};
    GVAR(pages) pushBack [_holder, _block, _set];
};

_set
