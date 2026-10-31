#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The colour picker of fnc_openColourPicker at work: a press on its square or its hue strip, the mouse moving while it is
 * held, and showing the colour picked - the square's hue, the two rings, the swatch and the hex digits.
 *   "begin"  a press on the square or the strip (the hit area as argument): picks there and follows the mouse
 *   "move"   the mouse moved while held: picks where it is now
 *   "up"     a button came up: the left one ends it
 *   "show"   puts the picker's controls where the colour picked says
 *
 * Arguments:
 * 0: What happened <STRING>
 * 1: The hit area pressed ("begin"), the event's arguments ("up") <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["show"] call aio_setup_fnc_colourPickerSlide;
 *
 * Public: No
 */

disableSerialization;

params [["_what", "", [""]], ["_argument", []]];

private _state = uiNamespace getVariable [QGVAR(colourPick), createHashMap];

if (count _state == 0) exitWith {};

// The colour picked shows: the square in its hue, the rings in place, the swatch and the digits.
private _fnc_show = {
    private _controls = _state getOrDefault ["controls", createHashMap];

    (_state get "hsv") params ["_hue", "_saturation", "_value"];
    (_state getOrDefault ["geometry", []]) params ["_pickW", "_pickH", "_stripW", "_gap", "_knobW", "_knobH"];

    private _base = _controls getOrDefault ["base", controlNull];

    if (isNull _base) exitWith {};

    private _rgb = ["rgb", [_hue, _saturation, _value]] call EFUNC(gui,hsv);

    _base ctrlSetBackgroundColor ((["rgb", [_hue, 1, 1]] call EFUNC(gui,hsv)) + [1]);

    private _squareKnob = _controls get "squareKnob";
    _squareKnob ctrlSetPosition [_saturation * _pickW - _knobW / 2, (1 - _value) * _pickH - _knobH / 2];
    _squareKnob ctrlCommit 0;

    private _hueKnob = _controls get "hueKnob";
    _hueKnob ctrlSetPosition [_pickW + _gap + (_stripW - _knobW) / 2, _hue * _pickH - _knobH / 2];
    _hueKnob ctrlCommit 0;

    (_controls get "preview") ctrlSetBackgroundColor (_rgb + [1]);

    private _edit = _controls get "edit";

    if (focusedCtrl (ctrlParent _edit) isNotEqualTo _edit) then {
        _edit ctrlSetText (([_rgb] call FUNC(hex)) select [1]);
    };
};

// Where the mouse is, as a share of the square or the strip.
private _fnc_pick = {
    private _hit = _state getOrDefault ["held", controlNull];

    if (isNull _hit) exitWith {};

    ([_hit] call FUNC(screenRect)) params ["_left", "_top", "_width", "_height"];
    getMousePosition params ["_mouseX", "_mouseY"];

    private _across = (((_mouseX - _left) / (_width max pixelW)) max 0) min 1;
    private _down = (((_mouseY - _top) / (_height max pixelH)) max 0) min 1;
    private _hsv = _state get "hsv";

    if ((_hit getVariable [QGVAR(pickKind), ""]) isEqualTo "hue") then {
        _hsv set [0, _down min 0.999];
    } else {
        _hsv set [1, _across];
        _hsv set [2, 1 - _down];
    };

    call _fnc_show;
};

switch (_what) do {
    case "show": {call _fnc_show};
    case "move": {
        // The popover closed while the picker was held: the display stops following the mouse.
        if (isNull (_state getOrDefault ["held", controlNull])) exitWith {
            ["end"] call FUNC(colourPickerSlide);
        };

        call _fnc_pick;
    };
    case "begin": {
        ["end"] call FUNC(colourPickerSlide);

        private _display = ctrlParent _argument;

        _state set ["held", _argument];
        _state set ["handlers", [
            _display,
            _display displayAddEventHandler ["MouseMoving", {["move"] call FUNC(colourPickerSlide); false}],
            _display displayAddEventHandler ["MouseHolding", {["move"] call FUNC(colourPickerSlide); false}],
            _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(colourPickerSlide); false}]
        ]];

        call _fnc_pick;
    };
    case "up";
    case "end": {
        if (_what isEqualTo "up" && {(_argument param [1, 0]) != 0}) exitWith {};

        (_state getOrDefault ["handlers", []]) params [["_display", displayNull], "_moving", "_holding", "_up"];

        if (!isNull _display) then {
            _display displayRemoveEventHandler ["MouseMoving", _moving];
            _display displayRemoveEventHandler ["MouseHolding", _holding];
            _display displayRemoveEventHandler ["MouseButtonUp", _up];
        };

        _state set ["handlers", []];
        _state set ["held", controlNull];
    };
};
