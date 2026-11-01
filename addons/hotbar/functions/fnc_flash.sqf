#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Says something about a slot on the screen: a line over the boxes and, for a refusal, the slot's box
 * lit in the error colour for a moment. With the bar set to never, a refusal is ACE's hint instead -
 * there is no bar to show it on - and anything else stays unsaid.
 *
 * Arguments:
 * 0: Slot index, -1 for no slot <NUMBER>
 * 1: Text <STRING>
 * 2: Colour of the line - "text" for what was done, "warning" for why not <STRING> (default: "text")
 *
 * Return Value:
 * None
 *
 * Example:
 * [2, "Nothing is bleeding", "warning"] call aio_hotbar_fnc_flash;
 *
 * Public: No
 */

params [["_index", -1, [0]], ["_text", "", [""]], ["_colour", "text", [""]]];

if (_text isEqualTo "") exitWith {};

if (GVAR(hudMode) == 0) exitWith {
    if (_colour isEqualTo "warning") then {
        [_text] call EFUNC(main,showText);
    };
};

private _now = diag_tickTime;

GVAR(flash) = [[], [_index, "error", _now + HUD_FLASH]] select ((_colour isEqualTo "warning") && {_index >= 0});
GVAR(message) = [_text, _colour, _now + HUD_MESSAGE_TIME];

call FUNC(hudPing);
