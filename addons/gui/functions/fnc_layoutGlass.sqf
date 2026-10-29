#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lays out the window, Enhanced First Aid Kits' glass:
 *
 *   | equipment |        free        | loot | storage |
 *
 * On the left what the unit wears, as cards (fnc_drawEquipmentCards). On the right its uniform, vest
 * and backpack stacked in one scrolling column titled "Your gear", and while it loots a second column for
 * that, titled with what is looted ("Loot - Miller", "Loot - Nearby" when it only shows what lies around) and
 * drawn in the theme's loot look (fnc_drawColumn) - the middle gets narrower for it. By
 * default the loot column opens left of the storage column, which stays where it is; the client setting
 * einv_gui_lootSide can have it open at the right edge instead, with the storage column moving in
 * (| storage | loot |). The middle stays free: an open kit's window
 * opens there (fnc_placeWindow). Kits never bring the loot column in: they float over the columns in
 * windows of their own (fnc_drawWindows).
 *
 * A storage column is as wide as its grid needs (fnc_getCell), so it is the same in every look. The
 * equipment column takes about a third of the screen; where the screen is too narrow for everything
 * (4:3 while looting), the middle gives way first, then the equipment column - nothing overlaps.
 *
 * The theme decides between cards floating on their own and a pane under them ("equipmentPanel"),
 * and whether the column titles carry icons ("titleIcons"). Every panel goes into GVAR(panels): an
 * item let go outside all of them goes on the ground (fnc_updateDrag).
 *
 * A window that attached (fnc_attach) may ask for more through the context, all optional: "rightColumn"
 * keeps the loot column's place without drawing it, "rightGrow" and "rightKeep" let that column grow
 * (above), its rectangle comes back as "rightRect" - [x, y, w, h], not added to GVAR(panels): whoever
 * draws there does that - and "storageSections" is what the storage column shows instead of the unit's
 * own sections.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Theme <HASHMAP>
 * 2: Context, see fnc_build <HASHMAP>
 *
 * Return Value:
 * The free middle, [x, y, w, h] on the screen - [] when it is too narrow <ARRAY>
 *
 * Example:
 * [_display, _theme, _context] call einv_gui_fnc_layoutGlass;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_theme", "_context"];

(call FUNC(getCell)) params ["_cellW"];

private _gap = COLUMN_GAP;

// The padding fnc_drawColumn gives its sections. The equipment column keeps to the same top, so its
// first card lines up with the storage column's title.
private _padY = UNIT * 0.4;
private _padX = SQUARE(_padY);
private _titleIcons = _theme getOrDefault ["titleIcons", true];

// A storage column: the container's picture box and its compartments beside it (fnc_drawSection), the
// column's padding - the right one wide enough for the scroll bar - and a little air. The same measure
// caps the player's tile scale (fnc_getCell), so the two can never disagree.
private _columnW = COLUMN_W(_cellW);

// The columns from the right edge inwards: storage and loot (while looting, in the order set below), then the
// middle. A window that attached keeps the place of the loot column although nothing is looted (the context's
// "rightColumn": it draws there itself) and may let it grow by what the middle has beyond "rightKeep" UNITs
// of width - at most "rightGrow" of a column - so a wide screen does not leave the soldier a hall.
private _looting = _context getOrDefault ["looting", false];
private _reserved = _looting || {_context getOrDefault ["rightColumn", false]};
private _rightW = _columnW;

// About a third of the screen, but no wider on ultra wide screens than the cards look good at.
private _leftW = (safezoneW * 0.3) min SQUARE(UNIT * 22);

if (_reserved) then {
    // What the middle would be with a loot column of the usual width: three gaps, two columns.
    private _middleW = CONTENT_W - _leftW - _gap * 3 - _columnW * 2;
    private _keep = _context getOrDefault ["rightKeep", 0];
    private _growBy = _context getOrDefault ["rightGrow", 0];
    private _grow = (_middleW - SQUARE(UNIT * _keep)) max 0;

    _rightW = _columnW + (_grow min (_growBy * _columnW));
};

private _right = CONTENT_X + CONTENT_W;

// Where the loot column goes is the player's own taste (the setting einv_gui_lootSide): by default it opens
// left of the storage column, which then never moves - looting or not, the storage column stands at the right
// edge - and the other way round, the loot column takes the right edge and the storage column moves in. A
// window that kept the right edge for itself ("rightColumn") has no say in it: its column stays there. The
// column widths and the gaps are the same either way, so the free middle is just as wide, only it lies
// against the loot column instead of the storage column.
private _lootLeft = _looting
    && {!(_context getOrDefault ["rightColumn", false])}
    && {GVAR(lootSide) isNotEqualTo "right"};

private _lootX = 0;
private _storageX = 0;

if (_lootLeft) then {
    _storageX = _right - _columnW;
    _lootX = _storageX - _gap - _rightW;
    _right = _lootX - _gap;
} else {
    _lootX = _right - _rightW;

    if (_reserved) then {
        _right = _lootX - _gap;
    };

    _storageX = _right - _columnW;
    _right = _storageX - _gap;
};

if (_reserved) then {
    _context set ["rightRect", [_lootX, CONTENT_Y, _rightW, CONTENT_H]];
};

_leftW = _leftW min ((_right - CONTENT_X) max 0);

// ----- Equipment -----

GVAR(panels) pushBack [CONTENT_X, CONTENT_Y, _leftW, CONTENT_H];

// Anything let go over it goes into the slot that takes it (fnc_updateDrag).
GVAR(equipmentRect) = [CONTENT_X, CONTENT_Y, _leftW, CONTENT_H];

private _cardsRect = if (_theme getOrDefault ["equipmentPanel", true]) then {
    [
        _display, controlNull, [CONTENT_X, CONTENT_Y, _leftW, CONTENT_H], _theme getOrDefault ["panel", []],
        _theme getOrDefault ["radius", 0], _theme getOrDefault ["panelBorder", []]
    ] call FUNC(uiPanel);

    [CONTENT_X + _padX, CONTENT_Y + _padY, _leftW - _padX * 2, CONTENT_H - _padY * 2]
} else {
    [CONTENT_X, CONTENT_Y + _padY, _leftW, CONTENT_H - _padY * 2]
};

[_display, controlNull, _cardsRect, _context, _theme] call FUNC(drawEquipmentCards);

// ----- Storage -----

private _ownSections = _context getOrDefault ["storageSections", _context getOrDefault ["ownSections", []]];

[
    _display, [_storageX, CONTENT_Y, _columnW, CONTENT_H], _ownSections, _theme,
    LLSTRING(Column_Storage), ["", UI_TEX(icon_inventory_ca)] select _titleIcons, QFUNC(drawSection), "storage"
] call FUNC(drawColumn);

// Without a uniform, vest or backpack the column would stand there empty, as if something had failed.
if (_ownSections isEqualTo []) then {
    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _size = TEXT_UNIT * 0.6;
    private _textW = _columnW - _padX * 4;

    [
        _display, controlNull, [_storageX + _padX * 2, CONTENT_Y + UNIT * 2.4, _textW, UNIT],
        [LLSTRING(Storage_Empty), _textW, _font, _size] call FUNC(fitText), _size,
        _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _font, 2
    ] call FUNC(uiLabel);
};

// ----- Loot -----

if (_looting) then {
    private _lootSections = _context getOrDefault ["lootSections", []];

    // Named after what is looted: the first section is the body, the crate or the ground the window was
    // opened on - and when that is only something lying nearby, nothing was opened: "Nearby".
    private _first = _lootSections param [0, createHashMap];
    private _title = _first getOrDefault ["title", ""];
    private _icon = switch (_first getOrDefault ["id", ""]) do {
        case "worn": {UI_TEX(icon_person_ca)};
        case "ground": {UI_TEX(icon_ground_ca)};
        case "container": {UI_TEX(icon_crate_ca)};
        default {UI_TEX(icon_inventory_ca)};
    };

    // A pile opened on is "Ground" however many others lie around (its section is named by its largest
    // item then, to tell the piles apart).
    if ((_first getOrDefault ["id", ""]) isEqualTo "ground") then {
        _title = localize ELSTRING(storage,Ground);
    };

    if (_first getOrDefault ["nearby", false]) then {
        _title = LLSTRING(Column_Nearby);
        _icon = UI_TEX(icon_ground_ca);
    };

    // "Loot - Miller", "Loot - Nearby": the column says that it is someone else's before it says whose (issue 7), as the
    // player's own says "Your gear"; drawColumn gives it the theme's loot look by its id.
    _title = if (_title isEqualTo "") then {LLSTRING(Column_Loot)} else {format [LLSTRING(Column_LootOf), _title]};

    [
        _display, [_lootX, CONTENT_Y, _rightW, CONTENT_H], _lootSections, _theme, _title, ["", _icon] select _titleIcons,
        QFUNC(drawSection), "loot"
    ] call FUNC(drawColumn);
};

// ----- The free middle -----

private _middleX = CONTENT_X + _leftW + _gap;
private _middleW = _right - _middleX;

if (_middleW < SQUARE(UNIT * 5)) exitWith {[]};

[_middleX, CONTENT_Y, _middleW, CONTENT_H]
