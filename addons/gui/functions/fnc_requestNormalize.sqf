#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Reports drift to the authorities, from fnc_onFrame at each signature check: a holder whose places and
 * cargo have disagreed for DRIFT_WAIT seconds (GVAR(drift)) and was not reported in the last
 * DRIFT_REPEAT seconds gets a silent transaction of one op, "normalize", with this machine's revision
 * and the hash of the records it holds - a holder local here runs it at once. The authority persists
 * exactly what every window already showed, and re-writes a stale copy.
 *
 * Not for a holder a move of this window is under way in (GVAR(inFlight)) - its places come with the
 * answer -, nor while the server's hub has not answered this client's greeting for a holder only the hub
 * reaches (einv_storage_fnc_hubReady): it is asked again at a later check. A holder gone null drops out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_requestNormalize;
 *
 * Public: No
 */

GVAR(drift) = GVAR(drift) select {
    private _holder = _x param [0, objNull];

    _holder isEqualType "" || {_holder isEqualType objNull && {!isNull _holder}}
};

if (GVAR(drift) isEqualTo []) exitWith {};

private _now = diag_tickTime;
private _ready = call EFUNC(storage,hubReady);

// Holders a move of this window is under way in settle by themselves.
private _busy = [];

{
    _y params [["_sources", [], [[]]], ["_targets", [], [[]]]];

    {_busy pushBackUnique (_x param [0, objNull])} forEach _sources;
    {_busy pushBackUnique (_x param [0, objNull])} forEach _targets;
} forEach GVAR(inFlight);

{
    _x params ["_holder", ["_root", objNull], ["_since", _now]];

    if (_now - _since < DRIFT_WAIT || {_holder in _busy}) then {continue};

    private _isKey = _holder isEqualType "";

    private _last = if (_isKey) then {
        GVAR(driftKits) getOrDefault [_holder, -1e9]
    } else {
        _holder getVariable [QGVAR(normalizedAt), -1e9]
    };

    if (_now - _last < DRIFT_REPEAT) then {continue};

    if (!(_root isEqualType objNull) || {isNull _root}) then {
        private _parent = objNull;

        if (!_isKey) then {
            private _index = GVAR(opened) findIf {(_x select 1) isEqualTo _holder};

            if (_index >= 0) then {
                _parent = (GVAR(opened) select _index) param [2, objNull];
            };
        };

        _root = [_holder, _parent] call EFUNC(storage,rootOf);
    };

    if (isNull _root) then {continue};
    if (!_ready && {!([_root] call EFUNC(storage,isLocalRoot))}) then {continue};

    if (_isKey) then {
        GVAR(driftKits) set [_holder, _now];
    } else {
        _holder setVariable [QGVAR(normalizedAt), _now];
    };

    // What this machine holds, so the authority can tell a stale copy here from a drift everywhere.
    ([_holder] call EFUNC(storage,readPlaces)) params [["_revision", 0], ["_records", []]];

    [[[_root, [["normalize", [_holder, _revision, hashValue _records]]]]], {}, [], true] call EFUNC(storage,request);
} forEach GVAR(drift);
