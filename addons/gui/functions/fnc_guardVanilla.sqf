#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes a vanilla inventory (RscDisplayInventory) that came up where this window is, or is about to be.
 *
 * The window replaces the vanilla inventory: fnc_onInventoryOpened answers true, and the engine opens
 * no display. Another mod can still bring the vanilla one up behind that answer - Better Inventory
 * (workshop 2791403093) patches the display itself and runs its own handler on the same event, any
 * mod can open it by createDisplay or an action. Left alone, it appears over the window, which is
 * then covered (fnc_isCovered) and no longer used, or in its place.
 *
 * It is closed again while this window is open, and for a short time after the engine was told to
 * keep the vanilla inventory away (BLOCK_GRACE, set by the handler fnc_initUnit puts on the unit) -
 * the window opens a frame later. Nothing is closed with the window switched off
 * (einv_gui_replaceVanilla), or after a vanilla inventory was asked for on purpose
 * (fnc_openVanilla, fnc_openPerson): the handler's answer of false ends the grace time, and
 * fnc_openVanilla closes the window first.
 *
 * Called by the display's load event (Extended_DisplayLoad_EventHandlers, argument 0 is the display)
 * and by fnc_onFrame, which looks for one while the window is open.
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

if (isNull _display) then {
    _display = findDisplay IDD_VANILLA_INVENTORY;
};

if (isNull _display || {!hasInterface} || {!GVAR(replaceVanilla)}) exitWith {false};

// Neither the window nor a blocked answer a moment ago: the vanilla inventory was let through on purpose.
if (isNull (uiNamespace getVariable [QGVAR(display), displayNull]) && {diag_tickTime >= GVAR(blockedUntil)}) exitWith {false};

if (isNil QGVAR(guardLogged)) then {
    GVAR(guardLogged) = true;
    INFO("A vanilla inventory came up over the window - another mod opened it. Closing it.");
};

_display closeDisplay 2;

// Still there a frame later (closed inside its own load event, or by something that opens it again).
[{
    if (!isNull _this) then {
        _this closeDisplay 2;
    };
}, _display] call FUNC(later);

true
