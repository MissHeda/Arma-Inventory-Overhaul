#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The window's theme (fnc_layoutGlass), in the feel of Arma's and ACE's own menus. Every column is a
 * near-black, mostly opaque pane with round corners, and what lies on it - cards, slots - is a faint
 * light film, so every layer is a small step brighter. Text is white with grey for the second line, the
 * accent is Arma's warning orange, and the font is Purista as in vanilla and ACE. Tiles are dark greys
 * tinted by what they are, with their short name and a magazine's ammo bar; captions sit over the
 * slots, in normal case.
 *
 * The palette is written out here rather than taken from fnc_themeBase as it is, so Glass stays Enhanced
 * First Aid Kits' look whatever the base theme turns into. "equipmentPanel", "titleIcons" and
 * "onAccent" are the layout's own keys (fnc_layoutGlass, fnc_drawEquipmentCards).
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
    ["panel", [0.05, 0.05, 0.05, 0.92]],
    ["panelBorder", []],
    ["card", [1, 1, 1, 0.045]],
    ["slot", [1, 1, 1, 0.07]],
    ["slotEmpty", [1, 1, 1, 0.04]],
    ["slotBorder", []],
    ["slotCaption", "above"],
    ["slotCaptionBg", [1, 1, 1, 0.06]],
    ["slotIcon", [1, 1, 1, 0.45]],
    ["slotAccent", [0.84, 0.54, 0.1, 1]],
    ["hatch", false],
    ["cell", [1, 1, 1, 0.05]],
    ["tileBg", _tileBg],
    ["tileBorder", []],
    ["tileName", true],
    ["tileCount", "text"],
    ["tileCountBg", [0.03, 0.03, 0.03, 0.75]],
    ["tileCountColor", [1, 1, 1, 1]],
    ["tileAmmoBar", true],
    ["text", [1, 1, 1, 1]],
    ["text2", [0.78, 0.78, 0.78, 1]],
    ["muted", [0.56, 0.56, 0.56, 1]],
    ["accent", [0.84, 0.54, 0.1, 1]],
    ["accentSoft", [0.84, 0.54, 0.1, 0.2]],
    ["line", [1, 1, 1, 0.08]],
    ["warn", [0.93, 0.75, 0.2, 1]],
    ["tooltipBg", [0.03, 0.03, 0.03, 0.96]],
    ["inspectBg", [0.06, 0.06, 0.06, 0.98]],
    ["barTrack", [1, 1, 1, 0.1]],
    ["barFill", [0.84, 0.54, 0.1, 1]],
    ["button", [1, 1, 1, 0.07]],
    ["buttonHover", [1, 1, 1, 0.16]],
    ["buttonText", [0.88, 0.88, 0.88, 1]],
    ["keyBg", [1, 1, 1, 0.14]],
    ["keyText", [1, 1, 1, 1]],
    ["keyRound", false],
    ["equipmentPanel", true],
    ["titleIcons", true],
    ["onAccent", [0.05, 0.05, 0.05, 1]]
], true];

_theme
