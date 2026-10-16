#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a unit carries without what lies in a container it cannot use from: the lists the hotbar counts
 * from (items, magazines, magazinesAmmoFull) with one entry less for every item that lies in a blocked
 * container (fnc_useState). An item that lies in two containers, one of them free, stays once for each
 * that is free. The loaded magazines and everything the unit wears stay as they are.
 *
 * While no setting limits anything the lists come back as they were, at no cost.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: [items, magazines, magazinesAmmoFull] of the unit - [] for a list that is not wanted <ARRAY>
 *
 * Return Value:
 * The three lists, what can be used <ARRAY>
 *
 * Example:
 * [player, [items player, magazines player, magazinesAmmoFull player]] call einv_storage_fnc_useCarried;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_carried", [], [[]]]];

if (isNull _unit || {!(missionNamespace getVariable [QGVAR(useActive), false])}) exitWith {_carried};

_carried params [["_items", [], [[]]], ["_magazines", [], [[]]], ["_ammoFull", [], [[]]]];

_items = +_items;
_magazines = +_magazines;
_ammoFull = +_ammoFull;

{
    private _kind = _x;
    private _container = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select _forEachIndex;

    if (isNull _container || {([_kind] call FUNC(useMode)) isEqualTo USE_ALL}) then {continue};

    // The items of this container: one entry of the list less for each. == ignores the case of a class.
    {
        private _class = _x;

        if (([_class, _kind] call FUNC(useState)) isEqualTo "blocked") then {
            private _at = _items findIf {_x == _class};

            if (_at >= 0) then {
                _items deleteAt _at;
            };
        };
    } forEach (itemCargo _container);

    // Its magazines and grenades, and with the rounds in them the entries of magazinesAmmoFull.
    {
        _x params ["_class", "_rounds"];

        if (([_class, _kind] call FUNC(useState)) isEqualTo "blocked") then {
            private _at = _magazines findIf {_x == _class};

            if (_at >= 0) then {
                _magazines deleteAt _at;
            };

            private _entry = _ammoFull findIf {(_x select 0) == _class && {(_x select 1) == _rounds} && {!(_x select 2)}};

            if (_entry >= 0) then {
                _ammoFull deleteAt _entry;
            };
        };
    } forEach (magazinesAmmoCargo _container);
} forEach USE_KINDS;

[_items, _magazines, _ammoFull]
