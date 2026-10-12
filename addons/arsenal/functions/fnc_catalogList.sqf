#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The list the catalog shows: the category, or with text in the search field every category; favorites
 * only; what fits the chosen weapon; sorted - by name, weight, size, mod or one of ACE's sorts for the
 * category (fnc_aceSorts). Worked out at most once a frame and not before the typing has
 * been still for SEARCH_DEBOUNCE seconds (the frame of the catalog, fnc_catalogFrame, sees to that).
 *
 * Only rows already read count (fnc_catalogRow, read in the background by the frame): while some are still
 * missing it answers [] and says in the column how many ("pending" of "pendingTotal"). The answer is kept
 * with the state it was made for.
 *
 * Also works out what the "Fits" chip says and whether it is there at all (the column's "fitsLabel" and
 * "fitsApplies").
 *
 * Reads the session only through GVAR(center), GVAR(catalogItems) and ACE's favorites.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows <ARRAY>
 *
 * Example:
 * call einv_arsenal_fnc_catalogList;
 *
 * Public: No
 */

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _text = toLowerANSI EGVAR(gui,filter);
private _searching = _text isNotEqualTo "";
private _categories = call FUNC(categories);
private _favorites = missionNamespace getVariable [QACEGVAR(arsenal,favorites), createHashMap];
private _favoritesOnly = missionNamespace getVariable [QACEGVAR(arsenal,favoritesOnly), false];
private _category = GVAR(category);
private _unit = GVAR(center);

// ----- What the Fits chip says -----
private _fitsApplies = !_searching && {_category in ["optic", "rail", "muzzle", "bipod", "magazine"]};
private _fits = GVAR(fits);
private _equipment = [_unit] call EFUNC(storage,getEquipment);

if (_fitsApplies && {_fits isEqualTo ""}) then {
    if (_category isEqualTo "magazine") then {
        _fits = "mine";
    } else {
        // The weapon in hand, else the primary one, else anything.
        private _held = currentWeapon _unit;

        _fits = "any";

        if ((_equipment getOrDefault ["primary", []]) isNotEqualTo []) then {
            _fits = "primary";
        };

        if (_held isNotEqualTo "") then {
            {
                if (((_equipment getOrDefault [_x, []]) param [0, ""]) isEqualTo _held) exitWith {
                    _fits = _x;
                };
            } forEach ["primary", "handgun", "launcher"];
        };
    };
};

(_fits splitString "_") params [["_fitsBase", ""], ["_fitsPart", ""]];

private _fitsWeapon = ((_equipment getOrDefault [_fitsBase, []]) param [0, ""]);

// A weapon the soldier no longer has fits nothing in particular.
if (!(_fits in ["", "any", "mine"]) && {_fitsWeapon isEqualTo ""}) then {
    _fits = "any";
};

private _fitsLabel = switch (true) do {
    case (_fits isEqualTo "mine"): {LLSTRING(Filter_FitsWeapons)};
    case (_fits in ["", "any"]): {LLSTRING(Filter_FitsAny)};
    default {format [LLSTRING(Filter_Fits), [_fitsWeapon] call EFUNC(gui,itemName)]};
};

_column set ["fitsApplies", _fitsApplies];
_column set ["fitsLabel", _fitsLabel];

// ----- The same list again -----
private _key = [
    GVAR(availableStamp), _text, _category, _fits, _favoritesOnly, GVAR(sort), count _favorites,
    ["", str GVAR(carried)] select _favoritesOnly, ["", str _equipment] select _fitsApplies
];

if ((_column getOrDefault ["listKey", []]) isEqualTo _key && {(_column getOrDefault ["pending", 0]) == 0}) exitWith {
    _column getOrDefault ["list", []]
};

// ----- Which classes -----
private _sources = [];

if (_searching) then {
    {
        if ((_x select 1) isNotEqualTo "identity") then {
            _sources pushBack [_forEachIndex, _x select 4];
        };
    } forEach _categories;
} else {
    private _index = _categories findIf {(_x select 0) isEqualTo _category};

    if (_index >= 0) then {
        _sources pushBack [_index, (_categories select _index) select 4];
    };
};

// ----- Their rows -----
private _pending = 0;
private _total = 0;
private _entries = [];
private _seen = createHashMap;

{
    _x params ["_categoryIndex", "_classes"];

    private _identity = ((_categories select _categoryIndex) select 1) isEqualTo "identity";
    private _id = (_categories select _categoryIndex) select 0;

    {
        private _lc = toLowerANSI _x;

        if !(_lc in _seen) then {
            _seen set [_lc, true];
            _total = _total + 1;

            // A piece of identity needs no config reading worth waiting for.
            private _row = if (_identity) then {[_x, _id] call FUNC(catalogRow)} else {GVAR(rows) get _lc};

            if (isNil "_row") then {
                _pending = _pending + 1;
            } else {
                _entries pushBack [_categoryIndex, _row];
            };
        };
    } forEach _classes;
} forEach _sources;

_column set ["pending", _pending];
_column set ["pendingTotal", _total];

if (_pending > 0) exitWith {[]};

// ----- The search: every word in the name, short name, class or mod; a magazine's class also finds the weapons
// that take it -----
if (_searching) then {
    private _words = _text splitString " ";
    private _magazineWords = _words select {isClass (configFile >> "CfgMagazines" >> _x)};
    private _takes = createHashMap;

    _entries = _entries select {
        private _row = _x select 1;
        private _search = _row select ROW_SEARCH;
        private _weapon = (_row select ROW_KIND) in ["rifle", "handgun", "launcher", "binocular"];
        private _compatible = [];

        // The magazines a weapon takes, worked out when a word asks for them.
        if (_weapon && {_magazineWords isNotEqualTo []}) then {
            private _class = _row select ROW_CLASS;

            _compatible = _takes get _class;

            if (isNil "_compatible") then {
                _compatible = (compatibleMagazines _class) apply {toLowerANSI _x};
                _takes set [_class, _compatible];
            };
        };

        _words findIf {
            (_search find _x) < 0 && {!(_x in _magazineWords && {_x in _compatible})}
        } < 0
    };
};

// ----- Favorites (and what the soldier carries, as ACE does) -----
if (_favoritesOnly && {(_categories findIf {(_x select 0) isEqualTo _category && {(_x select 1) isEqualTo "identity"}}) < 0}) then {
    private _carried = GVAR(carried);

    _entries = _entries select {
        private _row = _x select 1;

        (toLowerANSI (_row select ROW_CLASS)) in _favorites || {(_row select ROW_KEY) in _carried}
    };
};

// ----- Fits -----
if (_fitsApplies && {!(_fits in ["", "any"])}) then {
    private _fitting = createHashMap;

    if (_fits isEqualTo "mine") then {
        {
            private _weapon = (_equipment getOrDefault [_x, []]) param [0, ""];

            if (_weapon isNotEqualTo "") then {
                {
                    _fitting set [toLowerANSI _x, true];
                } forEach (compatibleMagazines _weapon);
            };
        } forEach ["primary", "handgun", "launcher", "binocular"];
    } else {
        if (_category isEqualTo "magazine") then {
            // From a second magazine's slot only the second muzzle's magazines.
            private _muzzles = getArray (configFile >> "CfgWeapons" >> _fitsWeapon >> "muzzles");
            private _second = (_muzzles select {_x != "this" && {_x != (_muzzles param [0, ""])}}) param [0, ""];
            private _list = if (_fitsPart isEqualTo "mag2" && {_second isNotEqualTo ""}) then {compatibleMagazines [_fitsWeapon, _second]} else {compatibleMagazines _fitsWeapon};

            {
                _fitting set [toLowerANSI _x, true];
            } forEach _list;
        } else {
            {
                _fitting set [toLowerANSI _x, true];
            } forEach ([_fitsWeapon] call CBA_fnc_compatibleItems);
        };
    };

    _entries = _entries select {(toLowerANSI ((_x select 1) select ROW_CLASS)) in _fitting};
};

// ----- Sorted: by category first while searching, then by the sort chosen -----
GVAR(sort) params [["_sortId", "name", [""]], ["_ascending", true, [true]]];

// One of ACE's sorts is for the category shown (fnc_aceSorts); in a search over every category, or in a
// category that has no such sort, the list goes by name.
private _aceSort = (_sortId select [0, 4]) isEqualTo "ace|";

if (_aceSort && {_searching || {(["label", _sortId, _category] call FUNC(aceSorts)) isEqualTo ""}}) then {
    _aceSort = false;
};

private _keys = [];

{
    private _row = _x select 1;

    private _primary = switch (_sortId) do {
        case "weight": {_row select ROW_MASS};
        case "size": {(_row select ROW_W) * (_row select ROW_H)};
        case "mod": {toLowerANSI (_row select ROW_MOD)};
        default {
            if (_aceSort) then {
                ["value", _sortId, _row select ROW_CLASS] call FUNC(aceSorts)
            } else {
                toLowerANSI (_row select ROW_NAME)
            }
        };
    };

    _keys pushBack [_x select 0, _primary, toLowerANSI (_row select ROW_NAME), _row select ROW_CLASS, _forEachIndex];
} forEach _entries;

_keys sort true;

if (!_ascending) then {
    if (_searching) then {
        // Each category on its own: the order of the categories stays.
        private _flipped = [];
        private _run = [];
        private _runCategory = -1;

        {
            if ((_x select 0) != _runCategory) then {
                reverse _run;
                _flipped append _run;
                _run = [];
                _runCategory = _x select 0;
            };

            _run pushBack _x;
        } forEach _keys;

        reverse _run;
        _flipped append _run;
        _keys = _flipped;
    } else {
        reverse _keys;
    };
};

private _rows = _keys apply {(_entries select (_x select 4)) select 1};

_column set ["list", _rows];
_column set ["listKey", _key];

_rows
