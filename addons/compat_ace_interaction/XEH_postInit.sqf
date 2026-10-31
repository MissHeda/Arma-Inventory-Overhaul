#include "script_component.hpp"

// ACE's interaction menu is the player's own: nothing to add where nobody looks at a screen.
if (!hasInterface) exitWith {};

// ACE interaction on a person > Inventory: the same as the action menu's "Inventory" on them
// (einv_gui_fnc_addPersonAction), for players who reach for ACE's menu first. That entry stays. On the
// person's class with inheritance, so every soldier, civilian and agent has it without being touched one
// by one, respawned ones included. Under the main actions ("Interactions"), where ACE puts what is done
// to the person in front of you.
private _action = [
    QGVAR(inventory),
    LLSTRING(Action_Inventory),
    QPATHTOEF(gui,ui\icon_inventory_ca.paa),
    {
        params ["_target"];

        // Out of the menu's own frame, as the action menu's entry does: the window is a dialog, made once
        // ACE's menu has closed.
        [{_this call EFUNC(gui,openPerson)}, [_target]] call CBA_fnc_execNextFrame;
    },
    {
        params ["_target", "_player"];

        [_target, _player] call FUNC(canOpen)
    }
] call ACEFUNC(interact_menu,createAction);

["CAManBase", 0, ["ACE_MainActions"], _action, true] call ACEFUNC(interact_menu,addActionToClass);

// ACE interaction on a vehicle > Inventory: the window on its cargo, as the engine's own Gear action opens it,
// for players who reach for ACE's menu first. Cars, tanks, static weapons, helicopters, planes and boats, by
// their base classes with inheritance, under the main actions ACE gives each of them. Shown exactly when the
// window may open on it (einv_gui_fnc_canOpenVehicle: alive, cells to show, the player on foot within the
// window's reach, not locked to him).
private _vehicleAction = [
    QGVAR(vehicleInventory),
    LLSTRING(Action_Inventory),
    QPATHTOEF(gui,ui\icon_inventory_ca.paa),
    {
        params ["_target", "_player"];

        // Out of the menu's own frame, and through the unit's handler as the engine's Gear action goes: the
        // same RPT lines and the same lock click, and the window a frame after that.
        [{_this call EFUNC(gui,onInventoryOpened)}, [_player, _target, objNull]] call CBA_fnc_execNextFrame;
    },
    {
        params ["_target", "_player"];

        [_player, _target] call EFUNC(gui,canOpenVehicle)
    }
] call ACEFUNC(interact_menu,createAction);

{
    [_x, 0, ["ACE_MainActions"], _vehicleAction, true] call ACEFUNC(interact_menu,addActionToClass);
} forEach ["LandVehicle", "Air", "Ship"];
