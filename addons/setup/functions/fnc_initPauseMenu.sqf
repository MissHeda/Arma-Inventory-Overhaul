#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes "Inventory setup" off the pause menu's Options list as the pause menu opens, for a player who may not see
 * the wizard (fnc_canOpen): CBA's entries carry no condition, so CBA made the button for everyone. Asked every
 * time the pause menu opens, so an admin who logs in or out finds it there - or not - the next time. The buttons
 * above it move down one row into its place: the list has no gap, and the Options button folds it out and in
 * as before.
 *
 * Runs when the pause menu loads (Extended_DisplayLoad_EventHandlers >> RscDisplayInterrupt and
 * RscDisplayMPInterrupt), after CBA's own handler, which made the buttons and keeps them on the display in its
 * order (cba_ui_MenuButtons: the game's four Options buttons, then one for each entry of CBA's list, which is
 * cba_ui_MenuButtons in missionNamespace). Those are CBA's internals, not a promise: should they ever be kept
 * otherwise, nothing is done here, the entry stays, and the wizard's onLoad closes it again for such a player.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_setup_fnc_initPauseMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

if (isNull _display) exitWith {};
if (call (missionNamespace getVariable [QFUNC(canOpen), {true}])) exitWith {};

private _entries = missionNamespace getVariable ["cba_ui_MenuButtons", uiNamespace getVariable ["cba_ui_MenuButtons", []]];
private _buttons = _display getVariable ["cba_ui_MenuButtons", []];
private _entry = _entries findIf {(_x param [2, ""]) isEqualTo QGVAR(RscWizard)};

if (_entry < 0 || {count _buttons != count _entries + 4}) exitWith {};

// The game's four buttons come first, then CBA's in the order of its list.
private _index = 4 + _entry;
private _button = _buttons select _index;

if (isNull _button || {(ctrlText _button) isNotEqualTo toUpper LLSTRING(OpenWizard)}) exitWith {};

// One row: how far two neighbours stand apart.
private _row = ((ctrlPosition (_buttons select 1)) select 1) - ((ctrlPosition (_buttons select 0)) select 1);

for "_i" from 0 to _index - 1 do {
    private _above = _buttons select _i;

    (ctrlPosition _above) params ["_left", "_top", "_width", "_height"];

    _above ctrlSetPosition [_left, _top + _row, _width, _height];
    _above ctrlCommit 0;
};

_buttons deleteAt _index;
ctrlDelete _button;
