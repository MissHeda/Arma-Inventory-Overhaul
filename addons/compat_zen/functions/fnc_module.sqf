#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The Zeus module "Lock inventory", placed on an object: a dialog with who it is locked to - not locked,
 * a side, one group, the admins - and which group, both preselected from the object's lock, and the
 * lock set on confirm. Placed on nothing a lock fits (the ground, a person), it says so.
 *
 * Arguments:
 * 0: Object the module was placed on, objNull when on the ground <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorObject] call aio_compat_zen_fnc_module;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

if (([[], _object] call FUNC(targets)) isEqualTo []) exitWith {
    [objNull, LLSTRING(Feedback_NoTarget)] call BIS_fnc_showCuratorFeedbackMessage;
};

private _groups = call FUNC(groups);
private _sides = [west, east, independent, civilian];

([_object] call EFUNC(locks,getLock)) params ["_mode", "_who"];

// What the lock says now, as a place in the two lists.
private _modeIndex = 0;
private _groupIndex = 0;

switch (_mode) do {
    case "side": {
        _modeIndex = 1 + ((_sides find _who) max 0);
    };
    case "group": {
        _modeIndex = 5;

        if (_who isEqualType grpNull) then {
            _groupIndex = (_groups findIf {(_x select 0) isEqualTo _who}) max 0;
        } else {
            _groupIndex = (_groups findIf {(groupId (_x select 0)) == _who}) max 0;
        };
    };
    case "admins": {
        _modeIndex = 6;
    };
};

[
    LLSTRING(Dialog_Title),
    [
        [
            "COMBO",
            LLSTRING(Dialog_Mode),
            [
                ["", "west", "east", "independent", "civilian", "group", "admins"],
                [
                    LLSTRING(Action_Everyone),
                    LELSTRING(locks,Side_West),
                    LELSTRING(locks,Side_East),
                    LELSTRING(locks,Side_Independent),
                    LELSTRING(locks,Side_Civilian),
                    LLSTRING(Dialog_OneGroup),
                    LLSTRING(Action_Admins)
                ],
                _modeIndex
            ]
        ],
        ["COMBO", [LLSTRING(Dialog_Group), LLSTRING(Dialog_Group_Tooltip)], [[], _groups apply {_x select 1}, _groupIndex]]
    ],
    {
        params ["_values", "_args"];

        _values params [["_choice", "", [""]], ["_index", 0, [0]]];
        _args params ["_object", "_groups"];

        private _mode = "";
        private _who = "";

        switch (_choice) do {
            case "west": {_mode = "side"; _who = west};
            case "east": {_mode = "side"; _who = east};
            case "independent": {_mode = "side"; _who = independent};
            case "civilian": {_mode = "side"; _who = civilian};
            case "admins": {_mode = "admins"};
            case "group": {
                private _entry = _groups param [_index, []];

                if (_entry isNotEqualTo []) then {
                    _mode = "group";
                    _who = _entry select 0;
                };
            };
        };

        // One group chosen and none to choose from: nothing was said, nothing is changed.
        if (_choice isEqualTo "group" && {_mode isEqualTo ""}) exitWith {
            [objNull, LLSTRING(Feedback_NoGroups)] call BIS_fnc_showCuratorFeedbackMessage;
        };

        [[_object], _mode, _who] call EFUNC(compat_zen,apply);
    },
    {},
    [_object, _groups]
] call zen_dialog_fnc_create;
