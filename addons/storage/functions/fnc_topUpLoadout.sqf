#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Adds what a loadout was meant to put into a unit's uniform, vest and backpack but the engine left out.
 * setUnitLoadout stops filling a container at its maximumLoad, while the grid of this mod does not care
 * about that load: a leg strap bag with twenty mines in a saved loadout comes back with eight. Each of the
 * three containers' intended contents is compared with what the unit holds now (getUnitLoadout), by kind of
 * thing - an item by class, a magazine by class and rounds, a weapon by class and attachments - and only the
 * difference is added, with the cargo commands that ignore maximumLoad on the container object. Nothing is
 * added twice: run again, or on a loadout that arrived whole, it adds nothing. The layout places the new
 * things as it places anything (overflow moves on, fnc_queueMigrate); classes the game does not have are
 * left out, as setUnitLoadout left them.
 *
 * Runs where the unit is local; the cargo commands are global. A container that is not the one the loadout
 * names (another class of uniform, vest or backpack) is skipped.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The loadout, as getUnitLoadout gives it <ARRAY>
 *
 * Return Value:
 * How many things were added <NUMBER>
 *
 * Example:
 * [player, _loadout] call aio_storage_fnc_topUpLoadout;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_loadout", [], [[]]]];

if (isNull _unit || {!local _unit} || {count _loadout < 6}) exitWith {0};

private _now = getUnitLoadout _unit;
private _added = 0;

// One list of a loadout's container as a map, key -> [kind, template, count]: kind 0 an item or a backpack,
// 1 a magazine, 2 a weapon. A weapon's key leaves its loaded magazines out, so rounds the engine counted
// another way do not make it a different weapon.
private _readList = {
    params ["_list"];

    private _result = createHashMap;

    {
        if (_x isEqualType [] && {count _x >= 2}) then {
            private _head = _x select 0;
            private _count = _x select 1;

            if (_count isEqualType 0 && {_count > 0}) then {
                if (_head isEqualType []) then {
                    if (_head isNotEqualTo [] && {(_head select 0) isEqualType ""}) then {
                        private _key = toLowerANSI str [_head param [0, ""], _head param [1, ""], _head param [2, ""], _head param [3, ""], _head param [6, ""]];
                        private _entry = _result getOrDefault [_key, [2, _head, 0]];

                        _entry set [2, (_entry select 2) + _count];
                        _result set [_key, _entry];
                    };
                } else {
                    if (_head isEqualType "" && {_head isNotEqualTo ""}) then {
                        private _isMagazine = count _x >= 3 && {(_x select 2) isEqualType 0};
                        private _rounds = [0, _x select 2] select _isMagazine;
                        private _key = toLowerANSI format ["%1|%2|%3", _isMagazine, _head, _rounds];
                        private _entry = _result getOrDefault [_key, [[0, 1] select _isMagazine, [_head, _rounds], 0]];

                        _entry set [2, (_entry select 2) + _count];
                        _result set [_key, _entry];
                    };
                };
            };
        };
    } forEach _list;

    _result
};

{
    _x params ["_index", "_container", "_wornClass"];

    private _wanted = _loadout select _index;

    if (
        !isNull _container
        && {_wanted isEqualType []}
        && {count _wanted >= 2}
        && {(_wanted select 0) isEqualType ""}
        && {(_wanted select 0) isNotEqualTo ""}
        && {(toLowerANSI (_wanted select 0)) isEqualTo (toLowerANSI _wornClass)}
    ) then {
        // Only a container the engine filled up can have lost anything to its load: one with room left got
        // all it was given, and a difference there is a renamed item (an EFAK kit or a radio gets a new
        // instance class when it is made again), which must not be added a second time.
        private _full = (maxLoad _container) <= 0 || {(loadAbs _container) >= 0.9 * (maxLoad _container)};
        private _have = [(_now param [_index, [], [[]]]) param [1, [], [[]]]] call _readList;
        private _need = [_wanted param [1, [], [[]]]] call _readList;

        {
            private _key = _x;

            (_need get _key) params ["_kind", "_what", "_count"];

            private _missing = _count - ((_have getOrDefault [_key, [_kind, _what, 0]]) select 2);

            // A kit is never topped up: its instance class changes whenever it is made again, so the loadout's
            // name is missing although the kit is there.
            private _class = _what;

            if (_what isEqualType []) then {
                _class = _what param [0, ""];
            };

            private _isKit = (([_class] call (missionNamespace getVariable ["aio_items_fnc_kitOf", {[]}])) isNotEqualTo []);

            if (_missing > 0 && {_full} && {!_isKit}) then {
                switch (_kind) do {
                    case 2: {
                        if (isClass (configFile >> "CfgWeapons" >> (_what select 0))) then {
                            _container addWeaponWithAttachmentsCargoGlobal [_what, _missing];
                            _added = _added + _missing;
                        };
                    };
                    case 1: {
                        if (isClass (configFile >> "CfgMagazines" >> (_what select 0))) then {
                            _container addMagazineAmmoCargo [_what select 0, _missing, _what select 1];
                            _added = _added + _missing;
                        };
                    };
                    default {
                        private _class = _what select 0;

                        if (isClass (configFile >> "CfgVehicles" >> _class) && {_class isKindOf ["Bag_Base", configFile >> "CfgVehicles"]}) then {
                            _container addBackpackCargoGlobal [_class, _missing];
                            _added = _added + _missing;
                        } else {
                            if (
                                isClass (configFile >> "CfgWeapons" >> _class)
                                || {isClass (configFile >> "CfgGlasses" >> _class)}
                                || {isClass (configFile >> "CfgMagazines" >> _class)}
                            ) then {
                                _container addItemCargoGlobal [_class, _missing];
                                _added = _added + _missing;
                            };
                        };
                    };
                };
            };
        } forEach (keys _need);
    };
} forEach [
    [3, uniformContainer _unit, uniform _unit],
    [4, vestContainer _unit, vest _unit],
    [5, backpackContainer _unit, backpack _unit]
];

if (_added > 0) then {
    INFO_2("A loadout of %1 left %2 things out beyond the containers' load; they were added.",_unit,_added);
};

_added
