#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A weapon array in the one shape everything here expects: [class, muzzle, rail, optic, [magazine,
 * rounds] or [], [second magazine, rounds] or [], bipod]. weaponsItems and weaponsItemsCargo leave the
 * second magazine out altogether when there is none - six entries, the bipod in the sixth place.
 *
 * Arguments:
 * 0: Weapon array <ARRAY>
 *
 * Return Value:
 * The weapon array with seven entries <ARRAY>
 *
 * Example:
 * [(weaponsItemsCargo _box) select 0] call aio_storage_fnc_normalizeWeapon;
 *
 * Public: No
 */

params [["_weapon", [], [[]]]];

if (count _weapon >= 7) exitWith {+_weapon};

private _copy = +_weapon;

// [class, muzzle, rail, optic, magazine, bipod]: the bipod moves to the end.
if (count _copy == 6) then {
    _copy pushBack (_copy select 5);
    _copy set [5, []];
};

// Anything shorter still: the missing parts empty.
private _empty = ["", "", "", "", [], [], ""];

while {count _copy < 7} do {
    _copy pushBack (_empty select count _copy);
};

_copy
