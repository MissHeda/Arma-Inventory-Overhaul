#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes out of a context menu's choices the rows that are hidden for an item: by their id (a choice's option
 * "id" - the window's own rows have one each, see fnc_contextMenu; an option of CBA's item context menu has its
 * CBA id) as the server setting "Hidden menu entries" (GVAR(menuHidden)) says for everything, and as
 * CfgAioMenu >> Hide and aio_gui_fnc_hideMenuEntry say for the item (fnc_menuRules). A line above a row that
 * goes moves to the next row that stays.
 *
 * Arguments:
 * 0: Choices, as fnc_openMenu takes them <ARRAY>
 * 1: The class the menu is for, "" for none <STRING>
 *
 * Return Value:
 * The choices left <ARRAY>
 *
 * Example:
 * [_choices, "FirstAidKit"] call aio_gui_fnc_menuFilter;
 *
 * Public: No
 */

params [["_choices", [], [[]]], ["_class", "", [""]]];

// Names and pictures a mod or the mission changed (fnc_changeMenuEntry), the rule nearest the item last so that it wins.
private _changes = [missionNamespace getVariable [QGVAR(menuChangeRules), createHashMap], _class] call FUNC(menuRules);

reverse _changes;

{
    {
        _x params ["_id", "_name", "_icon"];

        {
            private _options = _x param [3, createHashMap];

            if (_options isEqualType createHashMap && {toLowerANSI (_options getOrDefault ["id", ""]) isEqualTo _id}) then {
                if (_name isNotEqualTo "") then {_x set [0, _name]};
                if (_icon isNotEqualTo "") then {_options set ["icon", _icon]};
            };
        } forEach _choices;
    } forEach _x;
} forEach _changes;

private _hidden = createHashMap;

{
    private _id = toLowerANSI ((_x splitString toString [32, 9, 10, 13]) joinString "");

    if (_id isNotEqualTo "") then {_hidden set [_id, true]};
} forEach ((missionNamespace getVariable [QGVAR(menuHidden), ""]) splitString ",;");

{
    {_hidden set [toLowerANSI _x, true]} forEach _x;
} forEach ([missionNamespace getVariable [QGVAR(menuHideRules), createHashMap], _class] call FUNC(menuRules));

if (count _hidden == 0) exitWith {_choices};

private _kept = [];
private _carry = false;

{
    private _options = _x param [3, createHashMap];

    if (!(_options isEqualType createHashMap)) then {_options = createHashMap};

    if ((toLowerANSI (_options getOrDefault ["id", ""])) in _hidden) then {
        _carry = _carry || {_options getOrDefault ["separator", false]};
    } else {
        if (_carry && {_kept isNotEqualTo []}) then {
            if (count _x < 4 || {!((_x select 3) isEqualType createHashMap)}) then {_x set [3, createHashMap]};
            (_x select 3) set ["separator", true];
        };

        _carry = false;
        _kept pushBack _x;
    };
} forEach _choices;

// The first row never has a line above it.
if (_kept isNotEqualTo [] && {count (_kept select 0) >= 4} && {((_kept select 0) select 3) isEqualType createHashMap}) then {
    ((_kept select 0) select 3) set ["separator", false];
};

_kept
