#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws a weapon's attachments onto its picture as Arma's own inventory does: every slot of the weapon's
 * WeaponSlotsInfo that holds an attachment and has a positive iconScale marks it on the weapon picture with the
 * slot's white shape (iconPicture: attachment_muzzle.paa, attachment_top.paa and the like) - at iconPosition
 * (fractions of the picture, from its top left), the iconPinpoint of the mark ("Center", "Bottom", "Top", "Left",
 * "Right") on that point.
 *
 * The mark's size is the engine's, measured on the vanilla inventory (0.7.10): its height is iconScale of the
 * picture's height, its width follows from the shape's own texture - the muzzle's is twice as wide as high, the
 * optic's four times, the rail's square. So a suppressor's bar reaches out past the picture's left edge and an
 * optic's lies wide on the receiver, as players know them. Until 0.7.5 every mark was drawn in the picture's 2:1,
 * which made the rail's twice too wide (Mia, #56: "The IR icon is far too big") and the optic's half as wide; 0.7.6
 * to 0.7.9 drew the attachments' own pictures instead (Mia, 0.7.10: the white icons again, placed as Arma places them).
 *
 * The bipod too, as in Arma: its mark hangs under the barrel (UnderBarrelSlot).
 *
 * The slot an attachment sits in is the one whose compatibleItems name it (an array, or a class of
 * item = 1 entries as CBA's joint rails write them); failing that, the slot of the attachment's kind.
 *
 * A weapon picture is twice as wide as it is high and is fitted into its rectangle without stretching,
 * so the icons go onto the area it really takes.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group, or controlNull <CONTROL>
 * 2: The weapon picture's rectangle [x, y, w, h] <ARRAY>
 * 3: The weapon [class, muzzle, rail, optic, [magazine, rounds] or [], [magazine, rounds] or [], bipod] <ARRAY>
 * 4: The rectangle is the picture's area exactly, not fitted at 2:1 by the screen's pixels - the square texture of a turned
 *    picture, whose units are its own pixels (fnc_turnedTexture) <BOOL> (default: false)
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.2, 0.1], (weaponsItems player) select 0] call aio_gui_fnc_drawAttachments;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_weapon", ["_exact", false, [false]]];
_rect params ["_left", "_top", "_width", "_height"];
_weapon params [["_class", ""], ["_muzzle", ""], ["_rail", ""], ["_optic", ""], ["_magazine", []], ["_magazine2", []], ["_bipod", ""]];

private _controls = [];
private _slotsConfig = configFile >> "CfgWeapons" >> _class >> "WeaponSlotsInfo";

if (!isClass _slotsConfig) exitWith {_controls};

// The picture's real area, in pixels so the 2:1 holds on any screen.
private _pxW = _width / pixelW;
private _pxH = _height / pixelH;
private _imageH = _pxH min (_pxW / 2);
private _imageW = _imageH * 2;
private _x0 = _left + (_pxW - _imageW) / 2 * pixelW;
private _y0 = _top + (_pxH - _imageH) / 2 * pixelH;
private _w = _imageW * pixelW;
private _h = _imageH * pixelH;

if (_exact) then {
    _x0 = _left;
    _y0 = _top;
    _w = _width;
    _h = _height;
};

// With the slots the weapon inherits: configClasses leaves those out, and the MX's muzzle and side rail come from its base -
// only the optic showed (Mia, #56).
private _slots = (configProperties [_slotsConfig, "isClass _x", true]) select {getText (_x >> "iconPicture") isNotEqualTo ""};

private _fnc_takes = {
    params ["_slot", "_item"];

    private _list = _slot >> "compatibleItems";

    if (isArray _list) exitWith {
        (getArray _list) findIf {_x == _item} >= 0
    };

    isClass _list && {getNumber (_list >> _item) > 0}
};

{
    _x params ["_item", "_fallback"];

    if (_item isEqualTo "") then {continue};

    private _index = _slots findIf {[_x, _item] call _fnc_takes};

    if (_index < 0) then {
        _index = _slots findIf {configName _x == _fallback};
    };

    if (_index < 0) then {continue};

    private _slot = _slots select _index;

    private _scale = getNumber (_slot >> "iconScale");

    if (_scale <= 0) then {continue};

    (getArray (_slot >> "iconPosition")) params [["_fx", 0.5], ["_fy", 0.5]];

    // The slot's white shape, as high as iconScale of the picture and as wide as its own texture makes it (the engine's rule,
    // measured on the vanilla inventory): square in pixels the picture's area is 2:1, so half its width per height.
    private _texture = [getText (_slot >> "iconPicture")] call FUNC(safePicture);

    if (_texture isEqualTo "") then {continue};

    (getTextureInfo _texture) params [["_textureW", 2], ["_textureH", 1]];

    if (_textureW <= 0 || {_textureH <= 0}) then {
        _textureW = 2;
        _textureH = 1;
    };

    private _color = ATTACHMENT_MARK_COLOR;
    private _iconH = _h * _scale;
    private _iconW = _iconH * (_w / _h) / 2 * (_textureW / _textureH);
    private _iconX = _x0 + _fx * _w;
    private _iconY = _y0 + _fy * _h;

    // The point of the icon that sits on iconPosition.
    switch (toLowerANSI getText (_slot >> "iconPinpoint")) do {
        case "bottom": {_iconX = _iconX - _iconW / 2; _iconY = _iconY - _iconH};
        case "top": {_iconX = _iconX - _iconW / 2};
        case "left": {_iconY = _iconY - _iconH / 2};
        case "right": {_iconX = _iconX - _iconW; _iconY = _iconY - _iconH / 2};
        default {_iconX = _iconX - _iconW / 2; _iconY = _iconY - _iconH / 2};
    };

    // In a turned picture's texture, as it is: no rounding to the screen's pixels, and not one of the window's controls that a
    // build sweeps (fnc_uiCreate).
    if (_exact) then {
        private _icon = _display ctrlCreate ["AIO_Picture", -1];
        _icon ctrlSetPosition [_iconX, _iconY, _iconW, _iconH];
        _icon ctrlSetText _texture;
        _icon ctrlSetTextColor _color;
        _icon ctrlCommit 0;
        _controls pushBack _icon;
    } else {
        _controls pushBack ([_display, _parent, [_iconX, _iconY, _iconW, _iconH], _texture, _color] call FUNC(uiPicture));
    };
} forEach [
    [_muzzle, "MuzzleSlot"],
    [_rail, "PointerSlot"],
    [_optic, "CowsSlot"],
    [_bipod, "UnderBarrelSlot"]
];

_controls
