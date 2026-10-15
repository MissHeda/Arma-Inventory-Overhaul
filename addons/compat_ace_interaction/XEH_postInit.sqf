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
