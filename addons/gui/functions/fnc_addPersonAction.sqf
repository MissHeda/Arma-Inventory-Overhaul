#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Gives a soldier the scroll action that opens them - uniform, vest and backpack - in this window,
 * where the engine's own "Open <backpack>" stood (gui/CfgActions.hpp hides that one). It is there
 * whenever the player looks at the soldier within reach, from any side, and reads like the engine's
 * own entry: "Inventory" with the gear icon (fnc_personActionCondition decides when and how).
 *
 * Once per unit and client. A respawned soldier takes this unit's variables along but not its actions,
 * so the mark names the unit it was made for.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_addPersonAction;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!hasInterface || {isNull _unit} || {((_unit getVariable [QGVAR(personAction), [objNull, -1]]) select 0) isEqualTo _unit}) exitWith {};

// An agent carries no actions at all (BIKI addAction): the player's own soldier carries the one for
// agents instead (fnc_addAgentAction).
if (isAgent teamMember _unit) exitWith {};

// No shortcut: the engine's backpack action has none, and the Gear key pressed while looking at a
// teammate keeps opening the player's own inventory. In the middle of the screen only where the engine
// shows its backpack action there (CfgActions OpenBag showWindow - ACE switches it off): a gear icon
// each time the player looks at a teammate up close would be new noise.
private _id = _unit addAction [GVAR(gearText), {
    params ["_target"];

    // Out of the action's own frame, as fnc_onInventoryOpened waits for the engine to finish.
    [{_this call FUNC(openPerson)}, [_target]] call CBA_fnc_execNextFrame;
}, nil, GVAR(gearPriority), GVAR(openBagWindow), true, "", toString {
    [_target, _actionId] call FUNC(personActionCondition)
}, PERSON_REACH];

_unit setUserActionText [_id, GVAR(gearText), GVAR(gearIcon)];
_unit setVariable [QGVAR(personAction), [_unit, _id]];
_unit setVariable [QGVAR(personActionText), [_id, "whole"]];
