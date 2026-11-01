#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The inspect card's modding view for one of the player's own weapons (Inspect or Modify in its menu, fnc_drawInspect),
 * as in Tarkov (#56): where each of its parts goes, two ways -
 *
 *   - over the 3D picture, as in Tarkov's weapon builds, a box per part off the weapon with a line to a dot on the
 *     part's place on the model (fnc_weaponPoints), following the weapon as it is turned, moved and zoomed
 *     (fnc_placeHotspots) - hidden where the model names no place for it, or where it turns away behind the camera;
 *   - under the picture, the same parts as a fixed row - what the model names no place for, and every part in 2D or
 *     without Picture-in-Picture, is there all the same.
 *
 * Only the parts the weapon has: what is on it, and a slot of its kind the weapon takes parts for (CBA's
 * compatibleItems for the attachments, the muzzles' magazines). A point shows the part's picture, a free one the
 * silhouette of its slot. A click lists the parts that fit it from the player's gear and the open loot
 * (fnc_partChoices), a right click takes the part off into the gear (fnc_quickUnequip), a part dragged from a grid and
 * let go on a point goes on there (fnc_updateDrag, fnc_hotspotAt) - every move the server checks, as the old boxes'.
 *
 * The points' hit boxes keep their own tips (fnc_setTooltip), and the 3D view's areas that turn the item give the focus
 * away when pressed (fnc_drawInspect), so the points stay over them.
 *
 * Kept as uiNamespace QGVAR(hotspots): a HashMap per point - "part", "slot", "class" on it, "ctrl", "rel" (where it
 * lies in the card, [x, y, w, h]), "floating" (a point over the 3D picture) - and QGVAR(hotspotView): the picture's
 * area in the card and the areas a point never lies on.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The card's group <CONTROL>
 * 2: The 3D picture's area in the card, [] in 2D <ARRAY>
 * 3: The row's area in the card <ARRAY>
 * 4: The areas in the card no point may lie on - the 2D/3D switch <ARRAY>
 * 5: The weapon's slot, "primary", "primary2", "handgun" or "launcher" <STRING>
 * 6: The weapon, as fnc_getEquipment has it [class, muzzle, rail, optic, [magazine, rounds] or [], [magazine, rounds] or [], bipod] <ARRAY>
 * 7: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, _viewRect, _rowRect, [_toggleRect], "primary", _weapon, GVAR(theme)] call aio_gui_fnc_drawHotspots;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_viewRect", "_rowRect", "_blocked", "_base", "_weapon", "_theme"];
_rowRect params ["_rowX", "_rowY", "_rowW", "_rowH"];

private _class = _weapon param [0, "", [""]];
private _spots = [];

uiNamespace setVariable [QGVAR(hotspots), _spots];
uiNamespace setVariable [QGVAR(hotspotView), [_viewRect, _blocked]];

if (_class isEqualTo "") exitWith {};

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _colorMuted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _accent = (_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]) select [0, 3];
private _textUnit = TEXT_UNIT;

// The second muzzle that loads magazines - a grenade launcher.
private _config = configFile >> "CfgWeapons" >> _class;
private _second = (getArray (_config >> "muzzles")) select {
    _x != "this" && {_x != "safe"} && {isClass (_config >> _x)} && {(getArray (_config >> _x >> "magazines")) isNotEqualTo []}
};

// [part, index in the weapon, caption, silhouette, the weapon takes parts there]
private _parts = [
    ["muzzle", 1, LLSTRING(Slot_Muzzle), GEAR_ICON(ui_gear_muzzle_gs), {([_class, 101] call CBA_fnc_compatibleItems) isNotEqualTo []}],
    ["optic", 3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs), {([_class, 201] call CBA_fnc_compatibleItems) isNotEqualTo []}],
    ["rail", 2, LLSTRING(Slot_Rail), GEAR_ICON(ui_gear_side_gs), {([_class, 301] call CBA_fnc_compatibleItems) isNotEqualTo []}],
    ["bipod", 6, LLSTRING(Slot_Bipod), GEAR_ICON(ui_gear_bipod_gs), {([_class, 302] call CBA_fnc_compatibleItems) isNotEqualTo []}],
    ["mag", 4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs), {(getArray (_config >> "magazines")) isNotEqualTo [] || {(getArray (_config >> "magazineWell")) isNotEqualTo []}}],
    ["mag2", 5, LLSTRING(Slot_Magazine2), GEAR_ICON(ui_gear_magazineGL_gs), {_second isNotEqualTo []}]
] select {
    _x params ["", "_index", "", "", "_takes"];

    private _value = _weapon param [_index, ""];
    private _on = if (_value isEqualType []) then {_value param [0, ""]} else {_value};

    (_on isEqualType "" && {_on isNotEqualTo ""}) || {call _takes}
};

if (_parts isEqualTo []) exitWith {};

// What a point or a box of the row does under the mouse: its tip, its click and its right click. A frame later
// (fnc_later): the card may be drawn anew meanwhile.
private _fnc_hit = {
    params ["_parent", "_rect", "_slot", "_caption", "_on"];

    private _hit = [_display, "AIO_Hitbox", _parent, _rect] call FUNC(uiCreate);
    private _tip = if (_on isEqualTo "") then {
        format [LLSTRING(Modify_SpotEmpty), _caption]
    } else {
        format [LLSTRING(Modify_SpotFilled), _caption, [_on] call FUNC(itemName)]
    };

    [_hit, _tip] call FUNC(setTooltip);
    _hit setVariable [QGVAR(id), _slot];
    _hit ctrlAddEventHandler ["ButtonClick", {
        [(_this select 0) getVariable [QGVAR(id), ""], 0] call FUNC(hotspotClick);
    }];
    // Held and moved, the part is dragged out (fnc_hotspotPress).
    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_hit", "_button"];

        if (_button == 0) then {
            [_hit getVariable [QGVAR(id), ""]] call FUNC(hotspotPress);
        };
    }];
    _hit ctrlAddEventHandler ["MouseButtonUp", {
        params ["_hit", "_button"];

        if (_button == 1) then {
            [_hit getVariable [QGVAR(id), ""], 1] call FUNC(hotspotClick);
        };
    }];
};

// A part's picture, or the silhouette of its slot, inside a box.
private _fnc_face = {
    params ["_parent", "_rect", "_on", "_icon"];

    if (_on isEqualTo "") then {
        if (_icon isEqualTo "") exitWith {};

        [_display, _parent, _rect, _icon, _colorText2] call FUNC(uiIcon);
    } else {
        private _info = [_on] call EFUNC(items,getInfo);

        [_display, _parent, _rect, _info getOrDefault ["picture", ""], _info getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 1], _rect] call FUNC(uiItemPicture);
    };
};

// ---------------------------------------------------------------------------
// The row under the picture: a box per part, its picture and - where the row has the room - its name.
// ---------------------------------------------------------------------------
private _gap = SQUARE(_textUnit * 0.2);
private _boxW = (_rowW - _gap * (count _parts - 1)) / count _parts;
private _named = _boxW > SQUARE(_rowH * 2.6);
private _size = _textUnit * 0.5;

{
    _x params ["_part", "_index", "_caption", "_icon"];

    private _value = _weapon param [_index, ""];
    private _on = if (_value isEqualType []) then {_value param [0, "", [""]]} else {[_value, ""] select !(_value isEqualType "")};
    private _slot = format ["%1_%2", _base, _part];
    private _rel = [_rowX + _forEachIndex * (_boxW + _gap), _rowY, _boxW, _rowH];
    private _box = [_display, "AIO_Group", _group, _rel] call FUNC(uiCreate);

    [
        _display, _box, [0, 0, _boxW, _rowH], _theme getOrDefault [["slotEmpty", "slot"] select (_on isNotEqualTo ""), [1, 1, 1, 0.05]], _rowH * 0.3
    ] call FUNC(uiPanel);

    private _faceH = _rowH * 0.8;
    private _faceW = SQUARE(_faceH);
    private _faceX = [(_boxW - _faceW) / 2, SQUARE(_rowH * 0.1)] select _named;

    [_box, [_faceX, (_rowH - _faceH) / 2, _faceW, _faceH], _on, _icon] call _fnc_face;

    if (_named) then {
        private _textX = _faceX + _faceW + SQUARE(_rowH * 0.12);
        private _textW = (_boxW - _textX - SQUARE(_rowH * 0.12)) max pixelW;
        private _text = [[[_on] call FUNC(itemName), _caption] select (_on isEqualTo ""), _textW, _font, _size] call FUNC(fitText);

        [_display, _box, [_textX, 0, _textW, _rowH], _text, _size, [_colorText, _colorMuted] select (_on isEqualTo ""), _font, 0, "value"] call FUNC(uiLabel);
    };

    [_box, [0, 0, _boxW, _rowH], _slot, _caption, _on] call _fnc_hit;

    _spots pushBack createHashMapFromArray [
        ["part", _part], ["slot", _slot], ["class", _on], ["ctrl", _box], ["rel", _rel], ["floating", false]
    ];
} forEach _parts;

// ---------------------------------------------------------------------------
// The parts over the 3D picture, as in Tarkov's weapon builds (Mia, #56: "maybe square with rounded corners"): a box per part, off
// the weapon - the sights, the muzzle and the rail above it, the bipod and the magazines below -, the part's picture and short name
// in it, NONE while it is empty, and a thin line from the box to a dot on the part's place, bent at right angles. Made hidden; placed and shown every
// frame (fnc_placeHotspots): the lines and dots first, so the boxes lie over them.
// ---------------------------------------------------------------------------
if (_viewRect isEqualTo []) exitWith {};

private _boxH = _textUnit * 1.6;
private _boxW = SQUARE(_boxH);
private _dotH = _textUnit * 0.22;
private _lineColor = [1, 1, 1, 0.55];
private _nameSize = _textUnit * 0.34;
private _radius = ((_theme getOrDefault ["radius", 0]) * 0.6) min (_boxH / 5);

// The line in three straight pieces - down from the box, across, down to the dot: a turned control is cut to its own box, so a
// slanted line cannot be drawn.
private _marks = _parts apply {
    private _line = [0, 1, 2] apply {
        private _piece = [_display, "AIO_PictureTurned", _group, [0, 0, pixelW, pixelH]] call FUNC(uiCreate);
        _piece ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
        _piece ctrlSetTextColor _lineColor;
        _piece ctrlShow false;

        _piece
    };

    private _dot = [_display, "AIO_Group", _group, [0, 0, SQUARE(_dotH), _dotH]] call FUNC(uiCreate);
    [_display, _dot, [0, 0, SQUARE(_dotH), _dotH], [1, 1, 1, 0.9], _dotH / 2] call FUNC(uiPanel);
    _dot ctrlShow false;

    [_line, _dot]
};

{
    _x params ["_part", "_index", "_caption", "_icon"];

    private _value = _weapon param [_index, ""];
    private _on = if (_value isEqualType []) then {_value param [0, "", [""]]} else {[_value, ""] select !(_value isEqualType "")};
    private _slot = format ["%1_%2", _base, _part];
    private _rel = [_viewRect select 0, _viewRect select 1, _boxW, _boxH];
    private _box = [_display, "AIO_Group", _group, _rel] call FUNC(uiCreate);

    // Glass, framed thinly - in the accent colour while a part is on it.
    [_display, _box, [0, 0, _boxW, _boxH], [[0, 0, 0, 0.55], [0.1, 0.1, 0.11, 0.85]] select (_on isNotEqualTo ""), _radius] call FUNC(uiPanel);
    [_display, _box, [0, 0, _boxW, _boxH], [[1, 1, 1, 0.3], _accent + [0.9]] select (_on isNotEqualTo ""), _radius] call FUNC(uiRing);

    private _faceH = _boxH * 0.62;
    private _faceW = SQUARE(_faceH);

    [_box, [(_boxW - _faceW) / 2, _boxH - _faceH - _boxH * 0.06, _faceW, _faceH], _on, [_icon, ""] select (_on isEqualTo "")] call _fnc_face;

    // Its short name in the top left corner, NONE while it is empty.
    private _nameW = _boxW - SQUARE(_boxH * 0.08) * 2;
    private _name = [[toUpperANSI LLSTRING(Modify_None), [_on] call FUNC(itemName)] select (_on isNotEqualTo ""), _nameW, _font, _nameSize] call FUNC(fitText);

    [
        _display, _box, [SQUARE(_boxH * 0.08), _boxH * 0.04, _nameW, _nameSize * 1.3], _name, _nameSize,
        [_colorMuted, _colorText] select (_on isNotEqualTo ""), _font, 0, "value"
    ] call FUNC(uiLabel);

    [_box, [0, 0, _boxW, _boxH], _slot, _caption, _on] call _fnc_hit;

    _box ctrlShow false;

    (_marks select _forEachIndex) params ["_line", "_dot"];

    _spots pushBack createHashMapFromArray [
        ["part", _part], ["slot", _slot], ["class", _on], ["ctrl", _box], ["rel", _rel], ["floating", true],
        ["line", _line], ["dot", _dot], ["below", _part in ["bipod", "mag", "mag2"]]
    ];
} forEach _parts;

call FUNC(placeHotspots);
