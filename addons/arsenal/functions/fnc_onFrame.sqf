#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Every frame of the panel (the "frame" hook), also while something is dragged. While the engine holds
 * something lifted in the panel or out of ACE's list, ACE's camera must not take the same mouse button
 * for a pan or a turn over the middle: ACE notes every press on its display, also those on the panel, and
 * moves its camera while the button is down. So its note is emptied every frame meanwhile.
 *
 * A press on ACE's list that the mouse moves away from with the button held, further than LIST_DRAG_PX
 * pixels in any direction, becomes a drag of the pressed row's item (fnc_onListPress, fnc_listDrag): the
 * list scrolls by the wheel and its bar, not by dragging its rows, so a move up or down is a drag as well.
 * Its threshold is in pixels and smaller than the engine's own (DRAG_THRESHOLD, in screen units: 6 px at
 * 1080p and the normal interface size, 9 px at the largest), which the first moves of a quick grab did
 * not always pass. A press that never moved stays ACE's click.
 *
 * A button let go where no event of the display reached the engine (over one of ACE's own controls) ends
 * the drag where it stands all the same, and a press that never became a drag is forgotten - it would
 * otherwise start one later with the button up.
 *
 * The engine draws the focused control over every other, and a click into ACE's list gives it the focus:
 * the name at the mouse, the menu and the dragged ghost would lie under it where they reach over it. So
 * while the mouse is over the panel with no button held, or something is dragged, the focus goes to the
 * panel's sink (fnc_layout), a control of no size, unless one of ACE's fields or sort bars has it. Not to
 * ACE's 3D area (IDC 0), where ACE puts it when it opens: that covers the whole screen, and focused it lay
 * over the panel - the first press on a tile, a caption's click and the wheel went to it instead of the
 * panel. A click into the list takes the focus back for the list's own keys.
 *
 * And once the mouse has left the panel with nothing held, the focus goes back to ACE's list (IDC 15) -
 * if it was the sink's: ACE's arrow keys move the list's selection only while the list has the focus, and
 * without this the player would have to click the list first after every visit to the panel. Not before
 * the name at the mouse and the menu are gone: the list focused would lie over them where they reach
 * over it, which is exactly why the sink has the focus meanwhile.
 *
 * Where the column stood when Ctrl and the wheel added or took out a tile is held for a few frames
 * against the wheel's own step (fnc_onWheel). A move into or out of the staging space tells ACE once
 * the count in the container changed (fnc_onDrop): its list, load bar and event, as after a removal.
 *
 * A build ACE's events asked for while something was held (fnc_settle) comes once it is let go.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Mouse [x, y] <ARRAY>
 * 2: Now (diag_tickTime) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition, diag_tickTime] call einv_arsenal_fnc_onFrame;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_mouse", getMousePosition, [[]]], ["_now", diag_tickTime, [0]]];

// ----- The answers of the question fnc_confirmClose asks, lit up under the mouse -----
if !(isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) then {
    [_mouse] call FUNC(hoverConfirm);
};

// ----- A press on ACE's list that the mouse moves away from -----
if (GVAR(listPress) isNotEqualTo []) then {
    GVAR(listPress) params ["_pressed", "_shift", ["_frame", -1], ["_row", -1]];

    // Let go, the note goes - but not in the frame of the press nor the next: the press event may come
    // before the button reads as held, and the press was forgotten before it could become a drag (a second
    // click then did it).
    if ((inputMouse 0 == 0 && {diag_frameNo > _frame + 1}) || {EGVAR(gui,dragging)} || {EGVAR(gui,press) isNotEqualTo []}) exitWith {
        GVAR(listPress) = [];
    };

    // How far, in the screen's pixels.
    private _moveX = ((_mouse select 0) - (_pressed select 0)) / pixelW;
    private _moveY = ((_mouse select 1) - (_pressed select 1)) / pixelH;

    if (_moveX * _moveX + _moveY * _moveY > LIST_DRAG_PX * LIST_DRAG_PX) then {
        GVAR(listPress) = [];
        [_display, _pressed, _shift, _row, _frame] call FUNC(listDrag);
    };
};

private _holding = EGVAR(gui,dragging) || {EGVAR(gui,press) isNotEqualTo []} || {GVAR(listPress) isNotEqualTo []};

if (_holding) then {
    if (!isNil QACEGVAR(arsenal,mouseButtonState)) then {
        ACEGVAR(arsenal,mouseButtonState) = [[], []];
    };

    // Not in the frame the button went down in, nor the next: the press event may come before the button
    // reads as held, and a fresh press would be forgotten before it could become a drag.
    if (inputMouse 0 == 0 && {diag_frameNo > ((EGVAR(gui,lastButton) param [0, -1]) + 1)}) then {
        if (EGVAR(gui,dragging)) then {
            [_display] call EFUNC(gui,endDrag);
        } else {
            EGVAR(gui,press) = [];
        };
    };
};

// ----- The focus, away from ACE's list while the panel is used - not from a field (2) or a sort bar (4) -----
private _focus = focusedCtrl _display;
private _sink = uiNamespace getVariable [QGVAR(focusSink), controlNull];

if (
    !isNull _sink && {_focus isNotEqualTo _sink}
    && {isNull _focus || {!(ctrlType _focus in [2, 4])}}
    && {EGVAR(gui,dragging) || {inputMouse 0 == 0 && {inputMouse 1 == 0} && {[_mouse] call FUNC(isOver)}}}
) then {
    ctrlSetFocus _sink;
};

// ----- The focus back to ACE's list once the mouse is off the panel, once: from the sink only -----
// Not while the question of fnc_confirmClose is up: the list focused would be drawn over its card.
// Not while a button is held: a scroll bar dragged out of the panel is still being used, and the list taking
// the focus would let go of it.
private _tip = uiNamespace getVariable [QEGVAR(gui,tipShown), controlNull];

if (
    !isNull _sink && {_focus isEqualTo _sink} && {!_holding} && {inputMouse 0 == 0 && {inputMouse 1 == 0}}
    && {isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])}
    && {!([_mouse] call FUNC(isOver))}
    && {isNull _tip || {!ctrlShown _tip}} && {(uiNamespace getVariable [QEGVAR(gui,menu), []]) isEqualTo []}
) then {
    private _list = _display displayCtrl ARSENAL_IDC_LIST;

    if (!isNull _list && {ctrlShown _list} && {ctrlEnabled _list}) then {
        ctrlSetFocus _list;
    };
};

// ----- The column held where it stood against the wheel's own step -----
if (GVAR(scrollHold) isNotEqualTo []) then {
    GVAR(scrollHold) params ["_pixels", "_until"];

    if (diag_frameNo > _until) exitWith {
        GVAR(scrollHold) = [];
    };

    {
        if (!isNull _x && {ctrlType _x == 15} && {(_x getVariable [QEGVAR(gui,column), ""]) isEqualTo "storage"}) then {
            private _groupH = (ctrlPosition _x) select 3;
            private _range = (_x getVariable [QEGVAR(gui,contentH), _groupH]) - _groupH;

            if (_range > 0) then {
                _x ctrlSetScrollValues [(_pixels / _range) min 1, -1];
            };
        };
    } forEach (uiNamespace getVariable [QEGVAR(gui,created), []]);
};

// ----- A move into or out of the staging space, once it landed -----
if (GVAR(watch) isNotEqualTo []) then {
    GVAR(watch) params ["_watched", "_class", "_before", "_until"];

    (call FUNC(selected)) params ["", "_open"];

    if (_open isNotEqualTo _watched || {_now > _until}) exitWith {
        GVAR(watch) = [];
    };

    private _after = [_open, _class] call EFUNC(storage,countClass);

    if (_after == _before) exitWith {};

    GVAR(watch) = [];

    [_display] call FUNC(syncAce);
    [_class, _before, _after] call FUNC(tellAce);
};

if (_holding || {!GVAR(dirty)}) exitWith {};

GVAR(dirty) = false;

[_display] call EFUNC(gui,build);
