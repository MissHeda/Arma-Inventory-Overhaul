#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws a weapon's attachments onto its picture the way Arma's own inventory does: every slot of the
 * weapon's WeaponSlotsInfo that holds an attachment and has a positive iconScale lays its iconPicture
 * over the weapon picture - at iconPosition (fractions of the picture, from its top left), iconScale
 * of the picture's size, the iconPinpoint of the icon ("Center", "Bottom", "Top", "Left", "Right")
 * on that point. The pictures are the weapon's, not the attachments': the Spectrum Device has one per
 * antenna slot, rifles the generic shapes of their slot classes (attachment_top.paa and the like).
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

    private _iconW = _w * _scale;
    private _iconH = _h * _scale;
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
        _icon ctrlSetText ([getText (_slot >> "iconPicture")] call FUNC(safePicture));
        _icon ctrlCommit 0;
        _controls pushBack _icon;
    } else {
        _controls pushBack ([_display, _parent, [_iconX, _iconY, _iconW, _iconH], getText (_slot >> "iconPicture")] call FUNC(uiPicture));
    };
} forEach [
    [_muzzle, "MuzzleSlot"],
    [_rail, "PointerSlot"],
    [_optic, "CowsSlot"],
    [_bipod, "UnderBarrelSlot"]
];

_controls
