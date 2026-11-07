#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words for what a double click on an item does where a mod or the mission gave it one of its own (fnc_setDoubleClick,
 * fnc_doubleClickRule) - for the hint line at the bottom, so that it shows before the click (Mia, after 0.6.73). The name of the
 * menu row it runs: an option of CBA's item context menu by its id, else the action as it is written (a row named by its text, or
 * one of the window's own). Kept per class until the rules change (fnc_setDoubleClick empties it).
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * The words, "" for an item that does the usual <STRING>
 *
 * Example:
 * ["gmr_pack_556x45_basic_30"] call aio_gui_fnc_doubleClickLabel;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {""};

if (isNil QGVAR(doubleClickLabels)) then {GVAR(doubleClickLabels) = createHashMap};

private _key = toLowerANSI _class;
private _known = GVAR(doubleClickLabels) get _key;

if (!isNil "_known") exitWith {_known};

private _action = ([missionNamespace getVariable [QGVAR(doubleClickRules), createHashMap], _class] call FUNC(menuRules)) param [0, ""];
private _label = "";

switch (true) do {
    case (_action isEqualTo "" || {toLowerANSI _action isEqualTo "move"}): {};
    case (toLowerANSI _action isEqualTo "menu"): {_label = LLSTRING(Hint_DoubleClickMenu)};
    default {
        _label = _action;

        // An option of CBA's item context menu with that id: its name. The store is a HashMap per item, each of its options by id.
        {
            private _option = _y get _action;

            if (!isNil "_option") exitWith {
                private _name = _option param [1, ""];

                if (_name isEqualType [] ) then {_name = _name param [0, ""]};
                if (isLocalized _name) then {_name = localize _name};
                if (_name isNotEqualTo "") then {_label = _name};
            };
        } forEach (missionNamespace getVariable ["cba_ui_ItemContextMenuOptions", createHashMap]);
    };
};

GVAR(doubleClickLabels) set [_key, _label];

_label
