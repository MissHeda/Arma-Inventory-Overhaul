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
 *   v [1] Primary .............................. ::   each weapon a header line - fold chevron, key,
 *   | picture ............... | mag | optic | rail  |   caption, grip - over a big card, its attachments
 *   |                         | muz | bipod | 2nd   |   and loaded magazines as small slots beside it
 *   v [4] Second primary ....................... ::   on the back - only with WebKnight's or KJW's Two
 *   | ...                                             Primary Weapons (aio_storage_fnc_secondPrimary)
 *   > [2] Handgun - P99 ........................ ::   folded: the header alone, naming the weapon
 *   v [3] Launcher ............................. ::
 *   | picture ............... | mag | optic |
 *   GEAR
 *   | headgear |  | uniform |  | vest |  | backpack |
 *   | gog | nvg | bin | map | gps | radio | compass | watch |
 *   HOTBAR
 *   | 4 | 5 | 6 | 7 | 8 | 9 | 0 |                           the keys' items (aio_hotbar), when it is loaded
 *                                                              and on, in the inventory window only
 *
 * The weapon cards come in the order the player gave them, primary, second primary, handgun, launcher at first: a
 * card is dragged to another place by the grip at the right end of its header - a chevron up, a dash, a chevron down
 * (GVAR(weaponOrder), fnc_cardGrip).
 * A click on the header's chevron or caption folds the card to that line, and opens it again (GVAR(weaponFolds),
 * fnc_toggleWeaponFold) - a folded one still takes a weapon dragged onto its line. The second primary's card starts
 * folded while the back is empty. The column's sections - Equipment, Gear, Hotbar - fold to their caption the same
 * way, a click on it (GVAR(weaponFolds) under "equipment", "gear", "hotbar"). The headers keep their presses to
 * themselves (GVAR(cardButtons), fnc_onMouseButton).
 *
 * The weapon cards are as wide and as tall as each other, so their attachments start on one
 * line. The second primary's key names that mod's own switch key, and it is never the weapon in hand. The weapon in
 * hand is marked in the accent colour. The cards' pictures keep at least half the card's height, whatever the
 * text size: the name goes over the picture's foot where the card is too low for both. The attachments grow with the height the
 * column has, but never take more than about 40 % of its width, so a weapon keeps room for its picture
 * on a narrow (4:3) screen. The weapons stay at the top and the gear and the hotbar at the bottom;
 * whatever height is left over lies between them.
 *
 * A square theme gives each weapon card a strip down its left edge holding its number, and
 * frames the card; a round one (Glass) puts a small key cap in the header instead, as neither a strip
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

// The column's sections fold to their caption as the weapon cards do (fnc_toggleWeaponFold): what they hold is not
// drawn, and the weapons get the height it leaves.
private _equipFolded = GVAR(weaponFolds) getOrDefault ["equipment", false];
private _gearFolded = GVAR(weaponFolds) getOrDefault ["gear", false];
private _hotbarFolded = GVAR(weaponFolds) getOrDefault ["hotbar", false];
private _hotbarH = [0, _labelH + ([_smallH, 0] select _hotbarFolded) + _groupGap] select _hotbar;
private _gearBlockH = [_capH + _gearH + _gearGap + _smallH, 0] select _gearFolded;

// A fourth card for the second primary on the back, when a two-primary mod gives the unit that slot.
private _second = _equipment getOrDefault ["primary2", -1];
private _hasSecond = _second isEqualType [];

// The weapon cards in the player's order (GVAR(weaponOrder)), and which of them are folded to their header: as the
// player chose (GVAR(weaponFolds)), or until then the second primary while nothing is on the back.
private _shownOrder = GVAR(weaponOrder) select {_x isNotEqualTo "primary2" || _hasSecond};
private _cards = count _shownOrder;
private _foldedSlots = _shownOrder select {GVAR(weaponFolds) getOrDefault [_x, _x isEqualTo "primary2" && {_second isEqualTo []}]};
private _open = _cards - count _foldedSlots;

// Each card has its header line above it, whatever the theme's captions - with a little air under it.
private _headH = _lineH + _textUnit * 0.12;

// Each open weapon card is two attachment rows high. The primary's three attachments across may take about
// 40 % of the width.
private _fixed = _statH + _groupGap * 2 + _labelH * 2 + _rowGap * (_cards - 1) + _gapH * _open + _headH * _cards + _gearBlockH + _hotbarH;
private _slotWMax = ((_width * 0.42 - _gapW * 3) / 3) max (pixelW * 8);
private _slotH = (((_height - _fixed) / ((_open * 2) max 1)) min (UNIT * 2.7) min UNSQUARE(_slotWMax)) max (UNIT * 1.2);
private _slotW = SQUARE(_slotH);
private _cardH = _slotH * 2 + _gapH;
private _cardW = _width - (_slotW + _gapW) * 3;

// Left over height loosens the gaps between the weapons a little; the rest stays above the gear.
private _extra = (((_height - _fixed - _slotH * _open * 2) / (_cards + 1)) max 0) min (UNIT * 0.6);
_rowGap = _rowGap + _extra;

// The area of a hit box, kept for its presses (fnc_onMouseButton): where it lies in its group, as fnc_gridOrigin
// takes it.
private _fnc_keepPresses = {
    params ["_area"];

    (uiNamespace getVariable [QGVAR(cardButtons), []]) pushBack createHashMapFromArray [
        ["rel", [_area select 0, _area select 1]], ["parent", _parent], ["size", [_area select 2, _area select 3]]
    ];
};

// A slot's hover and drop area, the way fnc_drawSlot registers its own: on the screen, and inside a group also
// where it lies there, so the hint finds it after scrolling.
private _fnc_register = {
    params ["_area", "_class", "_caption", "_weapon", "_slot"];
    _area params ["_areaX", "_areaY", "_areaW", "_areaH"];

    if (isNull _parent) then {
        (uiNamespace getVariable [QGVAR(slots), []]) pushBack [_area, _class, _caption, createHashMap, _weapon, _slot, _unit];
    } else {
        private _anchor = createHashMapFromArray [["rel", [_areaX, _areaY]], ["parent", _parent]];
        ([_anchor] call FUNC(gridOrigin)) params ["_screenX", "_screenY"];

        (uiNamespace getVariable [QGVAR(slots), []]) pushBack [[_screenX, _screenY, _areaW, _areaH], _class, _caption, _anchor, _weapon, _slot, _unit];
    };
};

// A hit box in a group of its own, as the columns' buttons lie (a section's fold tab, Sort): a press on it gives the
// focus back at once and its click comes at the release (fnc_onFrame, fnc_onMouseButton), so the tip at the mouse
// stays as on those. Lying on the display itself it kept the focus, and its tip went with the click.
private _fnc_hitBox = {
    params ["_area"];

    private _group = [_display, "AIO_Group", _parent, _area] call FUNC(uiCreate);

    [_display, "AIO_Hitbox", _group, [0, 0, _area select 2, _area select 3]] call FUNC(uiCreate)
};

// A hit box that folds or opens what it heads (fnc_toggleWeaponFold): the key it is kept under, folded now.
private _fnc_foldHit = {
    params ["_area", "_key", "_isFolded"];

    private _hit = [_area] call _fnc_hitBox;
    [_hit, [LLSTRING(WeaponCard_Fold), LLSTRING(WeaponCard_Unfold)] select _isFolded] call FUNC(setTooltip);
    _hit setVariable [QGVAR(id), [_key, _isFolded]];
    _hit ctrlAddEventHandler ["ButtonClick", {
        [{_this call FUNC(toggleWeaponFold)}, (_this select 0) getVariable [QGVAR(id), ["", false]]] call FUNC(later);
    }];

    [_area] call _fnc_keepPresses;
};

// The fold chevron at the start of a line: pointing down while open, right while folded.
private _fnc_chevron = {
    params ["_lineY", "_lineH", "_isFolded"];

    private _iconH = _lineH * 0.6;

    [
        _display, _parent, [_left + (SQUARE(_lineH) - SQUARE(_iconH)) / 2, _lineY + (_lineH - _iconH) / 2, SQUARE(_iconH), _iconH],
        [UI_TEX(icon_chevron_down_ca), UI_TEX(icon_chevron_right_ca)] select _isFolded, _colorText2
    ] call FUNC(uiIcon);
};

// ---------------------------------------------------------------------------
// A weapon's header line: the fold chevron, the key (on a round theme - a square one names it on the card's strip),
// the caption - and the weapon's name after it while folded - and at the right end the grip that moves the card.
// The chevron and the caption are one hit box that folds or opens the card, the grip another; they lie side by
// side, neither under the other. A click runs a frame later (fnc_later), as the window may be built again meanwhile.
// ---------------------------------------------------------------------------
private _fnc_weaponHeader = {
    params ["_headY", "_slot", "_caption", "_number", "_inHand", "_isFolded", "_class"];

    private _space = SQUARE(_textUnit * 0.15);

    [_headY, _lineH, _isFolded] call _fnc_chevron;

    private _textX = _left + SQUARE(_lineH);

    // A key cap like the footer's key hints, in the accent colour while in hand.
    if (!_flat && {_number isNotEqualTo ""}) then {
        private _keyH = _lineH * 0.9;
        private _key = [_textX, _headY + (_lineH - _keyH) / 2, SQUARE(_keyH), _keyH];

        [_display, _parent, _key, [_theme getOrDefault ["keyBg", [1, 1, 1, 0.1]], _colorAccent] select _inHand, _keyH * 0.3] call FUNC(uiPanel);
        [
            _display, _parent, _key, _number, _lineSize * 0.85,
            [_theme getOrDefault ["keyText", _colorText], _colorOnAccent] select _inHand, _fontBold, 2, "key"
        ] call FUNC(uiLabel);

        _textX = _textX + SQUARE(_keyH) + _space;
    };

    private _gripW = SQUARE(_lineH);
    private _gripX = _left + _width - _gripW;
    private _text = [_caption, _theme] call FUNC(caption);
    private _named = _isFolded && {_class isNotEqualTo ""};

    if (_named) then {
        _text = format ["%1 - %2", _text, ([_class] call EFUNC(items,getInfo)) getOrDefault ["name", _class]];
    };

    private _textW = (_gripX - _textX - _space) max pixelW;

    [
        _display, _parent, [_textX, _headY, _textW, _lineH], [_text, _textW, _font, _lineSize] call FUNC(fitText), _lineSize,
        [_colorText2, _colorText] select _named, _font, 0, "caption"
    ] call FUNC(uiLabel);

    // The grip: a chevron up over a chevron down, close together, a dash between them - it moves the card up or down.
    // The chevron's picture has room round its stroke: the two overlap by that.
    private _chevronH = _lineH * 0.5;
    private _chevronW = SQUARE(_chevronH);
    private _chevronX = _gripX + (_gripW - _chevronW) / 2;
    private _middle = _headY + _lineH / 2;

    {
        _x params ["_chevronY", "_angle"];

        private _chevron = [_display, _parent, [_chevronX, _chevronY, _chevronW, _chevronH], UI_TEX(icon_chevron_down_ca), _colorText2] call FUNC(uiIcon);

        if (_angle != 0) then {
            _chevron ctrlSetAngle [_angle, 0.5, 0.5, true];
        };
    } forEach [[_middle - _chevronH * 0.82, 180], [_middle - _chevronH * 0.18, 0]];

    private _dashW = _chevronW * 0.85;
    [_display, _parent, [_gripX + (_gripW - _dashW) / 2, _headY + _lineH / 2 - pixelH, _dashW, pixelH * 2], _colorText2] call FUNC(uiPanel);

    [[_left, _headY - pixelH * 2, _gripX - _left, _lineH + pixelH * 4], _slot, _isFolded] call _fnc_foldHit;

    private _gripArea = [_gripX, _headY - pixelH * 2, _gripW, _lineH + pixelH * 4];
    private _grip = [_gripArea] call _fnc_hitBox;
    [_grip, LLSTRING(WeaponCard_Grip)] call FUNC(setTooltip);
    _grip setVariable [QGVAR(id), [_slot, _colorAccent]];
    _grip ctrlAddEventHandler ["MouseButtonDown", {
        params ["_grip", "_button"];

        if (_button != 0) exitWith {};

        (_grip getVariable [QGVAR(id), ["", []]]) params ["_slot", "_color"];

        ["begin", _slot, _color] call FUNC(cardGrip);
    }];

    [_gripArea] call _fnc_keepPresses;
};

// ---------------------------------------------------------------------------
// A weapon's card: its picture or silhouette, its name, and the mark of the weapon in hand.
// ---------------------------------------------------------------------------
private _fnc_weaponCard = {
    params ["_cardRect", "_class", "_caption", "_icon", "_number", "_inHand"];
    _cardRect params ["_cardX", "_cardY", "_cardW", "_cardH"];

    private _empty = _class isEqualTo "";
    private _info = if (_empty) then {createHashMap} else {[_class] call EFUNC(items,getInfo)};
    private _cardRadius = _radius min (_cardH / 4);
    private _padY = _textUnit * 0.22;
    private _padX = SQUARE(_padY);

    [_display, _parent, _cardRect, _theme getOrDefault [["slot", "slotEmpty"] select _empty, [1, 1, 1, 0.035]], _cardRadius] call FUNC(uiPanel);

    // Where the picture and the name may go - right of the strip.
    private _innerX = _cardX;
    private _innerTop = _cardY + _padY;

    if (_flat) then {
        private _stripW = SQUARE(_textUnit * 1.05);

        [_display, _parent, [_cardX, _cardY, _stripW, _cardH], [_colorStrip, _colorAccent] select _inHand] call FUNC(uiPanel);

        // A card with no key to name (the second primary, its mod's key unbound or with modifiers) keeps its strip.
        if (_number isNotEqualTo "") then {
            [
                _display, _parent, [_cardX, _cardY + _padY * 0.5, _stripW, _lineH], format ["[%1]", _number], _lineSize,
                [_colorMuted, _colorOnAccent] select _inHand, _fontBold, 2, "key"
            ] call FUNC(uiLabel);
        };

        _innerX = _cardX + _stripW;
    } else {
        // A bar down the left edge between the round corners, as fnc_drawSlot's accent.
        if (_inHand) then {
            private _bar = [_display, "AIO_PanelRect", _parent, [_cardX, _cardY + _cardRadius, pixelW * 3, _cardH - _cardRadius * 2]] call FUNC(uiCreate);
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
        private _nameSize = _textUnit * 0.5;
        private _nameTop = _cardY + _cardH - _padY * 0.5 - _lineH;
        private _name = [[_info getOrDefault ["name", _class], _theme] call FUNC(caption), _contentW, _font, _nameSize] call FUNC(fitText);

        // The picture keeps at least half the card: where the name's line would leave it less, it reaches to the
        // card's foot and the name goes over it.
        private _pictureBottom = [_nameTop, _cardY + _cardH - _padY] select ((_nameTop - _innerTop) < _cardH * 0.5);
        private _pictureRect = [_contentX, _innerTop, _contentW, (_pictureBottom - _innerTop) max pixelH];

        // As the rules draw it (icon=): larger, smaller or moved, and cut to the card where it would reach out.
        [_display, _parent, _pictureRect, _info getOrDefault ["picture", ""], _info getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 1], _cardRect] call FUNC(uiItemPicture);

        // What is on the weapon shows on its picture, the way Arma's own inventory draws it.
        [_display, _parent, _pictureRect, _weapon] call FUNC(drawAttachments);
        [_display, _parent, [_contentX, _nameTop, _contentW, _lineH], _name, _nameSize, _colorText, _font, 0, "weapon"] call FUNC(uiLabel);
    };

    // The weapon in hand is framed in the accent colour, over everything else on the card.
    if (_flat) then {
        private _frame = [_border, _colorAccent] select _inHand;

        if (_frame isNotEqualTo []) then {
            [_display, _parent, _cardRect, _frame] call FUNC(uiFrame);
        };
    };

    [_cardRect, _class, _caption, _weapon, _slot] call _fnc_register;
};

// ---------------------------------------------------------------------------
// A weapon's row: its header, its card, and its attachments beside it, row by row - or folded, the header alone.
// Returns the row's height.
// ---------------------------------------------------------------------------
private _fnc_weaponRow = {
    params ["_rowTop", "_slot", "_caption", "_icon", "_number", "_cols", "_parts", "_rowFolded"];

    // [class, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod]
    private _weapon = _equipment getOrDefault [_slot, []];
    private _class = _weapon param [0, "", [""]];
    private _cardY = _rowTop + _headH;

    // The second primary hangs on the back: never in hand, even of the same class as the one that is.
    private _inHand = _class isNotEqualTo "" && {_slot isNotEqualTo "primary2"} && {!isNull _unit} && {currentWeapon _unit == _class};

    [_rowTop, _slot, _caption, _number, _inHand, _rowFolded, _class] call _fnc_weaponHeader;

    // Where the grip finds the card (fnc_cardGrip): its header and its card.
    private _rowH = [_headH + _cardH, _lineH] select _rowFolded;

    (uiNamespace getVariable [QGVAR(cardSpans), []]) pushBack [
        _slot, createHashMapFromArray [["rel", [_left, _rowTop]], ["parent", _parent]], _width, _rowH
    ];

    // Folded, the header's line takes a weapon dragged onto it, and names it under the mouse.
    if (_rowFolded) exitWith {
        [[_left, _rowTop, _width, _lineH], _class, _caption, _weapon, _slot] call _fnc_register;

        _lineH
    };

    [[_left, _cardY, _cardW, _cardH], _class, _caption, _icon, _number, _inHand] call _fnc_weaponCard;

    {
        if (_x isEqualTo []) then {continue};

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

    _headH + _cardH
};

// A section's caption: its fold chevron, its words, and over both the hit box that folds or opens the section.
private _fnc_label = {
    params ["_labelTop", "_text", "_key", "_isFolded"];

    [_labelTop, _labelH, _isFolded] call _fnc_chevron;
    [
        _display, _parent, [_left + SQUARE(_labelH), _labelTop, _width - SQUARE(_labelH), _labelH], [_text, _theme] call FUNC(caption),
        _textUnit * 0.55, _colorText2, _font, 0, "section"
    ] call FUNC(uiLabel);

    // Over the words only, not the whole width: the room right of them is the column's.
    private _textW = (([_text, _theme] call FUNC(caption)) getTextWidth [_font, _textUnit * 0.55]) * TEXT_SLACK;

    [[_left, _labelTop, SQUARE(_labelH) + _textW + SQUARE(_textUnit * 0.3), _labelH], _key, _isFolded] call _fnc_foldHit;
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
[_cursor, LLSTRING(Column_Equipment), "equipment", _equipFolded] call _fnc_label;
_cursor = _cursor + _labelH;

// Each card's caption, silhouette, key, attachment columns and attachments: [index in the weapon, caption, silhouette],
// three across, in the same places on every card - muzzle, optic, rail over bipod, magazine, second magazine; [] keeps
// the place of one the weapon has not.
private _muzzle = [1, LLSTRING(Slot_Muzzle), GEAR_ICON(ui_gear_muzzle_gs)];
private _optic = [3, LLSTRING(Slot_Optic), GEAR_ICON(ui_gear_top_gs)];
private _rail = [2, LLSTRING(Slot_Rail), GEAR_ICON(ui_gear_side_gs)];
private _bipod = [6, LLSTRING(Slot_Bipod), GEAR_ICON(ui_gear_bipod_gs)];
private _magazine = [4, LLSTRING(Slot_Magazine), GEAR_ICON(ui_gear_magazine_gs)];
private _magazine2 = [5, LLSTRING(Slot_Magazine2), GEAR_ICON(ui_gear_magazineGL_gs)];
private _rifleParts = [_muzzle, _optic, _rail, _bipod, _magazine, _magazine2];

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
    ["handgun", [LLSTRING(Slot_Handgun), GEAR_ICON(ui_gear_hgun_gs), "2", 3, [_muzzle, _optic, _rail, [], _magazine, []]]],
    ["launcher", [LLSTRING(Slot_Launcher), GEAR_ICON(ui_gear_secondary_gs), "3", 3, [[], _optic, [], [], _magazine, []]]]
];

// In the player's order (see above) - none while the section is folded.
if (!_equipFolded) then {
    {
        (_rows get _x) params ["_rowCaption", "_rowIcon", "_rowNumber", "_rowCols", "_rowParts"];

        _cursor = _cursor + _rowGap + ([
            _cursor, _x, _rowCaption, _rowIcon, _rowNumber, _rowCols, _rowParts, _x in _foldedSlots
        ] call _fnc_weaponRow);
    } forEach _shownOrder;
};

// ---------------------------------------------------------------------------
// Gear, from the bottom of the column up. Both rows spread over the full width.
// ---------------------------------------------------------------------------
private _smallY = _top + _height - _hotbarH - _smallH;
private _gearY = _smallY - _gearGap - _gearH;

[_top + _height - _hotbarH - _gearBlockH - _labelH, LLSTRING(Column_Gear), "gear", _gearFolded] call _fnc_label;

if (!_gearFolded) then {
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
};

// ---------------------------------------------------------------------------
// The hotbar, at the very bottom
// ---------------------------------------------------------------------------
// Its counts follow what the unit carries: on the inventory's own display a part of its own as well, drawn
// again with the weight card (fnc_drawPart, fnc_refresh).
if (_hotbar) then {
    [_top + _height - ([_smallH, 0] select _hotbarFolded) - _labelH, LELSTRING(hotbar,Strip_Title), "hotbar", _hotbarFolded] call _fnc_label;

    if (_hotbarFolded) exitWith {};

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
