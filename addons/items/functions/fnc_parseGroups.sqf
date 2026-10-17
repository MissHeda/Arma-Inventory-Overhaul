#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads the value of cats= (a rule) or einv_cat (an item's config): the categories an item is in. The one
 * reader of that value, as fnc_parseUse is of use=. A category is one of ITEM_GROUPS: weapon, ammo, grenade,
 * gear, medical, food, tool, misc. The categories decide which button of a loot box's strip shows an item and
 * which compartments accept it (grid=, see fnc_parseGrid); an item may be in several.
 *
 *   medical+misc            any of the words, joined with + (the rules text) or with a comma, a bar, a
 *                           space or a slash (config: "medical,misc")
 *   grenade                 one category
 *
 * Case does not matter, plurals are read ("grenades", "tools"), and a few other words stand for the
 * category they mean: magazine and mag for ammo, throwable and explosive for grenade, clothing for gear,
 * medic for medical. A word that is none of these is left out with a note and the rest is kept; a value
 * without a single word that could be read is unreadable (the third element is false). The answer is
 * always in the order of ITEM_GROUPS, without doubles.
 *
 * Arguments:
 * 0: The value <STRING>
 * 1: What to call the key in a note, "cats" in a rules text and "einv_cat" in config <STRING> (default: "cats")
 *
 * Return Value:
 * [groups, notes, readable] <ARRAY>
 *   groups   - of ITEM_GROUPS, in that order <ARRAY of STRING>
 *   notes    - what was left out, naming the value <ARRAY of STRING>
 *   readable - false when nothing of the value could be read <BOOL>
 *
 * Example:
 * ["misc+medical"] call einv_items_fnc_parseGroups;
 * // [["medical", "misc"], [], true]
 *
 * Public: No
 */

params [["_text", "", [""]], ["_key", "cats", [""]]];

private _words = (toLowerANSI _text) splitString (toString [32, 9, 10, 13, 43, 44, 124, 59, 47]);
private _found = [];
private _notes = [];
private _aliases = createHashMapFromArray [
    ["magazine", "ammo"], ["mag", "ammo"], ["ammunition", "ammo"],
    ["throwable", "grenade"], ["explosive", "grenade"],
    ["clothing", "gear"], ["armour", "gear"], ["armor", "gear"],
    ["medic", "medical"], ["drink", "food"], ["gadget", "tool"], ["other", "misc"]
];

{
    private _word = _x;

    // A plural is no mistake.
    if (!(_word in ITEM_GROUPS) && {!(_word in _aliases)} && {(_word select [count _word - 1]) isEqualTo "s"} && {count _word > 3}) then {
        _word = _word select [0, count _word - 1];
    };

    _word = _aliases getOrDefault [_word, _word];

    if (_word in ITEM_GROUPS) then {
        _found pushBackUnique _word;
    } else {
        _notes pushBack format ["%1=%2: there is no category called '%3' (%4) - this part is left out", _key, _text, _x, ITEM_GROUPS joinString ", "];
    };
} forEach _words;

if (_words isEqualTo []) then {
    _notes pushBack format ["%1= without a value - this part is left out", _key];
};

// In the order the strip lists them.
[ITEM_GROUPS select {_x in _found}, _notes, _found isNotEqualTo []]
