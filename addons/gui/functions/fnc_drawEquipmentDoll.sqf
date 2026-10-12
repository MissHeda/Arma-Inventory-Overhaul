#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the Tarkov look's paper doll: what a unit wears, as slots in rows, each with its caption on a
 * tab - and behind them, faintly, a soldier standing.
 *
 *   EARPIECE  | HEADWEAR   | FACE COVER
 *   UNIFORM   | BODY ARMOR | BACKPACK
 *   ON SLING               | HOLSTER
 *   ON BACK                | BINOCULAR
 *   EYEWEAR | MAP | GPS | COMPASS | WATCH
 *
 * Uniform, body armor and backpack - the three that hold things - stand together, in the order their
 * sections follow under a body's doll; the eyewear (night vision) is one of the small slots (Mia, 0.2.3:
 * a body had no backpack slot to take one off or put one on).
 *
 * A weapon's slot is wide, about 2.3 squares; the three slots of each upper row spread out over the
 * same width, so the doll's edges line up. The player's doll fills the gear panel with square slots,
 * as big as the room allows. A body's doll is compact: low, wide slots in the loot column, as wide as
 * the containers under it, and no soldier behind them.
 *
 * Weapons show their short name in the top right corner and their magazine's rounds in big digits in
 * the bottom right. Their attachments are not slots of their own here, as in Tarkov - the hint names
 * them (fnc_updateHover). A caption that would not fit its slot whole is left off; the slot keeps it
 * for the hint, and the silhouette of an empty one still says what belongs there.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in, or controlNull for the display <CONTROL>
 * 2: Room [x, y, w, h] - h is how tall the doll may get, -1 for as tall as it needs <ARRAY>
 * 3: Equipment, see einv_storage_fnc_getEquipment <HASHMAP>
 * 4: Theme <HASHMAP>
 * 5: Compact - a body's doll in the loot column <BOOL> (default: false)
 * 6: Whose gear it is, so its slots can be taken off and put on <OBJECT> (default: objNull)
 *
 * Return Value:
 * Height used, from the top of the room <NUMBER>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.2, 0.4, 0.7], [player] call einv_storage_fnc_getEquipment, _theme] call einv_gui_fnc_drawEquipmentDoll;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_equipment", "_theme", ["_compact", false], ["_unit", objNull]];
_rect params ["_left", "_top", "_width", ["_height", -1]];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]];

// The caption tab as fnc_drawSlot draws it, to know how much of the slot's top it takes.
private _lineH = UNIT * 0.62;
private _lineSize = UNIT * 0.46;

// ---------------------------------------------------------------------------
// Sizes, in whole pixels: the slots are see-through, so their edges and gaps should not shift by a
// pixel from one to the next.
// ---------------------------------------------------------------------------
private _gapH = round (UNIT * ([0.3, 0.22] select _compact) / pixelH) * pixelH;
private _gapW = round (_gapH / pixelH) * pixelW;
private _colW = 0;
private _rowH = 0;

// The widest row is a weapon's slot (2.3 squares), a gap and a square slot.
if (_compact) then {
    _colW = floor (((_width - _gapW) / 3.3) / pixelW) * pixelW;
    _rowH = round (UNIT * 2.8 / pixelH) * pixelH;
} else {
    // Square slots: four rows and the small row (about two thirds of a slot) have to fit the height,
    // the widest row the width. Capped, so a big screen gets room around the doll rather than giant
    // boxes.
    private _byWidth = UNSQUARE((_width - _gapW) / 3.3);
    private _byHeight = if (_height > 0) then {(_height - _gapH * 4) / 4.7} else {_byWidth};
    private _pixels = floor ((_byWidth min _byHeight min (UNIT * 5.5)) / pixelH);

    _rowH = _pixels * pixelH;
    _colW = _pixels * pixelW;
};

private _wideW = round (_colW * 2.3 / pixelW) * pixelW;
private _dollW = _wideW + _gapW + _colW;
private _smallW = floor (((_dollW - _gapW * 4) / 5) / pixelW) * pixelW;
private _smallH = if (_compact) then {_rowH} else {round (_smallW / pixelW) * pixelH};
private _dollH = _rowH * 4 + _smallH + _gapH * 4;

if (_colW <= 0 || {_rowH <= 0}) exitWith {0};

// Centred across the room, and down it where the room has a height. Counted from the group's corner
// inside one, so the corner lands on a pixel there too.
private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _offsetY = if (!_compact && {_height > 0}) then {((_height - _dollH) / 2) max 0} else {0};
private _x0 = _originX + round ((_left + (((_width - _dollW) / 2) max 0) - _originX) / pixelW) * pixelW;
private _y0 = _originY + round ((_top + _offsetY - _originY) / pixelH) * pixelH;

// ---------------------------------------------------------------------------
// The soldier behind the slots - first, so everything lies on it.
// ---------------------------------------------------------------------------
if (!_compact) then {
    [_display, _parent, [_x0, _y0, _dollW, _dollH], UI_TEX(silhouette_ca), (_colorText select [0, 3]) + [0.08]] call FUNC(uiIcon);
};

// ---------------------------------------------------------------------------
// The slots
// ---------------------------------------------------------------------------

// A slot's look varies twice: an empty one gets a faint frame instead of the light one, and one whose
// caption does not fit gets no tab. Four copies of the theme, made once.
private _themes = [[false, true], [false, false], [true, true], [true, false]] apply {
    _x params ["_empty", "_tab"];

    private _variant = createHashMap;
    _variant merge _theme;

    if (_empty) then {
        _variant set ["slotBorder", _theme getOrDefault ["line", [1, 1, 1, 0.1]]];
    };

    // On a tab in the slot's corner, whatever the look puts elsewhere: the rows are laid out for that,
    // with no room for a caption above a slot.
    _variant set ["slotCaption", ["none", "tab"] select _tab];

    _variant
};

// The left edge of the n-th of several slots spread over the doll's width, the first flush left and the
// last flush right, on a whole pixel.
private _fnc_spreadX = {
    params ["_index", "_count", "_slotW"];
    _x0 + round (_index * (_dollW - _slotW) / (_count - 1) / pixelW) * pixelW
};

private _fnc_cellX = {
    params ["_col"];
    [_col, 3, _colW] call _fnc_spreadX
};

private _fnc_rowY = {
    params ["_row"];
    _y0 + _row * (_rowH + _gapH)
};

private _sideX = _x0 + _wideW + _gapW;
private _smallY = [4] call _fnc_rowY;

private _slots = [
    ["radio", LLSTRING(Tarkov_Earpiece), GEAR_ICON(ui_gear_radio_gs), [[0] call _fnc_cellX, [0] call _fnc_rowY, _colW, _rowH]],
    ["headgear", LLSTRING(Tarkov_Headwear), GEAR_ICON(ui_gear_helmet_gs), [[1] call _fnc_cellX, [0] call _fnc_rowY, _colW, _rowH]],
    ["goggles", LLSTRING(Tarkov_FaceCover), GEAR_ICON(ui_gear_glasses_gs), [[2] call _fnc_cellX, [0] call _fnc_rowY, _colW, _rowH]],
    ["uniform", LLSTRING(Tarkov_Uniform), GEAR_ICON(ui_gear_uniform_gs), [[0] call _fnc_cellX, [1] call _fnc_rowY, _colW, _rowH]],
    ["vest", LLSTRING(Tarkov_BodyArmor), GEAR_ICON(ui_gear_vest_gs), [[1] call _fnc_cellX, [1] call _fnc_rowY, _colW, _rowH]],
    ["backpack", LLSTRING(Tarkov_Backpack), GEAR_ICON(ui_gear_backpack_gs), [[2] call _fnc_cellX, [1] call _fnc_rowY, _colW, _rowH]],
    ["primary", LLSTRING(Tarkov_OnSling), GEAR_ICON(ui_gear_primary_gs), [_x0, [2] call _fnc_rowY, _wideW, _rowH]],
    ["handgun", LLSTRING(Tarkov_Holster), GEAR_ICON(ui_gear_hgun_gs), [_sideX, [2] call _fnc_rowY, _colW, _rowH]],
    ["launcher", LLSTRING(Tarkov_OnBack), GEAR_ICON(ui_gear_secondary_gs), [_x0, [3] call _fnc_rowY, _wideW, _rowH]],
    ["binocular", LLSTRING(Tarkov_Binocular), GEAR_ICON(ui_gear_binocular_gs), [_sideX, [3] call _fnc_rowY, _colW, _rowH]],
    ["nvg", LLSTRING(Tarkov_Eyewear), GEAR_ICON(ui_gear_nvg_gs), [[0, 5, _smallW] call _fnc_spreadX, _smallY, _smallW, _smallH]],
    ["map", LLSTRING(Tarkov_Map), GEAR_ICON(ui_gear_map_gs), [[1, 5, _smallW] call _fnc_spreadX, _smallY, _smallW, _smallH]],
    ["gps", LLSTRING(Tarkov_Gps), GEAR_ICON(ui_gear_gps_gs), [[2, 5, _smallW] call _fnc_spreadX, _smallY, _smallW, _smallH]],
    ["compass", LLSTRING(Tarkov_Compass), GEAR_ICON(ui_gear_compass_gs), [[3, 5, _smallW] call _fnc_spreadX, _smallY, _smallW, _smallH]],
    ["watch", LLSTRING(Tarkov_Watch), GEAR_ICON(ui_gear_watch_gs), [[4, 5, _smallW] call _fnc_spreadX, _smallY, _smallW, _smallH]]
];

{
    _x params ["_key", "_caption", "_icon", "_slotRect"];
    _slotRect params ["_slotX", "_slotY", "_slotW", "_slotH"];

    // Weapons come as [class, muzzle, rail, optic, [magazine, rounds] or [], ...], everything else as
    // its class.
    private _value = _equipment getOrDefault [_key, ""];
    private _isWeapon = _value isEqualType [];
    private _class = if (_isWeapon) then {_value param [0, ""]} else {_value};

    if !(_class isEqualType "") then {
        _class = "";
    };

    private _empty = _class isEqualTo "";
    private _tabW = (([_caption, _theme] call FUNC(caption)) getTextWidth [_fontBold, _lineSize]) * TEXT_SLACK + SQUARE(_lineH * 0.5);
    private _tab = _tabW <= _slotW;
    private _slotTheme = _themes select (2 * parseNumber _empty + parseNumber !_tab);

    // A body's weapon goes along with its slot, so the hint names that weapon's attachments.
    [
        _display, _parent, _slotRect, _class,
        createHashMapFromArray [["caption", _caption], ["icon", _icon], ["weapon", [[], _value] select _isWeapon], ["slot", _key], ["unit", _unit]],
        _slotTheme
    ] call FUNC(drawSlot);

    // A weapon in hand or on the back: its short name beside the tab, its rounds in the bottom right.
    // A designator's battery is no magazine to anyone, so binoculars get neither.
    if (_empty || {!_isWeapon} || {_key isEqualTo "binocular"}) then {continue};

    private _info = [_class] call EFUNC(items,getInfo);
    private _padY = (_slotH * 0.08) min (UNIT * 0.25);
    private _padX = SQUARE(_padY);
    private _nameX = _slotX + _padX + ([0, _tabW] select _tab);
    private _room = _slotX + _slotW - _padX - _nameX;

    if (_room > SQUARE(UNIT * 1.2)) then {
        private _name = [_info getOrDefault ["short", _class], _room, _font, _lineSize] call FUNC(fitText);

        [_display, _parent, [_nameX, _slotY, _room, _lineH], _name, _lineSize, _colorText2, _font, 1] call FUNC(uiLabel);
    };

    private _magazine = _value param [4, []];

    if (_magazine isEqualType [] && {_magazine isNotEqualTo []}) then {
        private _rounds = _magazine param [1, 0];
        private _capacity = ([_magazine param [0, ""]] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0];

        // A single rocket or grenade is no count worth showing.
        if (_capacity > 1) then {
            private _size = UNIT * ([0.8, 0.62] select _compact);
            private _boxH = _size * 1.15;

            [
                _display, _parent, [_slotX + _padX, _slotY + _slotH - _padY * 0.5 - _boxH, _slotW - _padX * 2, _boxH],
                format ["%1/%2", _rounds, _capacity], _size, _colorText, _fontBold, 1
            ] call FUNC(uiLabel);
        };
    };
} forEach _slots;

(_y0 - _top) + _dollH
