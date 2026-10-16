#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the hands' queue (fnc_queueMoves): every action waiting gets a circle on the tile it takes from - or
 * on the slot of the worn item it takes off -, made as the search's ring is (fnc_showSearch, the same ring
 * pictures) over a dark disc. The first, the one the hands are busy with, has the ring that fills
 * (fnc_animateQueue turns its picture on); the others wait with a faint ring and their place in the queue as a
 * number. The tiles are flagged "pending", so they cannot be lifted or acted on, and "queued" with the
 * entry's id, so a click on one cancels it (fnc_onMouseButton, fnc_cancelQueued); they fade as a move in
 * flight does.
 *
 * Called by fnc_drawPending, which every build and every redraw of tiles ends with: the circles of the
 * last call go first, whether or not their controls are still there (a build deleted them, a redraw of the
 * section did not). Not per frame - the frame only changes the first ring's picture. Only the first
 * QUEUE_SHOWN_MAX entries get a circle; the others still wait their turn, their tiles marked.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_drawQueue;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

{
    {ctrlDelete _x} forEach (_x getOrDefault ["fx", []]);

    _x set ["fx", []];
    _x set ["arc", controlNull];
} forEach GVAR(handQueue);

if (isNull _display || {GVAR(handQueue) isEqualTo []}) exitWith {};

private _theme = GVAR(theme);
private _accent = _theme getOrDefault ["accent", [1, 1, 1, 1]];
private _track = +(_theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]);
private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _font = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _now = diag_tickTime;
private _slots = uiNamespace getVariable [QGVAR(slots), []];

// A faint ring on a dark disc stays readable over any picture.
_track set [3, ((_track select 3) * 2.2) min 1];

{
    private _entry = _x;
    private _position = _forEachIndex;

    // [controls group or controlNull, rectangle in it]: where the circle goes - the first tile it takes from that
    // the window shows, else the slot of the worn item.
    private _target = [];

    {
        _x params ["", "_tile"];

        _tile set ["pending", true];
        _tile set ["queued", _entry get "id"];

        {
            _x ctrlSetFade DRAG_SOURCE_FADE;
            _x ctrlCommit 0;
        } forEach (_tile getOrDefault ["controls", []]);

        if (_target isEqualTo []) then {
            private _background = _tile getOrDefault ["background", controlNull];

            if (!isNull _background) then {
                // Its box: a shaped tile's first surface is only its top row's first run (fnc_createTile).
                _target = [ctrlParentControlsGroup _background, _tile getOrDefault ["rect", ctrlPosition _background]];
            };
        };
    } forEach ([_entry] call FUNC(queueTiles));

    if (_target isEqualTo [] && {(_entry get "slot") isNotEqualTo []}) then {
        (_entry get "slot") params ["_unit", "_slotId"];

        private _record = _slots param [_slots findIf {
            (_x param [5, ""]) isEqualTo _slotId && {(_x param [6, objNull]) isEqualTo _unit} && {(_x param [7, -1]) < 0}
        }, []];

        if (_record isNotEqualTo []) then {
            private _anchor = _record param [3, createHashMap];
            private _rect = _record param [0, [0, 0, 0, 0]];

            // In its group at its place there, so it scrolls and clips with it; else on the display where it was drawn.
            _target = if (
                _anchor isEqualType createHashMap && {"parent" in _anchor} && {"rel" in _anchor} && {!isNull (_anchor get "parent")}
            ) then {
                [_anchor get "parent", (_anchor get "rel") + [_rect select 2, _rect select 3]]
            } else {
                [controlNull, _rect]
            };
        };
    };

    if (_target isEqualTo [] || {_position >= QUEUE_SHOWN_MAX}) then {continue};

    _target params ["_parent", "_rect"];
    _rect params ["_left", "_top", "_width", "_height"];

    private _size = (((_width / pixelW) min (_height / pixelH)) * QUEUE_RING_SIZE) min QUEUE_RING_MAX;
    private _centerX = _left + _width / 2;
    private _centerY = _top + _height / 2;
    private _ringRect = [_centerX - _size * pixelW / 2, _centerY - _size * pixelH / 2, _size * pixelW, _size * pixelH];
    private _discSize = _size * QUEUE_DISC_SIZE;
    private _fx = [];

    // The disc, the whole ring faint, then what says where it is in the queue.
    _fx pushBack ([
        _display, _parent,
        [_centerX - _discSize * pixelW / 2, _centerY - _discSize * pixelH / 2, _discSize * pixelW, _discSize * pixelH],
        UI_TEX(circle_ca), [0, 0, 0, [0.6, 0.45] select (_position > 0)]
    ] call FUNC(uiIcon));

    _fx pushBack ([_display, _parent, _ringRect, SEARCH_RING(SEARCH_FRAMES), _track] call FUNC(uiIcon));

    if (_position == 0) then {
        // The ring that fills: as far round as the time has run (a redraw in the middle keeps it).
        private _progress = [0, ((_now - GVAR(handStarted)) / ((_entry get "time") max 0.05)) min 1] select (GVAR(handStarted) >= 0);
        private _step = ((ceil (_progress * SEARCH_FRAMES)) max 1) min SEARCH_FRAMES;
        private _arc = [_display, _parent, _ringRect, SEARCH_RING(_step), _accent] call FUNC(uiIcon);

        _entry set ["arc", _arc];
        _entry set ["step", _step];
        _fx pushBack _arc;
    } else {
        private _fontHeight = _size * pixelH * 0.46;

        _fx pushBack ([
            _display, _parent,
            [_centerX - _size * pixelW / 2, _centerY - _fontHeight * 0.62, _size * pixelW, _fontHeight * 1.3],
            str (_position + 1), _fontHeight, _text, _font, 2
        ] call FUNC(uiLabel));
    };

    _entry set ["fx", _fx];
} forEach GVAR(handQueue);
