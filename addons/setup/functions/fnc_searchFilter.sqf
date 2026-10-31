#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads what was typed into a class list's search (the Items and Containers steps, the Same as popover):
 * a plain text looks for itself anywhere in the class or the name, as it always did; a text with a * (any
 * run of characters, none too) or a ? (any one character) is a wildcard that has to fit the class or the
 * name as a whole - B_Bergen* the classes that begin so, *Carryall* those that hold the word anywhere,
 * *_F those that end so. Upper and lower case do not matter.
 *
 * A wildcard becomes a regular expression with every other character taken literally. The longest literal
 * run in it is kept as well: a cheap look for it (fnc_searchHit) keeps the expression away from most of the
 * thousands of classes.
 *
 * Arguments:
 * 0: Search text <STRING>
 *
 * Return Value:
 * The filter for fnc_searchHit <ARRAY>
 *   []                          - nothing typed, everything counts
 *   [text]                      - a plain text, lowercase
 *   [text, expression, literal] - a wildcard: the text, the expression, its longest literal run
 *
 * Example:
 * ["B_Bergen*"] call aio_setup_fnc_searchFilter;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _needle = toLower (trim _text);

if (_needle isEqualTo "") exitWith {[]};

if ((_needle find "*") < 0 && {(_needle find "?") < 0}) exitWith {[_needle]};

private _backslash = toString [92];
private _special = "^$.+()[]{}|" + _backslash;
private _expression = "^";
private _literal = "";
private _run = "";

{
    private _char = toString [_x];

    switch (true) do {
        // * and ?: the literal run so far ends here.
        case (_x == 42 || {_x == 63}): {
            _expression = _expression + ([".*", "."] select (_x == 63));

            if (count _run > count _literal) then {
                _literal = _run;
            };

            _run = "";
        };
        // The characters a regular expression reads as its own are escaped; anything else is itself.
        case ((_special find _char) >= 0): {
            _expression = _expression + _backslash + _char;
            _run = _run + _char;
        };
        default {
            _expression = _expression + _char;
            _run = _run + _char;
        };
    };
} forEach toArray _needle;

if (count _run > count _literal) then {
    _literal = _run;
};

[_needle, _expression + "$", _literal]
