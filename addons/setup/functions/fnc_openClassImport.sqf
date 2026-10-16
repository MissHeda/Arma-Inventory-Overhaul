#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the box under the Import button of the Items and Containers editors: paste config lines (what
 * Export wrote, or what a mod's config holds for its classes), a layout (Export's "layout only", which has no
 * class) or rules into it with Ctrl+V - a paste box, as CBA's own Import is one: it works for every player,
 * where a script reading the clipboard would not -, then Apply puts them into the draft
 * (fnc_applyClassImport, fnc_importClasses): a layout, and the values of a class this game does not have, go to
 * the class selected in the editor; for classes the game has, the editor asks whether the selected class or the
 * classes named in the text are meant (fnc_openImportChoice). It only changes the draft: Save is still to
 * come, and Undo takes it back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 * 2: The class selected in the editor <STRING> (default: "")
 * 3: The edit is for that class and everything built on it <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.5, 0.1, 0.03], "B_Carryall_blk", false] call einv_setup_fnc_openClassImport;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]], ["_class", "", [""]], ["_tree", false, [false]]];

[_display, _anchor, [SQUARE(UNIT * 24), UNIT * 11], LLSTRING(ClassImport_Title), {
    params ["_display", "_inner", "_theme", "_arguments"];
    _arguments params ["_class", "_tree"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _helpH = [_display, _inner, [0, 0, _width], LLSTRING(ClassImport_Help), TEXT_BODY, _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _theme getOrDefault ["font", "PuristaMedium"]] call FUNC(uiText);
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
        params ["_class", "_tree"];

        // The box as it is now, not the last change reported.
        private _edit = uiNamespace getVariable [QGVAR(classImportEdit), controlNull];

        if (!isNull _edit) then {
            GVAR(classImportText) = ctrlText _edit;
        };

        [GVAR(classImportText), _class, _tree, ""] call FUNC(applyClassImport);
    }, [_class, _tree], true, "accent"] call FUNC(uiAction);
}, [_class, _tree]] call FUNC(popover);
