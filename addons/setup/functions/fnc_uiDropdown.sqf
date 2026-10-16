#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a drop-down: a film showing the choice made, with a chevron. A click opens the choices in a
 * popover below it (fnc_popover), the one made ticked; picking one closes it and runs the code a moment
 * later with that choice's value (fnc_defer). With nothing to choose from it shows the placeholder.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Choices, [[label, value], ...] <ARRAY>
 * 4: Value of the choice made <ANY>
 * 5: Theme <HASHMAP>
 * 6: Code, called with [new value, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Enabled <BOOL> (default: true)
 * 9: Shown while no choice is made <STRING> (default: "")
 *
 * Return Value:
 * The controls, the hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.15, 0.03], [["Default", "default"], ["Realism", "realism"]], "default", _theme, {params ["_value"]}] call einv_setup_fnc_uiDropdown;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_options", [], [[]]], ["_value", ""], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_enabled", true, [true]], ["_placeholder", "", [""]]
];
_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _index = _options findIf {(_x select 1) isEqualTo _value};
private _label = _placeholder;

if (_index >= 0) then {
    _label = (_options select _index) select 0;
};

private _ink = _theme getOrDefault [["muted", "text"] select (_index >= 0), [1, 1, 1, 1]];

_enabled = _enabled && {_options isNotEqualTo []};

if (!_enabled) then {
    _ink = DISABLED_INK;
};

private _fill = [DISABLED_FILL, _theme getOrDefault ["button", [1, 1, 1, 0.08]]] select _enabled;
private _controls = [_display, _parent, _rect, _fill, (_theme getOrDefault ["radius", 0]) min (_height / 2)] call EFUNC(gui,uiPanel);
private _surface = +_controls;
private _pad = SQUARE(_height * 0.3);
private _iconH = _height * 0.5;
private _iconW = SQUARE(_iconH);
private _size = _height * 0.5;
private _textW = _width - _pad * 3 - _iconW;

_controls pushBack ([
    _display, _parent, [_left + _pad, _top, _textW, _height], [_label, _textW, _font, _size] call EFUNC(gui,fitText), _size, _ink, _font, 0
] call EFUNC(gui,uiLabel));

_controls pushBack ([
    _display, _parent, [_left + _width - _pad - _iconW, _top + (_height - _iconH) / 2, _iconW, _iconH],
    UI_TEX(icon_chevron_down_ca), [DISABLED_INK, _theme getOrDefault ["buttonText", [0.88, 0.88, 0.88, 1]]] select _enabled
] call EFUNC(gui,uiIcon));

private _hit = [_display, _parent, _rect, _surface, _fill, _theme getOrDefault ["buttonHover", [1, 1, 1, 0.12]], {}, [], _enabled] call FUNC(uiHit);

// The list opens below the drop-down as it is on the screen now, worked out from the hit area itself.
_hit setVariable [QGVAR(action), [{
    params ["_hit", "_options", "_value", "_code", "_arguments"];

    private _display = uiNamespace getVariable [QGVAR(display), displayNull];

    if (isNull _display || {isNull _hit}) exitWith {};

    private _rect = [_hit] call FUNC(screenRect);
    private _rowH = UNIT * 1.1;
    private _shown = (count _options) min 10;
    private _width = ((_rect select 2) - SQUARE(UNIT * 1.2)) max SQUARE(UNIT * 6);

    [_display, _rect, [_width, _shown * _rowH], "", {
        params ["_display", "_inner", "_theme", "_arguments"];
        _arguments params ["_options", "_value", "_code", "_codeArguments", "_rowH"];

        (ctrlPosition _inner) params ["", "", "_width", "_height"];

        private _font = _theme getOrDefault ["font", "PuristaMedium"];
        private _list = _inner;
        private _rowW = _width;

        // More than fit: the rows scroll.
        if (count _options > 10) then {
            _list = [_display, "EINV_ScrollGroup", _inner, [0, 0, _width, _height]] call EFUNC(gui,uiCreate);
            _rowW = _width - SCROLL_W - pixelW * 2;
        };

        {
            _x params ["_label", "_optionValue"];

            private _rowY = _forEachIndex * _rowH;
            private _picked = _optionValue isEqualTo _value;
            private _checkH = _rowH * 0.5;
            private _textX = SQUARE(_rowH * 0.9);
            private _surface = [_display, _list, [0, _rowY, _rowW, _rowH], [0, 0, 0, 0], (_theme getOrDefault ["radius", 0]) min (_rowH / 2)] call EFUNC(gui,uiPanel);

            if (_picked) then {
                [_display, _list, [SQUARE(_rowH * 0.25), _rowY + (_rowH - _checkH) / 2, SQUARE(_checkH), _checkH], UI_TEX(icon_check_ca), _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] call EFUNC(gui,uiIcon);
            };

            [
                _display, _list, [_textX, _rowY, _rowW - _textX, _rowH], [_label, _rowW - _textX, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY,
                _theme getOrDefault [["text2", "text"] select _picked, [1, 1, 1, 1]], _font, 0
            ] call EFUNC(gui,uiLabel);

            [_display, _list, [0, _rowY, _rowW, _rowH], _surface, [0, 0, 0, 0], [1, 1, 1, 0.1], {
                params ["_code", "_value", "_arguments"];

                call FUNC(closePopover);
                [_value, _arguments] call _code;
            }, [_code, _optionValue, _codeArguments]] call FUNC(uiHit);
        } forEach _options;
    }, [_options, _value, _code, _arguments, _rowH]] call FUNC(popover);
}, [_hit, _options, _value, _code, _arguments]]];

_controls pushBack _hit;

_controls
