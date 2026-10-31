#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "migrate": what a unit's uniform, vest or backpack holds beyond its grid moves on to the next of the
 * unit's containers that has free cells for it - uniform to vest to backpack, never the other way round
 * (unless "wide" is asked for, below). The surplus is what the layout has no room for (fnc_getLayout,
 * "overflow"): the engine's own commands (addItem, addMagazine, addWeapon, a loadout, a script, ACE) know
 * nothing of our cells and fill a container as long as its mass allows. What fits nowhere stays where it is
 * and is shown as overflow, as before. This op drops nothing and copies nothing.
 *
 * Every move is op "move" (fnc_opMove) with the cell fnc_plan found for it, largest first: a spot is checked
 * before anything leaves, out and in are verified by counting, and what did not arrive goes back into the
 * container it came from (forced - an overflow row is fine there). Only what even that could not put back
 * is produced and settles (fnc_settle). The uniform's surplus goes first, then the vest's, each planned
 * from the places the moves before it wrote (fnc_readPlaces reads the phase's buffer), so two moves never
 * plan the same cell. The unit's containers are laid out and written once at the end of the phase
 * (fnc_execute).
 *
 * It runs on the unit's authority like every op, so it needs no reach and no guard of its own: the person
 * guard lets it through for any requester (the unit's own gear moves between its own containers, which
 * changes nothing a viewer could not already see). It does nothing while ACE Arsenal or the vanilla
 * arsenal is open (ARSENAL_OPEN) - the arsenals give back what does not fit themselves - or when the
 * setting aio_storage_migrate is switched off.
 *
 * "wide" is the player's overflow sweep (fnc_requestSweep): after the passes on, what still lies on no cell
 * is offered to the containers before its own as well (fnc_migratePasses), since a free cell anywhere is
 * better than the ground.
 *
 * Extra: [how many tiles moved].
 *
 * Arguments:
 * 0: Args, [unit, wide (default: false)] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done (also when nothing could move), else why not ("Moved" the unit is gone, "Skipped" an
 *     arsenal is open or the switch is off, "Bounced" something is produced)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (aio_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[player], _context] call aio_storage_fnc_opMigrate;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_unit", objNull, [objNull]], ["_wide", false, [false]]];

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {["Moved", [], []]};

if (ARSENAL_OPEN || {!(missionNamespace getVariable [QGVAR(migrate), true])}) exitWith {["Skipped", [], []]};

// Uniform, vest, backpack - those the unit has. getSections also marks each with its unit, which the
// compartments depend on (fnc_getOwner).
private _containers = ([_unit] call FUNC(getSections)) apply {_x get "container"};

// Every move on its own terms, as if it were the only op of the phase: a take looks for later takes of its
// class in the phase's ops and batches them, and these moves have none (fnc_opTake).
private _moveContext = +_context;

_moveContext set ["opIndex", -1];
_moveContext set ["ops", []];
_moveContext set ["batch", createHashMap];

private _moved = 0;
private _produced = [];

{
    _x params ["_fromIndex", "_toIndices"];

    private _from = _containers select _fromIndex;

    // Laid out from the places as the moves so far left them.
    GVAR(cache) deleteAt (netId _from);

    private _over = +(([_from, []] call FUNC(findEntry)) getOrDefault ["overflow", []]);

    if (_over isEqualTo []) then {continue};

    // The order of the unit's containers is the order of preference.
    private _targets = _toIndices apply {[_containers select _x, _unit]};

    ([_over, _targets] call FUNC(plan)) params [["_assigned", [], [[]]]];

    {
        _x params ["_item", "_to", "", "_cell"];

        ([[_from, _to, [_item] call FUNC(entryToArray), -1, _cell], _moveContext] call FUNC(opMove)) params [
            ["_status", "Failed", [""]],
            ["_strays", [], [[]]]
        ];

        if (_status isEqualTo "") then {
            _moved = _moved + 1;
        } else {
            // A cell was planned and the move still failed (issue #23): why, in the RPT.
            private _class = _item getOrDefault ["class", ""];

            INFO_4("Migrate: %1 from %2 to %3 not moved (%4).",_class,typeOf _from,typeOf _to,_status);
        };

        // A move that went wrong hands on what it took out and could not land anywhere: back into the
        // container it came from, whatever the cells there say (forced, verified). What even that does not
        // take is the op's to produce.
        {
            if (_x isEqualType [] && {_x isNotEqualTo []}) then {
                ([[_from, _x, [], true], _moveContext] call FUNC(opPut)) params [
                    ["_putStatus", "Failed", [""]],
                    ["_rest", [], [[]]]
                ];

                if (_putStatus isNotEqualTo "") then {
                    _produced append ([[_x], _rest] select (_putStatus isEqualTo "Bounced"));
                };
            };
        } forEach _strays;
    } forEach _assigned;
} forEach ([count _containers, _wide] call FUNC(migratePasses));

if (_produced isNotEqualTo []) exitWith {["Bounced", _produced, [_moved]]};

["", [], [_moved]]
