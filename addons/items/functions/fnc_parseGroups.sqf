#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads the value of cats= (a rule) or aio_cat (an item's config): the categories an item is in. The one
 * reader of that value, as fnc_parseUse is of use=. A category is one of the eight built-in ones (ITEM_GROUPS: weapon, ammo,
 * grenade, gear, medical, food, tool, misc) or one the setup defines itself (category=... in the rules text, fnc_parseRules).
 * The categories decide which button of a loot box's strip shows an item and which compartments accept it (grid=, see
 * fnc_parseGrid); an item may be in several.
 *
 *   medical+misc            any of the words, joined with + (the rules text) or with a comma, a bar, a
 *                           space or a slash (config: "medical,misc")
 *   grenade                 one category
 *
 * Case does not matter, plurals are read ("grenades", "tools"), and a few other words stand for the
 * category they mean: magazine and mag for ammo, throwable and explosive for grenade, clothing for gear,
 * medic for medical (fnc_builtinGroup). Any other word that is an id - a-z, 0-9 and _, at most CAT_ID_MAX characters - is
 * kept as the id of a category of the setup's own: whether the setup defines it is not asked here (a mod's config is read
 * before the rules are) but when the rules are compiled (fnc_compileRules, which says so) and when an item is looked at
 * (fnc_getInfo ignores a category that does not exist). A word that is no id is left out with a note and the rest is kept;
 * a value without a single word that could be read is unreadable (the third element is false). The answer is always in
 * the order of fnc_orderGroups, without doubles.
 *
 * Arguments:
 * 0: The value <STRING>
 * 1: What to call the key in a note, "cats" in a rules text and "aio_cat" in config <STRING> (default: "cats")
 *
 * Return Value:
 * [groups, notes, readable] <ARRAY>
 *   groups   - the categories, in the order of fnc_orderGroups <ARRAY of STRING>
 *   notes    - what was left out, naming the value <ARRAY of STRING>
 *   readable - false when nothing of the value could be read <BOOL>
 *
 * Example:
 * ["misc+medical"] call aio_items_fnc_parseGroups;
 * // [["medical", "misc"], [], true]
 *
 * Public: No
 */

params [["_text", "", [""]], ["_key", "cats", [""]]];

private _words = (toLowerANSI _text) splitString (toString [32, 9, 10, 13, 43, 44, 124, 59, 47]);

// cats=none: in no category at all - not even the built-in one (fnc_getInfo); a compartment that takes only some takes it not.
if (_words isEqualTo ["none"]) exitWith {[["none"], [], true]};
private _found = [];
private _notes = [];

{
    private _id = [_x] call FUNC(builtinGroup);

    // Not one of the eight: a category of the setup's own, if the word is an id.
    if (_id isEqualTo "" && {_x regexMatch CAT_ID_PATTERN}) then {
        _id = _x;
    };

    if (_id isNotEqualTo "") then {
        _found pushBackUnique _id;
    } else {
        _notes pushBack format ["%1=%2: '%3' is no category name (letters, digits and _, at most %4 characters) - this part is left out", _key, _text, _x, CAT_ID_MAX];
    };
} forEach _words;

if (_words isEqualTo []) then {
    _notes pushBack format ["%1= without a value - this part is left out", _key];
};

// In the order the writer has them.
[[_found] call FUNC(orderGroups), _notes, _found isNotEqualTo []]
