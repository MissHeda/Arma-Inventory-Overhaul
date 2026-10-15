#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the equipment column of the Glass layout - what the unit wears, as cards:
 *
 *   WEIGHT  34.5 kg . Overloaded at 41 kg ... HEAVY . jogging tires you
 *                                                 how much it carries and what that does to it, over a bar
 *                                                 that fills towards the Critical limit (see below)
 *   EQUIPMENT
 *   [1] primary ............ | mag | optic | rail  |   each weapon a big card, its attachments and
 *                            | muz | bipod | 2nd   |   loaded magazines as small slots beside it
 *   [2] handgun ............ | mag | optic |
 *                            | rail| muzzle|
 *   [3] launcher ........... | mag | optic |
 *   GEAR
 *   | headgear |  | uniform |  | vest |  | backpack |
 *   | gog | nvg | bin | map | gps | radio | compass | watch |
 *   HOTBAR
 *   | 4 | 5 | 6 | 7 | 8 | 9 | 0 |                           the keys' items (einv_hotbar), when it is loaded
 *                                                              and on, in the inventory window only
 *
 * The three weapon cards are as wide and as tall as each other, so their attachments start on one
 * line. The weapon in hand is marked in the accent colour. The attachments grow with the height the
 * column has, but never take more than about 40 % of its width, so a weapon keeps room for its picture
 * on a narrow (4:3) screen. The weapons stay at the top and the gear and the hotbar at the bottom;
 * whatever height is left over lies between them.
 *
 * A square theme gives each weapon card a strip down its left edge holding its number, and
 * frames the card; a round one (Glass) puts a small key cap in the corner instead, as neither a strip
 * nor a frame can follow round corners. The attachments and the small slots never show a caption on
 * the slot - their silhouettes say what they are for, and the hint names it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Context, see fnc_build - "unit" and "equipment" are read <HASHMAP>
 * 4: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.5, 0.8], _context, _theme] call einv_gui_fnc_drawEquipmentCards;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_context", "_theme"];
_rect params ["_left", "_top", "_width", "_height"];

private _unit = _context getOrDefault ["unit", objNull];
private _equipment = _context getOrDefault ["equipment", createHashMap];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]];
private _colorMuted = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];
private _colorAccent = _theme getOrDefault ["slotAccent", [0.84, 0.54, 0.1, 1]];
private _colorOnAccent = _theme getOrDefault ["onAccent", [0.086, 0.094, 0.114, 1]];
private _colorStrip = _theme getOrDefault ["slotCaptionBg", [1, 1, 1, 0.1]];
private _colorCard = _theme getOrDefault ["card", [1, 1, 1, 0.035]];
private _barTrack = _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]];
private _border = _theme getOrDefault ["slotBorder", []];
private _radius = _theme getOrDefault ["radius", 0];
private _flat = _radius <= 0;

// Captions over the slots take a line of their own above them - room the rows below have to leave.
private _lineH = UNIT * 0.62;
private _lineSize = UNIT * 0.46;
private _capH = [0, _lineH] select ((_theme getOrDefault ["slotCaption", "none"]) isEqualTo "above");

// The same theme with no captions on the slots, for the attachments and the small slots.
private _quiet = createHashMap;
_quiet merge _theme;
_quiet set ["slotCaption", "none"];

// ---------------------------------------------------------------------------
// Sizes. The gear first, as it is limited by the width; the weapons share the height that is left.
// ---------------------------------------------------------------------------
private _gapH = UNIT * 0.25;
private _gapW = SQUARE(_gapH);
private _groupGap = UNIT * 0.5;
private _rowGap = UNIT * 0.4;
private _statH = UNIT * 2.2;
private _labelH = UNIT * 0.8;
private _gearGap = UNIT * 0.3;

// Square slots: eight small ones across a row, four big gear cards across another. The gear cards take what
// the width leaves after three gaps, so on the narrowest column they only grow a little smaller - the backpack
// never wraps into a row of its own.
private _smallW = ((_width - _gapW * 7) / 8) min SQUARE(UNIT * 2.2);
private _smallH = UNSQUARE(_smallW);
private _gearW = ((_width - _gapW * 3) / 4) min SQUARE(UNIT * 4.6);
private _gearH = UNSQUARE(_gearW);

// The hotbar's row under the gear (einv_hotbar - only when that addon is loaded and on, and only in the
// inventory, not in the Arsenal): a caption over seven small slots.
private _hotbar = call FUNC(isInventoryMode) && {!isNil QEFUNC(hotbar,drawStrip)} && {call EFUNC(hotbar,isActive)};
private _hotbarH = [0, _labelH + _smallH + _groupGap] select _hotbar;

// Each weapon card is two attachment rows high. The primary's three attachments across may take about
// 40 % of the width.
private _fixed = _statH + _groupGap * 2 + _labelH * 2 + _rowGap * 2 + _gapH * 3 + _capH * 4 + _gearH + _gearGap + _smallH + _hotbarH;
private _slotWMax = ((_width * 0.42 - _gapW * 3) / 3) max (pixelW * 8);
private _slotH = (((_height - _fixed) / 6) min (UNIT * 2.7) min UNSQUARE(_slotWMax)) max (UNIT * 1.2);
private _slotW = SQUARE(_slotH);
private _cardH = _slotH * 2 + _gapH;
private _cardW = _width - (_slotW + _gapW) * 3;

// Left over height loosens the gaps between the weapons a little; the rest stays above the gear.
private _extra = (((_height - _fixed - _slotH * 6) / 4) max 0) min (UNIT * 0.6);
_rowGap = _rowGap + _extra;

// ---------------------------------------------------------------------------
// A weapon's card: its number, its picture or silhouette, its name, and the mark of the weapon in hand.
// ---------------------------------------------------------------------------
private _fnc_weaponCard = {
    params ["_cardRect", "_class", "_caption", "_icon", "_number", "_inHand"];
    _cardRect params ["_cardX", "_cardY", "_cardW", "_cardH"];

    private _empty = _class isEqualTo "";
    private _info = if (_empty) then {createHashMap} else {[_class] call EFUNC(items,getInfo)};
    private _cardRadius = _radius min (_cardH / 4);
    private _padY = UNIT * 0.22;
    private _padX = SQUARE(_padY);

    [_display, _parent, _cardRect, _theme getOrDefault [["slot", "slotEmpty"] select _empty, [1, 1, 1, 0.035]], _cardRadius] call FUNC(uiPanel);

    if (_capH > 0 && {_caption isNotEqualTo ""}) then {
        private _shown = [[_caption, _theme] call FUNC(caption), _cardW, _font, _lineSize] call FUNC(fitText);
        [_display, _parent, [_cardX, _cardY - _lineH, _cardW, _lineH], _shown, _lineSize, _colorText2, _font, 0] call FUNC(uiLabel);
    };

    // Where the picture and the name may go - right of the strip, under the key cap.
    private _innerX = _cardX;
    private _innerTop = _cardY + _padY;

    if (_flat) then {
        private _stripW = SQUARE(UNIT * 1.05);

        [_display, _parent, [_cardX, _cardY, _stripW, _cardH], [_colorStrip, _colorAccent] select _inHand] call FUNC(uiPanel);
        [
            _display, _parent, [_cardX, _cardY + _padY * 0.5, _stripW, _lineH], format ["[%1]", _number], _lineSize,
            [_colorMuted, _colorOnAccent] select _inHand, _fontBold, 2
        ] call FUNC(uiLabel);

        _innerX = _cardX + _stripW;
    } else {
        // A key cap in the corner, like the footer's key hints, in the accent colour while in hand.
        private _key = [_cardX + _padX * 1.5, _cardY + _padY * 1.5, SQUARE(_lineH), _lineH];

        [_display, _parent, _key, [_theme getOrDefault ["keyBg", [1, 1, 1, 0.1]], _colorAccent] select _inHand, _lineH * 0.3] call FUNC(uiPanel);
        [
            _display, _parent, _key, _number, _lineSize * 0.9,
            [_theme getOrDefault ["keyText", _colorText], _colorOnAccent] select _inHand, _fontBold, 2
        ] call FUNC(uiLabel);

        _innerTop = _cardY + _padY * 1.5 + _lineH;

        // And a bar down the left edge between the round corners, as fnc_drawSlot's accent.
        if (_inHand) then {
            private _bar = [_display, "EINV_PanelRect", _parent, [_cardX, _cardY + _cardRadius, pixelW * 3, _cardH - _cardRadius * 2]] call FUNC(uiCreate);
            _bar ctrlSetBackgroundColor _colorAccent;
        };
    };

    private _contentX = _innerX + _padX;
    private _contentW = _cardX + _cardW - _padX - _contentX;

    if (_empty) then {
        // A silhouette is a hint, not the item: smaller than a picture would be, centred.
        private _iconH = (_cardH - _padY * 2) * 0.6;

        [_display, _parent, [_contentX, _cardY + (_cardH - _iconH) / 2, _contentW, _iconH], _icon, _theme getOrDefault ["slotIcon", [1, 1, 1, 0.15]]] call FUNC(uiIcon);
    } else {
        private _nameTop = _cardY + _cardH - _padY * 0.5 - _lineH;
        private _nameSize = UNIT * 0.5;
        private _name = [[_info getOrDefault ["name", _class], _theme] call FUNC(caption), _contentW, _font, _nameSize] call FUNC(fitText);

        [_display, _parent, [_contentX, _innerTop, _contentW, (_nameTop - _innerTop) max pixelH], _info getOrDefault ["picture", ""]] call FUNC(uiPicture);

        // What is on the weapon shows on its picture, the way Arma's own inventory draws it.
        [_display, _parent, [_contentX, _innerTop, _contentW, (_nameTop - _innerTop) max pixelH], _weapon] call FUNC(drawAttachments);
        [_display, _parent, [_contentX, _nameTop, _contentW, _lineH], _name, _nameSize, _colorText, _font, 0] call FUNC(uiLabel);
    };

    // The weapon in hand is framed in the accent colour, over everything else on the card.
    if (_flat) then {
        private _frame = [_border, _colorAccent] select _inHand;

        if (_frame isNotEqualTo []) then {
            [_display, _parent, _cardRect, _frame] call FUNC(uiFrame);
        };
    };

    // The hover area, the way fnc_drawSlot registers its own: on the screen, and inside a group also
    // where it lies there, so the hint finds it after scrolling.
    if (isNull _parent) then {
        (uiNamespace getVariable [QGVAR(slots), []]) pushBack [_cardRect, _class, _caption, createHashMap, _weapon, _slot, _unit];
    } else {
        private _anchor = createHashMapFromArray [["rel", [_cardX, _cardY]], ["parent", _parent]];
        ([_anchor] call FUNC(gridOrigin)) params ["_screenX", "_screenY"];

        (uiNamespace getVariable [QGVAR(slots), []]) pushBack [[_screenX, _screenY, _cardW, _cardH], _class, _caption, _anchor, _weapon, _slot, _unit];
    };
};

// ---------------------------------------------------------------------------
// A weapon's row: its card, and its attachments beside it, row by row. Returns the row's height.
// ---------------------------------------------------------------------------
private _fnc_weaponRow = {
    params ["_rowTop", "_slot", "_caption", "_icon", "_number", "_cols", "_parts"];

    // [class, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod]
    private _weapon = _equipment getOrDefault [_slot, []];
    private _class = _weapon param [0, "", [""]];
    private _cardY = _rowTop + _capH;
    private _inHand = _class isNotEqualTo "" && {!isNull _unit} && {currentWeapon _unit == _class};

    [[_left, _cardY, _cardW, _cardH], _class, _caption, _icon, _number, _inHand] call _fnc_weaponCard;

    {
        _x params ["_index", "_partCaption", "_partIcon"];

        private _value = _weapon param [_index, ""];
        private _partClass = "";
        private _ammo = [];

        // A loaded magazine comes with its rounds; they show only where it holds more than one.
        if (_value isEqualType []) then {
            _partClass = _value param [0, "", [""]];

            if (_partClass isNotEqualTo "") then {
                private _capacity = ([_partClass] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0];

                if (_capacity > 1) then {
                    _ammo = [_value param [1, 0, [0]], _capacity];
                };
            };
        } else {
            if (_value isEqualType "") then {
                _partClass = _value;
            };
        };

        private _col = _forEachIndex mod _cols;
        private _row = floor (_forEachIndex / _cols);

        [
            _display, _parent,
            [_left + _cardW + _gapW + _col * (_slotW + _gapW), _cardY + _row * (_slotH + _gapH), _slotW, _slotH],
            _partClass,
            createHashMapFromArray [
                ["caption", _partCaption], ["icon", _partIcon], ["ammo", _ammo], ["unit", _unit],
                ["slot", format ["%1_%2", _slot, ["", "muzzle", "rail", "optic", "mag", "mag2", "bipod"] select _index]]
            ],
            _quiet
        ] call FUNC(drawSlot);
    } forEach _parts;

    _capH + _cardH
};

private _fnc_label = {
    params ["_labelTop", "_text"];

    [_display, _parent, [_left, _labelTop, _width, _labelH], [_text, _theme] call FUNC(caption), UNIT * 0.55, _colorText2, _font, 0] call FUNC(uiLabel);
};

// ---------------------------------------------------------------------------
// Weight: what the unit carries, and how hard that is on it. Counted the way ACE counts it: what the
// engine weighs, plus ACE's virtual load on the unit and its uniform, vest and backpack (einv_weight_fnc_getLoad).
// That holds the weight overrides of the rules (weight=, handed to ACE by the weight addon), which the storage
// sections weigh by too, and what Enhanced First Aid Kits' kits hold - so the total here is the one ACE shows
// and tires the unit by.
//
// The bar runs from nothing to the Critical limit and carries no marks: a tick or a strip in yellow and red
// looked bad on a bar that is mostly empty. The tier shows in the fill's colour (fnc_weightColor, blending
// into the next one just before a limit), in the word on the right with what the tier does to the soldier,
// and in the kilograms on the left after the load: where the next tier starts. Where the limits are comes
// from the weight addon (einv_weight_fnc_getLimits); this card only draws it. While something from outside
// the soldier's own gear is dragged, a preview of its weight lies on the bar (fnc_previewWeight), found
// through uiNamespace weightBar.
// ---------------------------------------------------------------------------
private _limits = [_unit] call EFUNC(weight,getLimits);
private _mass = [_unit] call EFUNC(weight,getLoad);
private _tier = [_unit, _mass] call EFUNC(weight,getTier);
private _end = (_limits get "critical") max 1;

([_tier, _limits] call EFUNC(weight,tierText)) params ["_word", "_effect"];

// The fill and the words take the tier's colour.
private _fill = [_unit, _mass, _theme] call FUNC(weightColor);

// The tier that starts next and where, for the text beside the load. Heavy only counts as a tier of its own
// where it starts before Overloaded; Critical has nothing above it.
private _nextTier = -1;

for "_i" from _tier + 1 to TIER_CRITICAL do {
    if (_i != TIER_HEAVY || {(_limits get "heavyKg") < (_limits get "overloadedKg")}) exitWith {
        _nextTier = _i;
    };
};

private _cursor = _top;
private _statPadY = UNIT * 0.22;
private _statPadX = SQUARE(UNIT * 0.3);
private _stripH = UNIT * 0.68;
private _statBarH = (2 max round (UNIT * 0.2 / pixelH)) * pixelH;
private _statBarY = _cursor + _statH - _statPadY - _statBarH;
private _statBarW = _width - _statPadX * 2;

if (_flat) then {
    // The caption on a strip of its own across the top.
    [_display, _parent, [_left, _cursor, _width, _statH], _colorCard] call FUNC(uiPanel);
    [_display, _parent, [_left, _cursor, _width, _stripH], _colorStrip] call FUNC(uiPanel);
} else {
    [_display, _parent, [_left, _cursor, _width, _statH], _colorCard, _radius min (_statH / 4)] call FUNC(uiPanel);
};

[
    _display, _parent, [_left + _statPadX, _cursor, _statBarW, _stripH], [LLSTRING(Stat_Weight), _theme] call FUNC(caption),
    UNIT * 0.42, _colorText2, _font, 0
] call FUNC(uiLabel);

private _valueY = _cursor + _stripH;
private _valueH = _statBarY - _valueY;
private _wordSize = UNIT * 0.46;

// The load, and after it where the next tier starts, in kilograms.
private _valueText = format ["%1 kg", (_mass * MASS_TO_KG) toFixed 1];
private _valueSize = UNIT * 0.66;
private _valueW = (_valueText getTextWidth [_fontBold, _valueSize]) * TEXT_SLACK;
private _nextText = "";

if (_nextTier >= 0 && {_limits getOrDefault ["enabled", true]}) then {
    _nextText = format [
        LLSTRING(Load_Next), ([_nextTier, _limits] call EFUNC(weight,tierText)) select 0,
        (_limits get (["", "heavyKg", "overloadedKg", "criticalKg"] select _nextTier)) toFixed 1
    ];
};

// The word with its effect on the right, the next limit beside the load. On a narrow column they would run
// into each other, so the next limit goes first, then the effect: the tier itself always stays.
private _fnc_width = {
    params ["_text", "_textFont", "_textSize"];

    (_text getTextWidth [_textFont, _textSize]) * TEXT_SLACK
};

private _nextGap = SQUARE(UNIT * 0.2);
private _nextW = 0;

if (_nextText isNotEqualTo "") then {
    _nextW = ([_nextText, _font, UNIT * 0.46] call _fnc_width) + _nextGap;
};

private _wordFull = [_word, format [LLSTRING(Tier_Effect), _word, _effect]] select (_effect isNotEqualTo "");
private _room = _statBarW - _valueW - SQUARE(UNIT * 0.4);
private _fullW = [[_wordFull, _theme] call FUNC(caption), _fontBold, _wordSize] call _fnc_width;

if (_nextText isNotEqualTo "" && {_nextW + _fullW > _room}) then {
    _nextText = "";
    _nextW = 0;
};

if (_fullW > _room - _nextW) then {
    _wordFull = _word;
};

private _wordText = [_wordFull, _theme] call FUNC(caption);
private _wordW = [_wordText, _fontBold, _wordSize] call _fnc_width;

[_display, _parent, [_left + _statPadX + _statBarW - _wordW, _valueY, _wordW, _valueH], _wordText, _wordSize, _fill, _fontBold, 1] call FUNC(uiLabel);
[_display, _parent, [_left + _statPadX, _valueY, _statBarW - _wordW, _valueH], _valueText, _valueSize, _colorText, _fontBold, 0] call FUNC(uiLabel);

if (_nextText isNotEqualTo "") then {
    [
        _display, _parent, [_left + _statPadX + _valueW + _nextGap, _valueY, _nextW, _valueH],
        _nextText, UNIT * 0.46, _colorMuted, _font, 0
    ] call FUNC(uiLabel);
};

private _barRect = [_left + _statPadX, _statBarY, _statBarW, _statBarH];

if (_flat) then {
    // In a square look the bar is cut into segments with a small gap between them, each filling in turn.
    private _segments = 10;
    private _segmentGap = pixelW * 2;
    private _segmentW = (_statBarW - _segmentGap * (_segments - 1)) / _segments;
    private _share = (_mass / _end) min 1;

    for "_i" from 0 to (_segments - 1) do {
        [
            _display, _parent, [_left + _statPadX + _i * (_segmentW + _segmentGap), _statBarY, _segmentW, _statBarH],
            ((_share * _segments - _i) max 0) min 1, _barTrack, _fill, 0
        ] call FUNC(uiBar);
    };
} else {
    [_display, _parent, _barRect, (_mass / _end) min 1, _barTrack, _fill, _statBarH / 2] call FUNC(uiBar);
};

if (_flat) then {
    // Last, so nothing covers it.
    if (_border isNotEqualTo []) then {
        [_display, _parent, [_left, _cursor, _width, _statH], _border] call FUNC(uiFrame);
    };
};

// What a drag previews on the bar and where (fnc_previewWeight), and the hint over the whole card (fnc_infoHint).
uiNamespace setVariable [QGVAR(weightBar), createHashMapFromArray [
    ["parent", _parent], ["rect", _barRect], ["load", _mass], ["limits", _limits], ["unit", _unit]
]];

private _cardRect = [_left, _cursor, _width, _statH];
private _cardAnchor = createHashMap;

if (!isNull _parent) then {
    _cardAnchor = createHashMapFromArray [["rel", [_left, _cursor]], ["parent", _parent]];

    ([_cardAnchor] call FUNC(gridOrigin)) params ["_screenX", "_screenY"];

    _cardRect = [_screenX, _screenY, _width, _statH];
};

(uiNamespace getVariable [QGVAR(infoAreas), []]) pushBack [_cardRect, "", "", _cardAnchor, "weight", [_unit]];

_cursor = _cursor + _statH + _groupGap;

// ---------------------------------------------------------------------------
// Weapons, from the top down
// ---------------------------------------------------------------------------
[_cursor, LLSTRING(Column_Equipment)] call _fnc_label;
_cursor = _cursor + _labelH;

_cursor = _cursor + _rowGap + ([_cursor, "primary", LLSTRING(Slot_Primary), GEAR_ICON(ui_gear_primary_gs), "1", 3, [
    [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)],
    [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)],
    [2, LLSTRING(Slot_Rail), GEAR_ICON(ui_gear_side_gs)],
    [1, LLSTRING(Slot_Muzzle), GEAR_ICON(ui_gear_muzzle_gs)],
    [6, LLSTRING(Slot_Bipod), GEAR_ICON(ui_gear_bipod_gs)],
    [5, LLSTRING(Slot_Magazine2), GEAR_ICON(ui_gear_magazineGL_gs)]
]] call _fnc_weaponRow);

_cursor = _cursor + _rowGap + ([_cursor, "handgun", LLSTRING(Slot_Handgun), GEAR_ICON(ui_gear_hgun_gs), "2", 2, [
    [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)],
    [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)],
    [2, LLSTRING(Slot_Rail), GEAR_ICON(ui_gear_side_gs)],
    [1, LLSTRING(Slot_Muzzle), GEAR_ICON(ui_gear_muzzle_gs)]
]] call _fnc_weaponRow);

[_cursor, "launcher", LLSTRING(Slot_Launcher), GEAR_ICON(ui_gear_secondary_gs), "3", 2, [
    [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)],
    [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)]
]] call _fnc_weaponRow;

// ---------------------------------------------------------------------------
// Gear, from the bottom of the column up. Both rows spread over the full width.
// ---------------------------------------------------------------------------
private _smallY = _top + _height - _hotbarH - _smallH;
private _gearY = _smallY - _gearGap - _gearH;

[_gearY - _capH - _labelH, LLSTRING(Column_Gear)] call _fnc_label;

{
    _x params ["_slot", "_slotCaption", "_slotIcon"];

    [
        _display, _parent, [_left + _forEachIndex * (_width - _gearW) / 3, _gearY, _gearW, _gearH],
        _equipment getOrDefault [_slot, ""],
        createHashMapFromArray [["caption", _slotCaption], ["icon", _slotIcon], ["slot", _slot], ["unit", _unit]],
        _theme
    ] call FUNC(drawSlot);
} forEach [
    ["headgear", LLSTRING(Slot_Headgear), GEAR_ICON(ui_gear_helmet_gs)],
    ["uniform", LLSTRING(Slot_Uniform), GEAR_ICON(ui_gear_uniform_gs)],
    ["vest", LLSTRING(Slot_Vest), GEAR_ICON(ui_gear_vest_gs)],
    ["backpack", LLSTRING(Slot_Backpack), GEAR_ICON(ui_gear_backpack_gs)]
];

{
    _x params ["_slot", "_slotCaption", "_slotIcon"];

    // The binocular comes as a weapon, with its battery - only its class goes on the slot.
    private _value = _equipment getOrDefault [_slot, ""];

    if (_value isEqualType []) then {
        _value = _value param [0, "", [""]];
    };

    [
        _display, _parent, [_left + _forEachIndex * (_width - _smallW) / 7, _smallY, _smallW, _smallH],
        _value,
        createHashMapFromArray [["caption", _slotCaption], ["icon", _slotIcon], ["slot", _slot], ["unit", _unit]],
        _quiet
    ] call FUNC(drawSlot);
} forEach [
    ["goggles", LLSTRING(Slot_Goggles), GEAR_ICON(ui_gear_glasses_gs)],
    ["nvg", LLSTRING(Slot_NVG), GEAR_ICON(ui_gear_nvg_gs)],
    ["binocular", LLSTRING(Slot_Binocular), GEAR_ICON(ui_gear_binocular_gs)],
    ["map", LLSTRING(Slot_Map), GEAR_ICON(ui_gear_map_gs)],
    ["gps", LLSTRING(Slot_GPS), GEAR_ICON(ui_gear_gps_gs)],
    ["radio", LLSTRING(Slot_Radio), GEAR_ICON(ui_gear_radio_gs)],
    ["compass", LLSTRING(Slot_Compass), GEAR_ICON(ui_gear_compass_gs)],
    ["watch", LLSTRING(Slot_Watch), GEAR_ICON(ui_gear_watch_gs)]
];

// ---------------------------------------------------------------------------
// The hotbar, at the very bottom
// ---------------------------------------------------------------------------
if (_hotbar) then {
    [_top + _height - _smallH - _labelH, LELSTRING(hotbar,Strip_Title)] call _fnc_label;
    [_display, _parent, [_left, _top + _height - _smallH, _width, _smallH], _smallW, _quiet] call EFUNC(hotbar,drawStrip);
};
