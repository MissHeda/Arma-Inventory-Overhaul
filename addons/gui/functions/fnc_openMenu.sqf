#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens a context menu at the mouse: a card with a row per choice. A click on a row closes the menu and
 * runs its code; a left click anywhere else only closes it (a hit area over the whole screen, under the
 * menu). A right click beside the menu closes it as well, but is then worked out as a right click of its
 * own (fnc_onMouseButton), so that the next tile's menu opens in the same go. Kept on the screen whatever
 * corner the mouse is in.
 *
 * A choice may bring options as a fourth element, a HashMap - the options of other mods' context menus
 * (fnc_cbaOptions) use them:
 *   "icon"      - a picture before the text; every row's text moves over for it when any row has one
 *   "color"     - the text's colour, [] for the usual
 *   "tooltip"   - shown while the mouse rests on the row
 *   "enabled"   - false: greyed out, and a click on it does nothing - the menu stays open
 *   "separator" - true: a line above the row, setting it apart from the rows before
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Choices [[text, arguments, code, options (optional)], ...] <ARRAY>
 * 2: Where to open it [x, y], [] for the mouse <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [["Drop", [0, 3], {_this call einv_gui_fnc_dropToGround}]]] call einv_gui_fnc_openMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_choices", ["_at", [], [[]]]];

call FUNC(closeMenu);

// The name at the mouse would sit under it - and so would the comparison card (fnc_drawCompare).
(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;
ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

if (_choices isEqualTo []) exitWith {};

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _size = UNIT * 0.66;
private _rowH = UNIT * 1.15;
private _padY = UNIT * 0.2;
private _padX = SQUARE(UNIT * 0.45);
private _width = SQUARE(UNIT * 6);
private _iconH = _rowH * 0.6;

private _fnc_options = {
    private _options = _this param [3, createHashMap];

    [createHashMap, _options] select (_options isEqualType createHashMap)
};

// Room for a picture before every row's text once one row has one, so the texts stay in line.
private _hasIcons = _choices findIf {((_x call _fnc_options) getOrDefault ["icon", ""]) isNotEqualTo ""} >= 0;
private _textX = [0, SQUARE(_iconH) + SQUARE(UNIT * 0.3)] select _hasIcons;

{
    _width = _width max (((_x select 0) getTextWidth [_font, _size]) * TEXT_SLACK + _padX * 2 + _textX);
} forEach _choices;

private _height = count _choices * _rowH + _padY * 2;

([_at, getMousePosition] select (_at isEqualTo [])) params ["_mouseX", "_mouseY"];

private _left = _mouseX min (safezoneX + safezoneW - _width);
private _top = _mouseY min (safezoneY + safezoneH - _height);
private _controls = [];

// Under the menu, over everything else: a click beside the menu closes it.
private _catcher = [_display, "EINV_Hitbox", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);
_catcher ctrlAddEventHandler ["ButtonClick", {[{call FUNC(closeMenu)}] call FUNC(later)}];
_controls pushBack _catcher;

_controls append ([
    _display, controlNull, [_left, _top, _width, _height],
    [0.075, 0.083, 0.1, 0.97], _theme getOrDefault ["radius", 0], [1, 1, 1, 0.14]
] call FUNC(uiPanel));

{
    _x params ["_text", "_arguments", "_code"];

    private _options = _x call _fnc_options;
    private _enabled = _options getOrDefault ["enabled", true];
    private _rowTop = _top + _padY + _forEachIndex * _rowH;

    if (_options getOrDefault ["separator", false]) then {
        _controls append ([
            _display, controlNull, [_left + _padX * 0.3, _rowTop, _width - _padX * 0.6, pixelH],
            _theme getOrDefault ["line", [1, 1, 1, 0.07]]
        ] call FUNC(uiPanel));
    };

    private _surface = [_display, "EINV_PanelRect", controlNull, [_left + _padX * 0.3, _rowTop, _width - _padX * 0.6, _rowH]] call FUNC(uiCreate);
    _surface ctrlSetBackgroundColor [0, 0, 0, 0];
    _controls pushBack _surface;

    private _icon = _options getOrDefault ["icon", ""];

    if (_icon isNotEqualTo "") then {
        _controls pushBack ([
            _display, controlNull, [_left + _padX, _rowTop + (_rowH - _iconH) / 2, SQUARE(_iconH), _iconH], _icon,
            [[1, 1, 1, 0.4], [1, 1, 1, 1]] select _enabled
        ] call FUNC(uiPicture));
    };

    private _color = _options getOrDefault ["color", []];

    if !(_color isEqualType [] && {count _color >= 3}) then {
        _color = _theme getOrDefault ["text", [1, 1, 1, 1]];
    };

    if (!_enabled) then {
        _color = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];
    };

    _controls pushBack ([_display, controlNull, [_left + _padX + _textX, _rowTop, _width - _padX * 2 - _textX, _rowH], _text, _size, _color, _font, 0] call FUNC(uiLabel));

    // A greyed-out row takes the click, so it closes nothing and runs nothing.
    private _hit = [_display, "EINV_Hitbox", controlNull, [_left, _rowTop, _width, _rowH]] call FUNC(uiCreate);
    private _tooltip = _options getOrDefault ["tooltip", ""];

    if (_tooltip isEqualType "" && {_tooltip isNotEqualTo ""}) then {
        _hit ctrlSetTooltip _tooltip;
    };

    if (_enabled) then {
        _hit setVariable [QGVAR(surface), _surface];
        _hit setVariable [QGVAR(choice), [_arguments, _code]];
        _hit ctrlAddEventHandler ["MouseEnter", {((_this select 0) getVariable [QGVAR(surface), controlNull]) ctrlSetBackgroundColor [1, 1, 1, 0.1]}];
        _hit ctrlAddEventHandler ["MouseExit", {((_this select 0) getVariable [QGVAR(surface), controlNull]) ctrlSetBackgroundColor [0, 0, 0, 0]}];
        _hit ctrlAddEventHandler ["ButtonClick", {
            private _choice = (_this select 0) getVariable [QGVAR(choice), [[], {}]];

            // A frame later: the menu goes first, and a control must not be deleted inside its own event.
            // Through fnc_later, which also runs in the Eden editor.
            [{
                call FUNC(closeMenu);
                (_this select 0) call (_this select 1);
            }, _choice] call FUNC(later);
        }];
    };

    _controls pushBack _hit;
} forEach _choices;

uiNamespace setVariable [QGVAR(menu), _controls];

// Where it lies, so that a right click on it is told from one beside it (fnc_onMouseButton).
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];
