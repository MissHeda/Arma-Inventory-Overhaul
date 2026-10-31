#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Every frame while a repack runs (einv_gui_fnc_onFrame calls it, and nothing else of the window's
 * per-frame work). First what ACE's progress bar asks every frame - the same player, alive, free to use the
 * hands (ACE's own exceptions: inside, swimming and sitting are fine) -, else the repack is interrupted.
 * Then every step of ACE's schedule whose time has come is carried out: a round moved (or a belt link
 * joined), or a magazine done. A slow frame can bring several; they sound once, a magazine's before a
 * round's, with ACE's own sounds. The bars and rounds on the tiles follow (fnc_showProgress), the ring
 * fills with the time and the hint counts the seconds down. Nothing changes in the cargo until it ends.
 *
 * Arguments:
 * 0: Display - not looked at, the job holds everything <DISPLAY>
 * 1: Now, diag_tickTime - not looked at either <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call einv_magazines_fnc_onFrame;
 *
 * Public: No
 */

disableSerialization;

private _job = GVAR(job);

if (count _job == 0) exitWith {};

private _unit = _job get "unit";

// What ACE's progress bar asks every frame: the same player, alive, free to use the hands.
if (
    !alive _unit || {_unit isNotEqualTo ACE_player}
    || {!([_unit, objNull, REPACK_EXCEPTIONS] call ACEFUNC(common,canInteractWith))}
) exitWith {
    ["Interrupted"] call FUNC(stop);
};

private _elapsed = CBA_missionTime - (_job get "start");
private _events = _job get "events";
private _done = _job get "done";
private _sound = "";

// Every step whose time has come.
while {_done < count _events && {((_events select _done) select 0) <= _elapsed}} do {
    (_events select _done) params ["", "_isBullet", "_counts"];

    private _before = _job get "counts";

    // The magazine that took a round (or a link) is the one being filled now.
    {
        if (_x > (_before select _forEachIndex)) exitWith {
            _job set ["receiving", _forEachIndex];
        };
    } forEach _counts;

    _job set ["counts", +_counts];

    if (!_isBullet || {_sound isEqualTo ""}) then {
        _sound = [QACEGVAR(magazinerepack,soundMagazineFinished), QACEGVAR(magazinerepack,soundRoundFinished)] select _isBullet;
    };

    _done = _done + 1;
};

_job set ["done", _done];

if (_sound isNotEqualTo "") then {
    [_sound, "repack"] call EFUNC(gui,playClass);

    [] call FUNC(showProgress);
};

if (_done >= count _events) exitWith {
    ["Done"] call FUNC(stop);
};

// The ring fills with the time, the hint counts the seconds down.
private _fx = uiNamespace getVariable [QGVAR(fx), createHashMap];
private _arc = (_fx getOrDefault ["ring", []]) param [1, controlNull];
private _step = ((ceil ((_elapsed / (_job get "total")) * SEARCH_FRAMES)) max 1) min SEARCH_FRAMES;

if (!isNull _arc && {_step != (_fx getOrDefault ["step", 0])}) then {
    _arc ctrlSetText REPACK_RING(_step);
    _fx set ["step", _step];
};

private _left = ceil (((_job get "total") - _elapsed) max 0);

if (_left != (_job get "hintLeft")) then {
    _job set ["hintLeft", _left];
    [format [LLSTRING(Hint_Repacking), _job get "name", _left]] call EFUNC(gui,showHint);
};
