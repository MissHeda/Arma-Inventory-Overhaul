#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Cleans a text box's text as it is typed - CBA runs this on every key press in the row of the rules
 * and the tables. CBA's own export, its import and every cba_settings.sqf split their lines at ";"
 * without minding quotes, so one ";" in a value breaks all of them, and a server falls back to the
 * default without a word. Semicolons and line breaks therefore become commas, which part statements
 * and table entries just as well, and quotes, "#" and backslashes go: a cba_settings.sqf is run
 * through the preprocessor, where they mean something else.
 *
 * Arguments:
 * The text itself, not in an array - CBA calls it that way <STRING>
 *
 * Return Value:
 * The cleaned text <STRING>
 *
 * Example:
 * "einv1 base=default; @grenade > stack=3" call einv_items_fnc_sanitizeText;
 *
 * Public: No
 */

if !(_this isEqualType "") exitWith {""};

// Semicolon, line feed and carriage return become a comma.
private _codes = (toArray _this) apply {[_x, 44] select (_x in [59, 10, 13])};

// Double and single quotes, the hash and the backslash go.
toString (_codes select {!(_x in [34, 39, 35, 92])})
