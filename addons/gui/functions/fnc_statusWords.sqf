#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the activity chip of a box says now (fnc_updateStatus makes the chip as wide as these words, fnc_animateStatus
 * writes them once a second or when the hands' count changed):
 *   hands  - "Grabbing items 3 / 12" (or putting away, dropping, moving, changing gear), else the count alone
 *   search - "Searching 0:07", "Stopped 0:07" or "Unsearched 0:07", else the time alone: what is left of the box's queued
 *     entries, their cells at the box's time per cell (fnc_searchTime), less what its run has done (fnc_animateSearch).
 *     A sealed box says no time - it would tell how much it holds: "Searching", "Stopped", "Unsearched".
 * The long words when they fit the room, else the short ones, shortened where even they do not (fnc_fitText).
 *
 * Arguments:
 * 0: The box's container <OBJECT>
 * 1: "hands" or "search" <STRING>
 * 2: Stopped <BOOL>
 * 3: Not begun yet, waiting for the click (GVAR(searchIdle)) <BOOL>
 * 4: Sealed (fnc_isSealed) <BOOL>
 * 5: Now, diag_tickTime <NUMBER>
 * 6: The most room the words may take, in screen units <NUMBER>
 * 7: Font <STRING>
 * 8: Font size <NUMBER>
 *
 * Return Value:
 * The words, "" when the box has nothing left of that kind <STRING>
 *
 * Example:
 * [_crate, "search", false, false, false, diag_tickTime, 0.1, "PuristaSemibold", 0.012] call aio_gui_fnc_statusWords;
 *
 * Public: No
 */

params ["_holder", "_kind", "_stopped", "_idle", "_sealed", "_now", "_room", "_font", "_size"];

private _long = "";
private _short = "";

if (_kind isEqualTo "hands") then {
    private _index = GVAR(handBoxes) findIf {(_x get "holder") isEqualTo _holder};

    if (_index < 0) exitWith {};

    private _record = GVAR(handBoxes) select _index;
    private _total = _record get "total";
    private _at = ((_record get "done") + 1) min _total;

    // Parenthesised: max binds tighter than find, so without the brackets it was asked of the verb (a string) itself.
    private _verb = (["grab", "put", "drop", "move", "gear"] find (_record get "verb")) max 0;

    _long = format [
        [LLSTRING(Status_Grab), LLSTRING(Status_Put), LLSTRING(Status_Drop), LLSTRING(Status_Move), LLSTRING(Status_Gear)] select _verb,
        _at, _total
    ];
    _short = format ["%1 / %2", _at, _total];
} else {
    private _perCell = [_holder] call FUNC(searchTime);
    private _left = 0;
    private _items = 0;

    {
        if ((_x select 0) isEqualTo _holder) then {
            _left = _left + _perCell * (_x select 4);
            _items = _items + 1;
        };
    } forEach GVAR(searchQueue);

    if (_items == 0) exitWith {};

    // What the entry being searched has run already.
    private _run = GVAR(searchRuns) param [GVAR(searchRuns) findIf {(_x select 0) isEqualTo _holder}, []];

    if (!_stopped && {_run isNotEqualTo []}) then {
        _left = _left - ((_now - (_run select 2)) min (_run select 3));
    };

    private _seconds = ceil (_left max 0);
    private _rest = _seconds mod 60;
    private _clock = format ["%1:%2", floor (_seconds / 60), ["", "0"] select (_rest < 10)] + str _rest;
    private _words = [LLSTRING(Status_Search), [LLSTRING(Status_Stopped), LLSTRING(Status_Idle)] select _idle] select _stopped;

    if (_sealed) then {
        _long = trim format [_words, ""];
        _short = _long;
    } else {
        _long = format [_words, _clock];
        _short = _clock;
    };
};

if (_long isEqualTo "") exitWith {""};

if (((_long getTextWidth [_font, _size]) * TEXT_SLACK) <= _room) exitWith {_long};

[_short, _room, _font, _size] call FUNC(fitText)
