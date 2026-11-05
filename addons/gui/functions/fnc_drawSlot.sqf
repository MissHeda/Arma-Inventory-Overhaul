#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws a dedicated slot - a weapon, a piece of gear, an attachment or a loaded magazine: its surface,
 * its caption where the style puts it, and the item's picture - drawn as its rules say (icon=,
 * fnc_uiItemPicture) and never out of the slot - or, while the slot is empty, the
 * silhouette of what belongs there, hatched in Tarkov's look. Registers the slot in (uiNamespace getVariable [QGVAR(slots), []]), so
 * the mouse finds it (fnc_onFrame).
 *
 * A window that attached (fnc_attach) may mark a filled slot in its top left corner (the "tileBadge" hook).
 *
 * Where the caption goes (theme "slotCaption"):
 *   "above"  - over the slot, outside it
 *   "tab"    - on a small tab in its top left corner, in "slotCaptionBg"
 *   "inside" - plain words in its top left corner
 *   "none"   - nowhere
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Item in the slot, "" for empty <STRING>
 * 4: Options <HASHMAP>
 *   "caption" - what the slot is for, e.g. "Headgear" <STRING>
 *   "icon"    - silhouette for the empty slot, e.g. GEAR_ICON(ui_gear_helmet_gs) <STRING>
 *   "ammo"    - a magazine's [rounds, capacity], or [] - with a fill bar while it is not full <ARRAY>
 *   "number"  - a mark in the top right corner, e.g. "1" <STRING>
 *   "name"    - show the item's name in the bottom left corner <BOOL>
 *   "accent"  - a bar in the accent colour along the left edge <BOOL>
 *   "weapon"  - a weapon slot's [class, muzzle, rail, optic, magazine, magazine, bipod], for the hint <ARRAY>
 *   "slot"    - the equipment slot it shows, e.g. "primary_optic" (aio_storage_fnc_getSlot) <STRING>
 *   "unit"    - whose slot it is, for putting things on and taking them off <OBJECT>
 *   "count"   - a number in the bottom right corner, e.g. how many of the item there are; in the loss
 *               colour when it is "0" <STRING>
 *   "faded"   - show the item's picture dimmed, as when none is left <BOOL>
 *   "hotbar"  - the number of the hotbar's slot this is (aio_hotbar), -1 for a slot of the gear: kept
 *               as the eighth element of the slot's record, which tells the mouse handling that it takes
 *               a class and holds no item <NUMBER>
 *   "container" - the box of a uniform, vest or backpack opened from inside a container (fnc_openNested):
 *               its container object, kept as the ninth element of the record, so the box is lifted and
 *               hinted as its tile there (fnc_boxTile) <OBJECT>
 * 5: Theme <HASHMAP>
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.2, 0.25, 0.1], primaryWeapon player, createHashMapFromArray [["caption", "Primary"], ["icon", "\z\aio\addons\gui\ui\slot_rifle_ca.paa"], ["number", "1"]], _theme] call aio_gui_fnc_drawSlot;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_class", ["_options", createHashMap], "_theme"];
_rect params ["_left", "_top", "_width", "_height"];

if (_options isEqualType []) then {
    _options = createHashMapFromArray _options;
};

private _empty = _class isEqualTo "";
private _info = if (_empty) then {createHashMap} else {[_class] call EFUNC(items,getInfo)};
private _captionText = _options getOrDefault ["caption", ""];
private _caption = [_captionText, _theme] call FUNC(caption);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _colorMuted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (_height / 4);

// Every word on the slot and the rows that hold them grow with the tiles (TEXT_UNIT, fnc_textScale) - but never past what the
// slot holds: a small box beside a weapon (a part, its magazine) does not grow as the words do where the columns take the room
// larger tiles need (Mia, 0.6.35: "0/30" cut off at 130 %). A line is at most SLOT_LINE_MAX of the slot's height, so a caption
// at the top and the rounds at the bottom never meet; what is wider than the slot is set smaller below.
private _textUnit = TEXT_UNIT;
private _padY = (_height * 0.08) min (_textUnit * 0.25);
private _padX = SQUARE(_padY);
private _lineH = (_textUnit * 0.62) min (_height * SLOT_LINE_MAX);
private _lineSize = _lineH * (0.46 / 0.62);

private _controls = [
    _display, _parent, _rect, _theme getOrDefault [["slot", "slotEmpty"] select _empty, [1, 1, 1, 0.035]],
    _radius, _theme getOrDefault ["slotBorder", []]
] call FUNC(uiPanel);

if (_empty && {_theme getOrDefault ["hatch", false]}) then {
    _controls append ([_display, _parent, _rect, _theme getOrDefault ["line", [1, 1, 1, 0.07]]] call FUNC(uiHatch));
};

// A square look marks the weapon in hand with a bar along the left edge, between the round corners.
if (_options getOrDefault ["accent", false]) then {
    private _accent = [_display, "AIO_PanelRect", _parent, [_left, _top + _radius, pixelW * 3, _height - _radius * 2]] call FUNC(uiCreate);
    _accent ctrlSetBackgroundColor (_theme getOrDefault ["slotAccent", [0.84, 0.54, 0.1, 1]]);
    _controls pushBack _accent;
};

// The mark in the top right corner - a round badge where the theme says keyRound - takes its room from the caption.
private _number = _options getOrDefault ["number", ""];
private _numberW = 0;

if (_number isNotEqualTo "") then {
    if (_theme getOrDefault ["keyRound", false]) then {
        private _badge = [_left + _width - _padX - SQUARE(_lineH), _top + _padY, SQUARE(_lineH), _lineH];

        _controls pushBack ([_display, _parent, _badge, UI_TEX(circle_ca), _theme getOrDefault ["keyBg", [1, 1, 1, 0.15]]] call FUNC(uiIcon));
        _controls pushBack ([_display, _parent, _badge, _number, _lineH * 0.62, _theme getOrDefault ["keyText", _colorText], _fontBold, 2, "key"] call FUNC(uiLabel));
        _numberW = SQUARE(_lineH) + _padX;
    } else {
        _numberW = (_number getTextWidth [_fontBold, _lineSize]) * TEXT_SLACK + _padX;
        _controls pushBack ([_display, _parent, [_left + _width - _padX - _numberW, _top + _padY * 0.5, _numberW, _lineH], _number, _lineSize, _colorMuted, _fontBold, 1, "key"] call FUNC(uiLabel));
    };
};

// What is left for the picture.
private _areaTop = _top + _padY;
private _areaBottom = _top + _height - _padY;

if (_caption isNotEqualTo "") then {
    switch (_theme getOrDefault ["slotCaption", "inside"]) do {
        case "above": {
            private _shown = [_caption, _width, _font, _lineSize] call FUNC(fitText);
            _controls pushBack ([_display, _parent, [_left, _top - _lineH, _width, _lineH], _shown, _lineSize, _colorText2, _font, 0, "caption"] call FUNC(uiLabel));
        };
        case "tab": {
            private _room = _width - _numberW;
            private _shown = [_caption, _room - SQUARE(_lineH * 0.5), _fontBold, _lineSize] call FUNC(fitText);
            private _tabW = (((_shown getTextWidth [_fontBold, _lineSize]) * TEXT_SLACK) + SQUARE(_lineH * 0.5)) min _room;
            private _tab = [_left, _top, _tabW, _lineH];

            // Round like the slot's corner it lies in - as round as a tab this low can be - or its square
            // corner would stick out past the slot's.
            _controls append ([_display, _parent, _tab, _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]], _radius min (_lineH / 2)] call FUNC(uiPanel));
            _controls pushBack ([_display, _parent, _tab, _shown, _lineSize, _colorText2, _fontBold, 2, "caption"] call FUNC(uiLabel));
            _areaTop = _top + _lineH + _padY * 0.5;
        };
        case "inside": {
            private _room = _width - _padX * 2 - _numberW;
            private _shown = [_caption, _room, _font, _lineSize] call FUNC(fitText);

            _controls pushBack ([_display, _parent, [_left + _padX * 1.5, _top + _padY * 0.5, _room, _lineH], _shown, _lineSize, _colorMuted, _font, 0, "caption"] call FUNC(uiLabel));
            _areaTop = _top + _lineH;
        };
        default {};
    };
};

// The bottom line: a magazine's rounds on the right, the item's name on the left, and under them how
// full the magazine is.
private _ammo = _options getOrDefault ["ammo", []];
private _showName = !_empty && {_options getOrDefault ["name", false]};

if (_ammo isNotEqualTo [] || _showName) then {
    private _lineTop = _top + _height - _padY * 0.5 - _lineH;
    private _ammoW = 0;

    if (_ammo isNotEqualTo []) then {
        _ammo params ["_rounds", "_capacity"];

        // And under them how full a magazine that is not full is (aio_gui_magazineFillBar) - a full one
        // shows its rounds alone, a one-round magazine (launcher, grenade launcher) has nothing to fill.
        if (
            _capacity > 1 && {_rounds < _capacity}
            && {missionNamespace getVariable [QGVAR(magazineFillBar), true]}
            && {_theme getOrDefault ["tileAmmoBar", true]}
        ) then {
            private _barH = (2 max round (UNIT * 0.08 / pixelH)) * pixelH;
            private _barY = _top + _height - _padY - _barH;

            _controls append ([
                _display, _parent, [_left + _padX, _barY, _width - _padX * 2, _barH], _rounds / _capacity,
                _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]], _theme getOrDefault ["barFill", [0.84, 0.54, 0.1, 1]], _barH / 2, GRADIENT_BARS
            ] call FUNC(uiBar));

            _lineTop = _barY - _lineH;
        };

        // The rounds set smaller where they are wider than the slot - never cut.
        private _text = format ["%1/%2", _rounds, _capacity];
        private _ammoSize = [_text, _width - _padX * 2, _font, _lineSize] call FUNC(fitSize);
        _ammoW = (_text getTextWidth [_font, _ammoSize]) * TEXT_SLACK;
        _controls pushBack ([
            _display, _parent, [_left + _padX, _lineTop + _lineSize - _ammoSize, _width - _padX * 2, _lineH], _text, _ammoSize, _colorText, _font, 1, "weaponammo"
        ] call FUNC(uiLabel));
    };

    if (_showName) then {
        private _room = _width - _padX * 3 - _ammoW;
        private _name = [_info getOrDefault ["name", _class], _room, _font, _lineSize] call FUNC(fitText);

        _controls pushBack ([_display, _parent, [_left + _padX * 1.5, _lineTop, _room, _lineH], _name, _lineSize, _colorText2, _font, 0, "name"] call FUNC(uiLabel));
    };

    _areaBottom = _lineTop;
};

private _areaH = _areaBottom - _areaTop;

if (_areaH > 0) then {
    if (_empty) then {
        private _icon = _options getOrDefault ["icon", ""];

        if (_icon isEqualTo "") exitWith {};

        // A silhouette is a hint, not the item: smaller than a picture would be, centred.
        private _iconH = _areaH min (_height * 0.6);

        _controls pushBack ([
            _display, _parent, [_left + _padX, _areaTop + (_areaH - _iconH) / 2, _width - _padX * 2, _iconH], _icon,
            _theme getOrDefault ["slotIcon", [1, 1, 1, 0.15]]
        ] call FUNC(uiIcon));
    } else {
        // As the rules draw it (icon=): larger, smaller or moved, and cut to the slot where it would reach out.
        _controls pushBack ([
            _display, _parent, [_left + _padX, _areaTop, _width - _padX * 2, _areaH], _info getOrDefault ["picture", ""],
            _info getOrDefault ["icon", ICON_PLAIN], [[1, 1, 1, 1], [1, 1, 1, 0.35]] select (_options getOrDefault ["faded", false]),
            [_left, _top, _width, _height]
        ] call FUNC(uiItemPicture));

        private _weapon = _options getOrDefault ["weapon", []];

        if (_weapon isNotEqualTo []) then {
            _controls append ([_display, _parent, [_left + _padX, _areaTop, _width - _padX * 2, _areaH], _weapon] call FUNC(drawAttachments));
        };
    };
};

// A mark in the top left corner the window that attached asks for ("tileBadge": a texture, "" for none) -
// on what is in the slot, not on its silhouette.
if (!_empty) then {
    private _badge = ["tileBadge", [_class], ""] call FUNC(hook);

    if (_badge isEqualType "" && {_badge isNotEqualTo ""}) then {
        _controls pushBack ([
            _display, _parent, [_left + _padX * 0.5, _top + _padY * 0.5, SQUARE(_textUnit * 0.42), _textUnit * 0.42], _badge, _colorText2
        ] call FUNC(uiIcon));
    };
};

// A number in the bottom right corner, over the picture: how many there are, red at none. On the same small
// flat box as a stack's count on a tile (fnc_drawCountBackdrop), so a hotbar slot and a tile read alike -
// and the picture under it may be white.
private _countText = _options getOrDefault ["count", ""];

if (_countText isNotEqualTo "") then {
    private _countColor = [
        _theme getOrDefault ["tileCountColor", _colorText], _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
    ] select (_countText isEqualTo "0");

    // Only measured: the label lies on exactly the box and draws it as its own background (one control).
    private _backdrop = [
        _display, _parent, _countText, _fontBold, _lineSize, _left + _width - _padX, _top + _height - _padY * 0.5, _width - _padX * 2, _theme, true,
        false, true
    ] call FUNC(drawCountBackdrop);

    _backdrop params ["_backdropControls", "_backdropRect", ["_backdropColor", []]];

    _controls append _backdropControls;

    private _countRect = [_backdropRect, [_left + _padX, _top + _height - _padY * 0.5 - _lineH, _width - _padX * 2, _lineH]] select (_backdropRect isEqualTo []);

    private _countLabel = [
        _display, _parent, _countRect, _countText, _lineSize, _countColor, _fontBold, [2, 1] select (_backdropRect isEqualTo []), "stack"
    ] call FUNC(uiLabel);

    if (_backdropControls isEqualTo [] && {_backdropColor isNotEqualTo []}) then {
        _countLabel ctrlSetBackgroundColor _backdropColor;
    };

    _controls pushBack _countLabel;
};

// The hover area is kept in screen coordinates; a slot in a group counts from the group's corner, and
// also keeps its place there, so fnc_updateHover finds it where the group's scroll shows it now. The
// weapon array goes along, so the hint names the attachments of this weapon - a body's, say - rather
// than looking for them on the player.
private _anchor = createHashMap;
private _origin = [_left, _top];

if (!isNull _parent) then {
    _anchor = createHashMapFromArray [["rel", [_left, _top]], ["parent", _parent]];
    _origin = [_anchor] call FUNC(gridOrigin);
};

(uiNamespace getVariable [QGVAR(slots), []]) pushBack [[_origin select 0, _origin select 1, _width, _height], _class, _captionText, _anchor, _options getOrDefault ["weapon", []], _options getOrDefault ["slot", ""], _options getOrDefault ["unit", objNull], _options getOrDefault ["hotbar", -1], _options getOrDefault ["container", objNull]];

_controls
