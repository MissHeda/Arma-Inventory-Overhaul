#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the inspect card (GVAR(inspect), fnc_inspect): a glass window with the item's picture - what is
 * on a weapon drawn onto it, or for an item with a model of its own the item in 3D (fnc_inspect3D), as the
 * 2D/3D switch in the picture's corner says -, its name in its category's colour, its description and its figures:
 * weight, size, count, rounds, whether it stacks, its category, the mod it comes from
 * and its class name. A kit of Enhanced First Aid Kits also how full it is and what is in it
 * (aio_compat_efak), a radio its channel, frequency and state (aio_compat_tfar, aio_compat_acre -
 * whichever mod is loaded). A window that attached (fnc_attach) adds rows of its own before the mod's name (the
 * "inspectRows" hook) - a text, or a text beside a small bar. Everything lies in one controls group, so the card moves as one: by its title
 * (fnc_onFrame follows the mouse while it is held), and it closes with the cross in its corner.
 *
 * Made again after every build of the window and whenever a kit window opens, closes or comes to the
 * top, where it was last put (GVAR(inspectPos)) - after the kit windows, so it lies over them
 * (fnc_drawTopLayer). Clicks on it reach neither the inventory nor a kit window under it: fnc_topAt
 * finds the card first by QGVAR(inspectRect) (fnc_onMouseButton, fnc_updateHover, fnc_updateDrag).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_drawInspect;
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

ctrlDelete (uiNamespace getVariable [QGVAR(inspectGroup), controlNull]);
uiNamespace setVariable [QGVAR(inspectGroup), controlNull];
uiNamespace setVariable [QGVAR(inspectRect), []];

if (isNull _display || {GVAR(inspect) isEqualTo []}) exitWith {
    ["stop"] call FUNC(inspect3D);
};

GVAR(inspect) params ["_class", "_count", "_ammo", "_attachments", ["_holder", objNull, [objNull]]];

private _info = [_class] call EFUNC(items,getInfo);
private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];

private _fnc_hex = {
    params ["_color"];

    "#" + (((_color select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);
        ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
    }) joinString "")
};

private _fnc_kg = {
    params ["_mass"];

    private _kg = _mass * MASS_TO_KG;

    format ["%1 kg", _kg toFixed ([1, 2] select (_kg < 1))]
};

// ----- The figures -----

private _rows = [];

// A kit of Enhanced First Aid Kits weighs what it holds as well (aio_compat_efak, when loaded).
private _kitMass = if (isNil QEFUNC(compat_efak,getMass)) then {-1} else {[_class] call EFUNC(compat_efak,getMass)};
private _mass = if (_kitMass >= 0) then {
    _kitMass * _count
} else {
    [[createHashMapFromArray [["class", _class], ["count", _count], ["attachments", _attachments]]]] call EFUNC(storage,getMass)
};

_rows pushBack [LLSTRING(Inspect_Weight), [_mass] call _fnc_kg];

if (_count > 1) then {
    _rows pushBack [LLSTRING(Inspect_WeightEach), [_info getOrDefault ["mass", 0]] call _fnc_kg];
};

(_info getOrDefault ["size", [1, 1]]) params ["_w", "_h"];
_rows pushBack [LLSTRING(Inspect_Size), format ["%1×%2", _w, _h]];

if (_count > 1) then {
    _rows pushBack [LLSTRING(Inspect_Count), format ["×%1", _count]];
};

private _stack = [_holder, _class, _info getOrDefault ["stack", 1]] call EFUNC(storage,stackFor);

_rows pushBack [LLSTRING(Inspect_Stackable), [LLSTRING(Inspect_No), format [LLSTRING(Inspect_YesUpTo), _stack]] select (_stack > 1)];

private _capacity = _info getOrDefault ["capacity", 0];

if (_capacity > 0) then {
    _rows pushBack [LLSTRING(Inspect_Rounds), format ["%1 / %2", [_ammo, _capacity] select (_ammo < 0), _capacity]];
};

_rows pushBack [LLSTRING(Inspect_Category), [
    LLSTRING(Category_Misc), LLSTRING(Category_Gear), LLSTRING(Category_Weapon), LLSTRING(Category_Ammo), LLSTRING(Category_Medical)
] param [_info getOrDefault ["category", 0], LLSTRING(Category_Misc)]];

// What is on a weapon, one line each - labelled on the first line there is, whichever part that is.
private _attachedLabel = LLSTRING(Inspect_Attached);

{
    private _part = if (_x isEqualType []) then {_x param [0, ""]} else {_x};

    if (_part isEqualType "" && {_part isNotEqualTo ""}) then {
        _rows pushBack [_attachedLabel, ([_part] call EFUNC(items,getInfo)) getOrDefault ["name", _part]];
        _attachedLabel = "";
    };
} forEach (_attachments select [1]);

// A kit: how full it is and what it holds (aio_compat_efak, when loaded).
if (!isNil QEFUNC(compat_efak,inspectRows)) then {
    _rows append ([_class] call EFUNC(compat_efak,inspectRows));
};

// A radio: channel, frequency and state, from whichever of TFAR and ACRE2 is loaded. A long-range radio
// is told from its backpack object, which the card does not know - it says what it can.
_rows append ([[QEFUNC(compat_tfar,inspectRows), QEFUNC(compat_acre,inspectRows)], [_class, objNull]] call FUNC(compatCollect));

// What the window that attached has to add about the item (the "inspectRows" hook): [label, text] rows, or
// [label, how full 0 to 1, text] rows, which are drawn with a small bar.
private _more = ["inspectRows", [_class, _count, _ammo, _attachments], []] call FUNC(hook);

if (_more isEqualType []) then {
    _rows append (_more select {_x isEqualType [] && {count _x >= 2}});
};

// Where it comes from: the mod's name - Arma itself when no mod brings it - and the class.
private _config = configNull;

{
    if (isClass (configFile >> _x >> _class)) exitWith {_config = configFile >> _x >> _class};
} forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];

private _mod = if (isNull _config) then {""} else {configSourceMod _config};
private _modName = if (_mod isEqualTo "") then {"Arma 3"} else {(modParams [_mod, ["name"]]) param [0, _mod]};

if (_modName isEqualTo "") then {_modName = _mod};

_rows pushBack [LLSTRING(Inspect_Mod), _modName];
_rows pushBack [LLSTRING(Inspect_Class), _info getOrDefault ["class", _class]];

// ----- Measures -----

// The card and its words grow with the tiles (TEXT_UNIT, fnc_textScale).
private _textUnit = TEXT_UNIT;
private _width = SQUARE(_textUnit * 17);
private _padY = _textUnit * 0.7;
private _padX = SQUARE(_padY);
private _innerW = _width - _padX * 2;
private _titleH = _textUnit * 1.1;
private _pictureH = _textUnit * 6.5;
private _rowH = _textUnit * 0.8;
private _gap = _textUnit * 0.45;
private _closeH = _titleH;
private _closeW = SQUARE(_closeH);

// The item in 3D instead of its picture, for one with a model of its own (fnc_hasModel) and with 3D picked in the box's corner:
// its scene's camera films into a texture shown in the box (fnc_inspect3D). Picture-in-Picture renders it - off in the video
// options, there is no 3D. The box is then exactly twice as wide as high in pixels, as the texture (INSPECT_3D_RES) is, so the
// item is never squeezed; under it how to move it.
private _can3D = [_class] call FUNC(hasModel);
private _show3D = _can3D && {isPiPEnabled} && {GVAR(inspectView) isEqualTo "3d"};
private _viewPixelsW = floor ((_innerW - pixelW * 2) / pixelW);
private _viewPixelsH = floor (_viewPixelsW / 2);
private _hint3DH = 0;

if (_show3D) then {
    _pictureH = (_viewPixelsH + 2) * pixelH;
    _hint3DH = _textUnit * 0.75;
};

// The description, measured in a box of the card's width before anything is placed.
private _description = _info getOrDefault ["description", ""];
private _descText = parseText format [
    "<t font='%1' color='%2' size='%4'>%3</t>", _font, [_colorText2] call _fnc_hex, _description, (0.95 * TEXT_SCALE) toFixed 3
];
private _descH = 0;

if (_description isNotEqualTo "") then {
    private _probe = [_display, "AIO_StructuredText", controlNull, [0, 0, _innerW, UNIT]] call FUNC(uiCreate);
    _probe ctrlSetStructuredText _descText;
    _descH = (ctrlTextHeight _probe) min (_textUnit * 6);
    ctrlDelete _probe;
};

private _height = _padY * 2 + _titleH + _gap + _pictureH + _gap + _hint3DH
    + ([0, _descH + _gap] select (_descH > 0))
    + count _rows * _rowH;

// Where it was put, or the middle of the screen - always whole on it.
GVAR(inspectPos) params [["_left", safezoneX + (safezoneW - _width) / 2], ["_top", safezoneY + (((safezoneH - _height) / 2) max (_textUnit * 2))]];

_left = (_left max safezoneX) min (safezoneX + safezoneW - _width);
_top = (_top max safezoneY) min ((safezoneY + safezoneH - _height) max safezoneY);

private _group = [_display, "AIO_Group", controlNull, [_left, _top, _width, _height]] call FUNC(uiCreate);

uiNamespace setVariable [QGVAR(inspectGroup), _group];
uiNamespace setVariable [QGVAR(inspectRect), [_left, _top, _width, _height]];

// Like the columns (fnc_build), the card reports the mouse buttons as the display does: it takes the
// clicks over it, and a drag let go over it has to end all the same (fnc_onMouseButton).
_group ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
_group ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];

[
    _display, _group, [0, 0, _width, _height],
    _theme getOrDefault ["inspectBg", [0.06, 0.06, 0.06, 0.98]], _theme getOrDefault ["radius", 0]
] call FUNC(uiPanel);

private _cursor = _padY;

// The title, in its category's colour as a little bar beside it. Held, it moves the card.
private _categoryColor = [_theme, _info, [1, 1, 1, 0.1]] call FUNC(tileColour);
_categoryColor set [3, 1];

[_display, _group, [_padX, _cursor + _titleH * 0.15, pixelW * 3, _titleH * 0.7], _categoryColor] call FUNC(uiPanel);

private _titleW = _innerW - SQUARE(_textUnit * 0.35) - _closeW;

[
    _display, _group, [_padX + SQUARE(_textUnit * 0.35), _cursor, _titleW, _titleH],
    [[_class] call FUNC(itemName), _titleW, _fontBold, _textUnit * 0.8] call FUNC(fitText),
    _textUnit * 0.8, _colorText, _fontBold, 0, "name"
] call FUNC(uiLabel);

private _grip = [_display, "AIO_Hitbox", _group, [0, 0, _width - _padX - _closeW, _cursor + _titleH]] call FUNC(uiCreate);
[_grip, LLSTRING(Inspect_Move)] call FUNC(setTooltip);
_grip ctrlAddEventHandler ["MouseButtonDown", {
    params ["_ctrl", "_button"];

    if (_button != 0) exitWith {};

    getMousePosition params ["_mouseX", "_mouseY"];
    (ctrlPosition (ctrlParentControlsGroup _ctrl)) params ["_groupX", "_groupY"];

    GVAR(inspectMove) = [_mouseX - _groupX, _mouseY - _groupY];
}];

[_display, _group, [_width - _padX - _closeW, _cursor, _closeW, _closeH], "inspectClose", "", UI_TEX(icon_close_ca), _theme, {
    call FUNC(closeInspect);
}] call FUNC(uiButton);

_cursor = _cursor + _titleH + _gap;

// The picture on a lighter box, with what is on a weapon drawn onto it.
[_display, _group, [_padX, _cursor, _innerW, _pictureH], _theme getOrDefault ["slot", [1, 1, 1, 0.05]], (_theme getOrDefault ["radius", 0]) min (_pictureH / 4)] call FUNC(uiPanel);

private _pictureInner = [_padX * 2, _cursor + _padY * 0.5, _innerW - _padX * 2, _pictureH - _padY];

// Where the 2D/3D switch lies in the box's top right corner (drawn below, after the picture).
private _toggleH = _textUnit * 0.85;
private _inset = 2 * pixelH;
private _segmentH = _toggleH - _inset * 2;
private _segmentW = SQUARE(_segmentH * 1.5);
private _trackW = _segmentW * 2 + SQUARE(_inset) * 2;
private _trackX = _padX + _innerW - SQUARE(_textUnit * 0.3) - _trackW;
private _toggleY = _cursor + _textUnit * 0.3;

// In 3D (see the measures): held and dragged the item turns (fnc_onFrame), the wheel zooms, a double click puts it back.
if (_show3D) then {
    ["start", [_class, _attachments]] call FUNC(inspect3D);

    private _viewRect = [_padX + (_innerW - _viewPixelsW * pixelW) / 2, _cursor + pixelH, _viewPixelsW * pixelW, _viewPixelsH * pixelH];
    _viewRect params ["_viewX", "_viewY", "_viewW", "_viewH"];

    private _view = [_display, "AIO_PictureTurned", _group, _viewRect] call FUNC(uiCreate);
    _view ctrlSetText format ["#(argb,%1,%2,1)r2t(%3,2.0)", INSPECT_3D_RES select 0, INSPECT_3D_RES select 1, INSPECT_3D_TARGET];

    // The areas that turn it: the view but the switch. A held control is drawn over every other (the engine draws the focused
    // one last) - one lying under the switch as well hid it after the first turn, and took its clicks.
    private _belowY = _toggleY + _toggleH + _inset;
    private _hitRects = [
        [_viewX, _viewY, (_trackX - _inset - _viewX) max 0, _belowY - _viewY],
        [_viewX, _belowY, _viewW, _viewY + _viewH - _belowY]
    ];

    {
        private _hit = [_display, "AIO_Hitbox", _group, _x] call FUNC(uiCreate);

        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["", "_button"];

            if (_button == 0) then {
                GVAR(inspect3DTurn) = getMousePosition;
            };
        }];
        _hit ctrlAddEventHandler ["MouseButtonDblClick", {
            params ["", "_button"];

            if (_button == 0) then {
                ["reset"] call FUNC(inspect3D);
            };
        }];
        // The display reports the same turn of the wheel: one per frame counts.
        _hit ctrlAddEventHandler ["MouseZChanged", {
            params ["", "_scroll"];

            if (GVAR(lastWheel3D) isEqualTo diag_frameNo) exitWith {true};

            GVAR(lastWheel3D) = diag_frameNo;
            ["zoom", [_scroll]] call FUNC(inspect3D);
            true
        }];
    } forEach _hitRects;
} else {
    ["stop"] call FUNC(inspect3D);

    // As the rules draw it (icon=): larger, smaller or moved, and cut to the lighter box where it would reach out.
    [
        _display, _group, _pictureInner, _info getOrDefault ["picture", ""], _info getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 1],
        [_padX, _cursor, _innerW, _pictureH]
    ] call FUNC(uiItemPicture);

    if (_attachments isNotEqualTo []) then {
        [_display, _group, _pictureInner, _attachments] call FUNC(drawAttachments);
    };
};

// 2D or 3D, a switch in the box's corner, for an item with a model of its own: one dark track, the side shown lit on it. 3D is
// greyed out without Picture-in-Picture. The choice is kept for the next items and games.
if (_can3D) then {
    private _accent = (_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]) select [0, 3];
    private _shown = ["2d", "3d"] select _show3D;

    [_display, _group, [_trackX, _toggleY, _trackW, _toggleH], [0, 0, 0, 0.55], _toggleH / 2] call FUNC(uiPanel);

    {
        _x params ["_view", "_label", "_index"];

        private _active = _view isEqualTo _shown;
        private _buttonTheme = +_theme;

        _buttonTheme set ["radius", _segmentH / 2];
        _buttonTheme set ["button", [[0, 0, 0, 0], _accent + [1]] select _active];
        _buttonTheme set ["buttonHover", [[1, 1, 1, 0.1], _accent + [1]] select _active];
        _buttonTheme set ["buttonText", [_colorText2, _theme getOrDefault ["onAccent", [0, 0, 0, 1]]] select _active];

        private _left = _trackX + SQUARE(_inset) + _segmentW * _index;
        private _button = [
            _display, _group, [_left, _toggleY + _inset, _segmentW, _segmentH], "inspectView" + _view, _label, "", _buttonTheme, {
                params ["", "_id"];

                GVAR(inspectView) = ["2d", "3d"] select (_id isEqualTo "inspectView3d");
                profileNamespace setVariable [QGVAR(inspectView), GVAR(inspectView)];

                call FUNC(drawInspect);
            }, _view isEqualTo "3d" && {!isPiPEnabled}, -1, true
        ] call FUNC(uiButton);

        if (_view isEqualTo "3d" && {!isPiPEnabled}) then {
            [_button select -1, LLSTRING(Inspect_3DNoPiP)] call FUNC(setTooltip);
        };
    } forEach [["2d", LLSTRING(Inspect_2D), 0], ["3d", LLSTRING(Inspect_3D), 1]];
};

_cursor = _cursor + _pictureH + _gap;

// How to move it, under the 3D view.
if (_show3D) then {
    [_display, _group, [_padX, _cursor - _gap * 0.5, _innerW, _hint3DH], LLSTRING(Inspect_3DTip), _textUnit * 0.55, _muted, _font, 2, "hint"] call FUNC(uiLabel);

    _cursor = _cursor + _hint3DH;
};

if (_descH > 0) then {
    private _desc = [_display, "AIO_StructuredText", _group, [_padX, _cursor, _innerW, _descH]] call FUNC(uiCreate);
    _desc ctrlSetStructuredText _descText;

    _cursor = _cursor + _descH + _gap;
};

{
    _x params ["_label", "_value", ["_valueText", ""]];

    private _rowTop = _cursor + _forEachIndex * _rowH;

    [_display, _group, [_padX, _rowTop, _innerW * 0.4, _rowH], _label, _textUnit * 0.58, _muted, _font, 0, "hint"] call FUNC(uiLabel);

    // A number is how full something is: a bar over the first half of the value's room, its text after it.
    if (_value isEqualType 0) then {
        private _barW = _innerW * 0.3;
        private _barH = (2 max round (_textUnit * 0.1 / pixelH)) * pixelH;

        [
            _display, _group, [_padX + _innerW * 0.4, _rowTop + (_rowH - _barH) / 2, _barW, _barH], _value,
            _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]], _theme getOrDefault ["barFill", [0.84, 0.54, 0.1, 1]], _barH / 2, GRADIENT_BARS
        ] call FUNC(uiBar);

        [
            _display, _group, [_padX + _innerW * 0.4 + _barW + SQUARE(_textUnit * 0.3), _rowTop, _innerW * 0.3 - SQUARE(_textUnit * 0.3), _rowH],
            [_valueText, _innerW * 0.3 - SQUARE(_textUnit * 0.3), _font, _textUnit * 0.58] call FUNC(fitText), _textUnit * 0.58, _colorText, _font, 1, "value"
        ] call FUNC(uiLabel);
    } else {
        [
            _display, _group, [_padX + _innerW * 0.4, _rowTop, _innerW * 0.6, _rowH],
            [_value, _innerW * 0.6, _font, _textUnit * 0.58] call FUNC(fitText), _textUnit * 0.58, _colorText, _font, 1, "value"
        ] call FUNC(uiLabel);
    };
} forEach _rows;
