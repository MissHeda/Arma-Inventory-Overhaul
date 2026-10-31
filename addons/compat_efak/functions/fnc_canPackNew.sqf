#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many new items of a class a kit takes in the ACE Arsenal - dragged out of ACE's list or the kits tab's
 * list onto the kit's grid or tile in the panel, Ctrl and the wheel over its tile (aio_arsenal_fnc_listToKit,
 * fnc_packNew), and the greying of the kits tab's rows (aio_arsenal_fnc_ungreyKit). In this order:
 *   whether the kit may be filled there (fnc_arsenalEditable): its contents have reached this machine, the kit
 *   type's Arsenal setting lets things in (Eden always), the kit does not follow the default contents
 *   the kit (fnc_canPack): that mod's rules for it - kits in kits, its list, its types, medical only,
 *   its defaults -, and its room in the measure it is counted in (fnc_roomMode): that mod's capacity,
 *   or the free cells of a grid a rule or its config gives the kit, whatever the capacity says
 * All of them, else as many as fit - found by halving -, else none and why.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER> (default: 1)
 *
 * Return Value:
 * [how many it takes, why not all - "" when it takes them all] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_fieldDressing", 5] call aio_compat_efak_fnc_canPackNew;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]]];

if (_kit isEqualTo "" || {_class isEqualTo ""} || {_count < 1} || {!([_kit] call FUNC(isKit))}) exitWith {[0, "Failed"]};

private _locked = [_kit, true] call FUNC(arsenalEditable);

if (_locked isNotEqualTo "") exitWith {[0, _locked]};

([_kit, _class, _count] call FUNC(canPack)) params ["_ok", "_why"];

if (_ok) exitWith {[_count, ""]};

// As many as fit: the most for which the kit says yes, by halving between none and all.
private _low = 0;
private _high = _count - 1;

while {_low < _high} do {
    private _middle = ceil ((_low + _high) / 2);

    if (([_kit, _class, _middle] call FUNC(canPack)) select 0) then {
        _low = _middle;
    } else {
        _high = _middle - 1;
    };
};

[_low, _why]
