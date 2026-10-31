#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of a class share one tile in a holder. This is the one place a stack size is read for a place
 * where tiles lie: a class's stack (aio_items_fnc_getInfo "stack") in a uniform, vest, backpack or kit, and
 * that stack times the server setting "Stack multiplier for crates and vehicles"
 * (aio_storage_stackMultiplier) in a crate, a vehicle or a pile on the ground - the holders nobody wears.
 * A crate full of vials is then a few tiles of twenty-five instead of a mass of tiles of five.
 *
 * Only a class that stacks is multiplied: a stack of 1 (rifles, magazines, kits, bulky things) stays 1 in
 * every holder, so the multiplier makes a stack larger and never makes something stack that does not. The
 * result is rounded up (ceil), and 1 on the setting switches the whole thing off.
 *
 * A uniform, vest or backpack lying in a crate is a worn kind of container as well: what it holds goes by
 * its own stack, so the same pile is the same tiles once it is put on. A kit (a holder that is a key, not an
 * object) and a null holder have the plain stack.
 *
 * Whoever lays tiles out reads the stack through this: fnc_getContents, fnc_hasSpace, fnc_plan, the ops
 * that put and place, the badge on a tile and the merge of a drop. The setting is the same on every machine
 * (a server setting, aio_main_fnc_addSetting), so the machine that owns a holder and the ones that only read
 * it cut the same tiles. A count above this stack - the setting went down, or a pile was moved here from a
 * crate - is not an error: fnc_stackCounts reconciles the places with the cargo, the surplus opens new tiles
 * of full stacks and a remainder.
 *
 * Arguments:
 * 0: Holder - a container, or the key of a holder with no object <OBJECT or STRING>
 * 1: Class <STRING>
 * 2: The class's own stack when the caller has read it already (default: read here) <NUMBER>
 *
 * Return Value:
 * How many may share a tile there, at least 1 <NUMBER>
 *
 * Example:
 * [_crate, "ACM_Vial_Morphine"] call aio_storage_fnc_stackFor;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_class", "", [""]], ["_stack", -1, [0]]];

if (_stack < 1) then {
    _stack = (([_class] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) max 1;
};

if (_stack <= 1 || {_holder isEqualType ""}) exitWith {_stack};

private _multiplier = missionNamespace getVariable [QGVAR(stackMultiplier), 1];

if (!(_multiplier isEqualType 0) || {_multiplier <= 1}) exitWith {_stack};

// Whether a holder of this class is one nobody wears: not a uniform's or vest's container (a Supply class), not
// a backpack and not a unit. Worked out once per class.
private _type = typeOf _holder;
private _roomy = GVAR(stackRoomy) get _type;

if (isNil "_roomy") then {
    _roomy = _type isNotEqualTo ""
        && {!(_holder isKindOf "ContainerSupply")} && {!(_holder isKindOf "Bag_Base")} && {!(_holder isKindOf "CAManBase")};

    GVAR(stackRoomy) set [_type, _roomy];
};

if (_roomy) then {ceil (_stack * _multiplier)} else {_stack}
