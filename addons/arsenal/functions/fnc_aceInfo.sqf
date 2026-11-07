#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the info card of ACE Arsenal in this mod's look says of the item picked in its lists (fnc_aceSkin, Mia after 0.6.89:
 * "neat to know stats, as our hover in the inventory"): its name, then as the inventory's hint line says it - the cells it takes
 * in the grids, how many share one cell, its weight, a magazine's rounds, what a uniform, vest or backpack holds - in the theme's
 * colours. Words for parseText.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Structured text, "" for nothing picked <STRING>
 *
 * Example:
 * ["arifle_MX_F"] call aio_arsenal_fnc_aceInfo;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "" || {isNil "aio_items_fnc_getInfo"}) exitWith {""};

private _info = [_class] call aio_items_fnc_getInfo;

if (count _info == 0) exitWith {""};

private _theme = missionNamespace getVariable [QEGVAR(gui,theme), createHashMap];
private _fnc_hex = {
    params ["_colour"];

    "#" + ((_colour select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);
        ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
    } joinString "")
};

private _textColour = [_theme getOrDefault ["text", [1, 1, 1, 1]]] call _fnc_hex;
private _muted = [_theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]] call _fnc_hex;
private _accent = [_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] call _fnc_hex;
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _bold = _theme getOrDefault ["fontBold", _font];

(_info getOrDefault ["size", [1, 1]]) params [["_w", 1], ["_h", 1]];

private _kg = ((_info getOrDefault ["mass", 0]) max 0) * MASS_TO_KG;
private _parts = [
    format ["<t font='%1' color='%2'>%3</t>", _bold, _textColour, _info getOrDefault ["name", _class]],
    format ["<t color='%1'>%2×%3 cells</t>", _accent, _w, _h],
    format ["<t color='%1'>%2 kg</t>", _muted, _kg toFixed ([1, 2] select (_kg < 1))]
];

private _stack = _info getOrDefault ["stack", 1];

if (_stack > 1) then {
    _parts pushBack format ["<t color='%1'>%2 per cell</t>", _muted, _stack];
};

private _capacity = _info getOrDefault ["capacity", 0];

if (_capacity > 1) then {
    _parts pushBack format ["<t color='%1'>%2 rounds</t>", _muted, _capacity];
};

format ["<t font='%1' size='0.9' valign='middle'>%2</t>", _font, _parts joinString "      "]
