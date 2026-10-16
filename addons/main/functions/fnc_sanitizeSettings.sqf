#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Cleans the text of the server settings as it is typed - CBA runs this on every key press in the text box's
 * row. CBA's own export, its import and every cba_settings.sqf split their lines at ";" without minding
 * quotes, so one ";" in a value would break all of them: semicolons and line breaks become commas, which part
 * the statements just as well, and quotes, "#" and backslashes go - a cba_settings.sqf is run through the
 * preprocessor, where they mean something else. The text is the setup wizard's to write
 * (fnc_writeSettings); this only keeps a hand-typed one from doing harm.
 *
 * Arguments:
 * The text itself, not in an array - CBA calls it that way <STRING>
 *
 * Return Value:
 * The cleaned text <STRING>
 *
 * Example:
 * "einv1; gui_searchTime=1" call einv_main_fnc_sanitizeSettings;
 *
 * Public: No
 */

if !(_this isEqualType "") exitWith {""};

// Semicolon, line feed and carriage return become a comma, a backslash a slash; quotes and the hash go.
private _codes = (toArray _this) apply {
    switch (true) do {
        case (_x in [59, 10, 13]): {44};
        case (_x == 92): {47};
        default {_x};
    }
};

toString (_codes select {!(_x in [34, 39, 35])})
