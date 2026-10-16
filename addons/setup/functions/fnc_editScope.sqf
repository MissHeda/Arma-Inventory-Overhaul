#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What an edit of the picked class is for: just that class, or - when it was picked in the tree view
 * (fnc_drawTree) - that class and every class built on it. The second writes one rule with the
 * inheritance selector, class=X+ (fnc_upsertRules), instead of one rule per class. A class with nothing
 * built on it that a step lists has no tree: its edit is for that class alone.
 *
 * A kit of Enhanced First Aid Kits is always edited with its tree, however it was picked: the kits
 * players carry are the instance classes that mod makes of the type's own class ("efak_IFAK_7" of
 * "efak_IFAK", einv_items_fnc_kitOf), which no list shows, and a rule for the type's class alone would
 * never reach one of them. How many classes are built on it is then how many instances the type has.
 *
 * Arguments:
 * 0: Step: "items" or "containers" <STRING>
 * 1: Class <STRING>
 *
 * Return Value:
 * [for the tree, how many listed classes are built on it] <ARRAY>
 *
 * Example:
 * ["containers", "B_Carryall_mcamo"] call einv_setup_fnc_editScope;
 *
 * Public: No
 */

params [["_mode", "items", [""]], ["_class", "", [""]]];

if (_class isEqualTo "") exitWith {[false, 0]};

private _kit = [_class] call EFUNC(items,kitOf);

if ((_kit param [1, -1]) == 0) exitWith {[true, _kit select 2]};

if ((GVAR(editScope) getOrDefault [_mode, "class"]) isNotEqualTo "tree") exitWith {[false, 0]};

private _below = (count (([_class, _mode] call FUNC(treeRows)) getOrDefault ["rows", []]) - 1) max 0;

[_below > 0, _below]
