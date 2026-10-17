#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The strip of categories at the side of a loot box, as Tarkov has it left of its loot grid: one slim column of white
 * pictures - All, weapons, ammunition, gear and clothing, medical, food and drink, tools and electronics, other (the
 * groups of fnc_itemGroup). A click chooses a category (fnc_setGroup): only that kind of item shows in the box, the
 * rest fades as the search field fades it, and a paged box turns to its first page with a match; a click on it again, or
 * on All, shows everything. The chosen one is lit in the accent colour on a soft accent field; the mouse resting on one
 * lights it and shows its name (the tooltip).
 *
 * Three controls per picture - the field, the picture, the hit box -, kept in the section's info ("strip", [id, field,
 * picture]) for fnc_paintGroupStrip. Not for the player's own containers (they are small and the player knows what is in
 * them), a section with no grid of its own, or a column too narrow to spare the room (fnc_drawSection).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Where it stands [x, y, width, height]; the pictures share the height <ARRAY>
 * 3: The box's container <OBJECT>
 * 4: The section's info (fnc_drawSection) <HASHMAP>
 * 5: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [0, 0, 0.02, 0.3], _crate, _info, _theme] call einv_gui_fnc_drawGroupStrip;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_holder", "_info", "_theme"];
_rect params ["_left", "_top", "_width", "_height"];

private _groups = [
    ["all", UI_TEX(slot_cat_all_ca), LLSTRING(Group_All)],
    ["weapon", UI_TEX(slot_rifle_ca), LLSTRING(Group_Weapon)],
    ["ammo", UI_TEX(slot_magazine_ca), LLSTRING(Group_Ammo)],
    ["gear", UI_TEX(slot_vest_ca), LLSTRING(Group_Gear)],
    ["medical", UI_TEX(slot_cat_medical_ca), LLSTRING(Group_Medical)],
    ["food", UI_TEX(slot_cat_food_ca), LLSTRING(Group_Food)],
    ["tool", UI_TEX(slot_radio_ca), LLSTRING(Group_Tool)],
    ["misc", UI_TEX(slot_cat_misc_ca), LLSTRING(Group_Misc)]
];

private _pitch = _height / count _groups;
private _size = (_pitch * 0.78) min UNSQUARE(_width);
private _strip = [];

{
    _x params ["_id", "_texture", "_name"];

    private _cellTop = _top + _forEachIndex * _pitch;
    private _cell = [_left, _cellTop + (_pitch - _size) / 2 - _size * 0.1, _width, _size * 1.2];

    // The field the chosen one is lit on, the picture, and what catches the mouse.
    private _field = [_display, _parent, _cell, [0, 0, 0, 0], (_theme getOrDefault ["radius", 0]) min (_size * 0.25)] call FUNC(uiPanel);
    private _picture = [
        _display, _parent, [_left + (_width - SQUARE(_size)) / 2, _cellTop + (_pitch - _size) / 2, SQUARE(_size), _size], _texture,
        _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]
    ] call FUNC(uiIcon);
    private _hit = [_display, "EINV_Hitbox", _parent, [_left - pixelW * 2, _cell select 1, _width + pixelW * 4, _cell select 3]] call FUNC(uiCreate);

    _hit setVariable [QGVAR(key), _holder];
    _hit setVariable [QGVAR(kind), _id];
    _hit setVariable [QGVAR(picture), _picture];
    _hit ctrlSetTooltip _name;
    _hit ctrlAddEventHandler ["MouseEnter", {
        ((_this select 0) getVariable [QGVAR(picture), controlNull]) ctrlSetTextColor (GVAR(theme) getOrDefault ["text", [1, 1, 1, 1]]);
    }];
    _hit ctrlAddEventHandler ["MouseExit", {
        [(_this select 0) getVariable [QGVAR(key), objNull]] call FUNC(paintGroupStrip);
    }];
    _hit ctrlAddEventHandler ["ButtonClick", {
        [{_this call FUNC(setGroup)}, [(_this select 0) getVariable [QGVAR(key), objNull], (_this select 0) getVariable [QGVAR(kind), "all"]]] call FUNC(later);
    }];

    _strip pushBack [_id, _field, _picture];
} forEach _groups;

_info set ["strip", _strip];

[_holder] call FUNC(paintGroupStrip);
