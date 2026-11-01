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
 *   [4] second primary ..... | mag | optic | rail  |   on the back - only with WebKnight's or KJW's Two
 *                            | muz | bipod | 2nd   |   Primary Weapons (aio_storage_fnc_secondPrimary)
 *   [2] handgun ............ | mag | optic |
 *                            | rail| muzzle|
 *   [3] launcher ........... | mag | optic |
 *   GEAR
 *   | headgear |  | uniform |  | vest |  | backpack |
 *   | gog | nvg | bin | map | gps | radio | compass | watch |
 *   HOTBAR
 *   | 4 | 5 | 6 | 7 | 8 | 9 | 0 |                           the keys' items (aio_hotbar), when it is loaded
 *                                                              and on, in the inventory window only
 *
 * The weapon cards come in the order the player gave them (GVAR(weaponOrder), the arrows in each card's corner,
 * fnc_moveWeaponCard) - the order above is the default. The second primary's card folds to a single line with
 * the button beside those arrows (GVAR(secondFold), fnc_toggleSecondFold), and starts folded while the back is
 * empty. The corner's buttons keep their presses to themselves (GVAR(cardButtons), fnc_onMouseButton).
 *
 * The weapon cards are as wide and as tall as each other, so their attachments start on one
 * line. The second primary's card stands under the primary's, in the place EVEN Better Inventory gives it: its
 * corner names that mod's own switch key, and it is never the weapon in hand. The weapon in hand is marked in the accent colour. The attachments grow with the height the
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
 * [_display, controlNull, [0.1, 0.1, 0.5, 0.8], _context, _theme] call aio_gui_fnc_drawEquipmentCards;
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
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _colorMuted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _colorAccent = _theme getOrDefault ["slotAccent", [0.84, 0.54, 0.1, 1]];
private _colorOnAccent = _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]];
private _colorStrip = _theme getOrDefault ["slotCaptionBg", [1, 1, 1, 0.1]];
private _border = _theme getOrDefault ["slotBorder", []];
private _radius = _theme getOrDefault ["radius", 0];
private _flat = _radius <= 0;

// Captions over the slots take a line of their own above them - room the rows below have to leave.
// The words, and the rows and cards that hold them, grow with the tiles (TEXT_UNIT, fnc_textScale), as fnc_drawSlot's.
private _textUnit = TEXT_UNIT;
private _lineH = _textUnit * 0.62;
private _lineSize = _textUnit * 0.46;
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
private _statH = _textUnit * 2.2;
private _labelH = _textUnit * 0.8;
private _gearGap = UNIT * 0.3;

// Square slots: eight small ones across a row, four big gear cards across another. The gear cards take what
// the width leaves after three gaps, so on the narrowest column they only grow a little smaller - the backpack
// never wraps into a row of its own.
private _smallW = ((_width - _gapW * 7) / 8) min SQUARE(UNIT * 2.2);
private _smallH = UNSQUARE(_smallW);
private _gearW = ((_width - _gapW * 3) / 4) min SQUARE(UNIT * 4.6);
private _gearH = UNSQUARE(_gearW);

// The hotbar's row under the gear (aio_hotbar - only when that addon is loaded and on, and only in the
// inventory, not in the Arsenal): a caption over seven small slots.
private _hotbar = call FUNC(isInventoryMode) && {!isNil QEFUNC(hotbar,drawStrip)} && {call EFUNC(hotbar,isActive)};
private _hotbarH = [0, _labelH + _smallH + _groupGap] select _hotbar;

// A fourth card for the second primary on the back, when a two-primary mod gives the unit that slot.
private _second = _equipment getOrDefault ["primary2", -1];
private _hasSecond = _second isEqualType [];
private _cards = [3, 4] select _hasSecond;

// Folded, the second primary's card is a single line: as the player chose it, or until then while the back is empty.
private _folded = _hasSecond && {
    GVAR(secondFold) isEqualTo "folded" || {GVAR(secondFold) isEqualTo "" && {_second isEqualTo []}}
};
private _open = _cards - ([0, 1] select _folded);
private _foldH = _lineH + _textUnit * 0.66;

// Each weapon card is two attachment rows high. The primary's three attachments across may take about
// 40 % of the width.
private _fixed = _statH + _groupGap * 2 + _labelH * 2 + _rowGap * (_cards - 1) + _gapH * _open + _capH * (_cards + 1) + _foldH * (_cards - _open) + _gearH + _gearGap + _smallH + _hotbarH;
private _slotWMax = ((_width * 0.42 - _gapW * 3) / 3) max (pixelW * 8);
private _slotH = (((_height - _fixed) / (_open * 2)) min (UNIT * 2.7) min UNSQUARE(_slotWMax)) max (UNIT * 1.2);
private _slotW = SQUARE(_slotH);
private _cardH = _slotH * 2 + _gapH;
private _cardW = _width - (_slotW + _gapW) * 3;

// Left over height loosens the gaps between the weapons a little; the rest stays above the gear.
private _extra = (((_height - _fixed - _slotH * _open * 2) / (_cards + 1)) max 0) min (UNIT * 0.6);
_rowGap = _rowGap + _extra;

// ---------------------------------------------------------------------------
// The buttons in a card's top right corner, side by side, the last at the right edge: [id, texture, angle,
// tooltip] each, [] for a place left free - so an arrow stays where it is on every card, whether its neighbour
// is drawn or not. A button is its icon, and over it a hit area as wide as its place and two pixels higher and
// lower; the presses there are the buttons' (GVAR(cardButtons), fnc_onMouseButton). The click runs a frame later
// (fnc_later), as the window may be built again meanwhile.
// ---------------------------------------------------------------------------
private _fnc_cornerButtons = {
    params ["_buttonY", "_rightX", "_buttons"];

    private _buttonW = SQUARE(_lineH);
    private _iconH = _lineH * 0.7;
    private _firstX = _rightX - _buttonW * count _buttons;

    {
        if (_x isEqualTo []) then {continue};

        _x params ["_id", "_texture", "_angle", "_tip"];

        private _buttonX = _firstX + _forEachIndex * _buttonW;
        private _iconCtrl = [
            _display, _parent, [_buttonX + (_buttonW - SQUARE(_iconH)) / 2, _buttonY + (_lineH - _iconH) / 2, SQUARE(_iconH), _iconH],
            _texture, _colorText2
        ] call FUNC(uiIcon);

        if (_angle != 0) then {
            _iconCtrl ctrlSetAngle [_angle, 0.5, 0.5, true];
        };

        private _hit = [_display, "AIO_Hitbox", _parent, [_buttonX, _buttonY - pixelH * 2, _buttonW, _lineH + pixelH * 4]] call FUNC(uiCreate);
        [_hit, _tip] call FUNC(setTooltip);
        _hit setVariable [QGVAR(id), _id];
        _hit ctrlAddEventHandler ["ButtonClick", {
            [{
                params ["_id"];

                (_id splitString "|") params ["_kind", "_slot"];

                switch (_kind) do {
                    case "up": {[_slot, -1] call FUNC(moveWeaponCard)};
                    case "down": {[_slot, 1] call FUNC(moveWeaponCard)};
                    case "fold": {[false] call FUNC(toggleSecondFold)};
                    case "open": {[true] call FUNC(toggleSecondFold)};
                };
            }, [(_this select 0) getVariable [QGVAR(id), ""]]] call FUNC(later);
        }];
    } forEach _buttons;

    if (_buttons isNotEqualTo []) then {
        (uiNamespace getVariable [QGVAR(cardButtons), []]) pushBack createHashMapFromArray [
            ["rel", [_firstX, _buttonY - pixelH * 2]], ["parent", _parent], ["size", [_buttonW * count _buttons, _lineH + pixelH * 4]]
        ];
    };
};

// ---------------------------------------------------------------------------
// A weapon's card: its number, its picture or silhouette, its name, and the mark of the weapon in hand. Folded, a
// single line: its number, and its caption with the weapon's name - no picture.
// ---------------------------------------------------------------------------
private _fnc_weaponCard = {
    params ["_cardRect", "_class", "_caption", "_icon", "_number", "_inHand", ["_buttons", []], ["_cardFolded", false]];
    _cardRect params ["_cardX", "_cardY", "_cardW", "_cardH"];

    private _empty = _class isEqualTo "";
    private _info = if (_empty) then {createHashMap} else {[_class] call EFUNC(items,getInfo)};
    private _cardRadius = _radius min (_cardH / 4);
    private _padY = _textUnit * 0.22;
    private _padX = SQUARE(_padY);

    // The line of the key and the corner's buttons: the top of the card, the middle of a folded one.
    private _keyY = if (_cardFolded) then {_cardY + (_cardH - _lineH) / 2} else {_cardY + _padY * ([1.5, 0.5] select _flat)};

    [_display, _parent, _cardRect, _theme getOrDefault [["slot", "slotEmpty"] select _empty, [1, 1, 1, 0.035]], _cardRadius] call FUNC(uiPanel);

    if (_capH > 0 && {_caption isNotEqualTo ""}) then {
        private _shown = [[_caption, _theme] call FUNC(caption), _cardW, _font, _lineSize] call FUNC(fitText);
        [_display, _parent, [_cardX, _cardY - _lineH, _cardW, _lineH], _shown, _lineSize, _colorText2, _font, 0, "caption"] call FUNC(uiLabel);
    };

    // Where the picture and the name may go - right of the strip, under the key cap.
    private _innerX = _cardX;
    private _innerTop = _cardY + _padY;

    if (_flat) then {
        private _stripW = SQUARE(_textUnit * 1.05);

        [_display, _parent, [_cardX, _cardY, _stripW, _cardH], [_colorStrip, _colorAccent] select _inHand] call FUNC(uiPanel);

        // A card with no key to name (the second primary, its mod's key unbound or with modifiers) keeps its strip.
        if (_number isNotEqualTo "") then {
            [
                _display, _parent, [_cardX, _keyY, _stripW, _lineH], format ["[%1]", _number], _lineSize,
                [_colorMuted, _colorOnAccent] select _inHand, _fontBold, 2, "key"
            ] call FUNC(uiLabel);
        };

        _innerX = _cardX + _stripW;
    } else {
        // A key cap in the corner, like the footer's key hints, in the accent colour while in hand.
        private _key = [_cardX + _padX * 1.5, _keyY, SQUARE(_lineH), _lineH];

        if (_number isNotEqualTo "") then {
            [_display, _parent, _key, [_theme getOrDefault ["keyBg", [1, 1, 1, 0.1]], _colorAccent] select _inHand, _lineH * 0.3] call FUNC(uiPanel);
            [
                _display, _parent, _key, _number, _lineSize * 0.9,
                [_theme getOrDefault ["keyText", _colorText], _colorOnAccent] select _inHand, _fontBold, 2, "key"
            ] call FUNC(uiLabel);
        };

        _innerTop = _cardY + _padY * 1.5 + _lineH;

        // A folded card's caption starts right of the key cap.
        if (_cardFolded) then {
            _innerX = _cardX + _padX * 1.5 + SQUARE(_lineH);
        };

        // And a bar down the left edge between the round corners, as fnc_drawSlot's accent.
        if (_inHand) then {
            private _bar = [_display, "AIO_PanelRect", _parent, [_cardX, _cardY + _cardRadius, pixelW * 3, _cardH - _cardRadius * 2]] call FUNC(uiCreate);
            _bar ctrlSetBackgroundColor _colorAccent;
        };
    };

    // The picture keeps clear of the corner's buttons.
    if (_buttons isNotEqualTo []) then {
        _innerTop = _innerTop max (_keyY + _lineH);
    };

    [_keyY, _cardX + _cardW - _padX, _buttons] call _fnc_cornerButtons;

    private _contentX = _innerX + _padX;
    private _contentW = _cardX + _cardW - _padX - _contentX;

    if (_cardFolded) then {
        // The caption, and after it what is on the back.
        private _textW = (_contentW - SQUARE(_lineH) * count _buttons - _padX) max pixelW;
        private _text = [_caption, _theme] call FUNC(caption);

        if (!_empty) then {
            _text = format ["%1: %2", _text, _info getOrDefault ["name", _class]];
        };

        [
            _display, _parent, [_contentX, _keyY, _textW, _lineH], [_text, _textW, _font, _lineSize] call FUNC(fitText),
            _lineSize, [_colorText2, _colorText] select !_empty, _font, 0, "weapon"
        ] call FUNC(uiLabel);
    } else {
        if (_empty) then {
            // A silhouette is a hint, not the item: smaller than a picture would be, centred.
            private _iconH = (_cardH - _padY * 2) * 0.6;

            [_display, _parent, [_contentX, _cardY + (_cardH - _iconH) / 2, _contentW, _iconH], _icon, _theme getOrDefault ["slotIcon", [1, 1, 1, 0.15]]] call FUNC(uiIcon);
        } else {
            private _nameTop = _cardY + _cardH - _padY * 0.5 - _lineH;
            private _nameSize = _textUnit * 0.5;
            private _name = [[_info getOrDefault ["name", _class], _theme] call FUNC(caption), _contentW, _font, _nameSize] call FUNC(fitText);

            // As the rules draw it (icon=): larger, smaller or moved, and cut to the card where it would reach out.
            [
                _display, _parent, [_contentX, _innerTop, _contentW, (_nameTop - _innerTop) max pixelH], _info getOrDefault ["picture", ""],
                _info getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 1], _cardRect
            ] call FUNC(uiItemPicture);

            // What is on the weapon shows on its picture, the way Arma's own inventory draws it.
            [_display, _parent, [_contentX, _innerTop, _contentW, (_nameTop - _innerTop) max pixelH], _weapon] call FUNC(drawAttachments);
            [_display, _parent, [_contentX, _nameTop, _contentW, _lineH], _name, _nameSize, _colorText, _font, 0, "weapon"] call FUNC(uiLabel);
        };
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
    params ["_rowTop", "_slot", "_caption", "_icon", "_number", "_cols", "_parts", ["_buttons", []], ["_rowFolded", false]];

    // [class, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod]
    private _weapon = _equipment getOrDefault [_slot, []];
    private _class = _weapon param [0, "", [""]];
    private _cardY = _rowTop + _capH;

    // The second primary hangs on the back: never in hand, even of the same class as the one that is.
    private _inHand = _class isNotEqualTo "" && {_slot isNotEqualTo "primary2"} && {!isNull _unit} && {currentWeapon _unit == _class};

    // Folded, the card is a line over the whole width, with no attachments beside it.
    if (_rowFolded) exitWith {
        [[_left, _cardY, _width, _foldH], _class, _caption, _icon, _number, false, _buttons, true] call _fnc_weaponCard;

        _capH + _foldH
    };

    [[_left, _cardY, _cardW, _cardH], _class, _caption, _icon, _number, _inHand, _buttons] call _fnc_weaponCard;

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

    [_display, _parent, [_left, _labelTop, _width, _labelH], [_text, _theme] call FUNC(caption), _textUnit * 0.55, _colorText2, _font, 0, "section"] call FUNC(uiLabel);
};

// ---------------------------------------------------------------------------
// Weight: what the unit carries, and how hard that is on it (fnc_drawWeightCard). On the inventory's own
// display a part of its own (fnc_drawPart): drawn again alone when only what the unit carries changed
// (fnc_refresh), under everything made after it.
// ---------------------------------------------------------------------------
private _cursor = _top;
private _weightRect = [_left, _cursor, _width, _statH];

if (isNull _parent) then {
    [_display, "weight", controlNull, _weightRect, {_this call FUNC(drawWeightCard)}, [_unit, _theme]] call FUNC(drawPart);
} else {
    [_display, _parent, _weightRect, _unit, _theme] call FUNC(drawWeightCard);
};

_cursor = _cursor + _statH + _groupGap;

// ---------------------------------------------------------------------------
// Weapons, from the top down
// ---------------------------------------------------------------------------
[_cursor, LLSTRING(Column_Equipment)] call _fnc_label;
_cursor = _cursor + _labelH;

// Each card's caption, silhouette, key, attachment columns and attachments: [index in the weapon, caption, silhouette].
private _rifleParts = [
    [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)],
    [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)],
    [2, LLSTRING(Slot_Rail), GEAR_ICON(ui_gear_side_gs)],
    [1, LLSTRING(Slot_Muzzle), GEAR_ICON(ui_gear_muzzle_gs)],
    [6, LLSTRING(Slot_Bipod), GEAR_ICON(ui_gear_bipod_gs)],
    [5, LLSTRING(Slot_Magazine2), GEAR_ICON(ui_gear_magazineGL_gs)]
];

// The second primary's corner names the two-primary mod's own key that switches to it - when that key is short
// enough for the cap (a key with modifiers is left off).
private _keyName = "";

if (_hasSecond) then {
    private _keybind = EGVAR(storage,secondPrimaryMod) getOrDefault ["keybind", []];

    if (_keybind isNotEqualTo [] && {!isNil "CBA_fnc_getKeybind"}) then {
        private _entry = _keybind call CBA_fnc_getKeybind;

        if (isNil "_entry") exitWith {};

        ((_entry param [8, []]) param [0, []]) params [["_key", 0, [0]], ["_modifiers", [], [[]]]];

        if (_key > 0 && {!(true in _modifiers)}) then {
            _keyName = [_key, _modifiers] call CBA_fnc_localizeKey;
        };
    };

    if (count _keyName > 2) then {
        _keyName = "";
    };
};

private _rows = createHashMapFromArray [
    ["primary", [LLSTRING(Slot_Primary), GEAR_ICON(ui_gear_primary_gs), "1", 3, _rifleParts]],
    ["primary2", [LLSTRING(Slot_SecondPrimary), GEAR_ICON(ui_gear_primary_gs), _keyName, 3, _rifleParts]],
    ["handgun", [LLSTRING(Slot_Handgun), GEAR_ICON(ui_gear_hgun_gs), "2", 2, [
        [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)],
        [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)],
        [2, LLSTRING(Slot_Rail), GEAR_ICON(ui_gear_side_gs)],
        [1, LLSTRING(Slot_Muzzle), GEAR_ICON(ui_gear_muzzle_gs)]
    ]]],
    ["launcher", [LLSTRING(Slot_Launcher), GEAR_ICON(ui_gear_secondary_gs), "3", 2, [
        [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)],
        [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)]
    ]]]
];

// In the player's order, the second primary only where a two-primary mod gives the unit that slot. Each card's
// corner: the fold button on the second primary's, then the arrows up and down - none up on the first card, none
// down on the last.
private _shownOrder = GVAR(weaponOrder) select {_x isNotEqualTo "primary2" || _hasSecond};

{
    private _isSecond = _x isEqualTo "primary2";
    private _buttons = [];

    if (_isSecond) then {
        _buttons pushBack ([
            ["fold|primary2", UI_TEX(icon_minus_ca), 0, LLSTRING(WeaponCard_Fold)],
            ["open|primary2", UI_TEX(icon_plus_ca), 0, LLSTRING(WeaponCard_Unfold)]
        ] select _folded);
    };

    _buttons pushBack ([[], [format ["up|%1", _x], UI_TEX(icon_chevron_down_ca), 180, LLSTRING(WeaponCard_MoveUp)]] select (_forEachIndex > 0));
    _buttons pushBack ([[], [format ["down|%1", _x], UI_TEX(icon_chevron_down_ca), 0, LLSTRING(WeaponCard_MoveDown)]] select (_forEachIndex < count _shownOrder - 1));

    (_rows get _x) params ["_rowCaption", "_rowIcon", "_rowNumber", "_rowCols", "_rowParts"];

    _cursor = _cursor + _rowGap + ([
        _cursor, _x, _rowCaption, _rowIcon, _rowNumber, _rowCols, _rowParts, _buttons, _isSecond && _folded
    ] call _fnc_weaponRow);
} forEach _shownOrder;

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
// Its counts follow what the unit carries: on the inventory's own display a part of its own as well, drawn
// again with the weight card (fnc_drawPart, fnc_refresh).
if (_hotbar) then {
    [_top + _height - _smallH - _labelH, LELSTRING(hotbar,Strip_Title)] call _fnc_label;

    private _stripRect = [_left, _top + _height - _smallH, _width, _smallH];

    if (isNull _parent) then {
        [_display, "hotbar", controlNull, _stripRect, {
            params ["_display", "_group", "_rect", "_slotW", "_stripTheme"];

            [_display, _group, _rect, _slotW, _stripTheme] call EFUNC(hotbar,drawStrip);
        }, [_smallW, _quiet]] call FUNC(drawPart);
    } else {
        [_display, _parent, _stripRect, _smallW, _quiet] call EFUNC(hotbar,drawStrip);
    };
};
