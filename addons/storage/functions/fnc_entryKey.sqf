#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The key a tile's record carries (fnc_getLayout, fnc_setPlace, fnc_writePlaces). What looks different
 * has a key of its own: a weapon by what is on it (class|w<hash of its attachments>), a magazine by its
 * rounds (class|m<rounds>), a uniform, vest or backpack lying in a container by its own id (class|c<id>,
 * fnc_tagNested); anything else is its lowercase class.
 *
 * Identical keys are identical items: which of two of them lies where nobody can tell, so no two
 * machines can map the same records to different items.
 *
 * A nested container's id is its tag. In multiplayer, where a tag on the nested object does not reach
 * this machine, the copy on the outermost container it lies under is read (einv_storage_nested,
 * fnc_tagNested) - the same id either way. Untagged, the id is "" (class|c): all untagged ones of a class
 * are alike until their authority tags them.
 *
 * Arguments:
 * 0: Entry (fnc_getContents) <HASHMAP>
 * 1: The copies of nested tags the entry's container lies under, when the caller has them at hand
 *    (einv_storage_nested of the outermost container) <ARRAY> (default: read when needed)
 *
 * Return Value:
 * Key, "" for an entry without a class <STRING>
 *
 * Example:
 * [_entry] call einv_storage_fnc_entryKey;
 *
 * Public: No
 */

params [["_entry", createHashMap, [createHashMap]], "_nested"];

private _class = toLowerANSI (_entry getOrDefault ["class", ""]);

if (_class isEqualTo "") exitWith {""};

private _attachments = _entry getOrDefault ["attachments", []];
private _inside = _entry getOrDefault ["container", objNull];

if !(_inside isEqualType objNull) then {_inside = objNull};

// What looks different has a key of its own: a weapon by what is on it, a magazine by its rounds, a
// uniform, vest or backpack lying here by the id its authority gave it (fnc_tagNested). Items of one
// class are alike - which of two identical ones lies where nobody can tell.
switch (true) do {
    case (_attachments isNotEqualTo []): {
        _class + "|w" + hashValue ([_attachments] call FUNC(normalizeWeapon))
    };
    case (!isNull _inside): {
        private _tag = _inside getVariable [QGVAR(tag), []];
        private _uid = if (_tag isEqualType []) then {_tag param [0, ""]} else {""};

        if !(_uid isEqualType "") then {_uid = ""};

        // The tag on the object did not reach this machine: the copy on the outermost container.
        if (_uid isEqualTo "" && {isMultiplayer}) then {
            if (isNil "_nested") then {
                private _top = [_inside, objNull, "top"] call FUNC(rootOf);

                _nested = if (_top isEqualTo _inside) then {[]} else {_top getVariable [QGVAR(nested), []]};
            };

            if (_nested isEqualType []) then {
                private _netId = netId _inside;
                private _index = _nested findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}};

                if (_index >= 0) then {
                    _uid = (_nested select _index) select 1;
                };
            };
        };

        _class + "|c" + _uid
    };
    case ((_entry getOrDefault ["capacity", 0]) > 0): {
        _class + "|m" + str (_entry getOrDefault ["ammo", 0])
    };
    default {_class};
}
