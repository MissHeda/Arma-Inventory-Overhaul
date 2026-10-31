#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Marks what waits in the hands' queue (fnc_queueMoves): every action waiting has its tile - or, for a worn item to
 * be taken off, its slot - tinted. A tile's surface takes a tint of the accent colour (fnc_queueColor, painted with
 * fnc_paintSurface) and its picture fades as a move in flight does: no control is made for it, however long the queue.
 * A slot has no surface of its own to paint, so one panel in the soft accent colour lies over it (the entry's "fx").
 * No ring, no number and no disc: how far the queue is shows only in the caption line of the box
 * (fnc_updateStatus). The tiles are flagged "pending", so they cannot be lifted or acted on, and "queued" with the
 * entry's id, so a click on one cancels it (fnc_onMouseButton, fnc_cancelQueued).
 *
 * The marks are kept between calls: an entry whose tiles still have the surfaces it marked (the controls are still
 * there) is left as it is - a redraw of a section makes new controls over the old, so those entries are marked again; a
 * slot entry compares the slot's record (slotAt). The tiles are found through one index shared by the whole call
 * (fnc_queueTiles), and only for the entries that need a mark. The call clears GVAR(queueDirty).
 *
 * Called by fnc_drawPending, which every build and every redraw of tiles ends with, after a kit window is drawn,
 * and by fnc_animateQueue once a frame at most when the queue changed (GVAR(queueDirty): queued or cancelled). It
 * ends by bringing the page bars and the caption lines up to date.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The first place in the queue to look at - the entries before it keep their marks untouched: entries added at
 *    the end change nothing for those in front, so a long queue costs a pass only over what was added
 *    (fnc_animateQueue). Whoever changed the order or the tiles asks for all (default: 0) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_drawQueue;
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
    } forEach GVAR(handQueue);
};

// The bars of paged boxes count what waits on the pages not shown (fnc_updatePageBars): the same when nothing queued.
if (GVAR(handQueue) isEqualTo []) exitWith {
    [_display] call FUNC(updatePageBars);
    [_display] call FUNC(updateStatus);
};

private _tint = GVAR(theme) getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]];
private _slots = uiNamespace getVariable [QGVAR(slots), []];
private _cache = createHashMap;

// The index in the slots of a worn item's slot (an entry without a tile on the window), -1 if none.
private _fnc_slotAt = {
    params ["_entry"];

    (_entry get "slot") params ["_unit", "_slotId"];

    _slots findIf {
        (_x param [5, ""]) isEqualTo _slotId && {(_x param [6, objNull]) isEqualTo _unit} && {(_x param [7, -1]) < 0}
    }
};

// Whether the tiles still have the surfaces the marks were made over: a tile drawn anew has other controls (and
// the old ones are gone), so the tint would be on controls that are no longer there.
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

    private _fx = _entry getOrDefault ["fx", []];
    private _held = _entry getOrDefault ["tiles", []];
    private _marks = _entry getOrDefault ["marks", []];

    // Whether what was marked last time still lies on what it was marked for.
    private _alive = _entry getOrDefault ["marked", false] && {_fx findIf {isNull _x} < 0} && {[_held, _marks] call _fnc_onSurfaces};

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

        continue;
    };

    // Marked anew: the old panel goes first.
    {ctrlDelete _x} forEach _fx;

    _entry set ["fx", []];
    _entry set ["tiles", []];
    _entry set ["marks", []];
    _entry set ["marked", false];

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

        // A shaped tile lies over cells another tile may hold in its holes, so its surface is painted too - it is
        // the surface that is the tile's own.
        private _own = _tile getOrDefault ["color", []];

        if (_own isNotEqualTo []) then {
            [_tile getOrDefault ["backgrounds", []], [_own] call FUNC(queueColor)] call FUNC(paintSurface);
        };

        _surfaces pushBack (_tile getOrDefault ["background", controlNull]);
    } forEach _held;

    private _slotAt = -1;

    // The slot of a worn item that waits to come off: one panel over it, in its group where it has one so it
    // scrolls and clips with it.
    if (_held isEqualTo [] && {(_entry get "slot") isNotEqualTo []}) then {
        _slotAt = [_entry] call _fnc_slotAt;

        private _record = _slots param [_slotAt, []];

        if (_record isNotEqualTo []) then {
            private _anchor = _record param [3, createHashMap];
            private _rect = _record param [0, [0, 0, 0, 0]];

            private _target = if (
                _anchor isEqualType createHashMap && {"parent" in _anchor} && {"rel" in _anchor} && {!isNull (_anchor get "parent")}
            ) then {
                [_anchor get "parent", (_anchor get "rel") + [_rect select 2, _rect select 3]]
            } else {
                [controlNull, _rect]
            };

            _entry set ["fx", [_display, _target select 0, _target select 1, _tint] call FUNC(uiPanel)];
        };
    };

    _entry set ["tiles", _held];

    // Kept to tell later whether the marks still lie on what they were made for.
    _entry set ["marks", _surfaces];
    _entry set ["slotAt", _slotAt];
    _entry set ["marked", _held isNotEqualTo [] || {_slotAt >= 0}];
};

// What waits on the pages not shown is counted on the bars (an entry has no tile drawn there to mark), and the caption
// lines say how far the boxes are.
[_display] call FUNC(updatePageBars);
[_display] call FUNC(updateStatus);
