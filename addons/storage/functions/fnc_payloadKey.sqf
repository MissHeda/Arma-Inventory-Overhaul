#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The key the tile of a payload (fnc_removeEntry, fnc_takeOff) will have once it lies somewhere - the
 * one fnc_entryKey gives that tile: a weapon by its weapon array, a magazine by its first rounds (a
 * stacked payload shares its rounds), a uniform, vest or backpack with an inner snapshot by the
 * snapshot's id (fnc_snapshot), anything else by its lowercase class.
 *
 * So the record written for the cell a payload is dropped on matches the item the moment it lands.
 *
 * The id is the one in the snapshot's sixth element, [records, tag] - the tag fnc_restore writes on the
 * new object. A uniform, vest or backpack without one lands untagged, which fnc_entryKey keys class|c as
 * well.
 *
 * Arguments:
 * 0: Payload <ARRAY>
 *
 * Return Value:
 * Key, "" for an empty payload <STRING>
 *
 * Example:
 * [["magazine", "30Rnd_65x39_caseless_mag", [30]]] call einv_storage_fnc_payloadKey;
 *
 * Public: No
 */

params [["_payload", [], [[]]]];

if (_payload isEqualTo []) exitWith {""};

// The id in a snapshot's tag: [records, [id, item class, parent]] as its sixth element.
private _fnc_uid = {
    params ["_snapshot"];

    if !(_snapshot isEqualType []) exitWith {""};

    private _carried = _snapshot param [5, []];

    if !(_carried isEqualType []) exitWith {""};

    private _tag = _carried param [1, []];

    if !(_tag isEqualType []) exitWith {""};

    private _uid = _tag param [0, ""];

    ["", _uid] select (_uid isEqualType "")
};

switch (_payload param [0, ""]) do {
    case "weapon": {
        private _weapon = _payload param [1, []];

        if (_weapon isEqualType [] && {_weapon isNotEqualTo []} && {(_weapon select 0) isEqualType ""}) then {
            toLowerANSI (_weapon select 0) + "|w" + hashValue ([_weapon] call FUNC(normalizeWeapon))
        } else {
            ""
        }
    };
    case "magazine": {
        _payload params ["", ["_class", "", [""]], ["_rounds", [], [[]]]];

        private _key = toLowerANSI _class;

        // As fnc_getContents counts it: a magazine of no rounds at all is an item.
        if ((([_class] call EFUNC(items,getInfo)) get "capacity") > 0) then {
            _key = _key + "|m" + str (_rounds param [0, 0]);
        };

        _key
    };
    case "backpack": {
        _payload params ["", ["_class", "", [""]], ["_inner", [], [[]]]];

        toLowerANSI _class + "|c" + ([_inner] call _fnc_uid)
    };
    case "item": {
        _payload params ["", ["_class", "", [""]], "", ["_inner", [], [[]]]];

        // A uniform or vest always lies with a container of its own, with or without things in it.
        private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

        if (_inner isNotEqualTo [] || {_kind in ["uniform", "vest", "backpack"]}) then {
            toLowerANSI _class + "|c" + ([_inner] call _fnc_uid)
        } else {
            toLowerANSI _class
        }
    };
    default {""};
}
