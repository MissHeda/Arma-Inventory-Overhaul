#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The question an import at the Items and Containers editors asks when the text names classes this game has
 * (fnc_importClasses answered "ask"): in the middle of the screen over the dimmed wizard, two buttons -
 *   - "Apply to the selected class": the values go to the class selected in the editor, not to the one the
 *     text names. Offered when the text names one class (the likely wish when it is a design shared by someone
 *     else, who may have had another class), and then it is the highlighted one;
 *   - "Apply to the classes named in the text": each class the text names gets its own values. The highlighted
 *     one when the text names several, and the other is greyed out then - there is no telling which of them
 *     the selected class is to take.
 * Cancel leaves the draft as it is. An answer runs the import again with it (fnc_applyClassImport).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The pasted text <STRING>
 * 2: The class selected in the editor <STRING>
 * 3: The edit is for that class and everything built on it <BOOL>
 * 4: How many of the classes of the text the game has <NUMBER>
 * 5: [the first of them, how many classes the text names] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _text, "B_Carryall_blk", false, 1, ["B_Kitbag_cbr", 1]] call einv_setup_fnc_openImportChoice;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_text", "", [""]], ["_class", "", [""]], ["_tree", false, [false]], ["_known", 1, [0]], ["_info", [], [[]]]];

_info params [["_first", "", [""]], ["_named", 1, [0]]];

[_display, [], [SQUARE(UNIT * 24), UNIT * 9.2], LLSTRING(ImportChoice_Title), {
    params ["_display", "_inner", "_theme", "_arguments"];
    _arguments params ["_text", "_class", "_tree", "_known", "_first", "_named"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _colorText2 = _theme getOrDefault ["text2", [0.7, 0.73, 0.78, 1]];
    private _buttonH = UNIT * 1.2;
    private _one = _named == 1;
    private _cursorY = 0;

    private _question = if (_one) then {
        format [LLSTRING(ImportChoice_One), _first, _class]
    } else {
        format [LLSTRING(ImportChoice_Many), _named, _class]
    };

    _cursorY = ([_display, _inner, [0, _cursorY, _width], _question, TEXT_BODY, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.5;

    {
        _x params ["_label", "_choice", "_enabled", "_style"];

        [_display, _inner, [0, _cursorY, _width, _buttonH], _label, "", _theme, {
            params ["_text", "_class", "_tree", "_choice"];

            call FUNC(closePopover);

            [_text, _class, _tree, _choice] call FUNC(applyClassImport);
        }, [_text, _class, _tree, _choice], _enabled, _style] call FUNC(uiAction);

        _cursorY = _cursorY + _buttonH + UNIT * 0.3;
    } forEach [
        [format [LLSTRING(ImportChoice_Selected), _class], "selected", _one, ["", "accent"] select _one],
        [format [LLSTRING(ImportChoice_Named), _known], "named", true, ["accent", ""] select _one]
    ];

    private _cancelW = SQUARE(UNIT * 6);

    [_display, _inner, [_width - _cancelW, _height - _buttonH, _cancelW, _buttonH], LLSTRING(Cancel), "", _theme, {
        call FUNC(closePopover);
    }, [], true, "ghost"] call FUNC(uiAction);
}, [_text, _class, _tree, _known, _first, _named]] call FUNC(popover);
