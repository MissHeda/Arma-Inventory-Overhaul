#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the setup wizard over a display: CBA's Addon Options (menu mode), or Eden, the pause menu or the
 * game's own screen (direct mode).
 *
 * In menu mode what the wizard applies goes into CBA's menu as a change still to be confirmed: CBA's OK
 * saves it, its Cancel throws it away, like any other change made there. In direct mode the wizard's Save
 * writes the setting itself (fnc_save).
 *
 * The inventory and the wizard never share the screen: an open inventory window is closed first - unless
 * the player may not open the wizard at all (fnc_canOpen, einv_setup_access), who gets a hint instead.
 *
 * Arguments:
 * 0: Display to open it over, displayNull for Eden's or else the game's own screen <DISPLAY> (default: displayNull)
 * 1: Mode, "menu" or "direct" <STRING> (default: "direct")
 * 2: Step to open at, 0 (Start) to 3 (Review) - one out of range opens Start <NUMBER> (default: 0)
 * 3: Class to look at in that step, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The wizard's display, displayNull when it could not or may not open <DISPLAY>
 *
 * Example:
 * [findDisplay 313, "direct", 0, ""] call einv_setup_fnc_open;
 *
 * Public: Yes
 */

disableSerialization;

params [["_parent", displayNull, [displayNull]], ["_mode", "direct", [""]], ["_step", 0, [0]], ["_focusClass", "", [""]]];

if (!hasInterface) exitWith {displayNull};

// One wizard is enough.
private _open = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _open) exitWith {_open};

if !(_mode in ["menu", "direct"]) then {
    _mode = "direct";
};

// Not for this player (einv_setup_access): asked before the inventory closes for nothing.
if !([_mode, true] call FUNC(canOpen)) exitWith {displayNull};

if (isNull _parent) then {
    _parent = [findDisplay 46, findDisplay 313] select is3DEN;
};

if (isNull _parent) exitWith {
    ERROR("No display to open the setup wizard over.");
    displayNull
};

private _inventory = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (!isNull _inventory && {_inventory isNotEqualTo _parent}) then {
    _inventory closeDisplay 2;
};

// The engine runs onLoad inside createDisplay: this is how it learns what it was opened for.
uiNamespace setVariable [QGVAR(openArgs), [_mode, _step, _focusClass]];

private _display = _parent createDisplay QGVAR(RscWizard);

uiNamespace setVariable [QGVAR(openArgs), nil];

if (isNull _display) exitWith {
    ERROR("Could not create the setup wizard.");
    displayNull
};

_display
