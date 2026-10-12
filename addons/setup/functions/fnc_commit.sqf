#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a change into the draft: every edit of every step ends here. The draft before it goes onto the
 * undo stack, anything undone is forgotten, and the new one is compiled with a fresh cache
 * (fnc_setDraft), then the step is drawn again.
 *
 * The change comes as the rules engine's tree (einv_items_fnc_parseRules) - read anew from GVAR(draftText)
 * by whoever changes it, so the draft's own tree is never touched in place. A change that writes out the
 * same text is no change and leaves no undo step behind.
 *
 * Arguments:
 * 0: The changed setup, as einv_items_fnc_parseRules returns it <HASHMAP>
 * 1: Draw the step again <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * private _ast = [einv_setup_draftText] call einv_items_fnc_parseRules;
 * _ast set ["base", "tarkov"];
 * [_ast] call einv_setup_fnc_commit;
 *
 * Public: No
 */

params [["_ast", createHashMap, [createHashMap]], ["_redraw", true, [true]]];

private _text = [_ast] call EFUNC(items,writeRules);

if (_text isNotEqualTo GVAR(draftText)) then {
    GVAR(undo) pushBack GVAR(draftText);

    if (count GVAR(undo) > UNDO_DEPTH) then {
        GVAR(undo) deleteAt 0;
    };

    GVAR(redo) = [];

    [_text] call FUNC(setDraft);
};

// What the engine left out of the text the change came from - an import, the text typed at Review.
// fnc_setDraft only sees the clean text it was written into.
GVAR(parseWarnings) = +(_ast getOrDefault ["warnings", []]);
GVAR(rawText) = "";

if (_redraw) then {
    [GVAR(step)] call FUNC(showStep);
};
