#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the hands' queue (fnc_queueMoves): every action waiting gets a circle on the tile it takes from - or
 * on the slot of the worn item it takes off -, made as the search's ring is (fnc_showSearch, the same ring
 * pictures) over a dark disc. Past QUEUE_DISC_MAX entries the disc is left out (two controls instead of
 * three, so a Take all on a big crate stays cheap), the faint ring and the number still show. The first,
 * the one the hands are busy with, has the ring that fills (fnc_animateQueue turns its picture on); the others
 * wait with a faint ring and their place in the queue as a number. The tiles are flagged "pending", so they
 * cannot be lifted or acted on, and "queued" with the entry's id, so a click on one cancels it
 * (fnc_onMouseButton, fnc_cancelQueued); they fade as a move in flight does.
 *
 * The circles are kept between calls, one set per entry (the entry's "fx"), and only what changed is touched: an
 * entry whose circle still lies on its tile (the tile's surface is the control the circle was made over, and the
 * controls are still there) keeps it, and when only its place in the queue moved its number is written in place.
 * A circle is made anew for an entry that has none yet, whose tile was drawn again (a build, a redraw of its
 * section, a kit window drawn anew - the new controls lie over the old circle), whose slot was drawn anew, or
 * that became the first or crossed QUEUE_DISC_MAX (the first has a ring instead of a number, the disc is
 * left out past the limit). The tiles are found through one index shared by the whole call (fnc_queueTiles),
 * and only for the entries that need a circle. The call clears GVAR(queueDirty).
 *
 * Called by fnc_drawPending, which every build and every redraw of tiles ends with, after a kit window is drawn,
 * and by fnc_animateQueue once a frame at most when the queue changed (GVAR(queueDirty): queued or cancelled).
 * Not per frame otherwise - the frame only changes the first ring's picture. Every entry whose tile or slot the
 * window shows is marked.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The first place in the queue to look at - the entries before it keep their circles untouched: entries added at
 *    the end change nothing for those in front, so a long queue costs a pass only over what was added
 *    (fnc_animateQueue). Whoever changed the order or the tiles asks for all (default: 0) <NUMBER>
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

params [["_display", displayNull, [displayNull]], ["_from", 0, [0]]];

GVAR(queueDirty) = false;
GVAR(queueFrom) = 0;

if (isNull _display) exitWith {
    {
        {ctrlDelete _x} forEach (_x getOrDefault ["fx", []]);

        _x set ["fx", []];
        _x set ["arc", controlNull];
    } forEach GVAR(handQueue);
};

if (GVAR(handQueue) isEqualTo []) exitWith {};

private _theme = GVAR(theme);
private _accent = _theme getOrDefault ["accent", [1, 1, 1, 1]];
private _track = +(_theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]);
private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _font = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _now = diag_tickTime;
private _slots = uiNamespace getVariable [QGVAR(slots), []];
private _cache = createHashMap;

// A faint ring on a dark disc stays readable over any picture.
_track set [3, ((_track select 3) * 2.2) min 1];

// The index in the slots of a worn item's slot (an entry without a tile on the window), -1 if none.
private _fnc_slotAt = {
    params ["_entry"];

    (_entry get "slot") params ["_unit", "_slotId"];

    _slots findIf {
        (_x param [5, ""]) isEqualTo _slotId && {(_x param [6, objNull]) isEqualTo _unit} && {(_x param [7, -1]) < 0}
    }
};

// Whether the tiles still have the surfaces the circle was made over: a tile drawn anew has other controls (and
// the old ones are gone), so the circle would lie under them.
private _fnc_onSurfaces = {
    params ["_held", "_marks"];

    if (count _held != count _marks) exitWith {false};

    private _same = true;

    {
        private _surface = (_x select 1) getOrDefault ["background", controlNull];

        if (isNull _surface || {_surface isNotEqualTo (_marks select _forEachIndex)}) exitWith {
            _same = false;
        };
    } forEach _held;

    _same
};

for "_position" from (_from max 0) to (count GVAR(handQueue) - 1) do {
    private _entry = GVAR(handQueue) select _position;

    // What the circle is made of: the first has the ring that fills, the others a number; the disc is left out
    // past QUEUE_DISC_MAX.
    private _class = ([0, 2] select (_position == 0)) + parseNumber (_position < QUEUE_DISC_MAX);

    private _fx = _entry getOrDefault ["fx", []];
    private _held = _entry getOrDefault ["tiles", []];
    private _marks = _entry getOrDefault ["marks", []];

    // Whether the circle made last time still lies on what it was made for.
    private _alive = _fx isNotEqualTo [] && {(_entry getOrDefault ["class", -1]) == _class} && {_fx findIf {isNull _x} < 0}
        && {[_held, _marks] call _fnc_onSurfaces};

    // On a slot instead of a tile: the slot must be the record it was made on.
    if (_alive && {_marks isEqualTo []}) then {
        _alive = ([_entry] call _fnc_slotAt) == (_entry getOrDefault ["slotAt", -2]);
    };

    if (_alive) then {
        // Marked and faded already; a settle (fnc_refresh) lets go only what is not queued, but be sure.
        {
            private _tile = _x select 1;

            if !(_tile getOrDefault ["pending", false]) then {
                _tile set ["pending", true];

                {
                    _x ctrlSetFade DRAG_SOURCE_FADE;
                    _x ctrlCommit 0;
                } forEach (_tile getOrDefault ["controls", []]);
            };
        } forEach _held;

        // Only its place moved: the number is written in place (it is the last control).
        if (_position != (_entry getOrDefault ["position", -1])) then {
            (_fx select (count _fx - 1)) ctrlSetText str (_position + 1);
            _entry set ["position", _position];
        };

        continue;
    };

    // A circle of its own is made: the old one goes first.
    {ctrlDelete _x} forEach _fx;

    _entry set ["fx", []];
    _entry set ["arc", controlNull];
    _entry set ["tiles", []];
    _entry set ["marks", []];

    // [controls group or controlNull, rectangle in it]: where the circle goes - the first tile it takes from that
    // the window shows, else the slot of the worn item.
    private _target = [];
    private _surfaces = [];

    _held = [_entry, _cache] call FUNC(queueTiles);

    {
        _x params ["", "_tile"];

        _tile set ["pending", true];
        _tile set ["queued", _entry get "id"];

        {
            _x ctrlSetFade DRAG_SOURCE_FADE;
            _x ctrlCommit 0;
        } forEach (_tile getOrDefault ["controls", []]);

        private _background = _tile getOrDefault ["background", controlNull];

        _surfaces pushBack _background;

        if (_target isEqualTo [] && {!isNull _background}) then {
            // Its box: a shaped tile's first surface is only its top row's first run (fnc_createTile).
            _target = [ctrlParentControlsGroup _background, _tile getOrDefault ["rect", ctrlPosition _background]];
        };
    } forEach _held;

    private _slotAt = -1;

    if (_target isEqualTo [] && {(_entry get "slot") isNotEqualTo []}) then {
        _slotAt = [_entry] call _fnc_slotAt;

        private _record = _slots param [_slotAt, []];

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

    _entry set ["tiles", _held];

    if (_target isEqualTo []) then {continue};

    // Kept to tell later whether the circle still lies on what it was made for.
    _entry set ["marks", _surfaces];
    _entry set ["slotAt", _slotAt];
    _entry set ["class", _class];
    _entry set ["position", _position];

    _target params ["_parent", "_rect"];
    _rect params ["_left", "_top", "_width", "_height"];

    private _size = (((_width / pixelW) min (_height / pixelH)) * QUEUE_RING_SIZE) min QUEUE_RING_MAX;
    private _centerX = _left + _width / 2;
    private _centerY = _top + _height / 2;
    private _ringRect = [_centerX - _size * pixelW / 2, _centerY - _size * pixelH / 2, _size * pixelW, _size * pixelH];
    private _discSize = _size * QUEUE_DISC_SIZE;
    private _made = [];

    // The disc (not past QUEUE_DISC_MAX), the whole ring faint, then what says where it is in the queue.
    if (_position < QUEUE_DISC_MAX) then {
        _made pushBack ([
            _display, _parent,
            [_centerX - _discSize * pixelW / 2, _centerY - _discSize * pixelH / 2, _discSize * pixelW, _discSize * pixelH],
            UI_TEX(circle_ca), [0, 0, 0, [0.6, 0.45] select (_position > 0)]
        ] call FUNC(uiIcon));
    };

    // Without the disc behind it the ring is stronger, to stay readable over the picture.
    private _ringColor = +_track;

    if (_position >= QUEUE_DISC_MAX) then {
        _ringColor set [3, ((_track select 3) * 2) min 0.7];
    };

    _made pushBack ([_display, _parent, _ringRect, SEARCH_RING(SEARCH_FRAMES), _ringColor] call FUNC(uiIcon));

    if (_position == 0) then {
        // The ring that fills: as far round as the time has run (a redraw in the middle keeps it).
        private _progress = [0, ((_now - GVAR(handStarted)) / ((_entry get "time") max 0.05)) min 1] select (GVAR(handStarted) >= 0);
        private _step = ((ceil (_progress * SEARCH_FRAMES)) max 1) min SEARCH_FRAMES;
        private _arc = [_display, _parent, _ringRect, SEARCH_RING(_step), _accent] call FUNC(uiIcon);

        _entry set ["arc", _arc];
        _entry set ["step", _step];
        _made pushBack _arc;
    } else {
        private _fontHeight = _size * pixelH * 0.46;

        _made pushBack ([
            _display, _parent,
            [_centerX - _size * pixelW / 2, _centerY - _fontHeight * 0.62, _size * pixelW, _fontHeight * 1.3],
            str (_position + 1), _fontHeight, _text, _font, 2
        ] call FUNC(uiLabel));
    };

    _entry set ["fx", _made];
};
