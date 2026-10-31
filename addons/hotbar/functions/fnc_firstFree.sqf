#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The first slot with nothing on it - where a menu puts an item that has no key of its own.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Slot index, 0 to 6, -1 when every slot is taken <NUMBER>
 *
 * Example:
 * call aio_hotbar_fnc_firstFree;
 *
 * Public: No
 */

GVAR(slots) findIf {_x isEqualTo ""}
