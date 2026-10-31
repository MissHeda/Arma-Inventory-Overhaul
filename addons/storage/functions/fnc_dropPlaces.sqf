#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Forgets where things lie in a holder, for everyone - on its authority only. Used when Enhanced First
 * Aid Kits frees a kit instance class (aio_compat_efak): that mod reuses instance classes, so the next
 * kit of the class must not inherit the arrangement, and the variable must leave what joining players
 * receive. Objects need nothing: their variables go with them - one dropped all the same loses its
 * places and its copy on the outermost container it lies in.
 *
 * A kit's root is found through its type (GVAR(holderTypes) "root"): a kit found nowhere has the server
 * as its authority, so a kit is best dropped while it still lies somewhere - inside the op that frees it.
 * Within a running phase its buffered records go as well, so the phase's last write does not bring them
 * back.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["kit:efak_ifak_7"] call aio_storage_fnc_dropPlaces;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]]];

private _isKey = _holder isEqualType "";

if ((_isKey && {_holder isEqualTo ""}) || {!_isKey && {isNull _holder}}) exitWith {};

private _root = [_holder] call FUNC(rootOf);

// Only the authority drops; a phase running here was checked for that already.
private _authority = !isMultiplayer || {GVAR(executing)} || {GVAR(journalKey) isNotEqualTo ""} || {
    if (isNull _root) then {isServer} else {local _root}
};

if (!_authority) exitWith {
    private _name = if (_isKey) then {_holder} else {typeOf _holder};
    private _machine = call FUNC(machineId);

    WARNING_2("Places of %1 dropped on machine %2, which is not its authority - kept.",_name,_machine);
};

if (_isKey) then {
    missionNamespace setVariable [format ["%1_%2", QGVAR(places), (_holder splitString ":") joinString "_"], nil, isMultiplayer];

    // Pending heal checks find no latest write any more and do nothing.
    GVAR(writtenKits) deleteAt _holder;
} else {
    _holder setVariable [QGVAR(places), nil, isMultiplayer];
    _holder setVariable [QGVAR(written), nil];

    if (isMultiplayer) then {
        private _top = [_holder, objNull, "top"] call FUNC(rootOf);
        private _nested = _top getVariable [QGVAR(nested), []];

        if (_top isNotEqualTo _holder && {_nested isEqualType []}) then {
            private _netId = netId _holder;
            private _kept = _nested select {!(_x isEqualTypeArray ["", "", "", []]) || {(_x select 0) isNotEqualTo _netId}};

            if (count _kept != count _nested) then {
                _top setVariable [QGVAR(nested), _kept, true];
            };
        };
    };
};

if (GVAR(executing)) then {
    private _index = GVAR(buffer) findIf {(_x select 0) isEqualTo _holder};

    if (_index >= 0) then {GVAR(buffer) deleteAt _index};
};
