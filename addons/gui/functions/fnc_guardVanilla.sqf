#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes the vanilla inventory (RscDisplayInventory) the moment it is on the screen. The mod has no
 * vanilla inventory to fall back to, with the window open or not: whatever brought one up is undone here.
 *
 * The window replaces the vanilla inventory for good. The unit's handler answers the engine with true
 * (fnc_initUnit, fnc_onInventoryOpened) and no display opens - but another mod can still bring one up
 * behind that answer: Better Inventory (workshop 2791403093) patches the display itself and runs its
 * own handler on the same event, and any mod or script can open it by createDisplay or an action.
 * Left alone, it would appear over the window or in its place.
 *
 * Three places call it, so no way in leaves the display open: the display's load event
 * (Extended_DisplayLoad_EventHandlers, argument 0 is the display), a check every GUARD_INTERVAL seconds
 * on every client (XEH_postInit) for one that loaded without raising the event, and fnc_onFrame while
 * the window is open. Its controls are hidden first, so nothing of it is drawn before it is gone.
 *
 * Arguments:
 * 0: The vanilla inventory <DISPLAY> (default: the one open, if any)
 *
 * Return Value:
 * Closed <BOOL>
 *
 * Example:
 * [findDisplay 602] call einv_gui_fnc_guardVanilla;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (!hasInterface) exitWith {false};

if (isNull _display) then {
    _display = findDisplay IDD_VANILLA_INVENTORY;
};

if (isNull _display) exitWith {false};

if (isNil QGVAR(guardLogged)) then {
    GVAR(guardLogged) = true;
    INFO("The vanilla inventory came up - another mod or a script opened it. Closing it.");
};

{
    _x ctrlShow false;
} forEach allControls _display;

_display closeDisplay 2;

// Still there a frame later (closed inside its own load event, or by something that opens it again).
[{
    if (!isNull _this) then {
        _this closeDisplay 2;
    };
}, _display] call FUNC(later);

true
