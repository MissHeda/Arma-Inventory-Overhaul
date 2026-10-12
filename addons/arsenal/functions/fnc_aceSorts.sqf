#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE's sorts for the catalog: the ones ACE offers on the tab that belongs to a category (accuracy and rate of
 * fire for rifles, magnification for optics, protection for vests, ...) and what a sort says about a class.
 * Every other mod's sort added with ace_arsenal_fnc_addSort is among them.
 *
 * A sort is known here as "ace|" and the name ACE gives it on that tab (the class, "L" or "R" and the tab's
 * number, as ACE keeps them), so the catalog's sort setting can hold it like one of its own. Sorts that
 * only repeat the catalog's own - alphabetical, by mod, by weight - are left out. A sort is offered
 * when its condition holds for a list that is no container's (ACE's amount sort is a container's only).
 *
 * Modes:
 *   "list": [category] - the sorts of that category, [[id, label], ...]
 *   "label": [id, category] - the label of the sort, "" when the category has no such sort
 *   "value": [id, class] - what the sort says about the class, a string to sort by, kept per sort and class
 *
 * Arguments:
 * 0: Mode - "list", "label" or "value" <STRING>
 * 1: Category id for "list" and "label" (the catalog's: "rifle", "optic", ...), sort id for "value" <STRING>
 * 2: Sort id for "label", class for "value" <STRING>
 *
 * Return Value:
 * The sorts, the label or the value <ARRAY, STRING>
 *
 * Example:
 * ["list", "rifle"] call einv_arsenal_fnc_aceSorts;
 *
 * Public: No
 */

params [["_mode", "list", [""]], ["_first", "", [""]], ["_second", "", [""]]];

// The tab of ACE's lists a category is on: [left (true) or right panel, number].
private _fnc_tab = {
    params ["_category"];

    private _left = [
        "rifle", "handgun", "launcher", "uniform", "vest", "backpack", "headgear", "goggles", "nvg", "binocular", "map", "gps",
        "radio", "compass", "watch", "face", "voice", "insignia"
    ] find _category;

    if (_left >= 0) exitWith {[true, _left]};

    private _right = ["optic", "rail", "muzzle", "bipod", "magazine", "grenade", "explosive", "misc"] find _category;

    // A custom button of ACE's right panel is a misc tab as well.
    if (_right < 0 && {(_category select [0, 6]) isEqualTo "custom"}) then {
        _right = 7;
    };

    if (_right >= 0) exitWith {[false, _right]};

    []
};

// ACE's lists of sorts, left panel and right panel: tab by tab, [name, title, statement, condition] each.
private _fnc_lists = {
    params ["_left"];

    if (isNil QACEGVAR(arsenal,sortListLeftPanel) && {!isNil QACEFUNC(arsenal,compileSorts)}) then {
        call ACEFUNC(arsenal,compileSorts);
    };

    missionNamespace getVariable [[QACEGVAR(arsenal,sortListRightPanel), QACEGVAR(arsenal,sortListLeftPanel)] select _left, []]
};

// The sorts ACE offers for a category's tab.
private _fnc_sorts = {
    params ["_category"];

    private _tab = [_category] call _fnc_tab;

    if (_tab isEqualTo []) exitWith {[]};

    _tab params ["_left", "_index"];

    // The catalog sorts by name, mod and weight by itself.
    private _own = ["ACE_alphabetically", "ACE_mod", "ACE_mass"];

    (([_left] call _fnc_lists) param [_index, []]) select {
        _x isNotEqualTo [] && {
            private _name = _x select 0;

            !((_name select [0, (count _name) - 3]) in _own)
        } && {(_x select 3) isEqualType {}} && {(_x select 2) isEqualType {}} && {[false] call (_x select 3)}
    }
};

private _cache = uiNamespace getVariable QGVAR(sortCache);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(sortCache), _cache];
};

switch (_mode) do {
    case "list": {
        (([_first] call _fnc_sorts) apply {
            private _title = _x select 1;

            if ((_title select [0, 1]) isEqualTo "$") then {
                _title = localize (_title select [1]);
            };

            ["ace|" + (_x select 0), _title]
        })
    };
    case "label": {
        private _list = ["list", _second] call FUNC(aceSorts);
        private _index = _list findIf {(_x select 0) isEqualTo _first};

        if (_index < 0) then {""} else {(_list select _index) select 1}
    };
    case "value": {
        private _id = _first;
        private _class = _second;
        private _key = format ["%1|%2", _id, toLowerANSI _class];
        private _kept = _cache get _key;

        if (!isNil "_kept") exitWith {_kept};

        private _name = _id select [4];
        private _value = "_";

        // The id ends in the side and the tab's number, as ACE names it: "L00" is the left panel's first tab.
        private _suffix = _name select [(count _name) - 3];
        private _sorts = ([_suffix select [0, 1] isEqualTo "L"] call _fnc_lists) param [parseNumber (_suffix select [1]), []];
        private _found = _sorts param [_sorts findIf {(_x param [0, ""]) isEqualTo _name}, []];

        if (_found isNotEqualTo [] && {(_found select 2) isEqualType {}}) then {
            private _config = _class call CBA_fnc_getItemConfig;

            if (!isNull _config) then {
                // The statement gets [config, class, quantity]; the quantity is a container's.
                private _result = [_config, _class, 0] call (_found select 2);

                if (isNil "_result") then {
                    _result = "";
                };

                // A number is written so that the text sorts like it does: ACE does the same.
                if (_result isEqualType 0) then {
                    _result = [_result, 8, 2] call CBA_fnc_formatNumber;
                };

                if !(_result isEqualType "") then {
                    _result = str _result;
                };

                _value = [toLowerANSI _result, "_"] select (_result isEqualTo "");
            };
        };

        _cache set [_key, _value];

        _value
    };
    default {[]};
}
