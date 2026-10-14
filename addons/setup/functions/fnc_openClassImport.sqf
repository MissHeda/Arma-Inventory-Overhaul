#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the box under the Import button of the Items and Containers editors: paste config lines (what
 * Export wrote, or what a mod's config holds for its classes) or rules into it with Ctrl+V - a paste box,
 * as CBA's own Import is one: it works for every player, where a script reading the clipboard would not -,
 * then Apply puts them into the draft (fnc_importClasses). It only changes the draft: Save is still to
 * come, and Undo takes it back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.5, 0.1, 0.03]] call einv_setup_fnc_openClassImport;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]]];

[_display, _anchor, [SQUARE(UNIT * 24), UNIT * 11], LLSTRING(ClassImport_Title), {
    params ["_display", "_inner", "_theme"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _helpH = [_display, _inner, [0, 0, _width], LLSTRING(ClassImport_Help), TEXT_BODY, _theme getOrDefault ["text2", [0.7, 0.73, 0.78, 1]], _theme getOrDefault ["font", "PuristaMedium"]] call FUNC(uiText);
    private _buttonH = UNIT * 1.2;
    private _boxTop = _helpH + UNIT * 0.35;
    private _boxH = _height - _boxTop - _buttonH - UNIT * 0.45;

    private _box = [_display, _inner, [0, _boxTop, _width, _boxH], GVAR(classImportText), LLSTRING(Import_Placeholder), _theme, {
        params ["_text"];

        GVAR(classImportText) = _text;
    }, [], true, true] call FUNC(uiEdit);

    ctrlSetFocus (_box select (count _box - 1));
    uiNamespace setVariable [QGVAR(classImportEdit), _box select (count _box - 1)];

    private _buttonW = (_width - SQUARE(UNIT * 0.3)) / 2;
    private _buttonY = _height - _buttonH;

    [_display, _inner, [0, _buttonY, _buttonW, _buttonH], LLSTRING(Cancel), "", _theme, {
        call FUNC(closePopover);
    }, [], true, "ghost"] call FUNC(uiAction);

    [_display, _inner, [_width - _buttonW, _buttonY, _buttonW, _buttonH], LLSTRING(ClassImport_Apply), UI_TEX(icon_check_ca), _theme, {
        // The box as it is now, not the last change reported.
        private _edit = uiNamespace getVariable [QGVAR(classImportEdit), controlNull];

        if (!isNull _edit) then {
            GVAR(classImportText) = ctrlText _edit;
        };

        ([GVAR(classImportText)] call FUNC(importClasses)) params ["_kind", "_count", "_notes"];

        switch (_kind) do {
            case "none": {
                [LLSTRING(ClassImport_Nothing), "loss"] call FUNC(setHint);
            };
            case "tooLong": {
                [format [LLSTRING(Warning_TooLong), _count], "loss"] call FUNC(setHint);
            };
            // Said by fnc_upsertRules.
            case "refused": {};
            // The step is drawn again by the commit, which closes the box.
            default {
                GVAR(classImportText) = "";

                [
                    format [[LLSTRING(ClassImport_Config), LLSTRING(Import_Done)] select (_kind isEqualTo "rules"), _count, count _notes],
                    ["gain", "accent"] select (_notes isNotEqualTo [])
                ] call FUNC(setHint);
            };
        };
    }, [], true, "accent"] call FUNC(uiAction);
}] call FUNC(popover);
