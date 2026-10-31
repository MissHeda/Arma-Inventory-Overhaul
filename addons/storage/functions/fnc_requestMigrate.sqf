#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks the unit's authority to move the surplus of its uniform, vest and backpack on (op "migrate",
 * fnc_opMigrate) - when there is some that has somewhere to go. This machine looks first, from the cargo
 * and places it reads (fnc_getLayout is the same picture everywhere): for each container but the last, its
 * overflow entries planned into the containers after it (fnc_plan). Nothing is asked when nothing could
 * move, so a unit whose surplus fits nowhere costs one look and no transaction.
 *
 * The request is a silent transaction of one op on the unit as root (fnc_request): it runs at once for this
 * machine's own player unit and in single player, else through the server's hub on whichever machine the
 * unit is local. The requester is the unit itself unless another is given - a looter's window passes the
 * player -, so reach and the person guard have nothing to say about a unit's own gear. An answer that says
 * the op did not run ("NotReady": the server has not answered this machine's greeting yet; "Moved", "Failed":
 * the unit changed hands, the phase broke) queues the unit once more (fnc_queueMigrate), at most
 * MIGRATE_TRIES times.
 *
 * Strict mode rides along: when the unit's hidden holder and its containers disagree with the settings
 * (fnc_hiddenDue) the phase starts with op "strict" (fnc_opStrict), before the surplus - also under an open
 * arsenal, which is when the holder gives everything back, and with the surplus switch off.
 *
 * Nothing in Eden; no surplus while an arsenal is open (ARSENAL_OPEN) or with the setting
 * einv_storage_migrate off. Not for use inside a running phase: it starts a transaction.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Requester - whose reach counts <OBJECT> (default: the unit)
 * 2: Tries so far <NUMBER> (default: 0)
 *
 * Return Value:
 * A request was made <BOOL>
 *
 * Example:
 * [player] call einv_storage_fnc_requestMigrate;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_requester", objNull, [objNull]], ["_tries", 0, [0]]];

if (is3DEN || {isNull _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {false};

// A worn container changed since the last look (a swap in the window, a script, an arsenal): the other
// containers are left exactly as they are for a while - nothing moves between them because one was swapped.
// Only the changed container has a fresh layout; what it cannot hold stays shown as overflow until then.
private _held = ([_unit] call FUNC(wornHeld)) > 0;

private _ops = [];

// Strict mode first: the hidden holder and the containers disagree with the settings (fnc_hiddenDue,
// op "strict"). Also while an arsenal is open - that is when the holder gives everything back.
if ([_unit] call FUNC(hiddenDue)) then {
    _ops pushBack ["strict", [_unit]];
};

// Then the surplus - not under an open arsenal, not with the switch off.
if (!_held && {!ARSENAL_OPEN} && {missionNamespace getVariable [QGVAR(migrate), true]}) then {
    // Uniform, vest, backpack - those the unit has. getSections also marks each with its unit, which the
    // compartments depend on (fnc_getOwner).
    private _containers = ([_unit] call FUNC(getSections)) apply {_x get "container"};
    private _movable = false;

    for "_i" from 0 to (count _containers - 2) do {
        private _from = _containers select _i;
        private _over = ([_from, [_from] call FUNC(getContents)] call FUNC(getLayout)) get "overflow";

        if (_over isEqualTo []) then {continue};

        private _targets = (_containers select [_i + 1]) apply {[_x, _unit]};

        if ((([_over, _targets] call FUNC(plan)) select 0) isNotEqualTo []) exitWith {
            _movable = true;
        };
    };

    if (_movable) then {
        _ops pushBack ["migrate", [_unit]];
    };
};

if (_ops isEqualTo []) exitWith {false};

if (isNull _requester) then {
    _requester = _unit;
};

[[[_unit, _ops]], {
    params ["", "_summary", "", "_args"];
    _args params ["_unit", "_requester", "_tries"];

    // The statuses of the ops of the one phase: one that did not run queues the unit again.
    private _statuses = ((_summary param [0, []]) param [0, []]) apply {_x param [0, "Failed"]};

    if ((_statuses findIf {_x in ["NotReady", "Moved", "NotLocal", "Failed"]}) >= 0 && {_tries < MIGRATE_TRIES}) then {
        [_unit, MIGRATE_RETRY, _tries + 1, _requester] call FUNC(queueMigrate);
    };
}, [_unit, _requester, _tries], false, _requester] call FUNC(request);

true
