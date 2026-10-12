#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the vanilla inventory - closing this window first if it is open. Only the last resort now:
 * when this window cannot be created (fnc_open), the player still gets an inventory. A conscious person
 * opens there only by their backpack (CfgActions OpenBag), and one without a backpack not at all - the
 * player's own inventory opens then. A container that is locked to the player (einv_locks_fnc_canReach)
 * is left out as well: it opens on their own gear only.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container to open next to the unit's own, or objNull for the ground <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorObject] call einv_gui_fnc_openVanilla;
 *
 * Public: Yes
 */

params [["_unit", ACE_player], ["_container", objNull]];

if (!alive _unit) exitWith {};

// Never a container that is locked to the player (einv_locks): the vanilla inventory opens on their own gear.
if (!isNull _container && {!(([_unit, _container] call EFUNC(locks,canReach)) select 0)}) then {
    _container = objNull;
};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    _display closeDisplay 2;
};

// The vanilla inventory shows a conscious person only by their backpack, and nothing of one who has
// none - then the player's own.
private _action = "Gear";
private _wearer = if (_container isKindOf "CAManBase") then {_container} else {objectParent _container};

if (
    alive _wearer && {_wearer isKindOf "CAManBase"} && {_wearer isNotEqualTo _unit}
    && {lifeState _wearer in ["HEALTHY", "INJURED"]}
) then {
    if (isNull backpackContainer _wearer) then {
        _container = objNull;
    } else {
        _action = "OpenBag";
        _container = _wearer;
    };
};

// The engine runs the action and then asks fnc_onInventoryOpened, which lets it through once. The
// window goes first; the action comes a frame later, once it is gone.
[{
    params ["_unit", "_container", "_action"];

    GVAR(bypassUntil) = diag_tickTime + 1;
    _unit action [_action, _container];
}, [_unit, _container, _action]] call CBA_fnc_execNextFrame;
