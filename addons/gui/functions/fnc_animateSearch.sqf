#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Searching, every frame: the item at the head of the queue (fnc_markHidden) is searched for its time -
 * longer for bigger ones - and a rummaging sound plays now and then. Once its time is up it is known (fnc_learn), its tile is
 * drawn anew in place without its hatching (fnc_revealTile, fnc_revealFx), and the next one is searched. The
 * window is only built again when the section's caption line has to change with it (its first item
 * found brings Take all) - a build per item made a big crate or vehicle flicker while it was searched.
 *
 * What is searched is told only in the caption line of its box (fnc_updateStatus: a ring that goes round, the time that
 * is left, a button that stops it) - the tile has no ring or glass of its own. A box whose search the player stopped
 * (GVAR(searchPaused)) is passed over: the head is the first item of a box that is not stopped.
 *
 * The rummaging is the sound of what is searched - cloth on a body, things shifting in a crate, a hand on the
 * ground (fnc_playSound "search" for the container) -, heard by players near the looter as well; the speaker
 * in the header mutes it for the looter alone. An item found makes its own quiet sound ("uncover").
 *
 * Every item gets its own time from when it comes up - after a close and open of the window, too.
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

if (GVAR(searchStarted) >= 0 && {_gap > SEARCH_PAUSE}) then {
    GVAR(searchStarted) = GVAR(searchStarted) + _gap;
};

if (GVAR(searchQueue) isEqualTo []) exitWith {};

private _headIndex = GVAR(searchQueue) findIf {!((_x select 0) in GVAR(searchPaused))};

// Every box that is left was stopped: nothing runs.
if (_headIndex < 0) exitWith {
    GVAR(searchStarted) = -1;
    GVAR(searchHead) = [];
};

private _head = GVAR(searchQueue) select _headIndex;

if (_head isNotEqualTo GVAR(searchHead) || {GVAR(searchStarted) < 0}) then {
    GVAR(searchHead) = _head;
    GVAR(searchStarted) = _now;
};

private _duration = (GVAR(searchTime) * (_head select 4)) max 0.05;
private _progress = ((_now - GVAR(searchStarted)) / _duration) min 1;

if (_progress >= 1) exitWith {
    // What was found makes its own sound, quietly, for the looter alone.
    ["uncover", _head select 1, _head select 0, false] call FUNC(playSound);

    [_head select 0, _head select 1, 1] call FUNC(learn);
    GVAR(searchStarted) = -1;
    GVAR(searchHead) = [];

    private _revealFrom = diag_tickTime;
    private _inPlace = [_display, _head] call FUNC(revealTile);

    if (!_inPlace) then {
        [_display] call FUNC(build);
    };

    [_display, _head] call FUNC(revealFx);

    // For the tester's numbers (einv_gui_debugTiming): what finding it cost - a stutter while searching is this.
    if (missionNamespace getVariable [QGVAR(debugTiming), false]) then {
        private _revealTook = ((diag_tickTime - _revealFrom) * 1000) toFixed 1;
        private _revealHow = ["the window built anew, as the first find of a section brings Take all", "its tile drawn anew in place"] select _inPlace;

        INFO_2("timing: search found an item - %1 ms (%2)",_revealTook,_revealHow);
    };
};

// Rummaging: a short sound now and then, of what is searched - cloth on a body, things shifting in a crate, a
// hand on the ground. The speaker in the header mutes it for the looter only (fnc_playSound): the others still
// hear him.
if (_now >= GVAR(searchSoundAt)) then {
    GVAR(searchSoundAt) = _now + SEARCH_SOUND_GAP + random SEARCH_SOUND_GAP;
    ["search", "", _head select 0, true] call FUNC(playSound);
};
