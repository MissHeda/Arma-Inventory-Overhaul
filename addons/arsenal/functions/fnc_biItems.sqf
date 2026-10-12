#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Maps the cargo of a vanilla box into ACE's structure: the lists on the box and on the mission united, a
 * list that holds everything adding ACE's whole categories, the linked items of the virtual weapons and
 * what the soldier wears now, less what the mission restricts. A category the mission edited in the vanilla
 * catalog is limited to the edit.
 *
 * The lists are the vanilla ones, [items, weapons, magazines, backpacks], kept on the box and on the mission
 * by the vanilla functions; "%ALL" in one means every item of that kind. All four holding it, or the full
 * flag, is a full arsenal. What the soldier carries is offered - a mission built on vanilla boxes expects to
 * be able to put on again what it took off.
 *
 * The result is not a list in ACE's form but the class names; ACE's own addVirtualItems makes the form of it
 * (fnc_openWindow), which also takes base weapons and drops classes the game does not know.
 *
 * Arguments:
 * 0: Box <OBJECT>
 * 1: Offer everything <BOOL>
 * 2: Unit <OBJECT>
 *
 * Return Value:
 * [full, classes] <ARRAY>
 *
 * Example:
 * [_box, false, player] call einv_arsenal_fnc_biItems;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]], ["_full", false, [false]], ["_center", objNull, [objNull]]];

private _variable = "bis_addVirtualWeaponCargo_cargo";
private _empty = [[], [], [], []];

// ----- The lists, united -----

private _boxCargo = [_empty, _box getVariable [_variable, _empty]] select !isNull _box;
private _missionCargo = missionNamespace getVariable [_variable, _empty];

private _lists = [[], [], [], []];

{
    private _index = _forEachIndex;
    private _united = (_boxCargo param [_index, []]) + (_missionCargo param [_index, []]);

    _lists set [_index, _united select {_x isEqualType ""}];
} forEach _empty;

private _wantsAll = _lists apply {(_x findIf {(toLowerANSI _x) isEqualTo "%all"}) >= 0};

if (_full || {!(false in _wantsAll)}) exitWith {[true, []]};

// ----- ACE's categories, for the lists that hold everything -----

private _configItems = uiNamespace getVariable [QACEGVAR(arsenal,configItems), createHashMap];

// The classes of one of ACE's categories: a number, or [outer, inner] for the weapons and attachments, which
// are one deeper.
private _fnc_category = {
    params ["_category"];

    if (_category isEqualType []) exitWith {
        _category params ["_outer", "_inner"];

        keys (((_configItems getOrDefault [_outer, createHashMap]) getOrDefault [_inner, createHashMap]))
    };

    if (_category in [ACE_IDX_WEAPONS, ACE_IDX_ATTACHMENTS]) exitWith {
        private _all = [];

        {
            _all append (keys _y);
        } forEach (_configItems getOrDefault [_category, createHashMap]);

        _all
    };

    keys (_configItems getOrDefault [_category, createHashMap])
};

// Items, weapons, magazines, backpacks.
private _everything = [
    [ACE_IDX_ATTACHMENTS, ACE_IDX_HEADGEAR, ACE_IDX_UNIFORM, ACE_IDX_VEST, ACE_IDX_GOGGLES, ACE_IDX_NVG, ACE_IDX_BINO, ACE_IDX_MAP, ACE_IDX_COMPASS, ACE_IDX_RADIO, ACE_IDX_WATCH, ACE_IDX_COMMS, ACE_IDX_MISC_ITEMS, ACE_IDX_MISC_GOGGLES],
    [ACE_IDX_WEAPONS, ACE_IDX_BINO],
    [ACE_IDX_ITEMS_ALL, ACE_IDX_GRENADES, ACE_IDX_EXPLOSIVES],
    [ACE_IDX_BACKPACK]
];

private _classes = [];

{
    _classes append _x;

    if (_wantsAll select _forEachIndex) then {
        {
            _classes append ([_x] call _fnc_category);
        } forEach (_everything select _forEachIndex);
    };
} forEach _lists;

// ----- What is always there -----

// The default attachments of every virtual weapon, as the vanilla arsenal adds them (its linked items).
private _weapons = (_lists select 1) + (weapons _center);

{
    private _linked = "true" configClasses (configFile >> "CfgWeapons" >> _x >> "LinkedItems");

    {
        private _item = getText (_x >> "item");

        if (_item isNotEqualTo "") then {
            _classes pushBack _item;
        };
    } forEach _linked;
} forEach _weapons;

// What the soldier has on and with him now.
if (!isNull _center) then {
    _classes append (items _center);
    _classes append (assignedItems _center);
    _classes append (primaryWeaponItems _center);
    _classes append (secondaryWeaponItems _center);
    _classes append (handgunItems _center);
    _classes append (weapons _center);
    _classes append (magazines _center);
    _classes append [uniform _center, vest _center, headgear _center, goggles _center, binocular _center, backpack _center];
};

// ----- Less what is not allowed -----

private _restricted = ["u_virtualman_f", "fakeweapon"];
private _byMission = getMissionConfigValue ["arsenalRestrictedItems", []];

if (_byMission isEqualType [] && {_byMission isEqualTypeAll ""}) then {
    _restricted append (_byMission apply {toLowerANSI _x});
};

_classes = _classes select {_x isEqualType "" && {_x isNotEqualTo ""} && {!((toLowerANSI _x) in _restricted)}};

// ----- A category the mission edited in the vanilla catalog is limited to the edit -----

// Each: the vanilla tabs, and ACE's categories they hold the same kind as.
private _tabs = [
    [[0], [[ACE_IDX_WEAPONS, ACE_IDX_PRIMARY]]],
    [[1], [[ACE_IDX_WEAPONS, ACE_IDX_LAUNCHER]]],
    [[2], [[ACE_IDX_WEAPONS, ACE_IDX_HANDGUN]]],
    [[3], [ACE_IDX_UNIFORM]],
    [[4], [ACE_IDX_VEST]],
    [[5], [ACE_IDX_BACKPACK]],
    [[6], [ACE_IDX_HEADGEAR]],
    [[7], [ACE_IDX_GOGGLES]],
    [[8], [ACE_IDX_NVG]],
    [[9], [ACE_IDX_BINO]],
    [[10], [ACE_IDX_MAP]],
    [[11], [ACE_IDX_COMMS]],
    [[12], [ACE_IDX_RADIO]],
    [[13], [ACE_IDX_COMPASS]],
    [[14], [ACE_IDX_WATCH]],
    [[18], [[ACE_IDX_ATTACHMENTS, ACE_IDX_OPTIC]]],
    [[19], [[ACE_IDX_ATTACHMENTS, ACE_IDX_RAIL]]],
    [[20], [[ACE_IDX_ATTACHMENTS, ACE_IDX_MUZZLE]]],
    [[25], [[ACE_IDX_ATTACHMENTS, ACE_IDX_BIPOD]]],
    [[21, 26], [ACE_IDX_ITEMS_ALL]],
    [[22], [ACE_IDX_GRENADES]],
    [[23], [ACE_IDX_EXPLOSIVES]],
    [[24], [ACE_IDX_MISC_ITEMS, ACE_IDX_MISC_GOGGLES]]
];

private _data = missionNamespace getVariable ["bis_fnc_arsenal_data", []];
private _base = GVAR(biCatalogBase);

if (_base isNotEqualTo [] && {_data isEqualType []} && {_data isNotEqualTo _base}) then {
    {
        _x params ["_tabIndexes", "_categories"];

        private _edited = _tabIndexes findIf {(_data param [_x, []]) isNotEqualTo (_base param [_x, []])} >= 0;

        if (!_edited) then {continue};

        // What the edited tabs hold now ...
        private _allowed = createHashMap;

        {
            {
                if (_x isEqualType "") then {
                    _allowed set [toLowerANSI _x, true];
                };
            } forEach (_data param [_x, []]);
        } forEach _tabIndexes;

        // ... and what of ACE's category is not among it goes.
        private _dropped = createHashMap;

        {
            {
                if !((toLowerANSI _x) in _allowed) then {
                    _dropped set [toLowerANSI _x, true];
                };
            } forEach ([_x] call _fnc_category);
        } forEach _categories;

        _classes = _classes select {!((toLowerANSI _x) in _dropped)};
    } forEach _tabs;
};

[false, _classes arrayIntersect _classes]
