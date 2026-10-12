#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives the player's own soldier the person action for agents - the civilians of the Civilian Presence
 * module and anyone else made with createAgent. An agent carries no actions (BIKI addAction), so
 * fnc_addPersonAction leaves it out; gui/CfgActions.hpp takes the engine's "Open <backpack>" off it as
 * off everyone. This one stands in: shown while the player looks at an agent within reach
 * (fnc_agentActionCondition), it reads and opens exactly like the person action, and never shows for
 * anyone who carries that one.
 *
 * Once per unit and client, onto whichever unit the player is - again after a respawn, a team switch or
 * while remote controlling with Zeus. A respawned soldier takes this unit's variables along but not its
 * actions, so the mark names the unit it was made for.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call einv_gui_fnc_addAgentAction;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!hasInterface || {isNull _unit} || {((_unit getVariable [QGVAR(agentAction), [objNull, -1]]) select 0) isEqualTo _unit}) exitWith {};

// As the person action: no shortcut, and in the middle of the screen only as the engine's backpack
// action is (fnc_addPersonAction). On the player's own soldier the radius does not matter - the
// condition measures the reach to the agent itself.
private _id = _unit addAction [GVAR(gearText), {
    // The agent the condition found under the crosshair, out of the action's own frame.
    [{_this call FUNC(openPerson)}, [GVAR(actionAgent)]] call CBA_fnc_execNextFrame;
}, nil, GVAR(gearPriority), GVAR(openBagWindow), true, "", toString {
    [_target, _actionId] call FUNC(agentActionCondition)
}];

_unit setUserActionText [_id, GVAR(gearText), GVAR(gearIcon)];
_unit setVariable [QGVAR(agentAction), [_unit, _id]];
_unit setVariable [QGVAR(personActionText), [_id, "whole"]];
