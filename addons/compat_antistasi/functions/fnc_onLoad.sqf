#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi loaded the player's save (its plugin event A3A_event_clientPlayerLoad, sent to this machine after the
 * server set the saved loadout): LOAD_DELAY seconds later, when that loadout has arrived here, what Strict mode kept
 * out of the containers is added back (aio_storage_fnc_addToUnit - it is hidden again by the next look) and the places
 * saved with it are written (fnc_restorePlaces). A save without them (made before, or a fresh start) changes nothing.
 *
 * Arguments:
 * 0: The plugin data saved (fnc_onSave) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_data] call aio_compat_antistasi_fnc_onLoad;
 *
 * Public: No
 */

params [["_data", createHashMap, [createHashMap]]];

private _layout = _data getOrDefault [QGVAR(layout), []];
private _hidden = _data getOrDefault [QGVAR(hidden), []];

if (_layout isEqualTo [] && {_hidden isEqualTo []}) exitWith {};

[{
    params ["_layout", "_hidden"];

    private _unit = player;

    if (isNull _unit || {!alive _unit}) exitWith {};

    if (_hidden isEqualType []) then {
        {
            if (_x isEqualType []) then {
                {
                    _x params [["_class", "", [""]], ["_count", 0, [0]], ["_rounds", -1, [0]]];

                    if (_class isNotEqualTo "" && {_count > 0}) then {
                        private _placed = [_unit, _class, _count, _rounds] call EFUNC(storage,addToUnit);

                        if (_placed isEqualType 0 && {_placed < _count}) then {
                            WARNING_3("Antistasi load: %1 of %2 x%3 hidden by Strict mode had no room and were added past the grid.",_count - _placed,_class,_count);

                            for "_i" from 1 to (_count - _placed) do {
                                if (isClass (configFile >> "CfgMagazines" >> _class)) then {
                                    _unit addMagazine [_class, [getNumber (configFile >> "CfgMagazines" >> _class >> "count"), _rounds] select (_rounds >= 0)];
                                } else {
                                    _unit addItem _class;
                                };
                            };
                        };
                    };
                } forEach _x;
            };
        } forEach _hidden;
    };

    [_unit, _layout] call FUNC(restorePlaces);
}, [_layout, _hidden], LOAD_DELAY] call CBA_fnc_waitAndExecute;
