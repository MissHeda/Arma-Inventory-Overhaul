#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether KJW's Two Secondary Weapons lets a handgun be the second one: its server's lists, as its own key asks them
 * (its fnc_switchSecondaryHandler) - not on the blacklist, and on the whitelist when that names any. Both settings
 * are text, an array of class names.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 *
 * Return Value:
 * May be the second handgun <BOOL>
 *
 * Example:
 * [player, "hgun_P07_F"] call aio_compat_kjw_twosecondary_fnc_accepts;
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
private _white = ["KJW_TwoSecondaryWeapons_whitelistedClasses"] call _fnc_list;

!(_lower in (["KJW_TwoSecondaryWeapons_blacklistedClasses"] call _fnc_list)) && {_white isEqualTo [] || {_lower in _white}}
