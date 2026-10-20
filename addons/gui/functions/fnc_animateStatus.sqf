#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The caption lines' activity chips, every frame while one stands (fnc_onFrame, GVAR(statusLive)): the ring goes round
 * (one ctrlSetAngle on one control per chip) and the words are written in place when they changed - the hands' count
 * when an item of the queue finished, the search's time once a second. Nothing is made here. A chip whose box has
 * nothing left to do (the queue's last item was sent, the last item found) asks fnc_updateStatus, which deletes it.
 *
 * The search's time is what is left of the box's items: their cells at the time per cell, less what the item being
 * searched has run.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Now, diag_tickTime <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call einv_gui_fnc_animateStatus;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_now"];

if (!GVAR(statusLive)) exitWith {};

private _second = floor _now;
private _tick = _second != GVAR(statusSecond);

GVAR(statusSecond) = _second;

private _resync = false;

// The words as they are when they fit the room of the chip's label, else the short ones, else cut.
private _fnc_fit = {
    params ["_long", "_short", "_status"];

    private _room = _status get "labelW";
    private _font = _status get "font";
    private _size = _status get "size";

    if (((_long getTextWidth [_font, _size]) * TEXT_SLACK) <= _room) exitWith {_long};

    [_short, _room, _font, _size] call FUNC(fitText)
};

{
    // A sealed block's ring (fnc_drawSection), shown while its box is searched (fnc_updateStatus).
    private _sealArc = (_x getOrDefault ["seal", createHashMap]) getOrDefault ["arc", controlNull];

    if (!isNull _sealArc && {ctrlShown _sealArc}) then {
        _sealArc ctrlSetAngle [(_now * STATUS_SPIN_SPEED) mod 360, 0.5, 0.5];
    };

    private _status = _x getOrDefault ["status", createHashMap];

    if (count _status == 0) then {continue};

    private _holder = _x getOrDefault ["holder", objNull];
    private _kind = _status get "kind";
    private _text = _status get "text";

    // The ring: round and round.
    private _arc = _status get "arc";

    if (!isNull _arc) then {
        _arc ctrlSetAngle [(_now * STATUS_SPIN_SPEED) mod 360, 0.5, 0.5];
    };

    if (_kind isEqualTo "hands") then {
        private _record = GVAR(handBoxes) findIf {(_x get "holder") isEqualTo _holder};

        if (_record < 0) then {
            _resync = true;
            continue;
        };

        _record = GVAR(handBoxes) select _record;

        private _total = _record get "total";

        // Parenthesised: max binds tighter than find, so without the brackets it was asked of the verb (a string) itself.
        private _verb = (["grab", "put", "drop", "move", "gear"] find (_record get "verb")) max 0;
        private _words = format [
            [
                LLSTRING(Status_Grab), LLSTRING(Status_Put), LLSTRING(Status_Drop), LLSTRING(Status_Move), LLSTRING(Status_Gear)
            ] select _verb,
            ((_record get "done") + 1) min _total, _total
        ];

        // Too long for the room the line gave it: the count alone.
        _words = [_words, format ["%1 / %2", ((_record get "done") + 1) min _total, _total], _status] call _fnc_fit;

        if (_words isNotEqualTo _text) then {
            (_status get "label") ctrlSetText _words;
            _status set ["text", _words];
        };
    } else {
        // Once a second is as often as a time that counts seconds changes.
        if (!_tick && {_text isNotEqualTo ""}) then {continue};

        private _left = 0;
        private _items = 0;

        {
            if ((_x select 0) isEqualTo _holder) then {
                _left = _left + GVAR(searchTime) * (_x select 4);
                _items = _items + 1;
            };
        } forEach GVAR(searchQueue);

        if (_items == 0) then {
            _resync = true;
            continue;
        };

        // What the item being searched has run already.
        if (!(_status get "stopped") && {GVAR(searchStarted) >= 0} && {(GVAR(searchHead) param [0, objNull]) isEqualTo _holder}) then {
            _left = _left - ((_now - GVAR(searchStarted)) min (GVAR(searchTime) * (GVAR(searchHead) param [4, 1])));
        };

        private _seconds = ceil (_left max 0);
        private _rest = _seconds mod 60;
        private _clock = format ["%1:%2", floor (_seconds / 60), ["", "0"] select (_rest < 10)] + str _rest;

        // A sealed box says no time: it would tell how much the container holds (fnc_isSealed).
        private _sealedBox = _x getOrDefault ["sealed", false];

        if (_sealedBox) then {
            _clock = "";
        };

        private _words = trim format [[LLSTRING(Status_Search), [LLSTRING(Status_Stopped), LLSTRING(Status_Idle)] select (_status getOrDefault ["idle", false])] select (_status get "stopped"), _clock];

        _words = [_words, [_clock, _words] select _sealedBox, _status] call _fnc_fit;

        if (_words isNotEqualTo _text) then {
            (_status get "label") ctrlSetText _words;
            _status set ["text", _words];
        };
    };
} forEach (uiNamespace getVariable [QGVAR(sectionInfo), []]);

// Something ended: the chips are made true again (one pass, and the next frame finds nothing to ask).
if (_resync) then {
    [_display] call FUNC(updateStatus);
};
