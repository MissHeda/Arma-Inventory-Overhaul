#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes over the two ways ACE Arsenal's window closes by the player - its Close button and Escape - so that
 * fnc_confirmClose can ask first when something does not fit the grid of a uniform, vest or backpack.
 * ACE closes with a script handler of its own config for each (the button's onButtonClick, the display's
 * onKeyDown), and a display cannot be kept open once closeDisplay was called, so the handler itself is set
 * anew: the button's click (ctrlSetEventHandler) and the display's key (displaySetEventHandler, looked up
 * at run time as it is not on every game version), which hands every key but Escape on to ACE's own
 * handler unchanged (fnc_onAceKey).
 *
 * Where a handler cannot be replaced the window still closes the way it did, and what did not fit is taken
 * out right after it (fnc_onClosed); the RPT says which one was left alone, once.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [findDisplay 1127001] call einv_arsenal_fnc_interceptClose;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

// The Eden editor dresses a copy of the unit: nothing to ask there.
if (isNull _display || {is3DEN}) exitWith {};

private _button = _display displayCtrl ARSENAL_IDC_CLOSE;

if (isNull _button) then {
    if !("close button" in GVAR(missingSaid)) then {
        GVAR(missingSaid) pushBack "close button";
        INFO("ACE Arsenal's Close button was not found - what does not fit is taken out after the window closes.");
    };
} else {
    _button ctrlSetEventHandler ["ButtonClick", QUOTE(_this call FUNC(onCloseButton))];
};

if (isNil QACEFUNC(arsenal,onKeyDown) || {supportInfo "u:displaySetEventHandler*" isEqualTo []}) then {
    if !("escape key" in GVAR(missingSaid)) then {
        GVAR(missingSaid) pushBack "escape key";
        INFO("ACE Arsenal's key handler cannot be taken over here - Escape closes without asking and what does not fit is taken out after the window closes.");
    };
} else {
    // The command is looked up when this runs: a game without it must still load this file.
    [_display, "KeyDown", QUOTE(_this call FUNC(onAceKey))] call (compile "params ['_display', '_name', '_code']; _display displaySetEventHandler [_name, _code];");
};
