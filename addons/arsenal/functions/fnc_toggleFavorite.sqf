#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes an item a favorite or not, ACE's list in the profile (saved when the window closes).
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["arifle_MX_F"] call einv_arsenal_fnc_toggleFavorite;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {};

// The favorites are lower case, as ACE keeps them: a config's case may change.
private _favorites = missionNamespace getVariable [QACEGVAR(arsenal,favorites), createHashMap];
private _key = toLowerANSI _class;

if (_key in _favorites) then {
    _favorites deleteAt _key;
} else {
    _favorites set [_key, nil];
};

missionNamespace setVariable [QACEGVAR(arsenal,favorites), _favorites];

// The stars follow at once; the list only changes while it shows the favorites.
[true] call FUNC(bindCatalog);

if (missionNamespace getVariable [QACEGVAR(arsenal,favoritesOnly), false]) then {
    (uiNamespace getVariable [QGVAR(column), createHashMap]) set ["dirty", true];
};
