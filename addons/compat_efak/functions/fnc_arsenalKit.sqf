#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The kit section of ACE Arsenal's panel while Enhanced First Aid Kits' kits tab is open (aio_arsenal_fnc_layout):
 * the kit picked in that tab's list (fnc_arsenalFocus), as a section with its grid - filled there as a container is -
 * or, where there is no grid to show, a note in its place.
 *
 * Which kit: the very kit of the row picked (its data is the kit's instance class) where it lies in one of the
 * holders - the soldier's uniform, vest and backpack, then the staging space -, in their cargo or in what Strict
 * mode's hidden holder keeps for them (aio_storage_fnc_hiddenClasses). That mod's list follows a kit that was
 * moved, taken out or made anew (a loadout gives kits new instance classes) only at its next look; until then the
 * first kit of the same type lying there stands in. A kit packed in another kit is never shown.
 *
 * The section (fnc_kitSection) is titled "Kit: <name> (<used>/<room>)" - the name the player gave the kit or its
 * type's, and its fill in the measure its room is counted in (fnc_fillState: that mod's mass against its capacity,
 * or the cells of a grid of its own) -, and "panelTitle" names it for the panel's title row. A note instead
 * ("note", no grid, no "kit"): the row is one of kits still being made ready, the kits' contents have not reached
 * this machine yet (fnc_notReady), or no such kit lies in the holders - "Take the kit first".
 *
 * Where the kit lies is kept in GVAR(arsenalHolders), anew at every call, the kit alone (no holders given empties it):
 * no kit window is open in ACE's window, so GVAR(holders) knows none, and the moves between the kit's grid and a
 * container or the staging space (fnc_drop, fnc_canDrop, fnc_locate) find it there.
 *
 * Arguments:
 * 0: Class of the row picked in the kits tab, "" for none <STRING> (default: "")
 * 1: The row is one of kits still being made ready <BOOL> (default: false)
 * 2: Where to look - uniform, vest, backpack, the staging space <ARRAY of OBJECTs> (default: [])
 *
 * Return Value:
 * The section, see fnc_getSections - "container" objNull, "parent" the container the kit lies in; or a note
 * section ("note", "title", "panelTitle", "class" the type); an empty map when no holders were given <HASHMAP>
 *
 * Example:
 * ["efak_IFAK_7", false, [uniformContainer player, backpackContainer player]] call aio_compat_efak_fnc_arsenalKit;
 *
 * Public: No
 */

params [["_picked", "", [""]], ["_preparing", false, [false]], ["_holders", [], [[]]]];

GVAR(arsenalHolders) = createHashMap;

if (_holders isEqualTo []) exitWith {createHashMap};

// The type of the row picked, as that mod names it (efak_IFAK for efak_IFAK_7), and its name.
private _type = if (_picked isEqualTo "" || {isNil QEFAKFUNC(core,getPrototype)}) then {""} else {
    [_picked] call EFAKFUNC(core,getPrototype)
};

private _typeName = if (_type isEqualTo "") then {""} else {[_type] call EFAKFUNC(core,getKitName)};

private _fnc_note = {
    params ["_note"];

    createHashMapFromArray [
        ["id", "kitNote"],
        ["title", [LLSTRING(ArsenalKit), format [LLSTRING(ArsenalKitName), _typeName]] select (_typeName isNotEqualTo "")],
        ["panelTitle", [LLSTRING(ArsenalKit), _typeName] select (_typeName isNotEqualTo "")],
        ["class", _type],
        ["container", objNull],
        ["note", _note]
    ]
};

if (_picked isEqualTo "") exitWith {[LLSTRING(ArsenalTakeKit)] call _fnc_note};
if (_preparing) exitWith {[LLSTRING(Preparing)] call _fnc_note};

private _wait = [] call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[_wait] call _fnc_note};

// The kits lying in the holders, in their order: [class, container].
private _found = [];

{
    private _container = _x;

    if (isNull _container) then {continue};

    {
        if ([_x] call FUNC(isKit)) then {
            _found pushBack [_x, _container];
        };
    } forEach (((getItemCargo _container) param [0, []]) + ([_container] call EFUNC(storage,hiddenClasses)));
} forEach _holders;

// The kit of the row; else the first of its type that is no prototype still waiting for its instance.
private _unready = missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap];
private _index = _found findIf {(_x select 0) == _picked};

if (_index < 0 && {_type isNotEqualTo ""}) then {
    _index = _found findIf {
        !(toLowerANSI (_x select 0) in _unready) && {([_x select 0] call EFAKFUNC(core,getPrototype)) == _type}
    };
};

if (_index < 0) exitWith {[LLSTRING(ArsenalTakeKit)] call _fnc_note};

(_found select _index) params ["_kit", "_container"];

GVAR(arsenalHolders) set [toLowerANSI _kit, [_container, ""]];

private _section = [_kit, _container, "", _container] call FUNC(kitSection);

// The name the player gave it, else its type's; and how full it is.
private _name = [_kit] call FUNC(getName);

if (_name isEqualTo "") then {
    _name = [_typeName, _section getOrDefault ["title", _kit]] select (_typeName isEqualTo "");
};

([_kit] call FUNC(fillState)) params ["", "", ["_used", 0], ["_room", 0]];

_section set ["title", format [LLSTRING(ArsenalKitTitle), _name, _used, _room]];
_section set ["panelTitle", _name];

_section
