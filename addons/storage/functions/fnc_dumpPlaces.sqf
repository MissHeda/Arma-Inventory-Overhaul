#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes what this machine knows of a holder's places to the RPT - revision, records, the tags of the
 * uniforms, vests and backpacks lying in it and the view this machine draws - and returns the same text:
 * for tests from the debug console.
 *
 * Compared between two machines, the records and the view must be the same; the nested lines show each
 * nested container's tag as its own object carries it here and as the copy on the outermost container
 * has it (fnc_tagNested).
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 *
 * Return Value:
 * What was written, "" for no holder <STRING>
 *
 * Example:
 * [cursorObject] call aio_storage_fnc_dumpPlaces;
 *
 * Public: Yes
 */

params [["_holder", objNull, [objNull, ""]]];

private _isKey = _holder isEqualType "";

if ((_isKey && {_holder isEqualTo ""}) || {!_isKey && {isNull _holder}}) exitWith {""};

private _lines = [];
private _root = [_holder] call FUNC(rootOf);
private _name = if (_isKey) then {_holder} else {format ["%1 %2", typeOf _holder, netId _holder]};
private _rootName = if (isNull _root) then {"none (the server)"} else {format ["%1 %2, %3", typeOf _root, netId _root, ["remote", "local"] select local _root]};

_lines pushBack format ["Places of %1 on machine %2 - root %3", _name, call FUNC(machineId), _rootName];

([_holder, true] call FUNC(readPlaces)) params ["_revision", "_records"];

_lines pushBack format ["Revision %1, %2 records:", _revision, count _records];

{
    _lines pushBack format ["  %1", _x];
} forEach _records;

// What lies in it, as entries - and the uniforms, vests and backpacks among them.
private _entries = [];

if (_isKey) then {
    private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];
    private _code = _type get "entries";

    if (!isNil "_code") then {
        _entries = [_holder] call _code;
    };

    if (isNil "_entries" || {!(_entries isEqualType [])}) then {_entries = []};
} else {
    private _top = [_holder, objNull, "top"] call FUNC(rootOf);
    private _nested = _top getVariable [QGVAR(nested), []];

    if !(_nested isEqualType []) then {_nested = []};

    _lines pushBack format ["Outermost container %1 %2, %3 copies of nested tags", typeOf _top, netId _top, count _nested];

    {
        _x params ["_class", "_object"];

        private _netId = netId _object;
        private _index = _nested findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}};
        private _copy = if (_index >= 0) then {(_nested select _index) select [1, 2]} else {"none"};
        private _places = [_object, true] call FUNC(readPlaces);

        _lines pushBack format [
            "  nested %1 %2: tag %3, copy %4, places revision %5 with %6 records",
            _class, _netId, _object getVariable [QGVAR(tag), "none"], _copy, _places select 0, count (_places select 1)
        ];
    } forEach (everyContainer _holder);

    _entries = [_holder] call FUNC(getContents);
};

private _layout = [_holder, _entries, nil, [_revision, _records]] call FUNC(getLayout);

_lines pushBack format ["View: %1 tiles, %2 overflow, drift %3", count _entries, count (_layout get "overflow"), _layout get "drift"];

{
    _lines pushBack format [
        "  %1 x%2 - compartment %3, col %4, row %5, %6x%7%8",
        _x get "key", _x get "count", _x get "block", _x get "col", _x get "row", _x get "w", _x get "h",
        ["", " (overflow)"] select (_x get "overflow")
    ];
} forEach _entries;

{
    INFO_1("%1",_x);
} forEach _lines;

_lines joinString endl
