#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The presets there are (CfgAioRulesets): this mod's one, Default, and any that another mod adds, in config
 * order. The wizard offers no choice among them any more - a text names its preset by base=, which is the
 * default unless another mod's preset was named by hand -; this is what names them.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[id (lower case), name, description, revision, cell (-1 when it takes its base's)], ...] <ARRAY>
 *
 * Example:
 * call aio_setup_fnc_shippedPresets;
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

("true" configClasses (configFile >> "CfgAioRulesets")) apply {
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
