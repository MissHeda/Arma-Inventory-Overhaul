#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Drags a slider of the palette popover (fnc_openPaletteMenu), as fnc_soundSlide drags a volume. A press on a slider
 * ("begin") sets the value where the mouse is and, for as long as the button is held, the display's MouseMoving and
 * MouseHolding follow the mouse - along the whole screen, not only over the slider - until the release (MouseButtonUp)
 * takes the three handlers off again. Nothing runs while no slider is held. The place along the track, 0 at its left end to 1
 * at its right end, goes to fnc_paletteSet, which rounds it to the slider's steps and does nothing when the value is the
 * same. The mouse is read with getMousePosition at the press and at every move, in the space the track's place is given in.
 *
 * The drag survives the window being built again for the new colour (fnc_build makes the popover again at its end): the handlers
 * are the display's, and the track's place on the screen is kept in the state, so a hit area deleted under the mouse changes
 * nothing.
 *
 * Arguments (begin):
 * 0: "begin" <STRING>
 * 1: Array of:
 *    0: Display <DISPLAY>
 *    1: Which slider, 0 to 4 as in fnc_paletteSet <NUMBER>
 *    2: The slider's left end on the screen <NUMBER>
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
 * ["begin", [_display, 1, 0.4, 0.2]] call einv_gui_fnc_paletteSlide;
 *
 * Public: No
 */

disableSerialization;

params [["_what", "", [""]], ["_argument", []]];

// The place of the mouse along the track, asked at the press and at every move.
private _fnc_set = {
    params ["_state"];
    _state params ["", "_index", "_left", "_width"];

    private _mouseX = (getMousePosition) select 0;
    private _place = (((_mouseX - _left) / (_width max pixelW)) max 0) min 1;

    ["slider", [_index, _place]] call FUNC(paletteSet);
};

if (_what isEqualTo "move") exitWith {
    private _state = uiNamespace getVariable [QGVAR(paletteSlideState), []];

    if (_state isEqualTo []) exitWith {};

    [_state] call _fnc_set;
};

if (_what isEqualTo "end" || {_what isEqualTo "up"}) exitWith {
    // Only the left button ends it.
    if (_what isEqualTo "up" && {(_argument param [1, 0]) != 0}) exitWith {};

    private _state = uiNamespace getVariable [QGVAR(paletteSlideState), []];

    if (_state isEqualTo []) exitWith {};

    uiNamespace setVariable [QGVAR(paletteSlideState), []];

    _state params ["_display", "", "", "", "_ids"];

    if (!isNull _display) then {
        _display displayRemoveEventHandler ["MouseMoving", _ids select 0];
        _display displayRemoveEventHandler ["MouseHolding", _ids select 1];
        _display displayRemoveEventHandler ["MouseButtonUp", _ids select 2];
    };
};

// ----- A press on a slider -----
if (_what isEqualTo "begin") exitWith {
    _argument params ["_display", "_index", "_left", "_width"];

    // One at a time.
    ["end"] call FUNC(paletteSlide);

    if (isNull _display) exitWith {};

    private _ids = [
        _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(paletteSlide); false}],
        _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(paletteSlide); false}],
        _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(paletteSlide); false}]
    ];

    private _state = [_display, _index, _left, _width, _ids];

    uiNamespace setVariable [QGVAR(paletteSlideState), _state];

    [_state] call _fnc_set;
};
