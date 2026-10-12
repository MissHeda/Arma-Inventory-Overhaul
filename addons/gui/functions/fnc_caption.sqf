#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A caption the way the style writes it: in capitals for the looks that shout their labels (Tarkov),
 * as it is for the others.
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * The caption <STRING>
 *
 * Example:
 * ["Backpack", _theme] call einv_gui_fnc_caption;
 *
 * Public: No
 */

params ["_text", ["_theme", createHashMap]];

if (_theme getOrDefault ["upper", false]) exitWith {toUpper _text};

_text
