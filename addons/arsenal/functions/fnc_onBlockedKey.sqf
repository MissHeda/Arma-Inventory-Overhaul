#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A key on the red screen: Escape and Return close it. Every other key is taken too, so nothing behind it
 * hears them.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [_display, 1, false, false, false] call einv_arsenal_fnc_onBlockedKey;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_key", 0, [0]]];

if (_key in [DIK_ESCAPE, DIK_RETURN, DIK_NUMPADENTER]) exitWith {
    _display closeDisplay 2;

    true
};

false
