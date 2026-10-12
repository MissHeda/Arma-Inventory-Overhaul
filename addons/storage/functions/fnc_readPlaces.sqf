#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where things lie in a holder, as its authority last wrote it (fnc_writePlaces): [revision, records],
 * each record [key, col, row, w, h, block] - w and h as it lies - and the records canonical, sorted by
 * key and then by the entry's index within its key, so two machines with the same data hold the same
 * array.
 *
 * A holder is a container object or the key of a grid with no object of its own ("kit:" + the lowercase
 * class, einv_compat_efak). While a phase runs here (fnc_execute), what its ops changed comes first,
 * from the execution's buffer.
 *
 * Kept on the holder object (einv_storage_places), for kits in a mission variable
 * (einv_storage_places_kit_<class>). In multiplayer a uniform, vest or backpack lying in a container has
 * a copy on the outermost container it lies under as well (einv_storage_nested, fnc_tagNested), which
 * reaches every machine - whether its own variable does is not known. The fresher of the two counts:
 * the higher revision, the object's own on a tie. The copy only counts while it carries the same id as
 * the object's own tag, or the object has none here - so a copy can never hand one container's places
 * to another.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 * 1: As stored, never from a running phase's buffer - for the writer, which compares with what is
 *    stored <BOOL> (default: false)
 *
 * Return Value:
 * [revision, records], [0, []] when nothing was written - a copy, free to change <ARRAY>
 *
 * Example:
 * [backpackContainer player] call einv_storage_fnc_readPlaces;
 *
 * Public: Yes
 */

params [["_holder", objNull, [objNull, ""]], ["_raw", false, [false]]];

private _isKey = _holder isEqualType "";

if ((_isKey && {_holder isEqualTo ""}) || {!_isKey && {isNull _holder}}) exitWith {[0, []]};

private _places = [0, []];

if (_isKey) then {
    // "kit:efak_ifak_7" -> einv_storage_places_kit_efak_ifak_7
    _places = missionNamespace getVariable [format ["%1_%2", QGVAR(places), (_holder splitString ":") joinString "_"], [0, []]];
} else {
    _places = _holder getVariable [QGVAR(places), [0, []]];

    if !(_places isEqualTypeArray [0, []]) then {_places = [0, []]};

    // Lying in a container - only such a one carries a mark of where it lies or a tag: its copy on the
    // outermost container, when that is fresher.
    if (isMultiplayer && {!isNil {_holder getVariable QGVAR(parent)} || {!isNil {_holder getVariable QGVAR(tag)}}}) then {
        private _top = [_holder, objNull, "top"] call FUNC(rootOf);

        if (_top isNotEqualTo _holder) then {
            private _nested = _top getVariable [QGVAR(nested), []];

            if (_nested isEqualType []) then {
                private _netId = netId _holder;
                private _index = _nested findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}};

                if (_index >= 0) then {
                    (_nested select _index) params ["", "_uid", "", "_copy"];

                    private _tag = _holder getVariable [QGVAR(tag), []];
                    private _ownUid = if (_tag isEqualType []) then {_tag param [0, ""]} else {""};

                    if (
                        (_ownUid isEqualTo "" || {_ownUid isEqualTo _uid})
                        && {_copy isEqualTypeArray [0, []]}
                        && {(_copy select 0) > (_places select 0)}
                    ) then {
                        _places = _copy;
                    };
                };
            };
        };
    };
};

if !(_places isEqualTypeArray [0, []]) then {_places = [0, []]};

// A copy: what is stored must not change behind the writer's back - SQF arrays are references.
_places = +_places;

if (!_raw && {GVAR(executing)}) then {
    private _index = GVAR(buffer) findIf {(_x select 0) isEqualTo _holder};

    if (_index >= 0) then {
        _places set [1, +((GVAR(buffer) select _index) select 1)];
    };
};

_places
