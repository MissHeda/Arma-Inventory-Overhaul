#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The box under the Export button of the Items and Containers editors: what kind of export is wanted, as two
 * buttons, each with a line that says what it gives (fnc_exportClasses):
 *   - "Config entry (for a mod)": the config lines with the class name, for a mod's own config.
 *   - "Layout only (to share)": the values alone, one short text that starts with "aio-layout:" - for anyone
 *     to paste into Import at the class they have selected, with whichever mod that class is from.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 * 2: Step: "items" or "containers" <STRING> (default: "items")
 * 3: Class <STRING> (default: "")
 * 4: The edit is for the class and everything built on it <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.5, 0.1, 0.03], "containers", "B_Carryall_blk", false] call aio_setup_fnc_openExportChoice;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]], ["_mode", "items", [""]], ["_class", "", [""]], ["_tree", false, [false]]];

[_display, _anchor, [SQUARE(UNIT * 22), UNIT * 8], LLSTRING(ExportChoice_Title), {
    params ["_display", "_inner", "_theme", "_arguments"];
    _arguments params ["_mode", "_class", "_tree"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
    private _buttonH = UNIT * 1.2;
    private _cursorY = 0;

    {
        _x params ["_label", "_help", "_style", "_format"];

        [_display, _inner, [0, _cursorY, _width, _buttonH], _label, "", _theme, {
            params ["_mode", "_class", "_tree", "_format"];

            call FUNC(closePopover);

            [_mode, _class, _tree, _format] call FUNC(exportClasses);
        }, [_mode, _class, _tree, _format], true, _style] call FUNC(uiAction);

        _cursorY = _cursorY + _buttonH + UNIT * 0.15;
        _cursorY = _cursorY + ([_display, _inner, [0, _cursorY, _width], _help, TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.45;
    } forEach [
        [LLSTRING(ExportChoice_Config), LLSTRING(ExportChoice_ConfigHelp), "accent", "config"],
        [LLSTRING(ExportChoice_Layout), [LLSTRING(ExportChoice_LayoutHelp), LLSTRING(ExportChoice_LayoutHelpTree)] select _tree, "", "layout"]
    ];
}, [_mode, _class, _tree], [], "exportChoice"] call FUNC(popover);
