#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Finds room in the soldier's containers for something that must not be destroyed - an old weapon, a
 * container that is not in this arsenal - and puts it there. Without room the caller asks for the second
 * click. The target the player chose is tried first, then the uniform, the vest and the backpack.
 *
 * Room is by weight (einv_storage_fnc_hasRoom) and a free spot on the grid (einv_storage_fnc_hasSpace), and
 * the container it went into is kept in the column's "stored" for the hint.
 *
 * Arguments:
 * 0: The payload to store, see einv_storage_fnc_removeEntry <ARRAY>
 * 1: Only ask whether there is room, put nothing away <BOOL> (default: false)
 *
 * Return Value:
 * Stored - or, only asking, there is room <BOOL>
 *
 * Example:
 * [_payload] call einv_arsenal_fnc_storeAway;
 *
 * Public: No
 */

params [["_payload", [], [[]]], ["_test", false, [false]]];

if (_payload isEqualTo []) exitWith {false};

private _unit = GVAR(center);

// What it is, as a tile of a container would see it.
private _probe = createHashMapFromArray [["count", 1], ["ammo", 0], ["capacity", 0], ["attachments", []], ["container", objNull]];

switch (_payload select 0) do {
    case "weapon": {
        private _weapon = _payload param [1, [], [[]]];

        _probe set ["class", _weapon param [0, ""]];
        _probe set ["attachments", _weapon];
    };
    case "magazine": {
        private _rounds = _payload param [2, [], [[]]];

        _probe set ["class", _payload param [1, ""]];
        _probe set ["count", (count _rounds) max 1];
        _probe set ["ammo", _rounds param [0, 0]];
        _probe set ["capacity", getNumber (configFile >> "CfgMagazines" >> (_payload param [1, ""]) >> "count")];
    };
    case "item": {
        _probe set ["class", _payload param [1, ""]];
        _probe set ["count", _payload param [2, 1]];
    };
    default {
        _probe set ["class", _payload param [1, ""]];
    };
};

if ((_probe get "class") isEqualTo "") exitWith {false};

private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x};
private _target = GVAR(targetContainer);

if (!isNull _target && {_target in _containers}) then {
    _containers = [_target] + (_containers - [_target]);
};

private _index = _containers findIf {
    [_x, _probe] call EFUNC(storage,hasRoom) && {[_x, _probe] call EFUNC(storage,hasSpace)}
};

if (_index < 0) exitWith {false};
if (_test) exitWith {true};

private _container = _containers select _index;

// What did not arrive is not stored: the caller is told, and nothing of it is made twice.
if (([_container, _payload] call EFUNC(storage,addPayload)) isNotEqualTo []) exitWith {false};

(uiNamespace getVariable [QGVAR(column), createHashMap]) set ["stored", _container];

true
