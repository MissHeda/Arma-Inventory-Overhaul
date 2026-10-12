#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A radio's settings as TFAR keeps them, read raw: TFAR's own getters write default settings for a radio
 * that has none yet, and merely hovering a radio must not set one up. A short-range radio's are in TFAR's
 * settings namespace under its class; a long-range backpack's are the variable "radio_settings" on the
 * backpack object.
 *
 * [active channel (0 is the first), volume, [frequency of each channel], stereo, code, additional channel
 * (-1 for none), additional stereo, owner, speakers, on] - the last ones may be missing.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The backpack object, for a long-range radio <OBJECT> (default: objNull)
 *
 * Return Value:
 * Settings, [] while there are none <ARRAY>
 *
 * Example:
 * ["TFAR_anprc152_1"] call einv_compat_tfar_fnc_settings;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]]];

private _settings = switch ([_class] call FUNC(radioType)) do {
    case 1: {(missionNamespace getVariable ["TFAR_RadioSettingsNamespace", objNull]) getVariable [_class, []]};
    case 3: {_holder getVariable ["radio_settings", []]};
    default {[]};
};

[[], _settings] select (_settings isEqualType [])
