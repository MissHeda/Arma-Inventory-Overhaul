#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Display key down. Escape closes an open popover first, then the wizard - asking first when there are
 * changes (fnc_close). Ctrl+Z undoes, Ctrl+Y does again - Z and Y as printed on the keyboard, whatever
 * its layout. In a text field the keys are the field's; anything else goes to the open step
 * (GVAR(stepKey)) - not while a popover is open: it is answered first.
 *
 * Keys the wizard does not use are kept from the game: opened over the game's own screen, the soldier
 * must not walk off while the player types a rule.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 *
 * Return Value:
 * Key handled <BOOL>
 *
 * Example:
 * [_display, 1, false, false, false] call aio_setup_fnc_onKeyDown;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false]];

if (_key == DIK_ESCAPE) exitWith {
    if !(call FUNC(closePopover)) then {
        [FUNC(close)] call FUNC(defer);
    };

    true
};

if (ctrlType (focusedCtrl _display) == CTRL_TYPE_EDIT) exitWith {false};

// An open popover is answered first: the step's keys and undo wait. Ctrl+F would put the cursor into the
// pane, and the pane holding the focus is drawn over the popover (fnc_topLayer).
if ((uiNamespace getVariable [QGVAR(popover), []]) isNotEqualTo []) exitWith {
    !(_key in [DIK_RETURN, DIK_NUMPADENTER, DIK_SPACE])
};

// Undo and redo go by the letter on the key, not by where the key sits: on a German keyboard Z and Y have
// swapped places, and the footer says Ctrl+Z and Ctrl+Y. The game names a key as the keyboard's layout
// has it (keyName, in quotes). Where that is no letter from A to Z - a Cyrillic layout, say -, by where
// the key sits on an English keyboard.
private _letter = toUpper (((keyName _key) splitString """") joinString "");
private _codes = toArray _letter;
private _undoKey = _key == DIK_Z;
private _redoKey = _key == DIK_Y;

if (count _codes == 1 && {(_codes select 0) >= 65} && {(_codes select 0) <= 90}) then {
    _undoKey = _letter isEqualTo "Z";
    _redoKey = _letter isEqualTo "Y";
};

if (_ctrl && {_undoKey || {_redoKey}}) exitWith {
    [{
        params ["_direction"];

        [_direction] call FUNC(undo);
    }, [[1, -1] select _redoKey]] call FUNC(defer);

    true
};

private _handled = [_key, _shift, _ctrl, _alt, false] call GVAR(stepKey);

if (!isNil "_handled" && {_handled isEqualType true} && {_handled}) exitWith {true};

// Not a key the wizard uses: kept from the game, but Return and Space still press a focused button.
!(_key in [DIK_RETURN, DIK_NUMPADENTER, DIK_SPACE])
