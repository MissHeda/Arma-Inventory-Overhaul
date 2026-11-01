#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A click on a box of the modding view (fnc_drawHotspots): tiles under the box (fnc_openMenu), as Tarkov's weapon builds list them, of what fits that part
 * of the player's weapon - from the player's own gear and the loot open beside it, each with its picture and where it
 * lies, a magazine with its rounds. A click on one puts it on (fnc_doEquip: taken out where it lies, what was on the part
 * put back there - the server checks it). NONE, the first tile, takes what is on the part now off into the gear
 * (fnc_quickUnequip). No title: the box says what it is.
 *
 * Only what may be touched (fnc_checkTouch, a kit as Enhanced First Aid Kits says), and what the slot takes
 * (aio_storage_fnc_slotAccepts). The same part in the same place is one row, with how many there are.
 *
 * Arguments:
 * 0: The part's slot, e.g. "primary_optic" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["primary_optic"] call aio_gui_fnc_partChoices;
 *
 * Public: No
 */

disableSerialization;

params [["_slot", "", [""]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _unit = GVAR(unit);

if (isNull _display || {isNull _unit} || {_slot isEqualTo ""}) exitWith {};

private _part = (_slot splitString "_") select -1;
private _kinds = [[_part], ["magazine", "grenade"]] select (_part in ["mag", "mag2"]);
private _choices = [];
private _rows = createHashMap;

{
    private _grid = _x;
    private _from = _grid getOrDefault ["container", objNull];
    private _kit = _grid getOrDefault ["kit", ""];

    if (_grid getOrDefault ["virtual", true]) then {continue};
    if (isNull _from && {_kit isEqualTo ""}) then {continue};

    // As the tile's own menu asks it (fnc_contextMenu): a living person's things only as the settings say, never another
    // living player's kit.
    private _touch = if (_kit isNotEqualTo "" && {!isNil QEFUNC(compat_efak,checkTouch)}) then {
        ([_kit] call EFUNC(compat_efak,checkTouch)) isEqualTo ""
    } else {
        ([_from, "items"] call FUNC(checkTouch)) isEqualTo ""
    };

    if (!_touch) then {continue};

    private _where = if (_kit isNotEqualTo "") then {[_kit] call FUNC(itemName)} else {[_from] call FUNC(containerName)};

    {
        private _tile = _x;
        private _class = _tile getOrDefault ["class", ""];

        if (_class isEqualTo "") then {continue};
        if (_tile getOrDefault ["hidden", false] || {_tile getOrDefault ["pending", false]}) then {continue};
        if !((([_class] call EFUNC(items,getInfo)) getOrDefault ["kind", ""]) in _kinds) then {continue};
        if (_kit isEqualTo "" && {!isNil QEFUNC(compat_efak,checkTile)} && {([_class, _from] call EFUNC(compat_efak,checkTile)) isNotEqualTo ""}) then {continue};
        if !([_unit, _slot, _class] call EFUNC(storage,slotAccepts)) then {continue};

        private _ammo = _tile getOrDefault ["ammo", -1];
        private _key = format ["%1|%2|%3|%4", _class, _where, _kit, _ammo];
        private _row = _rows getOrDefault [_key, -1];

        if (_row >= 0) then {
            private _choice = _choices select _row;
            _choice set [4, (_choice select 4) + (_tile getOrDefault ["count", 1])];
            continue;
        };

        _rows set [_key, count _choices];
        _choices pushBack [_class, [_slot, _from, _tile, _kit], {_this call FUNC(doEquip)}, createHashMapFromArray [
            ["icon", ([_class] call EFUNC(items,getInfo)) getOrDefault ["picture", ""]]
        ], _tile getOrDefault ["count", 1], _where, _ammo];
    } forEach (_grid getOrDefault ["tiles", []]);
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

// The rows' words: the part's name, how many, where - a magazine's rounds after its name.
private _found = _choices isNotEqualTo [];

// A tile each: the part's short name on it, the whole of it as its tip - how many, where, a magazine's rounds.
_choices = _choices apply {
    _x params ["_class", "_arguments", "_code", "_options", ["_count", 1], ["_where", ""], ["_ammo", -1]];

    private _capacity = ([_class] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0];
    private _name = [_class] call FUNC(itemName);
    private _tip = _name;

    if (_ammo >= 0 && {_capacity > 1}) then {
        _tip = format ["%1 (%2/%3)", _tip, _ammo, _capacity];
    };

    if (_count > 1) then {
        _tip = format ["%1 ×%2", _tip, _count];
    };

    _options set ["tooltip", format ["%1 - %2", _tip, _where]];

    [_name, _arguments, _code, _options]
};

// At most a screen's worth of tiles.
if (count _choices > 17) then {
    _choices resize 17;
};

// NONE first, as in Tarkov - it takes what is on the part off into the gear (also a right click on the box); greyed while the
// part is free. Nothing that fits: one greyed tile more saying so.
private _on = ([_unit, _slot] call EFUNC(storage,getSlot)) getOrDefault ["class", ""];

_choices insert [0, [[
    toUpperANSI LLSTRING(Modify_None), [_unit, _slot], {_this call FUNC(quickUnequip)}, createHashMapFromArray [["enabled", _on isNotEqualTo ""]]
]]];

if (!_found) then {
    _choices pushBack [LLSTRING(Modify_NoParts), [], {}, createHashMapFromArray [["enabled", false], ["tooltip", LLSTRING(Modify_NoParts)]]];
};

// Right under the box that was clicked - over it where the screen ends below (fnc_openMenu keeps it on the screen).
private _spot = (uiNamespace getVariable [QGVAR(hotspots), []]) select {(_x get "slot") isEqualTo _slot};
private _group = uiNamespace getVariable [QGVAR(inspectGroup), controlNull];
private _at = [];

if (_spot isNotEqualTo [] && {!isNull _group}) then {
    (ctrlPosition _group) params ["_cardX", "_cardY"];
    (_spot select ((_spot findIf {(_x get "floating") && {ctrlShown (_x get "ctrl")}}) max 0) get "rel") params ["_boxX", "_boxY", "", "_boxH"];

    _at = [_cardX + _boxX, _cardY + _boxY + _boxH + pixelH * 4];
};

[_display, _choices, _at, 3] call FUNC(openMenu);
