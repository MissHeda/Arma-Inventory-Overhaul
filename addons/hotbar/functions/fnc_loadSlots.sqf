#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Reads the slots from the profile, where they are kept per player rather than per mission or loadout:
 * a class on a key fits any loadout that carries it, and the next mission starts with the same bar. A
 * profile that holds something else, a slot that holds no string, or a class the game does not know
 * (a mod taken away) gives an empty slot.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_hotbar_fnc_loadSlots;
 *
 * Public: No
 */

private _saved = profileNamespace getVariable ["einv_hotbar_slots", []];

if !(_saved isEqualType []) then {
    _saved = [];
};

GVAR(slots) = [];

for "_i" from 0 to (SLOT_COUNT - 1) do {
    private _class = _saved param [_i, ""];

    if !((_class isEqualType "") && {isClass (configFile >> "CfgWeapons" >> _class) || {isClass (configFile >> "CfgMagazines" >> _class)}}) then {
        _class = "";
    };

    GVAR(slots) pushBack _class;
};
