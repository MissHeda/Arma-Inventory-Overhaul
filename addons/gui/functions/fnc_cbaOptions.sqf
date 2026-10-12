#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The options other mods add to CBA's item context menu (CBA_fnc_addItemContextMenuOption) for an item,
 * as choices of this window's context menu: ACE's magazine repack, field rations, dog tags, IR modes,
 * CBA's optic and laser switching, and whatever else a mod registers.
 *
 * Read the way CBA reads them when the vanilla inventory opens its menu (cba_ui_fnc_openItemContextMenu),
 * so a mod sees the same: the item's class and every class it is built on, the options registered for
 * that class alone, then those for its type ("##" + subtype, "#" + type) and for everything ("#All").
 * The first option of an id wins. Shown where its slots name the slot - or "ALL" - and its condition
 * agrees; greyed out where it may not run now, and always where it would use the item up from the
 * ground or a crate, which CBA cannot. Its condition and statement get exactly what CBA hands them:
 * [unit, container, item, slot, its own arguments, id].
 *
 * Ordered by where it was found, then by name: CBA gives its rows no order of its own. The first row
 * carries a line above it, setting these choices apart from the window's own.
 *
 * An option a loaded compat addon replaces with a choice of its own is left out - Enhanced First Aid
 * Kits' "Open" (einv_compat_efak_fnc_hideCbaOption), ACRE2's "Open" on its radios (the window's own "Open
 * radio" steps aside first, einv_compat_acre_fnc_hideCbaOption) - and ACE's "Repack Magazines" while this
 * mod repacks magazines itself (einv_magazines_fnc_hideCbaOption).
 *
 * Arguments:
 * 0: Unit - the player, as CBA_fnc_currentUnit gives it <OBJECT>
 * 1: Container, see fnc_cbaTileTarget and fnc_cbaSlotTarget <OBJECT>
 * 2: Item class <STRING>
 * 3: CBA slot, e.g. "VEST_CONTAINER" or "RIFLE_OPTIC" - "" for none <STRING>
 *
 * Return Value:
 * Choices for fnc_openMenu, [text, [condition, statement, consume, arguments], code, options] each <ARRAY>
 *
 * Example:
 * [player, vestContainer player, "30Rnd_65x39_caseless_mag", "VEST_CONTAINER"] call einv_gui_fnc_cbaOptions;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_container", objNull, [objNull]], ["_item", "", [""]], ["_slot", "", [""]]];

if (_item isEqualTo "" || {_slot isEqualTo ""} || {isNil "cba_ui_ItemContextMenuOptions"}) exitWith {[]};

private _store = missionNamespace getVariable ["cba_ui_ItemContextMenuOptions", createHashMap];
private _unique = missionNamespace getVariable ["cba_ui_ItemContextMenuUniqueOptions", createHashMap];

// Where CBA looks, in its order - the most specific first.
private _sources = [];
private _config = _item call CBA_fnc_getItemConfig;

while {!isNull _config} do {
    _sources pushBack (_store getOrDefault [configName _config, createHashMap]);
    _config = inheritsFrom _config;
};

_sources pushBack (_unique getOrDefault [_item, createHashMap]);

(_item call BIS_fnc_itemType) params [["_type", "", [""]], ["_subtype", "", [""]]];

_sources pushBack (_store getOrDefault [format ["##%1", _subtype], createHashMap]);
_sources pushBack (_store getOrDefault [format ["#%1", _type], createHashMap]);
_sources pushBack (_store getOrDefault ["#All", createHashMap]);

// CBA's own "no icon".
private _noIcon = "#(argb,8,8,3)color(0,0,0,0)";
private _seen = createHashMap;
private _rows = [];

{
    private _rank = _forEachIndex;

    // Each source is a HashMap: _x is the option's id, _y the option.
    {
        private _id = _x;

        if (_id in _seen) then {continue};

        _seen set [_id, true];

        _y params ["_slots", "_displayName", "_tooltip", "_color", "_icon", "_conditionEnable", "_conditionShow", "_statement", "_consume", "_params"];

        private _args = [_unit, _container, _item, _slot, _params, _id];

        if (isLocalized _displayName) then {
            _displayName = localize _displayName;
        };

        if (isLocalized _tooltip) then {
            _tooltip = localize _tooltip;
        };

        // A condition that returns nothing counts as no.
        if !((_slot in _slots || {"ALL" in _slots}) && {[_args call _conditionShow] param [0, false]}) then {continue};

        if (!isNil QEFUNC(compat_efak,hideCbaOption) && {[_item, _displayName] call EFUNC(compat_efak,hideCbaOption)}) then {continue};
        if (!isNil QEFUNC(compat_acre,hideCbaOption) && {[_item, _displayName] call EFUNC(compat_acre,hideCbaOption)}) then {continue};
        if (!isNil QEFUNC(magazines,hideCbaOption) && {[_item, _displayName] call EFUNC(magazines,hideCbaOption)}) then {continue};

        // CBA has no command to take a single item out of the ground or a crate.
        if (_consume && {_slot in ["GROUND", "CARGO"]}) then {
            _conditionEnable = {false};
        };

        private _options = createHashMapFromArray [
            ["enabled", [_args call _conditionEnable] param [0, false]],
            ["tooltip", _tooltip],
            ["color", _color]
        ];

        if (_icon isNotEqualTo "" && {_icon isNotEqualTo _noIcon}) then {
            _options set ["icon", _icon];
        };

        // The running number keeps two options of the same name apart, so sorting never compares
        // the choices themselves.
        _rows pushBack [_rank, _displayName, count _rows, [
            _displayName,
            [_conditionEnable, _statement, _consume, _args],
            {_this call FUNC(cbaRun)},
            _options
        ]];
    } forEach _x;
} forEach _sources;

_rows sort true;

private _choices = _rows apply {_x select 3};

if (_choices isNotEqualTo []) then {
    ((_choices select 0) select 3) set ["separator", true];
};

_choices
