#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a change of both parts of the setup into the draft at once, as one undo step: what an import and
 * Reset to default do - the rules and the server settings change together, and Undo takes both back with one
 * click. The setup before it goes onto the undo stack, anything undone is forgotten, and the new
 * rules (fnc_setDraft) and settings (fnc_setSettingsDraft) are the draft; then the step is drawn again. Nothing
 * that writes out the same text leaves an undo step behind.
 *
 * Arguments:
 * 0: The new rules, as einv_items_fnc_parseRules returns them - an empty HashMap leaves them as they are <HASHMAP>
 *    (default: empty)
 * 1: The new server settings, setting's name -> value - nothing leaves them as they are <HASHMAP> (default: nothing)
 * 2: Draw the step again <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [createHashMap, createHashMap] call einv_setup_fnc_commitSetup;
 *
 * Public: No
 */

params [["_ast", createHashMap, [createHashMap]], ["_values", nil, [createHashMap]], ["_redraw", true, [true]]];

private _text = if (count _ast > 0) then {[_ast] call EFUNC(items,writeRules)} else {GVAR(draftText)};
private _settings = if (isNil "_values") then {GVAR(draftSettingsText)} else {[_values] call EFUNC(main,writeSettings)};

if (_text isNotEqualTo GVAR(draftText) || {_settings isNotEqualTo GVAR(draftSettingsText)}) then {
    GVAR(undo) pushBack [GVAR(draftText), GVAR(draftSettingsText)];

    if (count GVAR(undo) > UNDO_DEPTH) then {
        GVAR(undo) deleteAt 0;
    };

    GVAR(redo) = [];

    [_text] call FUNC(setDraft);
    [_settings] call FUNC(setSettingsDraft);
};

// What the engine left out of the text the change came from - an import. fnc_setDraft only sees the clean text.
if (count _ast > 0) then {
    GVAR(parseWarnings) = +(_ast getOrDefault ["warnings", []]);
};

if (_redraw) then {
    [GVAR(step)] call FUNC(showStep);
};
