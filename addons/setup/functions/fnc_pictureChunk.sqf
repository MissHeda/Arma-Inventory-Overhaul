#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Reads the next piece of the picture catalog (fnc_pictureCatalog) - rows of the class index until INDEX_BUDGET
 * has passed - and hands the one after it to the wizard's queue (fnc_defer). A picture the rows share becomes one
 * entry that lists its owners. A row's picture belongs to the category of its class (fnc_pictureCategory): items,
 * gear, or vehicles and boxes - for those the picture the editor shows of them (editorPreview) is catalogued as
 * well, as the box's picture is drawn from it. Once every row is read, the entries are sorted by the first
 * owner's name and the text a search looks through is made.
 *
 * Arguments:
 * 0: The run it belongs to - a run that is no longer the live one stops <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call einv_setup_fnc_pictureChunk;
 *
 * Public: No
 */

params [["_token", 0, [0]]];

private _catalog = uiNamespace getVariable [QGVAR(pictures), createHashMap];

if ((_catalog getOrDefault ["token", -1]) != _token || {_catalog getOrDefault ["done", true]}) exitWith {};

// The window went: stop here - the next time the picker asks, the reading goes on from here.
if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {
    _catalog set ["tick", -1];
};

private _rows = (uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["rows", []];
private _entries = _catalog get "entries";
private _position = _catalog get "position";
private _count = count _rows;
private _until = diag_tickTime + INDEX_BUDGET;

// One picture of one row: its entry made when it is the first, the row an owner of it.
private _fnc_add = {
    params ["_path", "_row", "_category"];

    // Only a picture that can be shown (the index has asked einv_gui_fnc_safePicture), no procedural texture.
    if (_path isEqualTo "" || {(_path select [0, 2]) isEqualTo "#("}) exitWith {};

    private _lcPath = toLowerANSI _path;
    private _entry = _entries get _lcPath;

    if (isNil "_entry") then {
        _entry = [_path, _lcPath, "", _row select ROW_NAME, _row select 1, 0, [], [], []];
        _entries set [_lcPath, _entry];
    };

    _entry set [5, (_entry select 5) + 1];

    if (count (_entry select 6) < PICKER_OWNERS) then {
        (_entry select 6) pushBack (_row select ROW_LC);
        (_entry select 7) pushBack (_row select ROW_NAME);
    };

    if !(_category in (_entry select 8)) then {
        (_entry select 8) pushBack _category;
    };
};

while {_position < _count && {diag_tickTime < _until}} do {
    private _stop = (_position + INDEX_STRIDE) min _count;

    for "_i" from _position to (_stop - 1) do {
        private _row = _rows select _i;
        private _kind = _row select ROW_KIND;
        private _category = [_kind] call FUNC(pictureCategory);

        [_row select ROW_PICTURE, _row, _category] call _fnc_add;

        // A crate or vehicle is shown by the picture the editor has of it.
        if (_category isEqualTo "vehicles") then {
            [[getText (configFile >> "CfgVehicles" >> (_row select 1) >> "editorPreview")] call EFUNC(gui,safePicture), _row, _category] call _fnc_add;
        };
    };

    _position = _stop;
};

_catalog set ["position", _position];
_catalog set ["tick", diag_tickTime];

if (_position < _count) exitWith {
    [FUNC(pictureChunk), [_token]] call FUNC(defer);
};

// Done: by the first owner's name, then by path - the paths are all different, so the entries themselves are
// never compared.
private _keyed = [];

{
    _x params ["", "_lcPath", "", "_name", "", "", "_classes", "_names"];

    _x set [2, toLower (_lcPath + " " + (_classes joinString " ") + " " + (_names joinString " "))];
    _keyed pushBack [toLower _name, _lcPath, _x];
} forEach (values _entries);

_keyed sort true;

_catalog set ["list", _keyed apply {_x select 2}];
_catalog set ["byPath", createHashMapFromArray ((_catalog get "list") apply {[_x select 1, _x]})];
_catalog set ["entries", createHashMap];
_catalog set ["done", true];

INFO_1("Setup wizard: %1 pictures catalogued.",count (_catalog get "list"));
