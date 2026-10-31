#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Runs the import of the Items and Containers editors (fnc_importClasses) and says what came of it in the
 * result line. The answers:
 *   - "config": the classes the text names got their values; a count of the ones the game lacks, which were left
 *     out, is said with it.
 *   - "layout": a layout (no class) went to the selected class.
 *   - "selected": the text named one class that this game does not have - another mod's, not loaded here -, and
 *     its values went to the selected class instead, which the line names.
 *   - "ask": the text names classes the game has: the question opens (fnc_openImportChoice), and this runs
 *     again with the answer.
 *   - the rest are refusals: nothing readable, too long, class names the rules cannot hold, classes the game
 *     lacks and no one to give their values to, values that fit nothing about the selected class.
 * Nothing is drawn here for a success: the commit of the import draws the step again, which closes the box.
 *
 * Arguments:
 * 0: Pasted text <STRING>
 * 1: The class selected in the editor <STRING>
 * 2: The edit is for that class and everything built on it <BOOL>
 * 3: The answer to the question: "selected" or "named"; "" when none was asked <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["class CfgVehicles { class X { aio_grid = ""6x4""; }; };", "B_Carryall_blk", false, ""] call aio_setup_fnc_applyClassImport;
 *
 * Public: No
 */

disableSerialization;

params [["_text", "", [""]], ["_class", "", [""]], ["_tree", false, [false]], ["_choice", "", [""]]];

([_text, _class, _tree, _choice] call FUNC(importClasses)) params ["_kind", "_count", "_notes", "_info"];

private _warnings = count _notes;

switch (_kind) do {
    case "none": {
        [LLSTRING(ClassImport_Nothing), "loss"] call FUNC(setHint);
    };
    case "tooLong": {
        [format [LLSTRING(Warning_TooLong), _count], "loss"] call FUNC(setHint);
    };
    case "skipped": {
        [format [LLSTRING(ClassImport_Skipped), _count], "loss"] call FUNC(setHint);
    };
    case "notFit": {
        [format [LLSTRING(ClassImport_NotFit), _info param [0, _class]], "loss"] call FUNC(setHint);
    };
    // Said by fnc_upsertRules.
    case "refused": {};
    case "ask": {
        [uiNamespace getVariable [QGVAR(display), displayNull], _text, _class, _tree, _count, _info] call FUNC(openImportChoice);
    };
    // The step is drawn again by the commit, which closes the box.
    default {
        GVAR(classImportText) = "";

        private _line = switch (_kind) do {
            case "layout": {format [LLSTRING(ClassImport_Layout), _info param [0, _class], _warnings]};
            case "selected": {format [LLSTRING(ClassImport_Redirected), _info param [1, ""], _info param [0, _class], _warnings]};
            case "config": {
                private _left = (_info param [0, 0]);

                [
                    format [LLSTRING(ClassImport_Config), _count, _warnings],
                    format [LLSTRING(ClassImport_ConfigLeft), _count, _left, _warnings]
                ] select (_left > 0)
            };
            default {format [LLSTRING(Import_Done), _count, _warnings]};
        };

        [_line, ["gain", "accent"] select (_notes isNotEqualTo [])] call FUNC(setHint);
    };
};
