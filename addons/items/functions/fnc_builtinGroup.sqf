#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which of the eight built-in categories (ITEM_GROUPS) a word means, "" for none: the category itself, one of the words that
 * stand for a category (GROUP_ALIASES: magazine, throwable, clothing, ...) or a plural of either ("tools", "magazines"). The one
 * place those words are listed. fnc_parseGroups reads a value by it, and the rules text refuses a category of the server's own
 * (category=...) whose id would read as one of the eight (fnc_parseRules).
 *
 * Arguments:
 * 0: The word, any case <STRING>
 *
 * Return Value:
 * "weapon", "ammo", "grenade", "gear", "medical", "food", "tool" or "misc"; "" when the word is none of them <STRING>
 *
 * Example:
 * ["Magazines"] call einv_items_fnc_builtinGroup; // "ammo"
 *
 * Public: No
 */

params [["_word", "", [""]]];

private _lower = toLowerANSI _word;

if (_lower in ITEM_GROUPS) exitWith {_lower};

private _aliases = createHashMapFromArray GROUP_ALIASES;

if (_lower in _aliases) exitWith {_aliases get _lower};

// A plural is no mistake.
private _found = "";

if (count _lower > 3 && {(_lower select [count _lower - 1]) isEqualTo "s"}) then {
    private _single = _lower select [0, count _lower - 1];

    _single = _aliases getOrDefault [_single, _single];

    if (_single in ITEM_GROUPS) then {
        _found = _single;
    };
};

_found
