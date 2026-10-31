#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Closes an open kit - its window's cross or Escape, a double click on its tile or Close in its context
 * menu, all through aio_gui_fnc_closeWindow, which calls this - with the sound of a medic bag closing.
 * Kits open inside it close when the windows are drawn again: they are found only through it
 * (fnc_getSections). Draws nothing itself - its caller does.
 *
 * Arguments:
 * 0: The kit's key, "kit:" + the lowercase class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["kit:efak_ifak_7"] call aio_compat_efak_fnc_close;
 *
 * Public: No
 */

params [["_key", "", [""]]];

// The medic bag closes with a sound of its own - only a kit that was open (aio_gui_fnc_playSound).
if ((GVAR(opened) findIf {("kit:" + toLowerANSI _x) isEqualTo _key}) >= 0) then {
    ["close", _key select [4]] call EFUNC(gui,playSound);
};

GVAR(opened) = GVAR(opened) select {("kit:" + toLowerANSI _x) isNotEqualTo _key};
GVAR(holders) deleteAt (_key select [4]);
