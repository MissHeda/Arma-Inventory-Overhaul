#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns the title bar of a popup window into a handle to drag it by: press on the bar and move, and the
 * whole window follows the mouse; let go and it stays. Two forms:
 *
 *   attach  - [display, moved, rect, kind, tint rect, parent] makes the handle: a button no one sees, laid
 *             over the given rectangle of the window's controls group (make it after the title and before
 *             the buttons that sit on the bar, so those stay clickable). The press and the movement are
 *             taken from here on.
 *   begin   - ["begin", [display, moved, handle, mouse, kind, tint]] starts a drag at once, for a display
 *             whose controls do not hear the mouse themselves (ACE Arsenal's): the caller finds the press
 *             on its own and hands the controls over.
 *
 * Nothing runs while no window is dragged. A press starts a drag; for as long as it lasts the display's
 * MouseMoving and MouseHolding move the window, and the release (MouseButtonUp) takes those handlers off
 * again. A moved window is set with ctrlSetPosition and ctrlCommit 0 - a controls group moves everything
 * in it with itself, so a window that is one group is one control to move. What lies beside it - a dimming
 * behind the window, a hit area that closes it - is not in the group and stays where it is. The distance
 * is kept to whole pixels, as the kit lays its controls, and clamped so the whole handle stays inside the
 * safe zone: the bar can always be reached to bring the window back.
 *
 * With a kind, the place a window was let go at is kept for the session (in uiNamespace) and the next
 * window of that kind is put there when it is made - brought back inside the screen, should it lie
 * outside it.
 *
 * Arguments (attach):
 * 0: Display <DISPLAY>
 * 1: The window, the group that is moved <CONTROL>
 * 2: The handle's place [x, y, w, h], relative to the group it is made in <ARRAY>
 * 3: Kind of window, to keep its place; "" to forget it <STRING> (default: "")
 * 4: A light film under the handle, shown while the mouse is on it, [x, y, w, h] in the same group; [] for none <ARRAY> (default: [])
 * 5: The group to make the handle in, when it is not the window itself - a group inside it <CONTROL> (default: the window)
 *
 * Return Value:
 * The handle <CONTROL>
 *
 * Arguments (begin):
 * 0: "begin" <STRING>
 * 1: Array of:
 *    0: Display <DISPLAY>
 *    1: The controls that are moved together, all in one parent <ARRAY>
 *    2: The handle - a control, or its rectangle on the screen [x, y, w, h] <CONTROL|ARRAY>
 *    3: The mouse, [x, y] <ARRAY>
 *    4: Kind of window <STRING> (default: "")
 *    5: A film that lights up while dragged <CONTROL> (default: controlNull)
 *
 * Return Value (begin):
 * None
 *
 * Example:
 * [_display, _card, [0, 0, 0.3, 0.04], "picker", [0.004, 0.004, 0.292, 0.032]] call aio_gui_fnc_dragHandle;
 *
 * Public: No
 */

disableSerialization;

// The film, clear, over the bar with the mouse on it, and over the bar being dragged.
#define FILM_OFF [1, 1, 1, 0]
#define FILM_HOVER [1, 1, 1, 0.06]
#define FILM_DRAG [1, 1, 1, 0.1]

// The place of a control on the screen is its own plus those of the groups it lies in.
private _fnc_origin = {
    params ["_ctrl"];

    private _originX = 0;
    private _originY = 0;
    private _group = ctrlParentControlsGroup _ctrl;

    while {!isNull _group} do {
        (ctrlPosition _group) params ["_groupX", "_groupY"];

        _originX = _originX + _groupX;
        _originY = _originY + _groupY;
        _group = ctrlParentControlsGroup _group;
    };

    [_originX, _originY]
};

// A distance of the window, in whole pixels and short enough to leave the whole handle on the safe zone.
private _fnc_clamp = {
    params ["_moveX", "_moveY", "_handle"];
    _handle params ["_handleX", "_handleY", "_handleW", "_handleH"];

    private _minX = ceil ((safezoneX - _handleX) / pixelW) * pixelW;
    private _maxX = floor ((safezoneX + safezoneW - _handleX - _handleW) / pixelW) * pixelW;
    private _minY = ceil ((safezoneY - _handleY) / pixelH) * pixelH;
    private _maxY = floor ((safezoneY + safezoneH - _handleY - _handleH) / pixelH) * pixelH;

    [
        ((round (_moveX / pixelW)) * pixelW) max _minX min _maxX,
        ((round (_moveY / pixelH)) * pixelH) max _minY min _maxY
    ]
};

// ----- A drag in progress: the display's mouse moved or rests -----
if (_this isEqualType [] && {(_this select 0) isEqualTo "move"}) exitWith {
    private _state = uiNamespace getVariable [QGVAR(drag), []];

    if (_state isEqualTo []) exitWith {};

    _state params ["", "_moved", "_starts", "_handle", "_start"];

    // The window went (closed, redrawn) while it was held.
    if ((_moved findIf {isNull _x}) >= 0) exitWith {
        ["end"] call FUNC(dragHandle);
    };

    // The mouse where the game reads it now, in the units the controls are placed in: the numbers an event of
    // another display reports (ACE Arsenal's) were seen on another scale, and the card ran ahead of the mouse.
    getMousePosition params ["_mouseX", "_mouseY"];

    private _delta = [_mouseX - (_start select 0), _mouseY - (_start select 1), _handle] call _fnc_clamp;

    if (_delta isEqualTo (_state select 5)) exitWith {};

    _state set [5, _delta];

    {
        (_starts select _forEachIndex) params ["_left", "_top", "_width", "_height"];

        _x ctrlSetPosition [_left + (_delta select 0), _top + (_delta select 1), _width, _height];
        _x ctrlCommit 0;
    } forEach _moved;
};

// ----- Let go: the left button of the display, or the end asked for -----
if (_this isEqualType [] && {(_this select 0) in ["up", "end"]}) exitWith {
    // Only the left button ends it.
    if ((_this select 0) isEqualTo "up" && {((_this select 1) param [1, 0]) != 0}) exitWith {};

    private _state = uiNamespace getVariable [QGVAR(drag), []];

    if (_state isEqualTo []) exitWith {};

    uiNamespace setVariable [QGVAR(drag), []];
    uiNamespace setVariable [QGVAR(dragEnd), diag_tickTime];

    _state params ["_display", "_moved", "", "_handle", "", "", "_kind", "_film", "_ids", "_focus"];

    if (!isNull _display) then {
        _display displayRemoveEventHandler ["MouseMoving", _ids select 0];
        _display displayRemoveEventHandler ["MouseHolding", _ids select 1];
        _display displayRemoveEventHandler ["MouseButtonUp", _ids select 2];
    };

    if ((_moved findIf {isNull _x}) >= 0) exitWith {};

    // Where it was let go, for the next window of its kind.
    if (_kind isNotEqualTo "") then {
        private _places = uiNamespace getVariable [QGVAR(places), createHashMap];

        _places set [_kind, (ctrlPosition (_moved select 0)) select [0, 2]];
        uiNamespace setVariable [QGVAR(places), _places];
    };

    // The film stays lit when the mouse is still on the bar.
    if (!isNull _film) then {
        _handle params ["_handleX", "_handleY", "_handleW", "_handleH"];
        getMousePosition params ["_mouseX", "_mouseY"];

        private _over = _mouseX >= _handleX && {_mouseX < _handleX + _handleW} && {_mouseY >= _handleY} && {_mouseY < _handleY + _handleH};

        _film ctrlSetBackgroundColor ([FILM_OFF, FILM_HOVER] select _over);
    };

    // The cursor goes back to what had it - a text field of the window - for as long as that is part of it.
    if (!isNull _focus) then {
        private _group = ctrlParentControlsGroup _focus;

        while {!isNull _group && {_group isNotEqualTo (_moved select 0)}} do {
            _group = ctrlParentControlsGroup _group;
        };

        if (!isNull _group) then {
            ctrlSetFocus _focus;
        };
    };
};

// ----- Whether a window is dragged, or was a moment ago (a click ending a drag is not meant for what lies under it) -----
if (_this isEqualType [] && {(_this select 0) isEqualTo "busy"}) exitWith {
    private _state = uiNamespace getVariable [QGVAR(drag), []];

    (_state isNotEqualTo [] && {(_state select 1) findIf {isNull _x} < 0}) || {diag_tickTime - (uiNamespace getVariable [QGVAR(dragEnd), -10]) < 0.3}
};

// ----- Start -----
if (_this isEqualType [] && {(_this select 0) isEqualTo "begin"}) exitWith {
    (_this select 1) params [
        "_display", "_moved", "_handle", ["_mouse", [0, 0], [[]], 2], ["_kind", "", [""]], ["_film", controlNull, [controlNull]]
    ];

    // One at a time.
    ["end"] call FUNC(dragHandle);

    if (isNull _display || {_moved isEqualTo []}) exitWith {};

    private _handleRect = _handle;

    if (_handle isEqualType controlNull) then {
        (ctrlPosition _handle) params ["_handleX", "_handleY", "_handleW", "_handleH"];
        ([_handle] call _fnc_origin) params ["_originX", "_originY"];

        _handleRect = [_handleX + _originX, _handleY + _originY, _handleW, _handleH];
    };

    private _ids = [
        _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(dragHandle); false}],
        _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(dragHandle); false}],
        _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(dragHandle); false}]
    ];

    if (!isNull _film) then {
        _film ctrlSetBackgroundColor FILM_DRAG;
    };

    uiNamespace setVariable [QGVAR(drag), [
        _display, _moved, _moved apply {ctrlPosition _x}, _handleRect, getMousePosition, [0, 0], _kind, _film, _ids, focusedCtrl _display
    ]];
};

// ----- A handle is made -----
params ["_display", "_window", "_rect", ["_kind", "", [""]], ["_filmRect", [], [[]]], ["_parent", controlNull, [controlNull]]];

if (isNull _parent) then {
    _parent = _window;
};

private _film = controlNull;

if (_filmRect isNotEqualTo []) then {
    _film = [_display, "AIO_PanelRect", _parent, _filmRect] call FUNC(uiCreate);
    _film ctrlSetBackgroundColor FILM_OFF;
};

private _handle = [_display, "AIO_Hitbox", _parent, _rect] call FUNC(uiCreate);

_handle setVariable [QGVAR(drag), [_window, _kind, _film]];

_handle ctrlAddEventHandler ["MouseButtonDown", {
    params ["_handle", "_button", "_mouseX", "_mouseY"];

    if (_button != 0) exitWith {};

    (_handle getVariable [QGVAR(drag), []]) params ["_window", "_kind", "_film"];

    if (isNull _window) exitWith {};

    ["begin", [ctrlParent _handle, [_window], _handle, [_mouseX, _mouseY], _kind, _film]] call FUNC(dragHandle);
}];

// A film under the bar lights up with the mouse on it (and stays lit while it is dragged: see "begin").
if (!isNull _film) then {
    _handle ctrlAddEventHandler ["MouseEnter", {
        params ["_handle"];

        (_handle getVariable [QGVAR(drag), []]) params ["", "", "_film"];

        if (!isNull _film && {(uiNamespace getVariable [QGVAR(drag), []]) isEqualTo []}) then {
            _film ctrlSetBackgroundColor FILM_HOVER;
        };
    }];

    _handle ctrlAddEventHandler ["MouseExit", {
        params ["_handle"];

        (_handle getVariable [QGVAR(drag), []]) params ["", "", "_film"];

        if (!isNull _film && {(uiNamespace getVariable [QGVAR(drag), []]) isEqualTo []}) then {
            _film ctrlSetBackgroundColor FILM_OFF;
        };
    }];
};

// The window opens where it was let go last time.
if (_kind isNotEqualTo "") then {
    private _place = (uiNamespace getVariable [QGVAR(places), createHashMap]) getOrDefault [_kind, []];

    if (_place isNotEqualTo []) then {
        (ctrlPosition _window) params ["_windowX", "_windowY", "_windowW", "_windowH"];
        (ctrlPosition _handle) params ["_handleX", "_handleY", "_handleW", "_handleH"];
        ([_handle] call _fnc_origin) params ["_originX", "_originY"];

        private _delta = [
            (_place select 0) - _windowX, (_place select 1) - _windowY, [_handleX + _originX, _handleY + _originY, _handleW, _handleH]
        ] call _fnc_clamp;

        if (_delta isNotEqualTo [0, 0]) then {
            _window ctrlSetPosition [_windowX + (_delta select 0), _windowY + (_delta select 1), _windowW, _windowH];
            _window ctrlCommit 0;
        };
    };
};

_handle
