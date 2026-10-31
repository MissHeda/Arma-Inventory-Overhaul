#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The condition of the person action for agents (fnc_addAgentAction), on the player's own soldier:
 * whether the player looks at an agent within reach that may be opened now. The rest - permissions,
 * ACE's conditions and the entry's text - is the person action's (fnc_personActionCondition), and the
 * agent found is kept for the action to open (GVAR(actionAgent)).
 *
 * An action on the player's own soldier is asked every frame, so the cheap checks come first. Within
 * the person action's own reach: from the player's eyes to the agent's feet, as the engine measures it.
 *
 * Arguments:
 * 0: Soldier the action is on <OBJECT>
 * 1: Action id <NUMBER>
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [player, 4] call aio_gui_fnc_agentActionCondition;
 *
 * Public: No
 */

params ["_holder", "_actionId"];

// The action stays on a unit the player left - only the one the player is now offers it.
if (_holder isNotEqualTo ACE_player) exitWith {false};

private _agent = cursorObject;

if (
    !(_agent isKindOf "CAManBase")
    || {(eyePos _holder) distance (getPosASL _agent) > PERSON_REACH}
    || {!isAgent teamMember _agent}
    || {!([_agent, _actionId, _holder] call FUNC(personActionCondition))}
) exitWith {false};

GVAR(actionAgent) = _agent;

true
