#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the inventory handler onto a unit the player now controls - or, asked to, behind every other
 * handler of the event again.
 *
 * A plain event handler rather than a CBA class event handler: only the unit's own handler can
 * answer the engine with true and so keep the vanilla inventory from opening. It always answers true -
 * there is no vanilla inventory to let through, this window opens in its place (fnc_onInventoryOpened).
 * A vanilla inventory that loads anyway - another mod's handler, a script, a script error in this
 * one - is closed at once (fnc_guardVanilla).
 *
 * A unit can have any number of InventoryOpened handlers - Better Inventory's runs from CBA's, SFX Project:
 * Remastered adds a plain one that answers nothing once the mission's display exists - and which answer
 * the engine goes by is the engine's business: with another mod's handler behind this one the display
 * can open for all that this one said true (the RPT then says "came up although the handler answered").
 * The window does not depend on it - the guard closes the display as it loads and the window opens a frame
 * later (fnc_guardVanilla, fnc_open) - but a display that never opens beats one that opens and is closed
 * again, so this handler is kept behind the others. The others are never touched: only this one, by its
 * id, is taken off and added again (never removeAllEventHandlers), so their sounds and work go on.
 *
 * It goes behind the others when a unit is first handled and on every CBA unit event (XEH_postInit: the
 * first body, a respawn, a team switch and the soldier a Zeus remote controls all arrive there), once
 * HANDLER_RECHECK seconds after the mission's display exists (XEH_postInit: other mods add theirs in a
 * postInit or in a script that waits for that display) and whenever a vanilla inventory came up although
 * this handler had answered (fnc_guardVanilla).
 *
 * Without _again, once per unit. The handler stays on a unit the player leaves, where
 * fnc_onInventoryOpened opens nothing but still blocks the vanilla inventory.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Take the handler off and add it again, behind the others <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call aio_gui_fnc_initUnit;
 * [player, true] call aio_gui_fnc_initUnit;
 *
 * Public: No
 */

params ["_unit", ["_again", false, [false]]];

if (isNull _unit) exitWith {};

private _old = _unit getVariable [QGVAR(inventoryHandler), -1];

if (_old >= 0 && {!_again}) exitWith {};

// This mod's own handler only, by its id: the others stay where they are.
if (_old >= 0) then {
    _unit removeEventHandler ["InventoryOpened", _old];
};

private _id = _unit addEventHandler ["InventoryOpened", {
    _this call FUNC(onInventoryOpened);

    true
}];
_unit setVariable [QGVAR(inventoryHandler), _id];
