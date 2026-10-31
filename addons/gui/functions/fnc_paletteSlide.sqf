#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Drags a picker of the palette popover (fnc_openPaletteMenu), as fnc_soundSlide drags a volume: the colour square, the hue strip
 * beside it or one of the two transparency sliders (the panels' and the item tiles'). A press on one ("begin") sets the value where the mouse is and, for as long as the button
 * is held, the display's MouseMoving and MouseHolding follow the mouse - along the whole screen, not only over the picker - until
 * the release (MouseButtonUp) takes the three handlers off again. Nothing runs while no picker is held. The place of the mouse in
 * the picker's rectangle, 0 at its left or top edge to 1 at its right or bottom edge and kept inside, goes to fnc_paletteSet,
 * which rounds it to the picker's steps and does nothing when the value is the same. The mouse is read with getMousePosition at
 * the press and at every move, in the space the picker's place is given in.
 *
 *   "alpha"   the panels' transparency slider: the place across (fnc_paletteSet "alpha")
 *   "tileAlpha"  the item tiles' transparency slider: the place across (fnc_paletteSet "tileAlpha")
 *   "hue"     the strip: the place down (fnc_paletteSet "hue")
 *   "square"  the colour square: the place across and down (fnc_paletteSet "square")
 *
 * The drag survives the window being built again for the new colour (fnc_build makes the popover again at its end): the handlers
 * are the display's, and the picker's place on the screen is kept in the state, so a hit area deleted under the mouse changes
 * nothing.
 *
 * Arguments (begin):
 * 0: "begin" <STRING>
 * 1: Array of:
 *    0: Display <DISPLAY>
 *    1: Which picker, "alpha", "tileAlpha", "hue" or "square" <STRING>
 *    2: Which colour, 0 accent, 1 secondary, 2 panels, 3 cells, 4 tiles, 5 text, 6 lines (not read for the sliders) <NUMBER>
 *    3: The picker's place on the screen [left, top, width, height] <ARRAY>
 *
 * Arguments (move, up, end):
 * 0: "move", "up" or "end" <STRING>
 * 1: The display event's arguments (move, up) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["begin", [_display, "square", 0, [0.4, 0.2, 0.1, 0.1]]] call aio_gui_fnc_paletteSlide;
 *
 * Public: No
 */

disableSerialization;

params [["_what", "", [""]], ["_argument", []]];

// The place of the mouse in the picker, asked at the press and at every move.
private _fnc_set = {
    params ["_state"];
    _state params ["", "_kind", "_which", "_rect"];
    _rect params ["_left", "_top", "_width", "_height"];

    getMousePosition params ["_mouseX", "_mouseY"];

    private _across = (((_mouseX - _left) / (_width max pixelW)) max 0) min 1;
    private _down = (((_mouseY - _top) / (_height max pixelH)) max 0) min 1;

    switch (_kind) do {
        case "alpha";
        case "cellAlpha";
        case "tileAlpha";
        case "secondaryAlpha";
        case "linesAlpha": {[_kind, _across] call FUNC(paletteSet)};
        case "hue": {["hue", [_which, _down]] call FUNC(paletteSet)};
        case "square": {["square", [_which, _across, _down]] call FUNC(paletteSet)};
    };
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

// ----- A press on a picker -----
if (_what isEqualTo "begin") exitWith {
    _argument params ["_display", "_kind", "_which", "_rect"];

    // One at a time.
    ["end"] call FUNC(paletteSlide);

    if (isNull _display) exitWith {};

    private _ids = [
        _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(paletteSlide); false}],
        _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(paletteSlide); false}],
        _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(paletteSlide); false}]
    ];

    // The state: the display, which picker, which colour, its place on the screen, and the handlers' ids.
    private _state = [_display, _kind, _which, _rect, _ids];

    uiNamespace setVariable [QGVAR(paletteSlideState), _state];

    [_state] call _fnc_set;
};
