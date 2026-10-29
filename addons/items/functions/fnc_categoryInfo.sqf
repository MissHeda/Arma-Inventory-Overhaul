#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a category is called and what it looks like: the name the setup gave it (category=bandit > name=Bandit_loot) or, for one
 * of the eight built-in ones, the name this mod ships, and its picture when the setup gave one (picture=PATH) and the game has
 * the file. The window and the wizard ask here for every name and picture of a category.
 *
 * Arguments:
 * 0: The category's id <STRING>
 * 1: Compiled rules, fnc_compileRules gives them <HASHMAP> (default: the rules in effect)
 *
 * Return Value:
 * <HASHMAP>
 *   "id"       - the id, lowercase <STRING>
 *   "builtin"  - one of the eight <BOOL>
 *   "known"    - the setup has it: a built-in one or a defined one <BOOL>
 *   "name"     - the short name: the chips of the wizard <STRING>
 *   "label"    - the longer name: the tooltip of the strip at the side of a loot box <STRING>
 *   "only"     - the name in "Only ... here", what a compartment that takes only this category says <STRING>
 *   "picture"  - the setup's picture of it, "" for none or when the game lacks the file <STRING>
 *   "nameSet"  - the setup's own name, "" for none <STRING>
 *   "pictureSet" - the setup's own picture path, "" for none, whether the game has the file or not <STRING>
 *   "color"    - the colour of its items' tiles (color=), [r, g, b] 0 to 1, [] for none <ARRAY>
 *   "colorSet" - the setup's own color= as written, six hex digits, "" for none <STRING>
 *
 * Example:
 * ["medical"] call einv_items_fnc_categoryInfo;
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_compiled", createHashMap, [createHashMap]]];

if (count _compiled == 0) then {
    _compiled = [] call FUNC(currentRules);
};

_id = toLowerANSI _id;

private _builtin = _id in ITEM_GROUPS;
private _definition = (_compiled getOrDefault ["categoryDefs", createHashMap]) getOrDefault [_id, ["", "", ""]];

_definition params [["_ownName", "", [""]], ["_ownPicture", "", [""]], ["_ownColor", "", [""]]];

// The tiles' colour, [r, g, b] 0 to 1 from the six hex digits of color=, [] for none.
private _color = [];

if (count _ownColor == 6) then {
    private _digits = "0123456789abcdef";
    private _nibbles = (toLowerANSI _ownColor splitString "") apply {_digits find _x};

    if (_nibbles findIf {_x < 0} < 0) then {
        _color = [0, 2, 4] apply {((_nibbles select _x) * 16 + (_nibbles select (_x + 1))) / 255};
    };
};

private _titled = (toUpper (_id select [0, 1])) + (_id select [1]);
private _name = _ownName;
private _label = _ownName;
private _only = _ownName;

if (_ownName isEqualTo "") then {
    if (_builtin) then {
        _name = localize format ["STR_einv_setup_Cat_%1", _id];
        _label = localize format ["STR_einv_gui_Group_%1", _titled];
        _only = localize format ["STR_einv_gui_Only_%1", _id];
    } else {
        // No name given: the id, as words.
        private _words = (_id splitString "_") joinString " ";

        _name = (toUpper (_words select [0, 1])) + (_words select [1]);
        _label = _name;
        _only = _name;
    };
};

// The game must have the file: a texture it does not know pops up a message when a control is given it. The engine reads a
// path with or without its leading backslash.
private _picture = "";

if (_ownPicture isNotEqualTo "") then {
    private _otherForm = if ((_ownPicture select [0, 1]) isEqualTo "\") then {_ownPicture select [1]} else {"\" + _ownPicture};

    if (fileExists _ownPicture || {fileExists _otherForm}) then {
        _picture = _ownPicture;
    };
};

createHashMapFromArray [
    ["id", _id],
    ["builtin", _builtin],
    ["known", _id in (_compiled getOrDefault ["categoryIds", ITEM_GROUPS])],
    ["name", _name],
    ["label", _label],
    ["only", _only],
    ["picture", _picture],
    ["nameSet", _ownName],
    ["pictureSet", _ownPicture],
    ["color", _color],
    ["colorSet", _ownColor]
]
