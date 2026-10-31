#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Who inherits from whom in one config root: the parent of every public-enough class (scope 1 or 2) and
 * of each class above it, whatever its scope - the hidden bases (B_Carryall_Base, Rifle_Base_F) that
 * several variants are built on belong in the tree even though no list shows them. Read once per root and
 * kept in uiNamespace for the game session, since config does not change; the first call for a root takes
 * a moment (noticeable with a large mod pack), every later one is a lookup.
 *
 * Arguments:
 * 0: Root, one of INDEX_ROOTS <STRING>
 *
 * Return Value:
 * Maps, all keyed by the class in lowercase <HASHMAP>
 *   "parent"   - the class it inherits from, "" for none
 *   "names"    - the class as config names it
 *   "scope"    - its scope
 *   "children" - the classes built directly on it, sorted
 *
 * Example:
 * ["CfgVehicles"] call aio_setup_fnc_treeIndex;
 *
 * Public: No
 */

params [["_rootName", "", [""]]];

private _all = uiNamespace getVariable QGVAR(treeIndex);

if (isNil "_all") then {
    _all = createHashMap;
    uiNamespace setVariable [QGVAR(treeIndex), _all];
};

private _known = _all get _rootName;

if (!isNil "_known") exitWith {_known};

private _parent = createHashMap;
private _names = createHashMap;
private _scope = createHashMap;
private _children = createHashMap;

// Every class that can be looked at, and from each the way up to the first class already known.
{
    private _config = _x;

    while {isClass _config} do {
        private _lc = toLowerANSI configName _config;

        if (_lc in _parent) exitWith {};

        private _up = inheritsFrom _config;
        private _upLc = "";

        if (isClass _up) then {
            _upLc = toLowerANSI configName _up;
        };

        _parent set [_lc, _upLc];
        _names set [_lc, configName _config];
        _scope set [_lc, getNumber (_config >> "scope")];

        _config = _up;
    };
} forEach ("getNumber (_x >> 'scope') >= 1" configClasses (configFile >> _rootName));

{
    if (_y isNotEqualTo "") then {
        private _kids = _children getOrDefault [_y, []];

        _kids pushBack _x;
        _children set [_y, _kids];
    };
} forEach _parent;

// By class, so a tree reads the same every time whatever order config listed them in.
{
    _y sort true;
} forEach _children;

_known = createHashMapFromArray [["parent", _parent], ["names", _names], ["scope", _scope], ["children", _children]];

_all set [_rootName, _known];

_known
