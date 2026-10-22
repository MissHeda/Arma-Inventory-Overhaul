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
 * The player's palette (fnc_palette, the header's palette button) is worked in last: the accent through fnc_accentColour,
 * the secondary colour - the tint of every faint film of the panes (cards, slots, caption tabs, cells, buttons and what lights
 * under the mouse, the hairlines and bar tracks) and of the soft accent (accentSoft: queued tiles, picked rows, banners), a
 * white film being the tint of saturation 0 and value 1 - the panels' colour (fnc_panelColour: kept dark, value 0.3 at most) and
 * the panels' alpha. A panel colour the player chose also lifts the greys of "text2" and "muted" where they would fall below
 * PALETTE_CONTRAST_TEXT2 and PALETTE_CONTRAST_MUTED to 1 against it (white text keeps 8 : 1 at the darkest the palette allows
 * and needs nothing). With no choice (or where the server switched the palette off) the theme is what it has always been.
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

private _theme = call FUNC(themeBase);

// The accent is the player's own active element colour (fnc_accentColour), read once for the theme; its shades are
// worked out from it. Every key gets a copy of its own.
private _accent = [] call FUNC(accentColour);

// The player's secondary colour, panel colour and panel transparency (fnc_palette), unset where the player chose nothing.
([] call FUNC(palette)) params ["", "_secondaryPick", "_alphaPick", "_panelPick"];

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
    ["dimCamera", [0, 0, 0, 0.25]],
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

// The secondary colour tints the films: each keeps its own strength, only its colour changes (vividness 0 is the white they had).
if (_tint isNotEqualTo []) then {
    {
        _theme set [_x, _tint + [(_theme get _x) select 3]];
    } forEach ["card", "slot", "slotEmpty", "slotCaptionBg", "cell", "line", "button", "buttonHover", "barTrack", "keyBg"];
};

// The panels' colour and alpha: the player's own, within what the palette offers - the colour kept dark (fnc_panelColour).
if (_panelPick isNotEqualTo [] || {_alphaPick >= 0}) then {
    private _panel = +(_theme get "panel");

    if (_panelPick isNotEqualTo []) then {
        private _panelRgb = [] call FUNC(panelColour);

        _panel set [0, _panelRgb select 0];
        _panel set [1, _panelRgb select 1];
        _panel set [2, _panelRgb select 2];

        // The light greys keep their contrast with the lighter panel: a neutral grey g has the luminance g ^ 2.2, and the contrast is
        // (luminance + 0.05) / (panel + 0.05), so the grey that just keeps a contrast c is (c * (panel + 0.05) - 0.05) ^ (1 / 2.2).
        private _panelLuma = 0.2126 * ((_panelRgb select 0) ^ 2.2) + 0.7152 * ((_panelRgb select 1) ^ 2.2) + 0.0722 * ((_panelRgb select 2) ^ 2.2);

        {
            _x params ["_key", "_contrast"];

            private _ink = +(_theme get _key);
            private _grey = (((_contrast * (_panelLuma + 0.05) - 0.05) max 0) ^ (1 / 2.2)) min 1;

            if (_grey > (_ink select 0)) then {
                _ink set [0, _grey];
                _ink set [1, _grey];
                _ink set [2, _grey];
                _theme set [_key, _ink];
            };
        } forEach [["text2", PALETTE_CONTRAST_TEXT2], ["muted", PALETTE_CONTRAST_MUTED]];
    };

    if (_alphaPick >= 0) then {
        _panel set [3, (_alphaPick max PALETTE_ALPHA_MIN) min 1];
    };

    _theme set ["panel", _panel];
};

_theme
