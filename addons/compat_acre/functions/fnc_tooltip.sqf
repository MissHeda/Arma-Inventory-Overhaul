#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What follows a radio's name at the mouse: its channel and frequency - "Block 1 · Ch 3", "152.6 MHz".
 * Nothing for a radio ACRE2 has not set up yet, for a base radio and for anything that is no radio.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Unused, the same arguments as the other radio addons take <OBJECT> (default: objNull)
 *
 * Return Value:
 * Texts to join after the name <ARRAY of STRINGs>
 *
 * Example:
 * ["ACRE_PRC152_ID_1", objNull] call aio_compat_acre_fnc_tooltip;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

if (([_class] call FUNC(radioType)) isNotEqualTo 1) exitWith {[]};

([_class] call FUNC(channel)) params [["_channel", ""], ["_frequency", ""]];

[_channel, _frequency] select {_x isNotEqualTo ""}
