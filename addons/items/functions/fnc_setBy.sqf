#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Who set a field of an item, in four words, read off the source tags fnc_resolve leaves in "src":
 *   "rule"    - the rules text: a rule for the class, its tree (class=X+), a group, a kind, everything
 *               else (all), or one of the older tables, which count as rules of the text
 *   "config"  - the item's own mod, its config keys (aio_grid and the others, the older ones too)
 *   "preset"  - the preset the rules build on, and the small items' stack slider, which has its say in
 *               the preset's layer (aio_items_stackSmall)
 *   "default" - nobody: the built-in answer, or one that is always the same (a weapon's stack)
 * A like= rule counts as the rule it is: the field was set by whoever wrote it.
 *
 * Arguments:
 * 0: The item, as fnc_getInfo gives it <HASHMAP>
 * 1: Field: "footprint", "stack", "grid", "weight" or "name" <STRING>
 *
 * Return Value:
 * "rule", "config", "preset" or "default" <STRING>
 *
 * Example:
 * [["efak_IFAK_7"] call aio_items_fnc_getInfo, "grid"] call aio_items_fnc_setBy;
 *
 * Public: Yes
 */

params [["_info", createHashMap, [createHashMap]], ["_field", "grid", [""]]];

private _src = (_info getOrDefault ["src", createHashMap]) getOrDefault [_field, "builtin"];
private _prefix = (_src splitString ":") param [0, ""];

if (_prefix isEqualTo "legacy" && {((_src splitString ":") param [1, ""]) isEqualTo QGVAR(stackSmall)}) exitWith {"preset"};

switch (_prefix) do {
    case "own";
    case "legacy";
    case "all": {"rule"};
    case "mod": {"config"};
    case "preset": {"preset"};
    default {"default"};
}
