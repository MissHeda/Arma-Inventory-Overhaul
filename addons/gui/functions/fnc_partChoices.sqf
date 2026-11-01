#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A click on a box of the modding view (fnc_drawHotspots): tiles under the box (fnc_openMenu), as Tarkov's weapon builds list them, of what fits that part
 * of the player's weapon - from the player's own gear and the loot open beside it, each with its picture and where it
 * lies, a magazine with its rounds. A click on one puts it on (fnc_doEquip: taken out where it lies, what was on the part
 * put back there - the server checks it). While a part is on it, that part comes first, framed in the accent colour, and NONE
 * next to it takes it off into the gear (fnc_quickUnequip). No title: the box says what it is. That nothing fits is a note
 * under the tiles, never a tile. For a weapon lying in a container (fnc_weaponTile) the same, through op "fit" (fnc_doFit).
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

// A weapon lying in a container (Attachments in its tile's menu): the card's target names it, its tile is found again by its
// cell (fnc_weaponTile) - its parts change through op "fit" (fnc_doFit), checked by the weapon alone (aio_storage_fnc_partFits).
private _inGrid = (_slot select [0, 5]) isEqualTo "tile_";
private _target = GVAR(inspect) param [5, ""];
private _weaponTile = if (_inGrid && {_target isEqualType createHashMap}) then {[_target] call FUNC(weaponTile)} else {createHashMap};

if (_inGrid && {count _weaponTile == 0}) exitWith {};

private _weaponClass = _weaponTile getOrDefault ["class", ""];
private _weaponFrom = if (_target isEqualType createHashMap) then {_target getOrDefault ["container", objNull]} else {objNull};

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
        if (_inGrid) then {
            if (_kit isNotEqualTo "" || {!([_weaponClass, _part, _class] call EFUNC(storage,partFits))}) then {continue};
        } else {
            if !([_unit, _slot, _class] call EFUNC(storage,slotAccepts)) then {continue};
        };

        private _ammo = _tile getOrDefault ["ammo", -1];
        private _key = format ["%1|%2|%3|%4", _class, _where, _kit, _ammo];
        private _row = _rows getOrDefault [_key, -1];

        if (_row >= 0) then {
            private _choice = _choices select _row;
            _choice set [4, (_choice select 4) + (_tile getOrDefault ["count", 1])];
            continue;
        };

        _rows set [_key, count _choices];
        _choices pushBack [_class, [[_slot, _from, _tile, _kit], [_part, _weaponFrom, _weaponTile, _from, _tile]] select _inGrid, [{_this call FUNC(doEquip)}, {_this call FUNC(doFit)}] select _inGrid, createHashMapFromArray [
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

// What is on the part now first, framed in the accent colour (a click on it changes nothing), then NONE, which takes it off into
// the gear (also a right click on the box) - as Mia asked. Only real choices are tiles (Mia: "why is there still a choice
// 'Nothing fits'?"): that nothing fits is a line of text under them - and with nothing on the part and nothing that fits there
// is no grid at all, only the hint says so.
private _on = if (_inGrid) then {
    private _value = (_weaponTile getOrDefault ["attachments", []]) param [["", "muzzle", "rail", "optic", "mag", "mag2", "bipod"] find _part, ""];

    if (_value isEqualType []) then {_value param [0, ""]} else {_value}
} else {
    ([_unit, _slot] call EFUNC(storage,getSlot)) getOrDefault ["class", ""]
};

if (_on isNotEqualTo "") then {
    _choices insert [0, [
        [
            [_on] call FUNC(itemName), [], {}, createHashMapFromArray [
                ["icon", ([_on] call EFUNC(items,getInfo)) getOrDefault ["picture", ""]], ["outline", true],
                ["tooltip", [_on] call FUNC(itemName)]
            ]
        ],
        [
            toUpperANSI LLSTRING(Modify_None),
            [[_unit, _slot], [_part, _weaponFrom, _weaponTile]] select _inGrid,
            [{_this call FUNC(quickUnequip)}, {_this call FUNC(doFit)}] select _inGrid,
            createHashMap
        ]
    ]];
};

if (_choices isEqualTo []) exitWith {
    [LLSTRING(Modify_NoParts)] call FUNC(flashHint);
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

[_display, _choices, _at, 3, ["", LLSTRING(Modify_NoParts)] select !_found] call FUNC(openMenu);
