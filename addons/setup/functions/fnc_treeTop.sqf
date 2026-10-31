#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where to start the tree so that a class stands in its place among its relatives: the highest class above it
 * whose tree is still small enough to be worth one edit (TREE_UP_MAX classes) - for a rifle of a mod's family, the
 * base class all its variants share, not the rifle alone. The tree view's button opens there, with the class
 * picked in it, so a wrong pick is one click from the right one: its siblings and cousins are in view.
 *
 * Arguments:
 * 0: Class, lowercase or as config names it <STRING>
 *
 * Return Value:
 * The class to start the tree at, lowercase; the class itself when nothing above it is small enough or it is not known <STRING>
 *
 * Example:
 * ["B_Carryall_mcamo"] call aio_setup_fnc_treeTop;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _top = toLowerANSI _class;
private _steps = 0;

while {_steps < 12} do {
    private _parent = ([_top] call FUNC(classTree)) getOrDefault ["parent", ""];

    if (_parent isEqualTo "") exitWith {};

    // Too many below it: one edit would change a whole game.
    if (count (([_parent] call FUNC(classTree)) getOrDefault ["order", []]) > TREE_UP_MAX) exitWith {};

    _top = _parent;
    _steps = _steps + 1;
};

_top
