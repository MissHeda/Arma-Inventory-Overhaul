#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a change of the server settings into the draft - the General step's controls end here, as every edit
 * of the rules ends in fnc_commit. The setup before it goes onto the undo stack, anything undone is forgotten,
 * and the new settings are the draft (fnc_setSettingsDraft); then the step is drawn again. A change that
 * writes out the same text is no change and leaves no undo step behind.
 *
 * Arguments:
 * 0: The settings the draft names, setting's name -> value - what is left out is at its default <HASHMAP>
 * 1: Draw the step again <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [createHashMapFromArray [["einv_gui_searchTime", 0.8]]] call einv_setup_fnc_commitSettings;
 *
 * Public: No
 */

params [["_values", createHashMap, [createHashMap]], ["_redraw", true, [true]]];

private _text = [_values] call EFUNC(main,writeSettings);

if (_text isNotEqualTo GVAR(draftSettingsText)) then {
    GVAR(undo) pushBack [GVAR(draftText), GVAR(draftSettingsText)];

    if (count GVAR(undo) > UNDO_DEPTH) then {
        GVAR(undo) deleteAt 0;
    };

    GVAR(redo) = [];

    [_text] call FUNC(setSettingsDraft);
};

if (_redraw) then {
    [GVAR(step)] call FUNC(showStep);
};
