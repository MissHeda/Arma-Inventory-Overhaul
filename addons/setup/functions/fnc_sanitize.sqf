#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Cleans a rules text typed or pasted into the wizard, the way the setting's own text box in CBA's menu
 * cleans it: semicolons and line breaks become commas, which separate the statements; quotes, # and
 * backslashes go.
 *
 * None of them may reach the stored text. CBA cuts its settings files at every semicolon, quotes or not -
 * one in the text breaks every cba_settings.sqf line and export holding it, and a server falls back to
 * the default at start. Quotes, # and backslashes are taken apart by the preprocessor those files go
 * through.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * Cleaned text <STRING>
 *
 * Example:
 * ["aio1 base=default; @grenade > stack=3"] call aio_setup_fnc_sanitize;
 *
 * Public: No
 */

params [["_text", "", [""]]];

// By character code: semicolon 59, line feed 10 and carriage return 13 become a comma (44), a tab (9) a
// space (32); double quote 34, single quote 39, hash 35 and backslash 92 are left out.
private _chars = toArray _text;

_chars = _chars apply {
    switch (true) do {
        case (_x in [59, 10, 13]): {44};
        case (_x == 9): {32};
        default {_x};
    }
};

toString (_chars - [34, 39, 35, 92])
