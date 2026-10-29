#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The window's theme (fnc_layoutGlass), in the feel of Arma's and ACE's own menus. Every column is a
 * near-black, mostly opaque pane with round corners, and what lies on it - cards, slots - is a faint
 * light film, so every layer is a small step brighter. Text is white with grey for the second line, the
 * accent is the player's own active element colour from Arma's Options > Game > Colors (fnc_accentColour; orange
 * without one), and the font is Purista as in vanilla and ACE. Tiles are dark greys tinted by what they are,
 * with their short name and a magazine's ammo bar; captions sit over the slots, in normal case.
 *
 * What is looted is told apart from what the player carries (issue 7) (issue 7, blue look reverted in issue 11) only by the header text; the loot keys stay empty, so it keeps the plain pane -
 * here: the loot column's pane is tinted towards it and ringed in it, its title has an accent strip and icon in it,
 * and the caption tabs and hairlines of its sections are a film of it - still the same near-black glass, only
 * cooler; the player's own column keeps the plain pane and the accent.
 *
 * The palette is written out here rather than taken from fnc_themeBase as it is, so Glass stays Enhanced
 * First Aid Kits' look whatever the base theme turns into. "equipmentPanel", "titleIcons" and
 * "onAccent" are the layout's own keys (fnc_layoutGlass, fnc_drawEquipmentCards).
 *
 * The player's palette (fnc_palette, the header's palette button) is worked in last. Every colour key belongs to exactly one row of
 * the palette and follows that row only; a row the player never touched leaves its keys as written below, so with no choice (or
 * where the server switched the palette off) the theme is what it has always been.
 *
 *   Row           Keys                                       How they follow the row's colour
 *   ------------  -----------------------------------------  ----------------------------------------------------------------------
 *   Accent        accent, accentHover, slotAccent, barFill,  the colour in place of the Arma profile's (fnc_accentColour: brightened
 *                 onAccent                                   where it would sink), the hover and the ink on it worked out from it
 *   Secondary     accentSoft, slotCaptionBg, button,         the tint of these films: each keeps its own strength (alpha) and takes
 *                 buttonHover, barTrack, keyBg               the colour, white being the tint of saturation 0 and value 1;
 *                                                            accentSoft is the colour at ACCENT_SOFT_ALPHA
 *   Panels        panel (its colour), card, tooltipBg,       panel is the colour (fnc_panelColour, kept dark); tooltipBg and inspectBg
 *                 inspectBg                                  are it shifted as far as they lie from the plain panel; card stays a
 *                                                            white film, a step above whatever the panel is
 *   Transparency  panel (its alpha)                          the panels' alpha, 1 down to 0 (fully see-through), nothing else
 *   Cells         cell, slot, slotEmpty                      solid: cell is the colour, the slots it shifted as far as they lie from
 *                                                            the plain cell (kept dark)
 *   Cell          cell, slot, slotEmpty (their alpha)        the empty cells' and slot boxes' alpha, 1 down to 0 (fully see-through)
 *   transparency
 *   Tile          tileBg (its alpha)                         the tiles' alpha, 1 down to 0 (fully see-through), on all five tiles
 *   transparency                                             alike; their hints and the count boxes keep their colours and strengths.
 *                                                            The tiles' colours are no longer the palette's: the setup gives them
 *                                                            by category (category=... color=, fnc_tileColour)
 *   Gradient      accentGradient                             the colour the accent's texts run into, left to right, as Discord's
 *                                                            gradient names do (fnc_uiLabel); [] for plain accent text
 *   Text          text, text2, muted, buttonText, keyText,   the colour times the grey each has against the white text (text2 0.78,
 *                 tileCountColor, slotIcon                   muted 0.56, ...): its dimmer shades
 *   Lines         line, panelBorder, slotBorder, tileBorder  the colour, at strengths that are seen (a hairline at the plain 8 % of a
 *                                                            colour was not): the hairlines, and a frame round the panels, the slot
 *                                                            boxes and the tiles; the hatch stripes are drawn from line
 *   Fixed         dim, lootPanel, lootBorder,                never: the screen's dim is the world behind the window, the loot keys
 *                 lootAccent, lootTab, lootLine, gain,       and the status colours mean something
 *                 loss, warn, info
 *
 * The keys that are no colour (font, radius, slotCaption, hatch, tileName, ...) are the look's own.
 *
 * The cells, the slot boxes and the tiles used to be faint films over the panel (a cell is white at 5 %), so they showed the panel
 * through them and took on its colour and its transparency as well. Now, as soon as the panels' colour or transparency is chosen,
 * they are drawn solid in the very colour they have on the plain panel (a film over what lies under it, worked out once below), and
 * a colour chosen for them is solid too: the panels move alone. Without any of these choices they stay the films they were. The
 * tiles alone can be made see-through on top of that (the tile transparency): they are solid in their colour at the alpha chosen,
 * so the card and the panel show through them, and 0 % is the solid tile as it is without the choice.
 *
 * Readability: the panels, the cells and the tiles are kept dark (value PALETTE_PANEL_VALUE_MAX at most), and the text keys are
 * lifted - their hue kept, made brighter, then towards white - where they would fall below PALETTE_CONTRAST_TEXT,
 * PALETTE_CONTRAST_TEXT2 (text2) and PALETTE_CONTRAST_MUTED (muted) to 1 against the lightest of the three as they are seen. That is a
 * guard, not a tint: at the plain look and with white text nothing moves (only muted, to 0.59, at the lightest panels).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Theme <HASHMAP>
 *
 * Example:
 * private _theme = call einv_gui_fnc_theme;
 *
 * Public: No
 */

private _theme = [] call FUNC(themeBase);

// The accent is the player's own active element colour (fnc_accentColour), read once for the theme; its shades are
// worked out from it. Every key gets a copy of its own.
private _accent = [] call FUNC(accentColour);

// What the player chose in the palette (fnc_palette), each unset where the player chose nothing. A palette saved before a row
// existed reads that row as unset (XEH_preInit), and so do the defaults here.
([] call FUNC(palette)) params [
    "", ["_secondaryPick", [], [[]]], ["_alphaPick", -1, [0]], ["_panelPick", [], [[]]],
    ["_cellsPick", [], [[]]], ["_tilesPick", [], [[]]], ["_textPick", [], [[]]], ["_linesPick", [], [[]]],
    ["_tileAlphaPick", -1, [0]], ["_cellAlphaPick", -1, [0]], ["_gradientPick", [], [[]]]
];

private _tint = [];

if (_secondaryPick isNotEqualTo []) then {
    _tint = ["rgb", _secondaryPick] call FUNC(hsv);
};

private _tileBg = [];
_tileBg set [CATEGORY_MISC, [0.15, 0.15, 0.15, 0.92]];
_tileBg set [CATEGORY_GEAR, [0.18, 0.18, 0.18, 0.92]];
_tileBg set [CATEGORY_WEAPON, [0.14, 0.19, 0.26, 0.92]];
_tileBg set [CATEGORY_AMMO, [0.21, 0.18, 0.09, 0.92]];
_tileBg set [CATEGORY_MEDICAL, [0.12, 0.21, 0.14, 0.92]];

_theme merge [createHashMapFromArray [
    ["id", "main"],
    ["name", LLSTRING(Title)],
    ["font", "PuristaMedium"],
    ["fontBold", "PuristaSemibold"],
    ["upper", false],
    ["radius", UNIT * 0.45],
    ["dim", [0, 0, 0, 0.5]],
    ["panel", [0.05, 0.05, 0.05, PANEL_ALPHA]],
    ["panelBorder", []],
    ["lootPanel", []],
    ["lootBorder", []],
    ["lootAccent", []],
    ["lootTab", []],
    ["lootLine", []],
    ["card", [1, 1, 1, 0.045]],
    ["slot", [1, 1, 1, 0.07]],
    ["slotEmpty", [1, 1, 1, 0.04]],
    ["slotBorder", []],
    ["slotCaption", "above"],
    ["slotCaptionBg", [1, 1, 1, 0.06]],
    ["slotIcon", [1, 1, 1, 0.45]],
    ["slotAccent", +_accent],
    ["hatch", false],
    ["cell", [1, 1, 1, 0.05]],
    ["tileBg", _tileBg],
    ["tileBorder", []],
    ["tileName", true],
    ["tileCount", "text"],
    ["tileCountBg", [0.03, 0.03, 0.03, 0.75]],
    ["tileCountColor", [1, 1, 1, 1]],
    ["raised", [0.27, 0.27, 0.27, 0.92]],
    ["tileAmmoBar", true],
    ["text", [1, 1, 1, 1]],
    ["text2", [0.78, 0.78, 0.78, 1]],
    ["muted", [0.56, 0.56, 0.56, 1]],
    ["accent", +_accent],
    ["accentSoft", ["soft", [_accent, _tint] select (_tint isNotEqualTo [])] call FUNC(accentColour)],
    ["accentHover", ["hover", _accent] call FUNC(accentColour)],
    ["line", [1, 1, 1, 0.08]],
    ["warn", [0.93, 0.75, 0.2, 1]],
    ["tooltipBg", [0.03, 0.03, 0.03, 0.96]],
    ["inspectBg", [0.06, 0.06, 0.06, 0.98]],
    ["barTrack", [1, 1, 1, 0.1]],
    ["barFill", +_accent],
    ["button", [1, 1, 1, 0.07]],
    ["buttonHover", [1, 1, 1, 0.16]],
    ["buttonText", [0.88, 0.88, 0.88, 1]],
    ["keyBg", [1, 1, 1, 0.14]],
    ["keyText", [1, 1, 1, 1]],
    ["keyRound", false],
    ["equipmentPanel", true],
    ["titleIcons", true],
    ["onAccent", ["on", _accent] call FUNC(accentColour)]
], true];

// ----- What the palette works with -----

// Luminance by the weights of sRGB, in a gamma of 2.2.
private _fnc_luma = {
    params ["_rgb"];

    0.2126 * ((_rgb select 0) ^ 2.2) + 0.7152 * ((_rgb select 1) ^ 2.2) + 0.0722 * ((_rgb select 2) ^ 2.2)
};

// A colour as it is seen where it lies, as [r, g, b]: a film mixed with what is under it by its alpha, a solid one as it is, none
// ([]) what is under it.
private _fnc_seen = {
    params ["_color", "_under"];

    if (count _color < 3) exitWith {+_under};

    private _alpha = _color param [3, 1];

    [0, 1, 2] apply {(_color select _x) * _alpha + (_under select _x) * (1 - _alpha)}
};

// A colour moved by the step from one colour to another (from the plain cell to the plain slot, say), each channel kept 0 to 1.
private _fnc_shift = {
    params ["_rgb", "_from", "_to"];

    [0, 1, 2] apply {(((_rgb select _x) + (_to select _x) - (_from select _x)) max 0) min 1}
};

// A chosen colour as [r, g, b], its value cut at the most the row allows.
private _fnc_pickRgb = {
    params ["_pick", "_valueMax"];

    _pick params [["_hue", 0, [0]], ["_saturation", 0, [0]], ["_value", 0, [0]]];

    ["rgb", [_hue, (_saturation max 0) min 1, ((_value max 0) min 1) min _valueMax]] call FUNC(hsv)
};

// Films take a tint: each key keeps its own strength and takes the colour; a key that is [] stays none.
private _fnc_tintFilms = {
    params ["_keys", "_rgb"];

    {
        private _film = _theme getOrDefault [_x, []];

        if (count _film >= 3) then {
            _theme set [_x, _rgb + [_film param [3, 1]]];
        };
    } forEach _keys;
};

// The plain look as it is seen, before any choice: the panel, the card's film over it (what the cells and tiles lie on), and the
// cells, the slot boxes and the tiles over those. What the surfaces are drawn in once the panels change under them, and what a
// colour chosen for them is measured from.
private _plainPanel = (_theme getOrDefault ["panel", PANEL_COLOR]) select [0, 3];
private _plainCard = [_theme getOrDefault ["card", []], _plainPanel] call _fnc_seen;
private _plainCell = [_theme getOrDefault ["cell", []], _plainCard] call _fnc_seen;
private _plainSlot = [_theme getOrDefault ["slot", []], _plainPanel] call _fnc_seen;
private _plainSlotEmpty = [_theme getOrDefault ["slotEmpty", []], _plainPanel] call _fnc_seen;
private _plainTiles = (_theme getOrDefault ["tileBg", []]) apply {[_x, _plainCard] call _fnc_seen};
private _plainTile = _plainTiles param [CATEGORY_MISC, _plainCard];
private _plainText = (_theme getOrDefault ["text", [1, 1, 1, 1]]) select [0, 3];

// ----- Secondary and Lines: the tint of their films -----

if (_tint isNotEqualTo []) then {
    [["slotCaptionBg", "button", "buttonHover", "barTrack", "keyBg"], _tint] call _fnc_tintFilms;
};

// Lines: the hairlines and a frame round the panels, the slot boxes and the tiles, each at a strength that is seen.
if (_linesPick isNotEqualTo []) then {
    private _lineRgb = [_linesPick, 1] call _fnc_pickRgb;

    _theme set ["line", _lineRgb + [0.3]];
    _theme set ["panelBorder", _lineRgb + [0.5]];
    _theme set ["slotBorder", _lineRgb + [0.3]];
    _theme set ["tileBorder", _lineRgb + [0.22]];
};

// The gradient of the accent's texts (fnc_uiLabel).
_theme set ["accentGradient", [[], ([_gradientPick, 1] call _fnc_pickRgb) + [1]] select (_gradientPick isNotEqualTo [])];

// ----- Panels and Transparency -----

private _panelRgb = +_plainPanel;

if (_panelPick isNotEqualTo []) then {
    _panelRgb = [] call FUNC(panelColour);

    // The darker card under the comparison and the mouse's name and the lighter one of the inspect card and kit windows keep their
    // step from the panel.
    {
        private _pane = _theme getOrDefault [_x, []];

        if (count _pane >= 3) then {
            _theme set [_x, ([_panelRgb, _plainPanel, _pane] call _fnc_shift) + [_pane param [3, 1]]];
        };
    } forEach ["tooltipBg", "inspectBg"];
};

// The panels moved under the cells, slots and tiles: their colour, their transparency or both.
private _panelsMoved = _panelPick isNotEqualTo [] || {_alphaPick >= 0};

if (_panelsMoved) then {
    private _panelAlpha = (_theme getOrDefault ["panel", []]) param [3, PANEL_ALPHA];

    if (_alphaPick >= 0) then {
        _panelAlpha = (_alphaPick max PALETTE_ALPHA_MIN) min 1;
    };

    _theme set ["panel", _panelRgb + [_panelAlpha]];
};

// ----- Cells: the empty grid cells and the slot boxes, solid (or see-through by the cell transparency) -----

private _cellAlpha = [1, (_cellAlphaPick max PALETTE_ALPHA_MIN) min 1] select (_cellAlphaPick >= 0);

if (_cellsPick isNotEqualTo []) then {
    private _cellRgb = [_cellsPick, PALETTE_PANEL_VALUE_MAX] call _fnc_pickRgb;

    _theme set ["cell", _cellRgb + [_cellAlpha]];
    _theme set ["slot", ([_cellRgb, _plainCell, _plainSlot] call _fnc_shift) + [_cellAlpha]];
    _theme set ["slotEmpty", ([_cellRgb, _plainCell, _plainSlotEmpty] call _fnc_shift) + [_cellAlpha]];
} else {
    if (_panelsMoved || {_cellAlphaPick >= 0}) then {
        _theme set ["cell", _plainCell + [_cellAlpha]];
        _theme set ["slot", _plainSlot + [_cellAlpha]];
        _theme set ["slotEmpty", _plainSlotEmpty + [_cellAlpha]];
    };
};

// ----- Tiles: the item tiles' backgrounds, solid (or see-through by the tile transparency), and the boxes of their counts -----

// The alpha of every tile: 1 (solid) unless the player made the tiles see-through. The item-kind hints are in the colours, not the
// alpha, so a weapon's blue and a medical item's green stay with every alpha.
private _tileAlpha = [1, (_tileAlphaPick max PALETTE_ALPHA_MIN) min 1] select (_tileAlphaPick >= 0);

// The tiles' colours are the setup's (by category, fnc_tileColour) - a Tiles colour of an older palette is left alone.
if (_panelsMoved || {_tileAlphaPick >= 0}) then {
    _theme set ["tileBg", _plainTiles apply {_x + [_tileAlpha]}];
};

// ----- Text: the colour and its dimmer shades -----

if (_textPick isNotEqualTo []) then {
    private _textRgb = [_textPick, 1] call _fnc_pickRgb;

    {
        private _key = _x;
        private _ink = _theme getOrDefault [_key, []];

        if (count _ink >= 3) then {
            private _shade = [0, 1, 2] apply {(((_textRgb select _x) * (_ink select _x) / ((_plainText select _x) max 0.001)) max 0) min 1};

            _theme set [_key, _shade + [_ink param [3, 1]]];
        };
    } forEach ["text", "text2", "muted", "buttonText", "keyText", "tileCountColor", "slotIcon"];
};

// The text keeps its contrast with the lightest of what it lies on as it is seen: the panel, the cells (over the card), the tiles,
// the raised boxes and count backdrops (over a tile) and the tooltip and inspect cards (over the panel).
private _cardSeen = [_theme getOrDefault ["card", []], _panelRgb] call _fnc_seen;
private _grounds = [_panelRgb, [_theme getOrDefault ["cell", []], _cardSeen] call _fnc_seen];

{
    _grounds pushBack ([_x, _cardSeen] call _fnc_seen);
} forEach (_theme getOrDefault ["tileBg", []]);

private _tileSeen = _grounds select 0;

{
    if (([_x] call _fnc_luma) > ([_tileSeen] call _fnc_luma)) then {_tileSeen = _x};
} forEach _grounds;

{
    _grounds pushBack ([_theme getOrDefault [_x, []], _tileSeen] call _fnc_seen);
} forEach ["raised", "tileCountBg"];

{
    _grounds pushBack ([_theme getOrDefault [_x, []], _panelRgb] call _fnc_seen);
} forEach ["tooltipBg", "inspectBg"];

private _groundLuma = selectMax (_grounds apply {[_x] call _fnc_luma});

// Brightens a colour, its hue kept, until its luminance reaches the one asked: scaled up until its brightest channel is 1, then
// mixed towards white. The step between the colour as it is (0) and white (2) is halved twelve times: the least change, to a
// 4096th. A neutral grey comes out as (c * (ground + 0.05) - 0.05) ^ (1 / 2.2), the grey that just keeps the contrast c.
private _fnc_lift = {
    params ["_rgb", "_minLuma"];

    if (([_rgb] call _fnc_luma) >= _minLuma) exitWith {_rgb};

    private _top = (selectMax _rgb) max 0.001;

    private _fnc_at = {
        params ["_step"];

        if (_step <= 1) exitWith {
            private _gain = 1 + _step * (1 / _top - 1);

            _rgb apply {(_x * _gain) min 1}
        };

        _rgb apply {
            private _full = (_x / _top) min 1;

            _full + (1 - _full) * (_step - 1)
        }
    };

    private _low = 0;
    private _high = 2;

    for "_i" from 1 to 12 do {
        private _middle = (_low + _high) / 2;

        if (([[_middle] call _fnc_at] call _fnc_luma) >= _minLuma) then {
            _high = _middle;
        } else {
            _low = _middle;
        };
    };

    [_high] call _fnc_at
};

{
    _x params ["_key", "_contrast"];

    private _ink = _theme getOrDefault [_key, []];

    if (count _ink >= 3) then {
        private _lifted = [_ink select [0, 3], _contrast * (_groundLuma + 0.05) - 0.05] call _fnc_lift;

        _theme set [_key, _lifted + [_ink param [3, 1]]];
    };
} forEach [
    ["text", PALETTE_CONTRAST_TEXT],
    ["text2", PALETTE_CONTRAST_TEXT2],
    ["muted", PALETTE_CONTRAST_MUTED],
    ["buttonText", PALETTE_CONTRAST_TEXT],
    ["keyText", PALETTE_CONTRAST_TEXT],
    ["tileCountColor", PALETTE_CONTRAST_TEXT]
];

_theme
