#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The actions ACE's window shows under a slot's tab, as rows of the slot's menu - the gunbag's among them,
 * and whatever other mods add with ace_arsenal_fnc_addAction. A button is a row that runs ACE's statement
 * (with the soldier as its argument) and has the window looked at again; a text is a row that says its text
 * in the hint. A group is shown when its condition holds for the soldier, an action when its own does.
 *
 * ACE decides what the Eden editor may do: an action with a scope that is not for the editor is not in
 * its tables there.
 *
 * Arguments:
 * 0: Slot id, as in einv_storage_fnc_getSlot <STRING>
 *
 * Return Value:
 * Choices [[text, arguments, code, options], ...] <ARRAY>
 *
 * Example:
 * ["backpack"] call einv_arsenal_fnc_aceActions;
 *
 * Public: No
 */

params [["_slot", "", [""]]];

private _unit = GVAR(center);

// ACE's tabs of the left panel, in its order; the slots of parts and magazines have no tab.
private _tab = [
    "primary", "handgun", "launcher", "uniform", "vest", "backpack", "headgear", "goggles", "nvg", "binocular", "map", "gps",
    "radio", "compass", "watch"
] find _slot;

if (_tab < 0 || {isNull _unit}) exitWith {[]};

// ACE builds its tables when it first needs them.
if (isNil QACEGVAR(arsenal,actionList) && {!isNil QACEFUNC(arsenal,compileActions)}) then {
    call ACEFUNC(arsenal,compileActions);
};

private _choices = [];

{
    // [root class, title, condition, actions]; an action is [class, type (0 text, 1 button), label, statement, condition]
    _x params ["", "_title", "_groupCondition", "_actions"];

    if ([_unit] call _groupCondition) then {
        if ((_title select [0, 1]) isEqualTo "$") then {
            _title = localize (_title select [1]);
        };

        {
            _x params ["", "_type", "_label", "_statement", "_condition"];

            if ([_unit] call _condition) then {
                if ((_label select [0, 1]) isEqualTo "$") then {
                    _label = localize (_label select [1]);
                };

                private _options = createHashMapFromArray [["separator", _choices isEqualTo []]];

                if (_type == 1) then {
                    _choices pushBack [
                        [_label, format ["%1: %2", _title, _label]] select (_title isNotEqualTo ""),
                        [_statement], {
                            params ["_statement"];

                            [] call _statement;
                            [] call EFUNC(gui,requestRebuild);
                        }, _options
                    ];
                } else {
                    private _text = [] call _statement;

                    if (isNil "_text") then {
                        _text = "";
                    };

                    if (_text isEqualType []) then {
                        _text = _text joinString ", ";
                    };

                    if (_text isEqualType "" && {_text isNotEqualTo ""}) then {
                        // One line, as short as a row: the whole text comes in the hint.
                        _text = (_text splitString (toString [10, 13])) joinString ", ";

                        _choices pushBack [
                            format ["%1: %2", [_label, _title] select (_label isEqualTo ""), _text select [0, 40]],
                            [_text], {
                                params ["_text"];

                                [_text] call FUNC(message);
                            }, _options
                        ];
                    };
                };
            };
        } forEach _actions;
    };
} forEach ((missionNamespace getVariable [QACEGVAR(arsenal,actionList), []]) param [_tab, []]);

_choices
