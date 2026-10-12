#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Checks the next few loadouts against the game and this arsenal with ACE's own functions -
 * VERIFY_PER_FRAME of them a frame - and keeps the answer: how many of its items are missing from the game,
 * and how many are not offered here.
 *
 * A loadout is checked as ACE's list checks it (verifyLoadout in "recover" mode, then
 * recoverInvalidContainers, which puts the soldier's own containers in place of ones this game lacks), the
 * same for Mine, Default and Public ones: the answer is what a load puts on, so nothing is ever set from
 * a loadout that was not checked. The loadouts to check wait in GVAR(verifyQueue), put there by
 * fnc_loadoutsData; the answers are kept in GVAR(verified) as [supply stamp, print of the loadout, answer]
 * by "tab|id", and hold until the loadout or the supply changes. With ace_arsenal_EnableRPTLog on, what is
 * missing is written to the RPT once for each answer, as ACE's list does.
 *
 * Given a row of fnc_loadoutsData, that one is checked at once, for an action that cannot wait its turn.
 *
 * Arguments:
 * 0: A row of fnc_loadoutsData, to check now <ARRAY> (default: [])
 *
 * Return Value:
 * The keys ("tab|id") of the loadouts checked, or with a row ACE's answer for it - [[loadout, extended
 * info], items missing from the game, items not offered here, extended info missing] <ARRAY>
 *
 * Example:
 * call einv_arsenal_fnc_verifyStep;
 *
 * Public: No
 */

params [["_row", [], [[]]]];

private _unit = GVAR(center);

if (isNull _unit) exitWith {[]};

private _fnc_check = {
    params ["_key", "_name", "_data", "_print"];

    // A copy: the check may turn the extended info of the stored loadout from an array into a map.
    private _answer = [+_data, true] call ACEFUNC(arsenal,verifyLoadout);
    _answer = [_unit, _answer] call ACEFUNC(arsenal,recoverInvalidContainers);

    GVAR(verified) set [_key, [GVAR(availableStamp), _print, _answer]];

    _answer params ["", "_missing", "_notHere", "_noInfo"];

    if (missionNamespace getVariable [QACEGVAR(arsenal,EnableRPTLog), false] && {_missing isNotEqualTo [] || {_notHere isNotEqualTo []} || {_noInfo isNotEqualTo []}}) then {
        diag_log text format [
            "ACE_Arsenal - Loadout:%5    Name: %1%5    Missing items: %2%5    Unavailable items: %3%5    Missing extended loadout: %4",
            _name, str _missing, str _notHere, str _noInfo, endl
        ];
    };

    _answer
};

// One at once.
if (_row isNotEqualTo []) exitWith {
    _row params ["_name", "_data", "", "", "_tab", "", "_id"];

    [_tab + "|" + _id, _name, _data, hashValue (str _data)] call _fnc_check
};

private _done = [];

for "_i" from 1 to VERIFY_PER_FRAME do {
    if (GVAR(verifyQueue) isEqualTo []) exitWith {};

    (GVAR(verifyQueue) deleteAt 0) params ["_key", "", "_name", "_data", "_print"];

    // Asked for twice, or answered meanwhile.
    private _known = GVAR(verified) getOrDefault [_key, []];

    if !((_known param [0, -1]) == GVAR(availableStamp) && {(_known param [1, ""]) isEqualTo _print}) then {
        [_key, _name, _data, _print] call _fnc_check;
    };

    _done pushBack _key;
};

_done
