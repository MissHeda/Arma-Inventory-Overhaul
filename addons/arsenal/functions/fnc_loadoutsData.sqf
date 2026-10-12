#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rows of a loadouts tab - ACE's lists in the profile, the mission's defaults, the shared ones -
 * filtered by the search field and with the verified state of each.
 *
 * A row is [name, data, author, shared, tab, check, id]: the loadout as it is kept ([loadout, extended
 * info], or a plain getUnitLoadout array in an older profile), the player who shares it ("" for Mine and
 * Default), whether the player shares it (Mine), the tab, ACE's verification of it ([] while it has not been
 * checked yet - fnc_verifyStep does that a few at a time, and what is asked for here and not known is put in
 * its queue) and the id that picks it: the name, and for a shared loadout the sharer's name before it, as
 * ACE keeps it in the shared namespace. Rows lie in alphabetical order.
 *
 * Listing the public tab also stops sharing what players who have left shared, which ACE's list does too -
 * ACE's own code writes the list of shared loadouts to the wrong variable when it does.
 *
 * Arguments:
 * 0: Tab - "mine", "default" or "public" <STRING>
 * 1: Only those the search field lets through, and look after the public list <BOOL> (default: true)
 * 2: Only the row with this id - none when no row has it, as with "" for nothing picked (default: all rows) <STRING>
 *
 * Return Value:
 * Rows <ARRAY>
 *
 * Example:
 * ["mine"] call einv_arsenal_fnc_loadoutsData;
 *
 * Public: No
 */

params [["_tab", "mine", [""]], ["_filtered", true, [true]], ["_only", nil, [""]]];

// Only one row is asked for (the picked one, which may be none: "" is the id of no row).
private _single = !isNil "_only";

private _namespace = missionNamespace getVariable [QACEGVAR(arsenal,sharedLoadoutsNamespace), locationNull];
private _sharedVars = [];

if (!isNull _namespace) then {
    _sharedVars = _namespace getVariable [QACEGVAR(arsenal,sharedLoadoutsVars), []];
};

// What is kept: [name, data, author, shared, id].
private _found = [];

switch (_tab) do {
    case "mine": {
        {
            _x params [["_name", "", [""]], ["_data", [], [[]]]];

            if (_name isNotEqualTo "" && {count _data in [2, 10]}) then {
                _found pushBack [_name, _data, "", (profileName + _name) in _sharedVars, _name];
            };
        } forEach (profileNamespace getVariable [QACEGVAR(arsenal,saved_loadouts), []]);
    };
    case "default": {
        if (missionNamespace getVariable [QACEGVAR(arsenal,allowDefaultLoadouts), true]) then {
            {
                _x params [["_name", "", [""]], ["_data", [], [[]]]];

                if (_name isNotEqualTo "" && {count _data in [2, 10]}) then {
                    _found pushBack [_name, _data, "", false, _name];
                };
            } forEach (missionNamespace getVariable [QACEGVAR(arsenal,defaultLoadoutsList), []]);
        };
    };
    case "public": {
        private _players = (allPlayers apply {name _x}) + [profileName];
        private _vars = +_sharedVars;

        {
            private _var = _x;
            private _entry = if (isNull _namespace) then {[]} else {_namespace getVariable [_var, []]};

            _entry params [["_author", "", [""]], ["_name", "", [""]], ["_data", [], [[]]]];

            if (_name isEqualTo "" || {count _data < 2}) then {continue};

            // The one who shared it is gone: it is shared no longer.
            if (!(_author in _players)) then {
                if (_filtered) then {
                    _namespace setVariable [_var, nil, true];
                    _namespace setVariable [QACEGVAR(arsenal,sharedLoadoutsVars), (_namespace getVariable [QACEGVAR(arsenal,sharedLoadoutsVars), []]) - [_var], true];

                    [QACEGVAR(arsenal,loadoutUnshared), [controlNull, _author, _name]] call CBA_fnc_remoteEvent;
                };

                continue;
            };

            _found pushBack [_name, _data, _author, false, _var];
        } forEach _vars;
    };
    default {};
};

// Alphabetical, whatever the case.
_found = [_found, [], {toLowerANSI (_x select 0)}, "ASCEND"] call BIS_fnc_sortBy;

// The search field: every word in the name, in any order, as in the catalog.
private _words = [];

if (_filtered) then {
    _words = (toLowerANSI EGVAR(gui,filter)) splitString " ";
};

private _rows = [];
private _stamp = GVAR(availableStamp);

{
    _x params ["_name", "_data", "_author", "_shared", "_id"];

    if (_single && {_id isNotEqualTo _only}) then {continue};

    private _lower = toLowerANSI _name;

    if (_words findIf {!(_x in _lower)} >= 0) then {continue};

    // What was found out about it holds until the loadout or the supply changes.
    private _key = _tab + "|" + _id;
    private _print = hashValue (str _data);
    private _known = GVAR(verified) getOrDefault [_key, []];
    private _check = [];

    if ((_known param [0, -1]) == _stamp && {(_known param [1, ""]) isEqualTo _print}) then {
        _check = _known select 2;
    } else {
        if ((_filtered || {_single}) && {GVAR(verifyQueue) findIf {(_x select 0) isEqualTo _key && {(_x select 4) isEqualTo _print}} < 0}) then {
            GVAR(verifyQueue) pushBack [_key, _tab, _name, _data, _print];
        };
    };

    _rows pushBack [_name, _data, _author, _shared, _tab, _check, _id];
} forEach _found;

_rows
