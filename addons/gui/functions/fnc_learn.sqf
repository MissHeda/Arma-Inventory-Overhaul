#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Changes how many items of a class this player knows in a searched container (fnc_markHidden):
 * searching one, putting one in (+1), taking one out (-1). Local - every player searches for
 * themselves - and kept where fnc_searchRecord keeps it: on a crate, a vehicle or a pile, and for a
 * uniform, vest or backpack by the id it carries, so it goes with it when it is moved.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Class <STRING>
 * 2: Change <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_box, "FirstAidKit", 1] call aio_gui_fnc_learn;
 *
 * Public: No
 */

params ["_container", "_class", "_delta"];

if !([_container] call FUNC(isSearched)) exitWith {};

private _record = [_container, true] call FUNC(searchRecord);
private _known = _record getOrDefault ["known", createHashMap];
private _key = toLowerANSI _class;

_known set [_key, ((_known getOrDefault [_key, 0]) + _delta) max 0];
_record set ["known", _known];
