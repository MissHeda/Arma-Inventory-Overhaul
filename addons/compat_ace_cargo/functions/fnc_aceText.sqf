#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE's own hint text for an unloading, as one line: ACE writes its hints as structured text with line
 * breaks, the window's footer shows a single line.
 *
 * Arguments:
 * 0: ACE's text, with %1 and %2 in it (STR_ACE_Cargo_UnloadedItem, STR_ACE_Cargo_UnloadingFailed) <STRING>
 * 1: What goes in for %1 <STRING>
 * 2: What goes in for %2 <STRING> (default: "")
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * [localize "STR_ACE_Cargo_UnloadedItem", "Spare Wheel", "Hunter HMG"] call einv_compat_ace_cargo_fnc_aceText;
 *
 * Public: No
 */

params [["_format", "", [""]], ["_first", "", [""]], ["_second", "", [""]]];

(format [_format, _first, _second]) regexReplace ["<br\s*/?>", " "]
