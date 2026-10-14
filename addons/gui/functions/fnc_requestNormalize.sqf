#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Asks the authorities to repair what the window shows, from fnc_onFrame at each signature check.
 *
 * Surplus: a person (the player's own unit, a body, someone looted) whose uniform, vest or backpack shows an
 * overflow tile is asked to pass what it can on to its next container with room
 * (einv_storage_fnc_requestMigrate, op "migrate"), once per DRIFT_REPEAT seconds per person.
 *
 * Drift: a holder whose places and cargo have disagreed for DRIFT_WAIT seconds (GVAR(drift)) and was not
 * reported in the last DRIFT_REPEAT seconds gets a silent transaction of one op, "normalize", with this
 * machine's revision and the hash of the records it holds - a holder local here runs it at once. The
 * authority persists exactly what every window already showed, and re-writes a stale copy.
 *
 * Neither is asked for a holder a move of this window is under way in (GVAR(inFlight)) - its places come
 * with the answer -, nor while the server's hub has not answered this client's greeting for a holder only
 * the hub reaches (einv_storage_fnc_hubReady): it is asked again at a later check. A holder gone null drops
 * out of the drift list.
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

private _now = diag_tickTime;
private _ready = call EFUNC(storage,hubReady);

// Holders a move of this window is under way in settle by themselves.
private _busy = [];

{
    _y params [["_sources", [], [[]]], ["_targets", [], [[]]]];

    {_busy pushBackUnique (_x param [0, objNull])} forEach _sources;
    {_busy pushBackUnique (_x param [0, objNull])} forEach _targets;
} forEach GVAR(inFlight);

// Surplus: a person's uniform, vest or backpack that shows an overflow tile - something a script, a loadout or
// the engine put in beyond the grid - is asked to pass it on to the person's next container with room (op
// "migrate", einv_storage_fnc_requestMigrate, which looks first and asks for nothing when nothing could move).
// The player's own unit is looked after when its loadout changes, with the window shut as well; this is for
// what lies around - a body, a person - and the safety net for the own gear. Only for what is drawn, at most
// every DRIFT_REPEAT seconds per person, and not while a move of this window is under way in it.
private _persons = [];

{
    private _root = _x getOrDefault ["root", objNull];
    private _holder = _x getOrDefault ["holder", objNull];

    if (
        (_x getOrDefault ["overflow", false])
        && {_root isEqualType objNull} && {!isNull _root} && {_root isKindOf "CAManBase"}
        && {_holder isEqualType objNull} && {_holder in [uniformContainer _root, vestContainer _root, backpackContainer _root]}
    ) then {
        _persons pushBackUnique _root;
    };
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

{
    private _person = _x;
    private _worn = [uniformContainer _person, vestContainer _person, backpackContainer _person];

    if (_now - (_person getVariable [QGVAR(migratedAt), -1e9]) < DRIFT_REPEAT) then {continue};
    if (_busy findIf {_x in _worn} >= 0) then {continue};
    if (!_ready && {!([_person] call EFUNC(storage,isLocalRoot))}) then {continue};

    _person setVariable [QGVAR(migratedAt), _now];

    [_person, missionNamespace getVariable ["ACE_player", player]] call EFUNC(storage,requestMigrate);
} forEach _persons;

// Drift: places and cargo that disagree.
GVAR(drift) = GVAR(drift) select {
    private _holder = _x param [0, objNull];

    _holder isEqualType "" || {_holder isEqualType objNull && {!isNull _holder}}
};

if (GVAR(drift) isEqualTo []) exitWith {};

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
