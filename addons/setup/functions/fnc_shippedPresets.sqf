#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The presets a setup can start from (CfgEinvRulesets): this mod's own - Default, Tarkov-like,
 * Weight-like - and any that another mod adds, in config order.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[id (lower case), name, description, revision, cell (-1 when it takes its base's)], ...] <ARRAY>
 *
 * Example:
 * call einv_setup_fnc_shippedPresets;
 *
 * Public: No
 */

// A name written as a stringtable key, in case the game has not put the text in its place.
private _fnc_text = {
    params ["_text"];

    if ((_text select [0, 4]) == "$STR") then {
        _text = localize (_text select [1]);
    };

    _text
};

("true" configClasses (configFile >> "CfgEinvRulesets")) apply {
    private _id = toLower configName _x;
    private _name = [getText (_x >> "name")] call _fnc_text;

    if (_name isEqualTo "") then {
        _name = _id;
    };

    private _cell = -1;

    if (isNumber (_x >> "cell")) then {
        _cell = getNumber (_x >> "cell");
    };

    [_id, _name, [getText (_x >> "description")] call _fnc_text, getNumber (_x >> "revision"), _cell]
}
