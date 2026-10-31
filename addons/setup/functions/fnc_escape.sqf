#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes out the characters structured text would take for markup, so a text shows as it is: a warning
 * quoting a statement with mass<=10 in it, a preset's description with an ampersand.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * Text for parseText <STRING>
 *
 * Example:
 * ["mass<=10"] call aio_setup_fnc_escape;
 *
 * Public: No
 */

params [["_text", "", [""]]];

((_text regexReplace ["&", "&amp;"]) regexReplace ["<", "&lt;"]) regexReplace [">", "&gt;"]
