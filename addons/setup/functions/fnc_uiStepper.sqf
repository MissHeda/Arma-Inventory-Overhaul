#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a number to step up and down: a minus on the left, the value in the middle, a plus on the
 * right, on one film. A click changes the value shown at once and runs the code a moment later with the
 * new value (fnc_defer), never past the ends. With a fourth number in the range, a click with Shift held
 * steps by that one instead.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Value <NUMBER>
 * 4: [lowest, highest, step, step with Shift held (default: the step)] <ARRAY>
 * 5: Theme <HASHMAP>
 * 6: Code, called with [new value, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: How the value is written, %1 for it <STRING> (default: "%1")
 * 9: Enabled <BOOL> (default: true)
 * 10: Tooltip of the two buttons, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The controls, the plus's hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.03], 5, [1, 50, 1], _theme, {params ["_cell"]; systemChat str _cell}] call einv_setup_fnc_uiStepper;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_value", 0, [0]], ["_range", [0, 100, 1], [[]]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_format", "%1", [""]], ["_enabled", true, [true]],
    ["_tooltip", "", [""]]
];
_rect params ["_left", "_top", "_width", "_height"];
_range params [["_min", 0, [0]], ["_max", 100, [0]], ["_step", 1, [0]], ["_big", 0, [0]]];

if (_big <= 0) then {
    _big = _step;
};

private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _ink = [DISABLED_INK, _theme getOrDefault ["text", [1, 1, 1, 1]]] select _enabled;
private _radius = (_theme getOrDefault ["radius", 0]) min (_height / 2);
private _controls = [_display, _parent, _rect, [DISABLED_FILL, _theme getOrDefault ["button", [1, 1, 1, 0.08]]] select _enabled, _radius] call EFUNC(gui,uiPanel);

private _buttonW = SQUARE(_height);
private _label = [
    _display, _parent, [_left + _buttonW, _top, _width - _buttonW * 2, _height],
    format [_format, _value, "%"], _height * 0.52, _ink, _fontBold, 2
] call EFUNC(gui,uiLabel);

_label setVariable [QGVAR(stepper), [_value, _min, _max, _step, _format, _code, _arguments, _big]];
_controls pushBack _label;

{
    _x params ["_direction", "_icon", "_buttonX"];

    private _canGo = _enabled && {[_value > _min, _value < _max] select (_direction > 0)};
    private _iconH = _height * 0.5;

    // What lights up under the mouse is the button's own square of the film, under its icon.
    private _surface = [_display, _parent, [_buttonX, _top, _buttonW, _height], [0, 0, 0, 0], _radius] call EFUNC(gui,uiPanel);

    _controls append _surface;
    _controls pushBack ([
        _display, _parent, [_buttonX + (_buttonW - SQUARE(_iconH)) / 2, _top + (_height - _iconH) / 2, SQUARE(_iconH), _iconH], _icon,
        [DISABLED_INK, _theme getOrDefault ["buttonText", [0.88, 0.88, 0.88, 1]]] select _canGo
    ] call EFUNC(gui,uiIcon));

    private _hit = [_display, _parent, [_buttonX, _top, _buttonW, _height], _surface, [0, 0, 0, 0], [1, 1, 1, 0.06], {}, [], _enabled, _tooltip] call FUNC(uiHit);

    _hit setVariable [QGVAR(stepperLabel), _label];
    _hit setVariable [QGVAR(direction), _direction];

    if (_enabled) then {
        // Shift is only known as the button goes down: the click itself does not say.
        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_hit", "", "", "", "_shift"];

            _hit setVariable [QGVAR(shift), _shift];
        }];

        _hit ctrlAddEventHandler ["ButtonClick", {
            params ["_hit"];

            private _label = _hit getVariable [QGVAR(stepperLabel), controlNull];

            (_label getVariable [QGVAR(stepper), []]) params [
                ["_value", 0], ["_min", 0], ["_max", 0], ["_step", 1], ["_format", "%1"], ["_code", {}], ["_arguments", []], ["_big", 1]
            ];

            private _by = [_step, _big] select (_hit getVariable [QGVAR(shift), false]);

            _hit setVariable [QGVAR(shift), false];

            private _new = ((_value + (_hit getVariable [QGVAR(direction), 1]) * _by) max _min) min _max;

            if (_new == _value) exitWith {};

            _label setVariable [QGVAR(stepper), [_new, _min, _max, _step, _format, _code, _arguments, _big]];
            _label ctrlSetText format [_format, _new, "%"];

            [_code, [_new, _arguments]] call FUNC(defer);
        }];
    };

    _controls pushBack _hit;
} forEach [
    [-1, ICON(icon_minus_ca,icon_chevron_left_ca), _left],
    [1, ICON(icon_plus_ca,icon_chevron_right_ca), _left + _width - _buttonW]
];

_controls
