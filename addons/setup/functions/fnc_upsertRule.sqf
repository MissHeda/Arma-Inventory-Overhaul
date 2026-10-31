#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes what the Items or Containers step sets for one class into the draft, as that class's own rule
 * class=X > ... - or, for a tree, as the one rule class=X+ > ... that covers the class and every class built
 * on it. All of it is fnc_upsertRules, with the one class; see there for what happens to the rules already
 * written and where the new one goes.
 * While "Edit all" is on for the step the class is picked in (fnc_drawResults, GVAR(groupEdit)), the edit is for
 * everything the list found: one rule class=X* when the search was the start of a name with a *, else one rule
 * per class - all in one undo step.
 *
 * Ends in fnc_commit: an undo step, and the step drawn again.
 *
 * Arguments:
 * 0: Class, as config names it <STRING>
 * 1: Values to set: "footprint" ("2x3" or a mask), "stack" <NUMBER>, "grid" (as aio_items_fnc_formatGrid
 *    writes it), "like" (a class), "weight" (kg) <NUMBER>, "name" <STRING>, "use" (the containers it may be used from, an array of "uniform", "vest", "backpack"), "icon" ([scale, across, down]
 *    <ARRAY>, aio_items_fnc_parseIcon) <HASHMAP> (default: none)
 * 2: Fields to take away <ARRAY of STRING> (default: [])
 * 3: For the class and every class built on it <BOOL> (default: false)
 *
 * Return Value:
 * Written - false for a class name the rules language cannot hold <BOOL>
 *
 * Example:
 * ["V_PlateCarrier1_rgr", createHashMapFromArray [["grid", "xxxx/x--x+2x3"]]] call aio_setup_fnc_upsertRule;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_set", createHashMap, [createHashMap]], ["_remove", [], [[]]], ["_tree", false, [false]]];

private _entries = [[_class, _set, _remove, _tree]];
private _lc = toLowerANSI _class;

{
    _y params ["_selector", "_classes"];

    if ((toLowerANSI (GVAR(selection) getOrDefault [_x, ""])) isEqualTo _lc) exitWith {
        _entries = if (_selector isNotEqualTo "") then {
            [[_selector, _set, _remove, false]]
        } else {
            _classes apply {[_x, _set, _remove, false]}
        };

        [format [LLSTRING(Hint_GroupApplied), count _classes], "text2"] call FUNC(setHint);
    };
} forEach (missionNamespace getVariable [QGVAR(groupEdit), createHashMap]);

[_entries] call FUNC(upsertRules)
