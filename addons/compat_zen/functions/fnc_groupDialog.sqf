#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks the game master which group the objects are locked to - a list of the groups there are, in a
 * Zeus Enhanced dialog - and locks them to it on confirm.
 *
 * Arguments:
 * 0: Objects <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_crate]] call einv_compat_zen_fnc_groupDialog;
 *
 * Public: No
 */

params [["_objects", [], [[]]]];

private _groups = call FUNC(groups);

if (_groups isEqualTo []) exitWith {
    [objNull, LLSTRING(Feedback_NoGroups)] call BIS_fnc_showCuratorFeedbackMessage;
};

// Values left empty: the dialog counts the entries, and the answer is the index into the list.
[
    LLSTRING(Dialog_Title),
    [
        ["COMBO", [LLSTRING(Dialog_Group), LLSTRING(Dialog_Group_Tooltip)], [[], _groups apply {_x select 1}, 0]]
    ],
    {
        params ["_values", "_args"];

        _values params [["_index", 0, [0]]];
        _args params ["_objects", "_groups"];

        private _entry = _groups param [_index, []];

        if (_entry isEqualTo []) exitWith {};

        [_objects, "group", _entry select 0] call EFUNC(compat_zen,apply);
    },
    {},
    [_objects, _groups]
] call zen_dialog_fnc_create;
