#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The hotbar's entry in the window's footer: "4-0  Hotbar", with the keys the player really has on the
 * first and the last slot.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [key, text] as the footer's key hints are, ["", ""] when the hotbar is off or either key is not set
 * <ARRAY>
 *
 * Example:
 * call aio_hotbar_fnc_footerHint;
 *
 * Public: No
 */

if (!(call FUNC(isActive))) exitWith {["", ""]};

private _first = [0] call FUNC(keyName);
private _last = [SLOT_COUNT - 1] call FUNC(keyName);

if (_first isEqualTo "" || {_last isEqualTo ""}) exitWith {["", ""]};

[format ["%1-%2", _first, _last], LLSTRING(Footer)]
