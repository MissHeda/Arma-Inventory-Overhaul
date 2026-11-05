#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether KJW's Two Primary Weapons lets a rifle go on the back: its server's lists, as its own key asks them
 * (its fnc_switchPrimaryHandler) - not on the blacklist, and on the whitelist when that names any. Both settings
 * are text, an array of class names.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 *
 * Return Value:
 * Goes on the back <BOOL>
 *
 * Example:
 * [player, "arifle_MX_F"] call aio_compat_kjw_twoprimary_fnc_accepts;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

private _fnc_list = {
    params ["_name"];

    private _text = missionNamespace getVariable [_name, "[]"];

    if !(_text isEqualType "") exitWith {[]};

    private _list = parseSimpleArray _text;

    if !(_list isEqualType []) exitWith {[]};

    (_list select {_x isEqualType ""}) apply {toLowerANSI _x}
};

private _lower = toLowerANSI _class;
private _white = ["KJW_TwoPrimaryWeapons_whitelistedClasses"] call _fnc_list;

!(_lower in (["KJW_TwoPrimaryWeapons_blacklistedClasses"] call _fnc_list)) && {_white isEqualTo [] || {_lower in _white}}
