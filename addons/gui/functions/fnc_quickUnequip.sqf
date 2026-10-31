#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Ctrl+click on a filled equipment slot, menu Take off: takes the item off into the player's uniform,
 * vest or backpack - the first with a free spot for it, never the one being taken off (fnc_doUnequip).
 * The player's own gear goes to the ground when none has one - the surface under the feet, or the
 * vehicle's cargo while seated; a body's or a living person's stays on them then, and the hint says
 * "Nowhere to go". A slot holds one of a kind, so there is no part of it to move.
 *
 * Arguments:
 * 0: Whose slot it is <OBJECT>
 * 1: Slot id <STRING>
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [player, "headgear"] call aio_gui_fnc_quickUnequip;
 *
 * Public: No
 */

params ["_unit", "_slot"];

private _entry = [_unit, _slot] call EFUNC(storage,getSlot);

if (count _entry == 0) exitWith {false};

private _player = GVAR(unit);
private _inside = _entry getOrDefault ["container", objNull];
private _targets = [uniformContainer _player, vestContainer _player, backpackContainer _player] select {
    !isNull _x && {_x isNotEqualTo _inside}
};

private _index = _targets findIf {[_x, _entry] call EFUNC(storage,hasRoom)};

private _to = switch (true) do {
    case (_index >= 0): {_targets select _index};
    case (_unit isEqualTo _player): {"ground"};
    default {""};
};

// The ground is the last resort. A window that attached takes the item itself instead (the "ground" hook:
// the Arsenal takes it out), told where it is, [unit, slot], and how many, -1 for all.
if (_to isEqualTo "ground" && {(["ground", [[_unit, _slot], -1], false] call FUNC(hook)) isEqualTo true}) exitWith {true};

if (_to isEqualTo "") exitWith {
    ["NowhereToGo"] call FUNC(flashHint);

    false
};

[_unit, _slot, _to, []] call FUNC(doUnequip)
