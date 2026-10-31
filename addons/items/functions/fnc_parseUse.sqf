#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads the value of use= (a rule) or aio_use (an item's config): the containers an item may be used
 * from even where a setting limits what can be used there (aio_storage_useUniform, aio_storage_useVest,
 * aio_storage_useBackpack set to "Only whitelisted"). The one reader of that value, as fnc_parseIcon is of
 * icon=.
 *
 *   uniform+vest+backpack   any of the three words, joined with + (the rules text) or with a comma, a bar
 *                           or a space (config: "backpack,vest")
 *   backpack                one container
 *   all                     the same as the three words
 *   none                    no container: the item is not whitelisted anywhere - the one value that
 *                           takes back what a broader rule whitelisted
 *
 * Case does not matter, "backpacks" and "vests" are read as well. A word that is none of these is left out
 * with a note and the rest is kept; a value without a single word that could be read is unreadable (the
 * third element is false). The answer is always in the order uniform, vest, backpack, without doubles.
 *
 * Arguments:
 * 0: The value <STRING>
 *
 * Return Value:
 * [containers, notes, readable] <ARRAY>
 *   containers - of "uniform", "vest", "backpack", in that order; [] for none <ARRAY of STRING>
 *   notes      - what was left out, naming the value <ARRAY of STRING>
 *   readable   - false when nothing of the value could be read <BOOL>
 *
 * Example:
 * ["backpack+vest"] call aio_items_fnc_parseUse;
 * // [["vest", "backpack"], [], true]
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _words = (toLowerANSI _text) splitString (toString [32, 9, 10, 13, 43, 44, 124, 59, 47]);
private _found = [];
private _notes = [];
private _readable = false;

{
    private _word = _x;

    // A plural is no mistake.
    if ((_word select [count _word - 1]) isEqualTo "s" && {count _word > 3}) then {
        _word = _word select [0, count _word - 1];
    };

    switch (true) do {
        case (_word in USE_KINDS): {
            _found pushBackUnique _word;
            _readable = true;
        };
        case (_word in ["all", "any", "every"]): {
            _found append USE_KINDS;
            _readable = true;
        };
        case (_word in ["none", "no", "nothing", "off"]): {
            _readable = true;
        };
        default {
            _notes pushBack format ["use=%1: there is no container called '%2' (uniform, vest, backpack, all or none) - this part is left out", _text, _x];
        };
    };
} forEach _words;

if (_words isEqualTo []) then {
    _notes pushBack "use= without a value - this part is left out (use=none whitelists nothing)";
};

// In the order the settings list the containers.
[USE_KINDS select {_x in _found}, _notes, _readable]
