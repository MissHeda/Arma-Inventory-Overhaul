#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives a unit a weapon exactly as it was - attachments, loaded magazines and their rounds.
 *
 * addWeapon does two things of its own: it loads a magazine from the unit's inventory, and a weapon
 * class with preset attachments comes with those. Both are undone first - the magazine goes back into
 * the inventory, the presets come off - and then the weapon gets its own parts.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon slot - "primary", "handgun" or "launcher" <STRING>
 * 2: The weapon [class, muzzle, rail, optic, [magazine, rounds] or [], [magazine, rounds] or [], bipod] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "primary", ["arifle_MX_F", "", "", "optic_Aco", ["30Rnd_65x39_caseless_mag", 17], [], ""]] call einv_storage_fnc_addWeapon;
 *
 * Public: No
 */

params ["_unit", "_base", "_weapon"];
_weapon params [["_class", ""], ["_muzzle", ""], ["_rail", ""], ["_optic", ""], ["_magazine", []], ["_magazine2", []], ["_bipod", ""]];

if (_class isEqualTo "") exitWith {};

_unit addWeapon _class;

// What the engine put on by itself.
private _now = ([_unit] call FUNC(getEquipment)) getOrDefault [_base, []];

{
    private _part = _now param [_x, ""];

    if (_part isEqualType [] && {_part isNotEqualTo []}) then {
        [_unit, _base, false, _part select 0] call FUNC(weaponPart);

        // Back into the inventory only once it is out of the weapon - else there would be two.
        private _still = (([_unit] call FUNC(getEquipment)) getOrDefault [_base, []]) param [_x, []];

        if (_still isEqualTo [] || {_still isEqualType ""}) then {
            _unit addMagazine [_part select 0, _part param [1, 0]];
        };
    };

    if (_part isEqualType "" && {_part isNotEqualTo ""}) then {
        [_unit, _base, false, _part] call FUNC(weaponPart);
    };
} forEach [1, 2, 3, 4, 5, 6];

{
    [_unit, _base, true, _x] call FUNC(weaponPart);
} forEach ([_muzzle, _rail, _optic, _bipod] select {_x isNotEqualTo ""});

if (_magazine isNotEqualTo []) then {
    [_unit, _base, true, _magazine select 0, _magazine param [1, -1], false] call FUNC(weaponPart);
};

if (_magazine2 isNotEqualTo []) then {
    [_unit, _base, true, _magazine2 select 0, _magazine2 param [1, -1], true] call FUNC(weaponPart);
};
