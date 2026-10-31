#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Reads the next piece of the class index (fnc_buildIndex) - config entries until INDEX_BUDGET has
 * passed - and hands the one after it to the wizard's queue (fnc_defer), which also runs in Eden. Once
 * every root is read, the rows are sorted by name and the open list is drawn again.
 *
 * Kept, besides the public classes (scope 2, nothing named ..._Base), what fnc_classKind lists: weapons and
 * items, magazines with a picture, goggles, backpacks (those that hold nothing by their config too, an own
 * grid gives them room), crates and vehicles that hold something.
 * A class in two roots counts once, under the first - the rules engine reads it there too.
 *
 * Arguments:
 * 0: The run it belongs to - a run that is no longer the live one stops <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call aio_setup_fnc_indexChunk;
 *
 * Public: No
 */

params [["_token", 0, [0]]];

private _index = uiNamespace getVariable [QGVAR(index), createHashMap];

if ((_index getOrDefault ["token", -1]) != _token || {_index getOrDefault ["done", true]}) exitWith {};

// The window went: stop here - the next time a step asks, the reading goes on from here.
if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {
    _index set ["tick", -1];
};

private _rows = _index get "rows";
private _byClass = _index get "byClass";
private _mods = _index get "mods";
private _rootId = _index get "root";
private _position = _index get "position";
private _read = _index get "read";
private _until = diag_tickTime + INDEX_BUDGET;
private _roots = INDEX_ROOTS;

// The mod a class comes from, by the name it gives itself; the base game's classes have none of their own.
private _fnc_mod = {
    params ["_config"];

    private _folder = configSourceMod _config;
    private _name = _mods get _folder;

    if (isNil "_name") then {
        _name = (modParams [_folder, ["name"]]) param [0, ""];

        if (_name isEqualTo "") then {
            _name = [_folder, "Arma 3"] select (_folder isEqualTo "");
        };

        _mods set [_folder, _name];
    };

    _name
};

while {_rootId < count _roots && {diag_tickTime < _until}} do {
    private _rootName = _roots select _rootId;
    private _root = configFile >> _rootName;
    private _count = count _root;
    private _stop = (_position + INDEX_STRIDE) min _count;

    for "_i" from _position to (_stop - 1) do {
        private _config = _root select _i;

        if (isClass _config && {getNumber (_config >> "scope") == 2}) then {
            private _class = configName _config;
            private _lc = toLowerANSI _class;

            ([_config, _rootName] call FUNC(classKind)) params ["_kind", "_family", "_load"];

            if (_kind isNotEqualTo "" && {!(_lc in _byClass)} && {count _lc < 5 || {(_lc select [count _lc - 5]) isNotEqualTo "_base"}}) then {
                private _name = getText (_config >> "displayName");

                if (_name isEqualTo "") then {
                    _name = _class;
                };

                // Only a picture that can be shown, looked at once here (aio_gui_fnc_safePicture): some
                // vehicles name an icon class instead of a texture, and some mod classes a placeholder word
                // ("picturething") - the engine pops up a message over the wizard for those.
                private _picture = [getText (_config >> "picture")] call EFUNC(gui,safePicture);

                private _row = [_lc, _class, toLower (_class + " " + _name), _name, _kind, _family, _picture, [_config] call _fnc_mod, _load];

                _rows pushBack _row;
                _byClass set [_lc, _row];
            };
        };
    };

    _read = _read + (_stop - _position);
    _position = _stop;

    if (_position >= _count) then {
        _rootId = _rootId + 1;
        _position = 0;
    };
};

_index set ["root", _rootId];
_index set ["position", _position];
_index set ["read", _read];
_index set ["tick", diag_tickTime];

if (_rootId < count _roots) exitWith {
    private _label = uiNamespace getVariable [QGVAR(indexLabel), controlNull];

    if (!isNull _label) then {
        _label ctrlSetText format [LLSTRING(Index_Reading), floor (100 * _read / (_index get "total")) min 99];
    };

    [FUNC(indexChunk), [_token]] call FUNC(defer);
};

// Done: by name, then by class - the class names are all different, so the rows themselves are never
// compared.
private _keyed = _rows apply {[toLower (_x select ROW_NAME), _x select ROW_LC, _x]};

_keyed sort true;

_index set ["rows", _keyed apply {_x select 2}];
_index set ["done", true];

INFO_1("Setup wizard: %1 classes indexed.",count _rows);

[] call FUNC(drawResults);
