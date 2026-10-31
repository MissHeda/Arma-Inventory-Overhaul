#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit's hidden holder and its containers disagree with the settings, so that op "strict"
 * (fnc_opStrict) has something to do - looked at from the cargo and the holder this machine reads, before a
 * transaction is asked for (fnc_requestMigrate). True when:
 *
 *   - the holder keeps things of a kind whose container is not Strict any more, or the holder is not in
 *     force (fnc_hiddenActive: the unit died, became an AI, an arsenal is open): they go back;
 *   - the holder keeps things taken out of a container that is not the one worn now: they follow it, or go
 *     with it;
 *   - the holder keeps something that is whitelisted meanwhile (the rules changed): it goes back;
 *   - a Strict container holds, in its cargo, something of a limited kind that is not whitelisted (a
 *     script, a loadout, the engine, ACE put it there): it goes into the holder.
 *
 * Nothing in Eden. Costs a few cargo reads for the player's own unit on each look.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Something to do <BOOL>
 *
 * Example:
 * [player] call aio_storage_fnc_hiddenDue;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (is3DEN || {isNull _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {false};

private _strictActive = missionNamespace getVariable [QGVAR(strictActive), false];
private _hasHolder = !isNil {_unit getVariable QGVAR(hidden)};

if (!_strictActive && {!_hasHolder}) exitWith {false};

([_unit] call FUNC(hiddenLists)) params ["_lists", "_containers"];

private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _active = _strictActive && {[_unit] call FUNC(hiddenActive)};

([0, 1, 2] findIf {
    private _kind = USE_KINDS select _x;
    private _container = _own select _x;
    private _list = _lists select _x;
    private _strict = _active && {!isNull _container} && {([_kind] call FUNC(useMode)) isEqualTo USE_STRICT};

    if (_list isNotEqualTo [] && {
        !_strict
        || {(_containers select _x) isNotEqualTo _container}
        || {(_list findIf {([_x select 0, _kind] call FUNC(useState)) isNotEqualTo "blocked"}) >= 0}
    }) exitWith {true};

    _strict && {
        (((getItemCargo _container) select 0) findIf {([_x, _kind] call FUNC(useState)) isEqualTo "blocked"}) >= 0
        || {((magazineCargo _container) findIf {([_x, _kind] call FUNC(useState)) isEqualTo "blocked"}) >= 0}
    }
}) >= 0
