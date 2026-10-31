#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words in the window's hint over a slot of the hotbar: which slot, then what lies on it, how many,
 * and what its key does - "Hotbar 5 · Elastic Bandage · ×6 · Bandages what bleeds most". An empty slot
 * says how to fill it.
 *
 * Arguments:
 * 0: Slot index <NUMBER>
 *
 * Return Value:
 * Parts as the hint takes them, [text, colour name] <ARRAY>
 *
 * Example:
 * [1] call aio_hotbar_fnc_hintParts;
 *
 * Public: No
 */

params [["_index", 0, [0]]];

private _slot = [_index] call FUNC(slotInfo);
private _key = _slot get "key";

private _parts = [[format [LLSTRING(Strip_Caption), [str (_index + 1), _key] select (_key isNotEqualTo "")], "muted"]];

if ((_slot get "class") isEqualTo "") exitWith {
    _parts pushBack [LLSTRING(Strip_Empty), "text2"];

    _parts
};

_parts pushBack [_slot get "name", "text"];
_parts pushBack [format ["×%1", _slot get "count"], ["text2", "loss"] select ((_slot get "count") == 0)];

if ((_slot get "does") isNotEqualTo "") then {
    _parts pushBack [_slot get "does", "text2"];
};

_parts
