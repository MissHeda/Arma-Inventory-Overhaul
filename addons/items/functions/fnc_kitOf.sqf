#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a class is a kit of Enhanced First Aid Kits (fnc_kitTypes) and which: the type's own class, the
 * prototype, or one of the instance classes that mod makes of it - "<prototype>_<n>", n from 1 to as many
 * as the type has, exactly as that mod names them. Only the name decides, as in that mod's own
 * efak_core_fnc_isKit.
 *
 * Arguments:
 * 0: Class, any case <STRING>
 *
 * Return Value:
 * [prototype as config names it, the instance's number - 0 for the prototype itself, how many instances
 * the type has, its capacity], [] for anything that is no kit <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_items_fnc_kitOf;
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

private _kitTypes = [] call FUNC(kitTypes);

if (_class isEqualTo "" || {count _kitTypes == 0}) exitWith {[]};

private _key = toLowerANSI _class;
private _type = _kitTypes getOrDefault [_key, []];

if (_type isNotEqualTo []) exitWith {
    _type params ["_prototype", "_instances", "_capacity"];

    [_prototype, 0, _instances, _capacity]
};

// An instance: the prototype before the last "_", a whole number after it.
private _chars = toArray _key;
private _cut = -1;

for "_i" from (count _chars - 1) to 1 step -1 do {
    if ((_chars select _i) == 95) exitWith {
        _cut = _i;
    };
};

if (_cut < 1) exitWith {[]};

_type = _kitTypes getOrDefault [_key select [0, _cut], []];

if (_type isEqualTo []) exitWith {[]};

_type params ["_prototype", "_instances", "_capacity"];

private _number = _key select [_cut + 1];
private _n = parseNumber _number;

if (_n < 1 || {_n > _instances} || {str _n isNotEqualTo _number}) exitWith {[]};

[_prototype, _n, _instances, _capacity]
