#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Which slot a key press belongs to, by the keybinds the player has set in Configure Addons. CBA's
 * keybinds do not run while the inventory window is open, so the window asks this itself.
 *
 * Arguments:
 * 0: DIK code <NUMBER>
 * 1: Modifiers held, [shift, ctrl, alt] <ARRAY>
 *
 * Return Value:
 * Slot index, -1 when the key is no slot's <NUMBER>
 *
 * Example:
 * [6, [false, false, false]] call aio_hotbar_fnc_keyIndex;
 *
 * Public: No
 */

params [["_key", 0, [0]], ["_modifiers", [false, false, false], [[]]]];

private _pressed = [_key, _modifiers];
private _found = -1;

for "_i" from 0 to (SLOT_COUNT - 1) do {
    private _entry = [CBA_SETTINGS_AIO, format [QGVAR(slot%1), _i + 1]] call CBA_fnc_getKeybind;

    if (!isNil "_entry" && {((_entry param [8, []]) findIf {_x isEqualTo _pressed}) >= 0}) exitWith {
        _found = _i;
    };
};

_found
