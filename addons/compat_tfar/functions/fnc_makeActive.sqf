#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes a short-range radio the one in use - TFAR's own "Use" choice: it goes into the radio slot and the
 * one that was there goes into the inventory, TFAR's change event fires, and its radio info shows. The
 * window shows the new arrangement as soon as it looks again (aio_gui_fnc_requestRebuild).
 *
 * Arguments:
 * 0: Class of the radio, one the player carries <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TFAR_anprc152_2"] call aio_compat_tfar_fnc_makeActive;
 *
 * Public: No
 */

params [["_radio", "", [""]]];

if (_radio isEqualTo "") exitWith {};

_radio call TFAR_fnc_setActiveSwRadio;

[[] call TFAR_fnc_activeSwRadio, false] call TFAR_fnc_showRadioInfo;

[] call EFUNC(gui,requestRebuild);
