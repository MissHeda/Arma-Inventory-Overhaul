#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How long the hands are busy with one move of the window (fnc_sendMoves), and with what kind of work: a
 * drop onto the ground (or onto a pile the window shows), a move to a different container or holder (a kit
 * too, and two tiles that swap places between containers), or putting on and taking off worn gear (equip,
 * unequip, swap with another unit). The times are the server settings einv_gui_handDrop, handMove and
 * handEquip, in seconds; 0 is no wait at all.
 *
 * What needs no hands takes no time: a tile put somewhere else in the holder it lies in, several tiles laid
 * down at once, sorting.
 *
 * Arguments:
 * 0: The move, as fnc_sendMoves takes it <HASHMAP>
 *
 * Return Value:
 * [kind, seconds] - kind "drop", "move" or "equip", "" for a move that needs no hands <ARRAY>
 *
 * Example:
 * [createHashMapFromArray [["from", _crate], ["to", "ground"]]] call einv_gui_fnc_queueTime;
 *
 * Public: No
 */

params [["_move", createHashMap, [createHashMap]]];

private _hand = "";

switch (_move getOrDefault ["kind", "move"]) do {
    case "move": {
        private _from = _move getOrDefault ["from", objNull];
        private _to = _move getOrDefault ["to", objNull];

        if (_from isNotEqualTo _to) then {
            private _ground = (_to isEqualType "" && {_to in ["ground", "vehicle"]})
                || {_to isEqualType objNull && {!isNull _to} && {[_to] call EFUNC(storage,isGroundHolder)}};

            _hand = ["move", "drop"] select _ground;
        };
    };
    case "exchange": {
        _hand = "move";
    };
    case "equip";
    case "unequip";
    case "swap": {
        _hand = "equip";
    };
};

if (_hand isEqualTo "") exitWith {["", 0]};

private _seconds = missionNamespace getVariable [
    [QGVAR(handMove), QGVAR(handDrop), QGVAR(handEquip)] select (["move", "drop", "equip"] find _hand), 0
];

if !(_seconds isEqualType 0) then {
    _seconds = 0;
};

[_hand, _seconds max 0]
