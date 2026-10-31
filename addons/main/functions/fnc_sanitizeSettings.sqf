#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Cleans a text of server settings that came from outside - the line of the settings box of the test builds
 * (einv_main_settings) pasted into the setup wizard's Import (einv_setup_fnc_importSettings). CBA's own export,
 * its import and every cba_settings.sqf split their lines at ";" without minding
 * quotes, so one ";" in a value would break all of them: semicolons and line breaks become commas, which part
 * the statements just as well, and quotes, "#" and backslashes go - a cba_settings.sqf is run through the
 * preprocessor, where they mean something else.
 *
 * Arguments:
 * The text itself, not in an array - the way CBA called it while it was the box's sanitizer <STRING>
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
