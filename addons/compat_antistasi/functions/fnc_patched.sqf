#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * One of Antistasi's own files as this addon runs it: read from that mod's addon, every occurrence of each given text
 * replaced, compiled once and kept (GVAR(patched)). The rest is that mod's as it ships. Should one of the texts not be
 * in the file any more - a newer Antistasi -, nothing of it is changed: the file runs as it ships and the RPT says so
 * once. With no changes given it is the file as it ships, for the functions that only wrap it.
 *
 * Arguments:
 * 0: Name to keep it by <STRING>
 * 1: Antistasi's file <STRING>
 * 2: Changes, [[text, replacement], ...] <ARRAY> (default: [])
 *
 * Return Value:
 * The code, {} when the file cannot be read <CODE>
 *
 * Example:
 * ["mineSweep", A3A_FILE_MINESWEEP, [["a", "b"]]] call aio_compat_antistasi_fnc_patched;
 *
 * Public: No
 */

params [["_key", "", [""]], ["_path", "", [""]], ["_changes", [], [[]]]];

private _code = GVAR(patched) get _key;

if (!isNil "_code") exitWith {_code};

private _source = preprocessFileLineNumbers _path;

if (_source isEqualTo "") exitWith {
    WARNING_2("Antistasi's %1 (%2) could not be read - it does nothing.",_key,_path);
    GVAR(patched) set [_key, {}];
    {}
};

private _patched = _source;
private _missing = [];

{
    _x params [["_find", "", [""]], ["_replace", "", [""]]];

    private _at = _patched find _find;

    if (_find isEqualTo "" || {_at < 0}) then {
        _missing pushBack _find;
        continue;
    };

    private _done = "";
    private _rest = _patched;

    while {_at >= 0} do {
        _done = _done + (_rest select [0, _at]) + _replace;
        _rest = _rest select [_at + count _find];
        _at = _rest find _find;
    };

    _patched = _done + _rest;
} forEach _changes;

if (_missing isNotEqualTo []) then {
    WARNING_2("Antistasi's %1 reads differently - it runs as it ships. Not found: %2",_key,_missing);
    _patched = _source;
};

_code = compile _patched;
GVAR(patched) set [_key, _code];

_code
