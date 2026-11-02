#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Drags a slider of the size popover under its button in the header (fnc_openSizeMenu), as fnc_soundSlide drags a volume: a press
 * on a slider ("begin") sets the size where the mouse is and, for as long as the button is held, the display's MouseMoving and
 * MouseHolding follow the mouse along the whole screen until the release (MouseButtonUp) takes the three handlers off again. The
 * size is the mouse's place along the track, the slider's least at its left end to its most at its right end, in its steps
 * (fnc_sizeSet). The window is built again under the popover while the slider moves; the display and its handlers stay, and the
 * popover is made again at the same place (fnc_build), so the drag goes on. Letting go writes the size to CBA ("commit").
 *
 * Arguments (begin):
 * 0: "begin" <STRING>
 * 1: Array of:
 *    0: Display <DISPLAY>
 *    1: Which size: an index of fnc_sizeDefs <NUMBER>
 *    2: The track's left end on the screen <NUMBER>
 *    3: Its width <NUMBER>
 *
 * Arguments (move, up, end):
 * 0: "move", "up" or "end" <STRING>
 * 1: The display event's arguments (move, up) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["begin", [_display, 0, 0.4, 0.2]] call aio_gui_fnc_sizeSlide;
 *
 * Public: No
 */

disableSerialization;

params [["_what", "", [""]], ["_argument", []]];

// The size of the mouse's place; the same place is asked at the press and at every move.
private _fnc_set = {
    params ["_state"];
    _state params ["", "_index", "_left", "_width"];

    ((call FUNC(sizeDefs)) param [_index, []]) params ["", "", "", ["_least", 0], ["_most", 1]];

    private _mouseX = (getMousePosition) select 0;
    private _place = (((_mouseX - _left) / (_width max pixelW)) max 0) min 1;

    ["value", [_index, _least + (_most - _least) * _place]] call FUNC(sizeSet);
};

if (_what isEqualTo "move") exitWith {
    private _state = uiNamespace getVariable [QGVAR(sizeSlideState), []];

    if (_state isEqualTo []) exitWith {};

    [_state] call _fnc_set;
};

if (_what isEqualTo "end" || {_what isEqualTo "up"}) exitWith {
    // Only the left button ends it.
    if (_what isEqualTo "up" && {(_argument param [1, 0]) != 0}) exitWith {};

    private _state = uiNamespace getVariable [QGVAR(sizeSlideState), []];

    if (_state isEqualTo []) exitWith {};

    uiNamespace setVariable [QGVAR(sizeSlideState), []];

    _state params ["_display", "", "", "", "_ids"];

    if (!isNull _display) then {
        _display displayRemoveEventHandler ["MouseMoving", _ids select 0];
        _display displayRemoveEventHandler ["MouseHolding", _ids select 1];
        _display displayRemoveEventHandler ["MouseButtonUp", _ids select 2];
    };

    ["commit"] call FUNC(sizeSet);
};

// ----- A press on a slider -----
if (_what isEqualTo "begin") exitWith {
    _argument params ["_display", "_index", "_left", "_width"];

    // One at a time.
    ["end"] call FUNC(sizeSlide);

    if (isNull _display) exitWith {};

    private _ids = [
        _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(sizeSlide); false}],
        _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(sizeSlide); false}],
        _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(sizeSlide); false}]
    ];

    private _state = [_display, _index, _left, _width, _ids];

    uiNamespace setVariable [QGVAR(sizeSlideState), _state];

    [_state] call _fnc_set;
};
