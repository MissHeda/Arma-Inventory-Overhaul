#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates the hit area of a widget: a button with no look of its own over what the widget drew. Its
 * surface lights up while the mouse is on it, and a click hands the code to fnc_defer, which runs it a
 * moment later - it may redraw the wizard, and with it delete this very control.
 *
 * Unlike the inventory's buttons (aio_gui_fnc_uiButton) nothing here waits for CBA's next frame: that
 * never comes in Eden.
 *
 * A disabled one still shows its tooltip - a disabled control would not - but does nothing.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Surface: the controls that light up - rectangles take the colour as background, round corners as
 *    their text colour <ARRAY> (default: [])
 * 4: Surface colour <ARRAY> (default: [])
 * 5: Surface colour under the mouse <ARRAY> (default: [])
 * 6: Code, called a moment later with the arguments as _this <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Enabled <BOOL> (default: true)
 * 9: Tooltip, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The hit area <CONTROL>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.03], _surface, [1, 1, 1, 0.08], [1, 1, 1, 0.12], {systemChat "Hello"}] call aio_setup_fnc_uiHit;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect",
    ["_surface", [], [[]]], ["_normal", [], [[]]], ["_hover", [], [[]]],
    ["_code", {}, [{}]], ["_arguments", []], ["_enabled", true, [true]], ["_tooltip", "", [""]]
];

private _hit = [_display, "AIO_Hitbox", _parent, _rect] call EFUNC(gui,uiCreate);
_hit setVariable [QGVAR(surface), [_surface, _normal, _hover]];
_hit setVariable [QGVAR(action), [_code, _arguments]];

if (_tooltip isNotEqualTo "") then {
    _hit ctrlSetTooltip _tooltip;
};

if (!_enabled) exitWith {_hit};

// Rectangles take the colour as their background, round corners - pictures - as their text colour.
_hit ctrlAddEventHandler ["MouseEnter", {
    params ["_hit"];

    (_hit getVariable [QGVAR(surface), [[], [], []]]) params ["_surface", "", "_color"];

    if (_color isEqualTo []) exitWith {};

    {
        if (ctrlClassName _x isEqualTo "AIO_PanelCorner") then {
            _x ctrlSetTextColor _color;
        } else {
            _x ctrlSetBackgroundColor _color;
        };
    } forEach _surface;
}];

_hit ctrlAddEventHandler ["MouseExit", {
    params ["_hit"];

    (_hit getVariable [QGVAR(surface), [[], [], []]]) params ["_surface", "_color"];

    if (_color isEqualTo []) exitWith {};

    {
        if (ctrlClassName _x isEqualTo "AIO_PanelCorner") then {
            _x ctrlSetTextColor _color;
        } else {
            _x ctrlSetBackgroundColor _color;
        };
    } forEach _surface;
}];

_hit ctrlAddEventHandler ["ButtonClick", {
    params ["_hit"];

    (_hit getVariable [QGVAR(action), [{}, []]]) params ["_code", "_arguments"];

    [_code, _arguments] call FUNC(defer);
}];

_hit
