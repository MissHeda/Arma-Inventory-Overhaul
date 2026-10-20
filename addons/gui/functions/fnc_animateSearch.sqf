#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Searching, every frame: every box that has something queued (fnc_markHidden) and is not stopped searches at the same
 * time, each with its own clock - a body's uniform and vest clicked one after the other both run. One run per box
 * (GVAR(searchRuns): [container, the entry being searched, when it started, how long it takes]); the entry is the box's
 * first one in the queue and takes its cells times the box's time per cell (fnc_searchTime: the kind of box, a body's).
 * The runs are matched with the queue only when it changed (GVAR(searchDirty), a new queue after a build or a find), so a
 * frame costs a look at each run's clock, whatever is still hidden.
 *
 * A box's seal comes first (a sealed box, fnc_isSealed): when its time is up - about two seconds - the box is open to this
 * player (fnc_searchRecord "unsealed"), its "open" sound plays and the window is built with its real grid, every item a
 * hatched footprint, which are then queued and found one by one. An item found is known (fnc_learn), makes its own quiet
 * sound ("uncover"), and its tile is drawn anew in place without its hatching (fnc_revealTile, fnc_revealFx); the window
 * is only built again when something other than the tile has to change with it - a
 * build per item made a big crate or vehicle flicker while it was searched. Several finds of one frame build it once.
 *
 * What is searched is told only in the caption line of its box (fnc_updateStatus: a ring that goes round, the time that
 * is left, a button that stops it). A box whose search the player stopped (GVAR(searchPaused)) has no run; going on, the
 * item it was at starts again from nothing.
 *
 * The rummaging is the sound of what is searched - cloth on a body, things shifting in a crate, a hand on the
 * ground (fnc_playSound "search" for the container) -, heard by players near the looter as well; the speaker
 * in the header mutes it for the looter alone. One clock for it, however many boxes search.
 *
 * Every item gets its own time from when it comes up - after a close and open of the window, too (fnc_attach empties
 * the runs). A pause - something held, the window busy - does not count for any box.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Now, diag_tickTime <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call einv_gui_fnc_animateSearch;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_now"];

// Paused - something was held, or the window busy: the time it stood still does not count.
private _gap = _now - GVAR(searchLast);
GVAR(searchLast) = _now;

if (_gap > SEARCH_PAUSE) then {
    {
        _x set [2, (_x select 2) + _gap];
    } forEach GVAR(searchRuns);
};

// One run per box that has something queued and is not stopped, at its first entry. A run whose entry is still that
// entry keeps its clock; any other starts now.
private _fnc_sync = {
    private _runs = [];
    private _boxes = [];

    {
        private _box = _x select 0;

        if (_box in _boxes) then {continue};

        _boxes pushBack _box;

        if (isNull _box || {_box in GVAR(searchPaused)}) then {continue};

        private _head = _x;
        private _run = GVAR(searchRuns) param [GVAR(searchRuns) findIf {(_x select 0) isEqualTo _box}, []];

        if (_run isNotEqualTo [] && {(_run select 1) isEqualTo _head}) then {
            _runs pushBack _run;
        } else {
            _runs pushBack [_box, _head, _now, (([_box] call FUNC(searchTime)) * (_head select 4)) max 0.05];
        };
    } forEach GVAR(searchQueue);

    GVAR(searchRuns) = _runs;
    GVAR(searchSynced) = GVAR(searchQueue);
    GVAR(searchDirty) = false;
};

if (GVAR(searchDirty) || {!(GVAR(searchQueue) isEqualRef GVAR(searchSynced))}) then {
    call _fnc_sync;
};

if (GVAR(searchRuns) isEqualTo []) exitWith {
    GVAR(searchStarted) = -1;
};

GVAR(searchStarted) = _now;

// The boxes whose entry's time is up.
private _done = GVAR(searchRuns) select {(_now - (_x select 2)) >= (_x select 3)};

if (_done isNotEqualTo []) then {
    private _build = false;
    private _found = [];
    private _revealFrom = diag_tickTime;

    {
        private _head = _x select 1;
        _head params ["_container", "_class"];

        // The seal (fnc_markHidden, fnc_isSealed): the box is open to this player from now on, and the window shows its
        // real grid with every item a hatched footprint.
        if (_class isEqualTo "") then {
            ([_container, true] call FUNC(searchRecord)) set ["unsealed", true];
            GVAR(searchQueue) = GVAR(searchQueue) select {_x isNotEqualTo _head};
            ["open", "", _container, false] call FUNC(playSound);
            _build = true;
            continue;
        };

        // What was found makes its own sound, quietly, for the looter alone.
        ["uncover", _class, _container, false] call FUNC(playSound);
        [_container, _class, 1] call FUNC(learn);

        // Drawn anew in place - unless the window is built anyway, which draws it found.
        if (_build || {!([_display, _head] call FUNC(revealTile))}) then {
            _build = true;
            GVAR(searchQueue) = GVAR(searchQueue) select {_x isNotEqualTo _head};
        };

        _found pushBack _head;
    } forEach _done;

    // The next entry of each box that found something starts now; the others keep their clocks.
    call _fnc_sync;

    if (_build) then {
        [_display] call FUNC(build);
    };

    {
        [_display, _x] call FUNC(revealFx);
    } forEach _found;

    // For the tester's numbers (einv_gui_debugTiming): what finding it cost - a stutter while searching is this.
    if (missionNamespace getVariable [QGVAR(debugTiming), false]) then {
        private _revealTook = ((diag_tickTime - _revealFrom) * 1000) toFixed 1;
        private _revealHow = ["its tile drawn anew in place", "the window built anew, as a box opened"] select _build;
        private _revealCount = count _done;

        INFO_3("timing: search found %1 item(s) - %2 ms (%3)",_revealCount,_revealTook,_revealHow);
    };
};

// Rummaging: a short sound now and then, of what is searched - cloth on a body, things shifting in a crate, a
// hand on the ground. The speaker in the header mutes it for the looter only (fnc_playSound): the others still
// hear him. One clock, the sound of one of the boxes.
if (_now >= GVAR(searchSoundAt) && {GVAR(searchRuns) isNotEqualTo []}) then {
    GVAR(searchSoundAt) = _now + SEARCH_SOUND_GAP + random SEARCH_SOUND_GAP;
    ["search", "", (selectRandom GVAR(searchRuns)) select 0, true] call FUNC(playSound);
};
