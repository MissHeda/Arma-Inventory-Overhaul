#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The tree of a class as a step lists it: the classes built on it (fnc_classTree) that the step shows -
 * scope 1 or 2, not named ..._Base, and of a kind the step lists (fnc_classKind: on Containers a uniform,
 * vest, backpack, crate or vehicle that holds something, a backpack always; on Items everything but the
 * cargo) -, in tree order with how far each is indented and how many of the listed classes are built on it.
 * A class that is not listed itself (a hidden base) leaves its listed children one level up, under the
 * nearest class that is. The class the tree starts at is always the first row, whatever it is.
 *
 * Kept per step and class for the game session.
 *
 * Arguments:
 * 0: Class the tree starts at, lowercase or as config names it <STRING>
 * 1: Step: "items" or "containers" <STRING>
 *
 * Return Value:
 * An empty HashMap for a class no config knows, else <HASHMAP>
 *   "rows" - [[class in lowercase, class, name as shown, depth, how many listed classes are built on it],
 *            ...] <ARRAY>
 *
 * Example:
 * ["B_Carryall_Base", "containers"] call einv_setup_fnc_treeRows;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_mode", "items", [""]]];

private _lc = toLowerANSI _class;
private _cache = uiNamespace getVariable QGVAR(treeRowsCache);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(treeRowsCache), _cache];
};

private _key = format ["%1#%2", _mode, _lc];
private _known = _cache get _key;

if (!isNil "_known") exitWith {_known};

private _tree = [_lc] call FUNC(classTree);

if (count _tree == 0) exitWith {createHashMap};

private _rootName = _tree get "root";
private _data = [_rootName] call FUNC(treeIndex);
private _names = _data get "names";
private _scopes = _data get "scope";
private _root = configFile >> _rootName;
private _containers = _mode isEqualTo "containers";
private _rows = [];

// How far in the nearest listed class above a class of each depth stands (so [-1] above the first): a
// class that is not listed does not move its children in.
private _listedDepth = [-1];

{
    _x params ["_node", "_depth"];

    private _name = _names getOrDefault [_node, _node];
    private _config = _root >> _name;
    private _listed = _depth == 0;

    if (!_listed && {(_scopes getOrDefault [_node, 0]) >= 1} && {count _node < 5 || {(_node select [count _node - 5]) isNotEqualTo "_base"}}) then {
        ([_config, _rootName] call FUNC(classKind)) params ["_kind", "_family", "_load"];

        _listed = if (_containers) then {
            _kind in CONTAINER_KINDS && {_load > 0 || {_kind isEqualTo "backpack"}}
        } else {
            _family isNotEqualTo "" && {_family isNotEqualTo "cargo"}
        };
    };

    private _above = _listedDepth select _depth;
    private _shown = _above + 1;

    if (_listed) then {
        private _title = getText (_config >> "displayName");

        if (_title isEqualTo "") then {
            _title = _name;
        };

        _rows pushBack [_node, _name, _title, _shown, 0];
    };

    // What stands above the children of this class: itself if listed, else what stood above it.
    _listedDepth resize (_depth + 1);
    _listedDepth pushBack ([_above, _shown] select _listed);
} forEach (_tree get "order");

// How many listed classes are built on each: every row adds one to the rows that are still open above it.
private _open = [];

{
    private _depth = _x select 3;

    while {_open isNotEqualTo [] && {((_rows select (_open select (count _open - 1))) select 3) >= _depth}} do {
        _open deleteAt (count _open - 1);
    };

    {
        private _row = _rows select _x;

        _row set [4, (_row select 4) + 1];
    } forEach _open;

    _open pushBack _forEachIndex;
} forEach _rows;

_known = createHashMapFromArray [["rows", _rows]];

_cache set [_key, _known];

_known
