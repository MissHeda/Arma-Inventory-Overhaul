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
 *   v [1] Primary ...............................   each weapon a header line - fold chevron, key,
 *   | picture ................................... |   caption - over a card as wide as the column:
 *   | MX 6.5 mm ............ [o][=] [▮ 27/30]     |   its picture, its name, and small pictures of what is
 *   v [4] Second primary ........................   on it and its loaded magazines with their rounds -
 *   | ...                                             nothing for a part it has not. The second primary on
 *   > [2] Handgun - P99 .........................   the back only with WebKnight's or KJW's Two Primary
 *   v [3] Launcher ..............................   Weapons (aio_storage_fnc_secondPrimary); folded: the
 *   | picture ................................... |   header alone, naming the weapon
 *   GEAR
 *   | headgear |  | uniform |  | vest |  | backpack |
 *   | gog | nvg | bin | map | gps | radio | compass | watch |
 *   HOTBAR
 *   | 4 | 5 | 6 | 7 | 8 | 9 | 0 |                           the keys' items (aio_hotbar), when it is loaded
 *                                                              and on, in the inventory window only
 *
 * The weapon cards come in the order the player gave them, primary, second primary, handgun, launcher at first: a
 * card is moved to another place by its header: held CARD_HOLD_TIME seconds, the card lifts off and follows the mouse
 * up or down (GVAR(weaponOrder), fnc_cardGrip).
 * A click on the header folds the card to that line, and opens it again (GVAR(weaponFolds), fnc_toggleWeaponFold) - a
 * folded one still takes a weapon dragged onto its line. The second primary's card starts
 * folded while the back is empty. The column's sections - Equipment, Gear, Hotbar - fold to their caption the same
 * way, a click on it (GVAR(weaponFolds) under "equipment", "gear", "hotbar"). The headers keep their presses to
 * themselves (GVAR(cardButtons), fnc_onMouseButton).
 *
 * The weapon cards are as wide and as tall as each other. The parts have no boxes of their own any more (Mia, #56: half of
 * them stood empty): an attachment or a magazine let go on a card goes on the part of the weapon that takes it
 * (aio_storage_fnc_partFor, fnc_updateDrag), and the parts are changed, put on and taken off in the inspect card's modding
 * view (Modify in the weapon's menu, fnc_drawInspect). The second primary's key names that mod's own switch key, and it is
 * never the weapon in hand. The weapon in hand is marked in the accent colour. The cards' pictures keep at least half the
 * card's height, whatever the text size: the name goes over the picture's foot where the card is too low for both. The
 * cards grow with the height the column has. The weapons stay at the top and the gear and the hotbar at the bottom;
 * whatever height is left over lies between them.
 *
 * A square theme gives each weapon card a strip down its left edge holding its number, and
 * frames the card; a round one (Glass) puts a small key cap in the header instead, as neither a strip
 * nor a frame can follow round corners. The small slots never show a caption on
 * the slot - their silhouettes say what they are for, and the hint names it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Context, see fnc_build - "unit" and "equipment" are read <HASHMAP>
 * 4: Theme <HASHMAP>
 * 5: The parts to draw, of "weight", "weapons", "gear", "hotbar" (EQUIPMENT_PARTS): a part the player placed on its own in the edit
 *    mode is drawn alone in its own panel (fnc_layoutGlass), and the column keeps the others <ARRAY> (default: all)
 *
 * Where each part was drawn goes to aio_gui_partRects, part -> [x, y, w, h], for the edit mode's frames (fnc_openLayoutEditor).
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

params ["_display", "_parent", "_rect", "_context", "_theme", ["_only", EQUIPMENT_PARTS, [[]]]];
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

// The same theme with no captions on the slots, for the small slots.
private _quiet = createHashMap;
_quiet merge _theme;
_quiet set ["slotCaption", "none"];

// ---------------------------------------------------------------------------
// Sizes. The gear first, as it is limited by the width; the weapons share the height that is left.
// ---------------------------------------------------------------------------
private _gapH = UNIT * 0.25;
private _gapW = SQUARE(_gapH);
private _groupGap = UNIT * 0.5;
private _rowGap = UNIT * 0.2;
// What the player switched off goes, and the weapons get its room (aio_gui_showWeight, showGear, showSmallSlots, showHotbar). Read
// from the mission namespace: this is drawn in Eden as well, where CBA runs no settings.
private _showWeight = (missionNamespace getVariable [QGVAR(showWeight), true]) && {"weight" in _only};
private _showGear = (missionNamespace getVariable [QGVAR(showGear), true]) && {"gear" in _only};
private _showSmall = (missionNamespace getVariable [QGVAR(showSmallSlots), true]) && {"gear" in _only};
private _showWeapons = "weapons" in _only;
private _statH = [0, _textUnit * 2.2] select _showWeight;
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
private _hotbar = call FUNC(isInventoryMode) && {!isNil QEFUNC(hotbar,drawStrip)} && {call EFUNC(hotbar,isActive)}
    && {missionNamespace getVariable [QGVAR(showHotbar), true]} && {"hotbar" in _only};

// The column's sections fold to their caption as the weapon cards do (fnc_toggleWeaponFold): what they hold is not
// drawn, and the weapons get the height it leaves.
private _equipFolded = GVAR(weaponFolds) getOrDefault ["equipment", false];
private _gearFolded = GVAR(weaponFolds) getOrDefault ["gear", false];
private _hotbarFolded = GVAR(weaponFolds) getOrDefault ["hotbar", false];
private _hotbarH = [0, _labelH + ([_smallH, 0] select _hotbarFolded) + _groupGap] select _hotbar;
private _gearBlockH = 0;

if (!_gearFolded) then {
    _gearBlockH = ([0, _capH + _gearH] select _showGear) + ([0, _smallH] select _showSmall) + ([0, _gearGap] select (_showGear && _showSmall));
};

private _gearSection = _showGear || _showSmall;

// A fourth card for the second primary on the back, when a two-primary mod gives the unit that slot.
private _second = _equipment getOrDefault ["primary2", -1];
private _hasSecond = _second isEqualType [];

// The weapon cards in the player's order (GVAR(weaponOrder)), and which of them are folded to their header: as the
// player chose (GVAR(weaponFolds)), or until then the second primary while nothing is on the back.
private _shownOrder = [[], GVAR(weaponOrder) select {_x isNotEqualTo "primary2" || _hasSecond}] select _showWeapons;
private _cards = count _shownOrder;
private _foldedSlots = _shownOrder select {GVAR(weaponFolds) getOrDefault [_x, _x isEqualTo "primary2" && {_second isEqualTo []}]};
private _open = _cards - count _foldedSlots;

// Each card has its header line above it, whatever the theme's captions - with a little air under it.
private _headH = _lineH + _textUnit * 0.12;

// Each open weapon card shares the height that is left - as high as the two rows of parts beside it were at most, and never
// higher than half its width, as a weapon's picture is twice as wide as high.
private _fixed = _statH + _groupGap * 2 + _labelH * (([0, 1] select _showWeapons) + ([0, 1] select _gearSection)) + _rowGap * ((_cards - 1) max 0) + _headH * _cards + _gearBlockH + _hotbarH;
private _cardH = (((_height - _fixed) / (_open max 1)) min (UNIT * 5.65) min UNSQUARE(_width * 0.5)) max (UNIT * 2.6);
private _cardW = _width;

// Left over height loosens the gaps between the weapons a little; the rest stays above the gear.
private _extra = (((_height - _fixed - _cardH * _open) / (_cards + 1)) max 0) min (UNIT * 0.15);
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

// A hit box that folds or opens what it heads (fnc_toggleWeaponFold): the key it is kept under, folded now - and for a
// weapon's header what its hold needs to lift the card (fnc_cardGrip "press"): the header's words, as the lifted card
// shows them. A click that ended a hold which lifted the card is not a click: the card was moved, not folded.
private _fnc_foldHit = {
    params ["_area", "_key", "_isFolded", ["_hold", false], ["_holdText", ""], ["_textOffset", 0]];

    private _tip = [LLSTRING(WeaponCard_Fold), LLSTRING(WeaponCard_Unfold)] select _isFolded;

    if (_hold) then {
        _tip = format ["%1 | %2", _tip, LLSTRING(WeaponCard_HoldToMove)];
    };

    private _hit = [_area] call _fnc_hitBox;
    [_hit, _tip] call FUNC(setTooltip);
    _hit setVariable [QGVAR(id), [_key, _isFolded]];
    _hit ctrlAddEventHandler ["ButtonClick", {
        private _id = (_this select 0) getVariable [QGVAR(id), ["", false]];

        if (GVAR(cardHoldTaken) isNotEqualTo "" && {GVAR(cardHoldTaken) isEqualTo (_id select 0)}) exitWith {
            GVAR(cardHoldTaken) = "";
        };

        [{_this call FUNC(toggleWeaponFold)}, _id] call FUNC(later);
    }];

    if (_hold) then {
        _hit setVariable [QGVAR(hold), [
            _key, _colorAccent, createHashMapFromArray [["rel", [_area select 0, _area select 1]], ["parent", _parent]],
            [_area select 2, _area select 3], _holdText, _font, _lineSize, _colorText, _colorOnAccent, _textOffset
        ]];
        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_hit", "_button"];

            if (_button != 0) exitWith {};

            ["press", _hit] call FUNC(cardGrip);

            // Not taken: the button still gets its press, and its click at the release.
            false
        }];
    };

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
// the caption - and the weapon's name after it while folded. The whole line is one hit box: a click folds or opens the
// card, held CARD_HOLD_TIME seconds it lifts the card to move it (fnc_cardGrip) - one place for both, no grip of its
// own. A click runs a frame later (fnc_later), as the window may be built again meanwhile.
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

    private _text = [_caption, _theme] call FUNC(caption);
    private _named = _isFolded && {_class isNotEqualTo ""};

    if (_named) then {
        _text = format ["%1 - %2", _text, ([_class] call EFUNC(items,getInfo)) getOrDefault ["name", _class]];
    };

    private _textW = (_left + _width - _textX - _space) max pixelW;
    private _fitted = [_text, _textW, _font, _lineSize] call FUNC(fitText);

    [
        _display, _parent, [_textX, _headY, _textW, _lineH], _fitted, _lineSize,
        [_colorText2, _colorText] select _named, _font, 0, "caption"
    ] call FUNC(uiLabel);

    [[_left, _headY - pixelH * 2, _width, _lineH + pixelH * 4], _slot, _isFolded, true, _fitted, _textX - _left] call _fnc_foldHit;
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

        // The weapon as it really looks, filmed with what it carries (fnc_cardScene) - with Picture-in-Picture on and the player's
        // setting. The picture has the screen's shape and the card shows its middle, as the inspect card's 3D view (fnc_drawInspect).
        private _real = false;

        if (isPiPEnabled && {missionNamespace getVariable [QGVAR(weapon3D), false]}) then {
            // The whole card, edge to edge and down to its foot: the attachments' plates and the name lie wholly on the picture,
            // not half on it (Mia, 0.6.106), drawn over it after; its corners rounded as the card's.
            // On whole pixels as the card's panel (fnc_uiPanel): else a pixel's line of the card showed under the picture's corner
            // (Mia, 0.6.107).
            private _picX = round (_innerX / pixelW) * pixelW;
            private _picY = round (_cardY / pixelH) * pixelH;
            private _picW = (round ((_cardX + _cardW) / pixelW) * pixelW) - _picX;
            private _picH = (round ((_cardY + _cardH) / pixelH) * pixelH) - _picY;

            private _viewPixelsW = round (_picW / pixelW);
            private _viewPixelsH = round (_picH / pixelH);
            private _aspect = INSPECT_3D_ASPECT;
            private _imagePixelsH = _viewPixelsH max (round (_viewPixelsW / _aspect));
            private _imagePixelsW = _viewPixelsW max (round (_imagePixelsH * _aspect));
            private _textureW = (round (2 ^ ceil ((ln ((_imagePixelsW * INSPECT_3D_SUPER) max 64)) / (ln 2)))) min CARD_3D_MAX_RES;
            private _textureH = round (2 ^ round ((ln (_textureW / _aspect)) / (ln 2)));
            private _target = format ["%1_%2_%3x%4", CARD_3D_TARGET, _slot, _textureW, _textureH];

            // The card's colour over the panel's, as the sphere round the weapon: the picture sits on the card.
            private _panel = _theme getOrDefault ["panel", [0.05, 0.055, 0.065, 0.9]];
            private _film = _theme getOrDefault ["slot", [1, 1, 1, 0.035]];
            private _filmAlpha = _film param [3, 0];
            private _background = [0, 1, 2] apply {((_panel param [_x, 0.05]) * (1 - _filmAlpha)) + ((_film param [_x, 1]) * _filmAlpha)};

            // Behind the weapon the card's own colour, so the picture follows the player's colours (Mia, 0.6.102). Never darker than
            // CARD_3D_BACKDROP: on black the camera's exposure opened up and the weapon came out white (seen in game, 0.6.88).
            // The scene's lights and the camera's own exposure brighten the sphere a lot (a 0.04 grey came out near 0.17, a card's
            // colour near 0.45 - seen in game, 0.6.107/0.6.109), so it is painted darker by CARD_3D_BACKDROP_GAIN to land near the card.
            _background = _background apply {(_x * CARD_3D_BACKDROP_GAIN) max CARD_3D_BACKDROP};

            // How far each slot's camera stands, the player's own (Layout: weapon picture size per slot): 100 % fits the weapon to
            // the card, less shows it smaller. Given as the share of the picture the weapon takes, so a change frames it anew.
            // Both only with "Centre weapon pictures" off (0.7.12): on, the weapon lies in the middle, fitted, and nothing is nudged.
            private _own = !(missionNamespace getVariable [QGVAR(weapon3DAuto), true]);
            private _zoom = [1, (((missionNamespace getVariable [format ["%1_%2", QGVAR(weapon3DZoom), _slot], 100]) / 100) max 0.3) min 2] select _own;

            // And where on the card it lies, the player's own nudge per slot (Mia, 0.6.107), in % of the weapon's length.
            private _offset = ["X", "Y"] apply {[0, (missionNamespace getVariable [format ["%1%2_%3", QGVAR(weapon3DOffset), _x, _slot], 0]) / 100] select _own};

            // The name line lies over the picture's foot: the weapon is fitted to what is free above it and lifted into the middle
            // of that, so no grip or magazine hangs into the name (0.7.10).
            private _strip = (((_picY + _picH - _nameTop) / _picH) max 0) min 0.5;

            _real = ["show", [
                _slot, _weapon, _target, _background,
                [_zoom * _viewPixelsW / _imagePixelsW, _zoom * (1 - _strip) * _viewPixelsH / _imagePixelsH], _offset,
                _strip / 2 * _viewPixelsH / _imagePixelsH
            ]] call FUNC(cardScene);

            if (_real) then {
                _scene3DSlots pushBack _slot;

                private _clip = [_display, "AIO_Group", _parent, [_picX, _picY, _viewPixelsW * pixelW, _viewPixelsH * pixelH]] call FUNC(uiCreate);
                private _view = [
                    _display, "AIO_PictureTurned", _clip,
                    [floor ((_viewPixelsW - _imagePixelsW) / 2) * pixelW, floor ((_viewPixelsH - _imagePixelsH) / 2) * pixelH, _imagePixelsW * pixelW, _imagePixelsH * pixelH]
                ] call FUNC(uiCreate);

                _view ctrlSetText format ["#(argb,%1,%2,1)r2t(%3,%4)", _textureW, _textureH, _target, _aspect toFixed 4];
                _view ctrlEnable false;

                // The group only cuts the picture to the card: off, the mouse wheel no longer scrolls the picture inside it (Mia,
                // 0.6.102) and goes on to the column.
                _clip ctrlEnable false;

                // Round corners as the card's: the outside of a quarter circle in the picture's backdrop colour over each corner.
                private _maskRadius = round (_cardRadius / pixelH) * pixelH;

                if (_maskRadius >= pixelH * 2) then {
                    private _maskW = round (SQUARE(_maskRadius) / pixelW) * pixelW;
                    // The column round the card shows at its corners: the panel's colour.
                    private _maskColor = ((_panel select [0, 3]) apply {_x max 0}) + [1];

                    {
                        _x params ["_texture", "_maskX", "_maskY"];

                        private _mask = [_display, _parent, [_maskX, _maskY, _maskW, _maskRadius], _texture, _maskColor] call FUNC(uiIcon);
                        _mask ctrlEnable false;
                    } forEach [
                        [UI_TEX(mask_tl_ca), _picX, _picY],
                        [UI_TEX(mask_tr_ca), _picX + _picW - _maskW, _picY],
                        [UI_TEX(mask_bl_ca), _picX, _picY + _picH - _maskRadius],
                        [UI_TEX(mask_br_ca), _picX + _picW - _maskW, _picY + _picH - _maskRadius]
                    ];
                };

                // The weapon in hand's bar down the left edge, which the picture now covers: again on top of it.
                if (!_flat && {_inHand}) then {
                    private _bar = [_display, "AIO_PanelRect", _parent, [_cardX, _cardY + _cardRadius, pixelW * 3, _cardH - _cardRadius * 2]] call FUNC(uiCreate);
                    _bar ctrlSetBackgroundColor _colorAccent;
                };
            };
        };

        // What is on it, at the right end of the name's line: a small plate with the picture of each attachment, a loaded magazine's
        // with its rounds on the same plate where it holds more than one, so each count plainly belongs to its magazine - muzzle,
        // optic, rail, bipod, magazine, second magazine from the left, drawn from the right; nothing for a part it has not.
        // [class, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod]
        private _partH = _lineH * 1.15;
        private _partW = SQUARE(_partH);
        private _partsRight = _contentX + _contentW;
        private _partsTop = _nameTop + _lineH - _partH;
        private _ammoSize = _textUnit * 0.42;

        {
            private _value = _weapon param [_x, ""];
            private _partClass = if (_value isEqualType []) then {_value param [0, "", [""]]} else {_value};

            if !(_partClass isEqualType "" && {_partClass isNotEqualTo ""}) then {continue};

            private _partInfo = [_partClass] call EFUNC(items,getInfo);
            private _capacity = _partInfo getOrDefault ["capacity", 0];

            // Rounds beside the magazine's picture, as "27/30" - the loss colour when it is empty.
            private _hasRounds = _value isEqualType [] && {_capacity > 1};
            private _rounds = if (_hasRounds) then {_value param [1, 0, [0]]} else {0};
            private _text = if (_hasRounds) then {format ["%1/%2", _rounds, _capacity]} else {""};
            private _textW = if (_hasRounds) then {(_text getTextWidth [_font, _ammoSize]) * TEXT_SLACK + SQUARE(_textUnit * 0.1)} else {0};

            _partsRight = _partsRight - _partW - _textW;

            private _partRect = [_partsRight, _partsTop, _partW, _partH];

            // On a real weapon picture the plates are the panel's own dark, nearly solid: a see-through film was lost on a light
            // backdrop (Mia, 0.6.109).
            private _plateColor = if (_real) then {
                ((_theme getOrDefault ["panel", [0.05, 0.05, 0.05, 0.9]]) select [0, 3]) + [0.85]
            } else {
                _theme getOrDefault ["slotEmpty", [1, 1, 1, 0.05]]
            };

            [_display, _parent, [_partsRight, _partsTop, _partW + _textW, _partH], _plateColor, _partH * 0.25] call FUNC(uiPanel);

            // Framed thinly in the accent colour, as the parts' boxes of the Attachments view are (fnc_drawHotspots) - faint here: the
            // plates are small and many (Mia, 0.7.12).
            [
                _display, _parent, [_partsRight, _partsTop, _partW + _textW, _partH], (_colorAccent select [0, 3]) + [PLATE_RING_ALPHA], _partH * 0.25
            ] call FUNC(uiRing);
            [
                _display, _parent, _partRect, _partInfo getOrDefault ["picture", ""], _partInfo getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 1], _partRect
            ] call FUNC(uiItemPicture);

            if (_hasRounds) then {
                [
                    _display, _parent, [_partsRight + _partW, _partsTop, _textW, _partH], _text, _ammoSize,
                    [_colorText2, _theme getOrDefault ["loss", [0.9, 0.3, 0.25, 1]]] select (_rounds <= 0), _font, 0, "ammo"
                ] call FUNC(uiLabel);
            };

            _partsRight = _partsRight - SQUARE(_textUnit * 0.12);
        } forEach [5, 4, 6, 2, 3, 1];

        private _name = [
            [_info getOrDefault ["name", _class], _theme] call FUNC(caption), (_partsRight - _contentX - SQUARE(_textUnit * 0.2)) max pixelW, _font, _nameSize
        ] call FUNC(fitText);

        // The picture keeps at least half the card: where the name's line would leave it less, it reaches to the
        // card's foot and the name goes over it.
        private _pictureBottom = [_nameTop, _cardY + _cardH - _padY] select ((_nameTop - _innerTop) < _cardH * 0.5);
        private _pictureRect = [_contentX, _innerTop, _contentW, (_pictureBottom - _innerTop) max pixelH];

        if (!_real) then {
            // As the rules draw it (icon=): larger, smaller or moved, and cut to the card where it would reach out.
            [_display, _parent, _pictureRect, _info getOrDefault ["picture", ""], _info getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 1], _cardRect] call FUNC(uiItemPicture);

            // What is on the weapon shows on its picture, the way Arma's own inventory draws it.
            [_display, _parent, _pictureRect, _weapon] call FUNC(drawAttachments);
        };
        [_display, _parent, [_contentX, _nameTop, (_partsRight - _contentX) max pixelW, _lineH], _name, _nameSize, _colorText, _font, 0, "weapon"] call FUNC(uiLabel);
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
// A weapon's row: its header and its card - or folded, the header alone.
// Returns the row's height.
// ---------------------------------------------------------------------------
private _fnc_weaponRow = {
    params ["_rowTop", "_slot", "_caption", "_icon", "_number", "_rowFolded"];

    // [class, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod]
    private _weapon = _equipment getOrDefault [_slot, []];
    private _class = _weapon param [0, "", [""]];
    private _cardY = _rowTop + _headH;

    // The second primary hangs on the back: never in hand, even of the same class as the one that is.
    private _inHand = _class isNotEqualTo "" && {_slot isNotEqualTo "primary2"} && {!isNull _unit} && {currentWeapon _unit == _class};

    [_rowTop, _slot, _caption, _number, _inHand, _rowFolded, _class] call _fnc_weaponHeader;

    // Where a lifted card finds the cards (fnc_cardGrip): its header and its card.
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

if (_showWeight) then {
    if (isNull _parent) then {
        [_display, "weight", controlNull, _weightRect, {_this call FUNC(drawWeightCard)}, [_unit, _theme]] call FUNC(drawPart);
    } else {
        [_display, _parent, _weightRect, _unit, _theme] call FUNC(drawWeightCard);
    };

    GVAR(partRects) set ["weight", _weightRect];
    _cursor = _cursor + _statH + _groupGap;
};

// ---------------------------------------------------------------------------
// Weapons, from the top down
// ---------------------------------------------------------------------------
private _weaponsTop = _cursor;

if (_showWeapons) then {
    [_cursor, LLSTRING(Column_Equipment), "equipment", _equipFolded] call _fnc_label;
    _cursor = _cursor + _labelH;
};

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
    ["primary", [LLSTRING(Slot_Primary), GEAR_ICON(ui_gear_primary_gs), "1"]],
    ["primary2", [LLSTRING(Slot_SecondPrimary), GEAR_ICON(ui_gear_primary_gs), _keyName]],
    ["handgun", [LLSTRING(Slot_Handgun), GEAR_ICON(ui_gear_hgun_gs), "2"]],
    ["launcher", [LLSTRING(Slot_Launcher), GEAR_ICON(ui_gear_secondary_gs), "3"]]
];

// The slots whose cards show the weapon filmed (fnc_cardScene): the scenes of the others go once the cards are drawn.
private _scene3DSlots = [];

// In the player's order (see above) - none while the section is folded.
if (_showWeapons && {!_equipFolded}) then {
    {
        (_rows get _x) params ["_rowCaption", "_rowIcon", "_rowNumber"];

        _cursor = _cursor + _rowGap + ([
            _cursor, _x, _rowCaption, _rowIcon, _rowNumber, _x in _foldedSlots
        ] call _fnc_weaponRow);
    } forEach _shownOrder;
};

if (_showWeapons) then {
    GVAR(partRects) set ["weapons", [_left, _weaponsTop, _width, (_cursor - _weaponsTop) max _labelH]];

    ["keep", [_scene3DSlots]] call FUNC(cardScene);
};

// ---------------------------------------------------------------------------
// Gear, from the bottom of the column up. Both rows spread over the full width.
// ---------------------------------------------------------------------------
private _smallY = _top + _height - _hotbarH - _smallH;
private _gearY = _top + _height - _hotbarH - _gearH - ([0, _smallH + _gearGap] select _showSmall);

if (_gearSection) then {
    [_top + _height - _hotbarH - _gearBlockH - _labelH, LLSTRING(Column_Gear), "gear", _gearFolded] call _fnc_label;

    GVAR(partRects) set ["gear", [_left, _top + _height - _hotbarH - _gearBlockH - _labelH, _width, _gearBlockH + _labelH]];
};

if (!_gearFolded && {_showGear}) then {
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
};

if (!_gearFolded && {_showSmall}) then {
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

    GVAR(partRects) set ["hotbar", [_left, _top + _height - ([_smallH, 0] select _hotbarFolded) - _labelH, _width, _labelH + ([_smallH, 0] select _hotbarFolded)]];

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
