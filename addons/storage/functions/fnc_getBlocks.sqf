#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The compartments of a container object: whose it is and what it is decide which class to ask the
 * rules about, and fnc_blocksFor lays it out. The class is the uniform's or vest's item class
 * (CfgWeapons), the backpack's class or the crate's or vehicle's own (CfgVehicles).
 *
 * Where the grid comes from, first answer wins:
 *   1. einv_grid on the object itself - a mission's word for this one crate, vehicle or unit's
 *      uniform, vest or backpack container: _crate setVariable ["einv_grid", "6x4+2x3", true]. Any
 *      grid the rules know (einv_items_fnc_parseGrid), shapes like "xxx/x-x" too; one that cannot be
 *      read is named in the RPT once and the rules count instead. A script of this mod may give the
 *      compartments as they are instead, [[cols, rows], ...]: taken exactly, never cut to MAX_ROWS - the
 *      Arsenal's staging space grows with what lies in it, up to its own cap (einv_arsenal_fnc_growStaging).
 *   2. the rules for its class (einv_items_fnc_getInfo "grid"): the older container table, the rules
 *      text, einv_grids[] / einv_slots in config, the preset - "auto", by its load, when none says.
 * The load is the object's own maximumLoad (fnc_getMaxLoad), the mass per cell the rules'.
 *
 * The ground has no compartments and no limit: [].
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Compartments [[cols, rows, holes, pos], ...] (see fnc_blocksFor), [] for the ground <ARRAY>
 *
 * Example:
 * [vestContainer player] call einv_storage_fnc_getBlocks;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {[_container] call FUNC(isGroundHolder)}) exitWith {[]};

// What the container belongs to: a unit's uniform, vest or backpack - or the object itself.
([_container] call FUNC(getOwner)) params ["_owner", "_slot"];

private _class = typeOf _container;
private _kind = "crate";

switch (_slot) do {
    case "uniform": {_class = uniform _owner; _kind = "uniform"};
    case "vest": {_class = vest _owner; _kind = "vest"};
    case "backpack": {_class = backpack _owner; _kind = "backpack"};
    default {
        // Nobody's: a crate or vehicle - or a uniform, vest or backpack lying in one. The container
        // object of a uniform or vest is only its Supply class, which does not say which uniform or
        // vest it is. Its tag says (fnc_tagNested, public), else the mark every read of the container it
        // lies in leaves here (fnc_getContents, fnc_verifyChain, einv_gui_fnc_openNested), else - in
        // multiplayer, where the tag on the object may not arrive - the copy on the outermost container.
        // The same class either way. Known by none, it is laid out like a crate.
        private _tag = _container getVariable [QGVAR(tag), []];
        private _itemClass = if (_tag isEqualType []) then {_tag param [1, ""]} else {""};

        if !(_itemClass isEqualType "") then {_itemClass = ""};

        if (_itemClass isEqualTo "") then {
            _itemClass = _container getVariable [QGVAR(itemClass), ""];
        };

        if (_itemClass isEqualTo "" && {isMultiplayer}) then {
            private _top = [_container, objNull, "top"] call FUNC(rootOf);

            if (_top isNotEqualTo _container) then {
                private _nested = _top getVariable [QGVAR(nested), []];
                private _netId = netId _container;
                private _index = if (_nested isEqualType []) then {
                    _nested findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}}
                } else {-1};

                if (_index >= 0) then {
                    _itemClass = (_nested select _index) select 2;
                };
            };
        };

        if (_itemClass isNotEqualTo "") then {
            private _itemKind = ([_itemClass] call EFUNC(items,getInfo)) get "kind";

            if (_itemKind in ["uniform", "vest", "backpack"]) then {
                _class = _itemClass;
                _kind = _itemKind;
            };
        };
    };
};

if (_kind isEqualTo "crate" && {getNumber (configFile >> "CfgVehicles" >> _class >> "isBackpack") == 1}) then {
    _kind = "backpack";
};

// The mission's word for this object. Read once per text: a broken one is named once, not on every
// layout, and the rules count instead.
private _spec = [];
private _objectGrid = _container getVariable [QGVARMAIN(grid), ""];

// Compartments given as they are: no text to read, and no cut to the rules' limits.
if (_objectGrid isEqualType [] && {_objectGrid isNotEqualTo []} && {_objectGrid findIf {!(_x isEqualTypeParams [0, 0])} < 0}) then {
    _spec = ["blocks", _objectGrid];
};

if (_objectGrid isEqualType "" && {_objectGrid isNotEqualTo ""}) then {
    _spec = GVAR(objectGrids) get _objectGrid;

    if (isNil "_spec") then {
        ([_objectGrid] call EFUNC(items,parseGrid)) params ["_parsed", "_messages"];

        {
            WARNING_2("einv_grid on %1: %2",typeOf _container,_x);
        } forEach _messages;

        _spec = _parsed;
        GVAR(objectGrids) set [_objectGrid, _spec];
    };
};

// The rules for the class - a class that is no container to them (a mod's odd cargo object) gets its
// grid by load.
if (_spec isEqualTo []) then {
    _spec = ([_class] call EFUNC(items,getInfo)) getOrDefault ["grid", []];
};

if (_spec isEqualTo []) then {
    _spec = ["auto"];
};

[
    _class,
    _kind,
    [_container] call FUNC(getMaxLoad),
    _spec,
    (call EFUNC(items,currentRules)) getOrDefault ["cell", 5]
] call FUNC(blocksFor)
