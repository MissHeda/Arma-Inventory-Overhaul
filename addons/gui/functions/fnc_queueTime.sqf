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
 * Whether the kind waits at all is the server's second word, four switches: the quick move and group moves
 * (einv_gui_waitMove, on by default), dropping (waitDrop, on), putting on and taking off a uniform, vest, backpack or
 * headgear (waitWorn, off) and equipping anything else (waitEquip, off). A drag out of the window never waits: what
 * fnc_endDrag sends in the frame it was let go in (GVAR(instantFrame)) goes at once, whatever the switches say.
 *
 * What needs no hands takes no time: a tile put somewhere else in the holder it lies in, several tiles laid
 * down at once, sorting.
 *
 * Arguments:
 * 0: The move, as fnc_sendMoves takes it <HASHMAP>
 *
 * Return Value:
 * [kind, seconds] - kind "drop", "move" or "equip", "" for a move that needs no hands or does not wait <ARRAY>
 *
 * Example:
 * [createHashMapFromArray [["from", _crate], ["to", "ground"]]] call einv_gui_fnc_queueTime;
 *
 * Public: No
 */

params [["_move", createHashMap, [createHashMap]]];

// What a drag sends goes out at once.
if (GVAR(instantFrame) == diag_frameNo) exitWith {["", 0]};

private _hand = "";
private _worn = false;

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

        // The four things a soldier wears on the body, by the slot they go in or come off.
        _worn = (_move getOrDefault ["slot", ""]) in ["uniform", "vest", "backpack", "headgear"];
    };
};

if (_hand isEqualTo "") exitWith {["", 0]};

// Whether this kind waits, by the switches.
private _waits = switch (_hand) do {
    case "drop": {missionNamespace getVariable [QGVAR(waitDrop), true]};
    case "move": {missionNamespace getVariable [QGVAR(waitMove), true]};
    default {
        if (_worn) then {
            missionNamespace getVariable [QGVAR(waitWorn), false]
        } else {
            missionNamespace getVariable [QGVAR(waitEquip), false]
        }
    };
};

if (_waits isNotEqualTo true) exitWith {["", 0]};

private _seconds = missionNamespace getVariable [
    [QGVAR(handMove), QGVAR(handDrop), QGVAR(handEquip)] select (["move", "drop", "equip"] find _hand), 0
];

if !(_seconds isEqualType 0) then {
    _seconds = 0;
};

[_hand, _seconds max 0]
