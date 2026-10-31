#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The strip of categories at the side of a loot box, as Tarkov has it left of its loot grid: one slim column of white
 * pictures - All, weapons, ammunition, grenades and explosives, gear and clothing, medical, food and drink, tools and electronics, other
 * and the categories the setup defines itself (fnc_stripEntries). A click chooses a category (fnc_setGroup): only that kind of item
 * shows in the box, the rest is hidden (fnc_applyFilter), and a paged box turns to its first page with a match; a click on it again, or
 * on All, shows everything. With more categories than the strip has fields (STRIP_SLOTS) its last field is "more" and turns to the next
 * group of them (fnc_stripMore). The chosen one is a lighter field with a white picture - no accent colour (Mia, 0.5.7);
 * the mouse resting on one lights it a little and shows its name (the tooltip).
 *
 * The strip is one rounded bar (the colour of the caption chips) and its fields lie exactly on it: each field is as wide
 * as the bar and as high as its share of it, the first with the bar's round top corners, the last with its round bottom
 * corners (fnc_uiSurface), so a chosen field ends where the bar ends and nothing shows round it.
 *
 * Three controls (sets) per picture - the field, the picture, the hit box -, kept in the section's info ("strip", [id, field,
 * picture, hit]) for fnc_paintGroupStrip and fnc_stripMore. Not for the player's own containers (they are small and the player knows what is in
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
 * [_display, _group, [0, 0, 0.02, 0.3], _crate, _info, _theme] call aio_gui_fnc_drawGroupStrip;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_holder", "_info", "_theme"];
_rect params ["_left", "_top", "_width", "_height"];

private _pageAt = GVAR(stripPages) findIf {(_x select 0) isEqualTo _holder};
private _page = 0;

if (_pageAt >= 0) then {
    _page = (GVAR(stripPages) select _pageAt) select 1;
};

([_page] call FUNC(stripEntries)) params ["_groups"];

private _count = STRIP_SLOTS min (count _groups);
private _pitch = _height / _count;
private _size = (_pitch * 0.78) min (UNSQUARE(_width) * 0.78);
private _strip = [];

// The bar the fields lie on, as round as the chips of the caption line; the fields take its corners (the first its top ones, the last its
// bottom ones) in pixels, as fnc_uiPanel works them out.
private _radius = (_theme getOrDefault ["radius", 0]) min (UNSQUARE(_width) / 2);
private _cornerPx = floor (_radius / pixelH);

[_display, _parent, _rect, _theme getOrDefault ["slotCaptionBg", [1, 1, 1, 0.06]], _radius] call FUNC(uiPanel);

{
    _x params ["_id", "_texture", "_name"];

    private _cellTop = _top + _forEachIndex * _pitch;
    private _first = _forEachIndex == 0;
    private _last = _forEachIndex == _count - 1;

    // The field: exactly this share of the bar, so a lit one ends where the bar ends.
    private _fieldTop = [_cellTop, _top] select _first;
    private _fieldBottom = [_cellTop + _pitch, _top + _height] select _last;
    private _field = [
        _display, _parent, [_left, _fieldTop, _width, _fieldBottom - _fieldTop], [0, 0, 0, 0],
        [[], [_cornerPx, [_first, _first, _last, _last]]] select (_cornerPx >= 1 && {_first || _last})
    ] call FUNC(uiSurface);

    private _picture = [
        _display, _parent, [_left + (_width - SQUARE(_size)) / 2, _cellTop + (_pitch - _size) / 2, SQUARE(_size), _size], _texture,
        _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]
    ] call FUNC(uiIcon);

    // What catches the mouse: the field, and two pixels either side (above and below it lie the neighbours' own).
    private _hit = [_display, "AIO_Hitbox", _parent, [_left - pixelW * 2, _fieldTop, _width + pixelW * 4, _fieldBottom - _fieldTop]] call FUNC(uiCreate);

    _hit setVariable [QGVAR(key), _holder];
    _hit setVariable [QGVAR(kind), _id];
    _hit setVariable [QGVAR(picture), _picture];
    _hit setVariable [QGVAR(field), _field];
    [_hit, _name] call FUNC(setTooltip);

    // Under the mouse: a little lighter, the chosen one stays as it is.
    _hit ctrlAddEventHandler ["MouseEnter", {
        params ["_ctrl"];

        // "All" is the lit one while no category is chosen.
        private _chosen = [_ctrl getVariable [QGVAR(key), objNull]] call FUNC(boxGroup);

        if (_chosen isEqualTo "") then {_chosen = "all"};

        if (_chosen isEqualTo (_ctrl getVariable [QGVAR(kind), ""])) exitWith {};

        [_ctrl getVariable [QGVAR(field), []], [1, 1, 1, 0.07]] call FUNC(paintSurface);
        (_ctrl getVariable [QGVAR(picture), controlNull]) ctrlSetTextColor (GVAR(theme) getOrDefault ["text", [1, 1, 1, 1]]);
    }];
    _hit ctrlAddEventHandler ["MouseExit", {
        [(_this select 0) getVariable [QGVAR(key), objNull]] call FUNC(paintGroupStrip);
    }];
    _hit ctrlAddEventHandler ["ButtonClick", {
        [{
            params ["_holder", "_kind"];

            // The last field turns to the next group of categories; the others choose one.
            if (_kind isEqualTo "more") then {
                [_holder] call FUNC(stripMore);
            } else {
                [_holder, _kind] call FUNC(setGroup);
            };
        }, [(_this select 0) getVariable [QGVAR(key), objNull], (_this select 0) getVariable [QGVAR(kind), "all"]]] call FUNC(later);
    }];

    _strip pushBack [_id, _field, _picture, _hit];
} forEach _groups;

_info set ["strip", _strip];

[_holder] call FUNC(paintGroupStrip);
