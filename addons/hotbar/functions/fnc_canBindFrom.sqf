#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item may go on the hotbar from where it lies: only what the player carries - the own
 * uniform, vest and backpack, a kit that is carried, the own equipment slots. What lies in a crate, on
 * the ground or on a body cannot be used from the bar, and neither can a uniform, vest or backpack
 * lying inside the own backpack (ACE's item list does not see into it), nor an item that lies in a
 * uniform, vest or backpack the settings "Use items from ..." close to it (aio_storage_fnc_useState)
 * unless it is whitelisted there. Then the item itself has to be one for the bar (fnc_canBind).
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Where it lies <ARRAY> (default: [])
 *    ["grid", the grid it lies on, as the window keeps it <HASHMAP>]
 *    ["slot", a slot record of the window, or [unit, slot]]
 *    [] - not checked
 *
 * Return Value:
 * [may, reason] - reason is a text to show, "" when it may <ARRAY>
 *
 * Example:
 * ["ACE_elasticBandage", ["grid", _grid]] call aio_hotbar_fnc_canBindFrom;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_from", [], [[]]]];

private _unit = EGVAR(gui,unit);

// The container it lies in, when that is one of the own three and the settings close it to this item.
private _blockedIn = "";

private _carried = switch (_from param [0, ""]) do {
    case "grid": {
        private _grid = _from param [1, createHashMap, [createHashMap]];
        private _kit = _grid getOrDefault ["kit", ""];

        // Nothing moves in or out of a virtual grid: a body's worn gear.
        if (_grid getOrDefault ["virtual", true]) exitWith {false};

        // What lies in a kit is carried when the kit is.
        if (_kit isNotEqualTo "") exitWith {
            !isNil "efak_core_fnc_getCarriedKits"
            && {(([ACE_player] call efak_core_fnc_getCarriedKits) findIf {_x == _kit}) >= 0}
        };

        private _container = _grid getOrDefault ["container", objNull];
        private _kind = [_container, ACE_player] call EFUNC(storage,useKind);

        if (([_class, _kind] call EFUNC(storage,useState)) isEqualTo "blocked") then {
            _blockedIn = _kind;
        };

        !isNull _container
        && {_unit isEqualTo ACE_player}
        && {(([_container] call EFUNC(storage,getOwner)) select 0) isEqualTo _unit}
    };
    case "slot": {
        // A record the window drew has the rectangle first and the unit at the end; [unit, slot] has the unit first.
        private _ref = _from param [1, []];
        private _owner = if ((_ref param [0, objNull]) isEqualType objNull) then {_ref param [0, objNull]} else {_ref param [6, objNull]};

        !isNull _owner && {_owner isEqualTo ACE_player}
    };
    default {true};
};

if (!_carried) exitWith {[false, LLSTRING(Reason_NotCarried)]};

if (_blockedIn isNotEqualTo "") exitWith {
    [false, format [LLSTRING(Reason_UseBlocked), [_blockedIn] call EFUNC(storage,useKindName)]]
};

[_class] call FUNC(canBind)
