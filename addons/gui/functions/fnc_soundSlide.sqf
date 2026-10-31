#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Drags a volume slider of the dropdown under the speaker in the header (fnc_openSoundMenu). A press on a slider
 * ("begin") sets the volume where the mouse is and, for as long as the button is held, the display's
 * MouseMoving and MouseHolding follow the mouse - along the whole screen, not only over the slider - until the
 * release (MouseButtonUp) takes the three handlers off again. Nothing runs while no slider is held. The volume
 * is the mouse's place along the track, 0 at its left end to 1 at its right end, in steps of SOUND_STEP (5 %) - the ends are
 * the ends (fnc_soundSet). The mouse is read with getMousePosition at the press and at every move, in the space the track's
 * place is given in: the arguments of the control's press and of the display's move were not in it (0.5.7 gave only 0 and
 * 100 %). Letting go plays a sample of the kind, so the player hears what he set.
 *
 * Arguments (begin):
 * 0: "begin" <STRING>
 * 1: Array of:
 *    0: Display <DISPLAY>
 *    1: Which volume: an index of einv_gui_soundGroups <NUMBER>
 *    2: The slider's left end on the screen <NUMBER>
 *    3: Its width <NUMBER>
 *    4: The mouse's x, only the press's own - the mouse is read again here <NUMBER> (default: 0)
 *
 * Arguments (move, up, end):
 * 0: "move", "up" or "end" <STRING>
 * 1: The display event's arguments (move, up) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["begin", [_display, 2, 0.4, 0.2, 0.45]] call einv_gui_fnc_soundSlide;
 *
 * Public: No
 */

disableSerialization;

params [["_what", "", [""]], ["_argument", []]];

// The volume of the mouse's place, in whole steps; the same place is asked at the press and at every move.
private _fnc_set = {
    params ["_state"];
    _state params ["", "_index", "_left", "_width"];

    private _mouseX = (getMousePosition) select 0;
    private _place = (((_mouseX - _left) / (_width max pixelW)) max 0) min 1;

    ["volume", [_index, (round (_place * (1 / SOUND_STEP))) * SOUND_STEP]] call FUNC(soundSet);
};

if (_what isEqualTo "move") exitWith {
    private _state = uiNamespace getVariable [QGVAR(soundSlideState), []];

    if (_state isEqualTo []) exitWith {};

    [_state] call _fnc_set;
};

if (_what isEqualTo "end" || {_what isEqualTo "up"}) exitWith {
    // Only the left button ends it.
    if (_what isEqualTo "up" && {(_argument param [1, 0]) != 0}) exitWith {};

    private _state = uiNamespace getVariable [QGVAR(soundSlideState), []];

    if (_state isEqualTo []) exitWith {};

    uiNamespace setVariable [QGVAR(soundSlideState), []];

    _state params ["_display", "_index", "", "", "_ids"];

    if (!isNull _display) then {
        _display displayRemoveEventHandler ["MouseMoving", _ids select 0];
        _display displayRemoveEventHandler ["MouseHolding", _ids select 1];
        _display displayRemoveEventHandler ["MouseButtonUp", _ids select 2];
    };

    // A sample of what was set: a rifle lifted, a magazine loaded, the container that is looted opened or searched,
    // an item inspected.
    private _sample = [
        ["lift", "arifle_MX_F"], ["loadMag", "30Rnd_65x39_caseless_mag"], ["open", ""], ["search", ""], ["inspect", "arifle_MX_F"]
    ] param [_index, ["lift", "arifle_MX_F"]];

    _sample params ["_action", "_class"];

    [_action, _class, GVAR(openedOn), false] call FUNC(playSound);
};

// ----- A press on a slider -----
if (_what isEqualTo "begin") exitWith {
    _argument params ["_display", "_index", "_left", "_width"];

    // One at a time.
    ["end"] call FUNC(soundSlide);

    if (isNull _display) exitWith {};

    private _ids = [
        _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(soundSlide); false}],
        _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(soundSlide); false}],
        _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(soundSlide); false}]
    ];

    private _state = [_display, _index, _left, _width, _ids];

    uiNamespace setVariable [QGVAR(soundSlideState), _state];

    [_state] call _fnc_set;
};
