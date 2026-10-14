#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the inventory handler onto a unit the player now controls.
 *
 * A plain event handler rather than a CBA class event handler: only the unit's own handler can
 * answer the engine with true and so keep the vanilla inventory from opening. It always answers true -
 * there is no vanilla inventory to let through, this window opens in its place (fnc_onInventoryOpened).
 * A vanilla inventory that loads anyway - another mod's handler, a script, a script error in this
 * one - is closed at once (fnc_guardVanilla).
 *
 * Once per unit. Called for the unit the player is now by the CBA unit event (XEH_postInit): the first
 * body, a respawn, a team switch and the soldier a Zeus remote controls all arrive there. The handler
 * stays on a unit the player leaves, where fnc_onInventoryOpened opens nothing but still blocks the
 * vanilla inventory.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call einv_gui_fnc_initUnit;
 *
 * Public: No
 */

params ["_unit"];

if (isNull _unit || {(_unit getVariable [QGVAR(inventoryHandler), -1]) >= 0}) exitWith {};

private _id = _unit addEventHandler ["InventoryOpened", {
    _this call FUNC(onInventoryOpened);

    true
}];
_unit setVariable [QGVAR(inventoryHandler), _id];
