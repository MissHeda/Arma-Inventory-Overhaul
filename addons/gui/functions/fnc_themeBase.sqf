#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The theme every look starts from: every key a building block may ask for, with quiet values - near-black
 * panes with faint light films over them, as in Arma's and ACE's menus. A look copies it and changes what
 * makes it that look:
 *
 *   private _theme = call FUNC(themeBase);
 *   _theme merge [createHashMapFromArray [["id", "tarkov"], ...], true];
 *
 * A fresh HashMap each call, with arrays of its own, so a look can change it freely. What each key
 * means is in docs/ARCHITECTURE.md (Themes); colours are RGBA, [] where a key allows "none". fnc_build
 * sets the id from GVAR(styles), and the name too where a look leaves it empty.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Theme <HASHMAP>
 *
 * Example:
 * private _theme = call einv_gui_fnc_themeBase;
 *
 * Public: No
 */

private _tileBg = [];
_tileBg set [CATEGORY_MISC, [0.15, 0.15, 0.15, 0.92]];
_tileBg set [CATEGORY_GEAR, [0.18, 0.18, 0.18, 0.92]];
_tileBg set [CATEGORY_WEAPON, [0.14, 0.19, 0.26, 0.92]];
_tileBg set [CATEGORY_AMMO, [0.21, 0.18, 0.09, 0.92]];
_tileBg set [CATEGORY_MEDICAL, [0.12, 0.21, 0.14, 0.92]];

createHashMapFromArray [
    ["id", ""],
    ["name", ""],
    ["font", "PuristaMedium"],
    ["fontBold", "PuristaSemibold"],
    ["upper", false],
    ["radius", 0],
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
    ["raised", [0.27, 0.27, 0.27, 0.92]],
    ["tileAmmoBar", true],
    ["text", [1, 1, 1, 1]],
    ["text2", [0.78, 0.78, 0.78, 1]],
    ["muted", [0.56, 0.56, 0.56, 1]],
    ["accent", [0.84, 0.54, 0.1, 1]],
    ["accentSoft", [0.84, 0.54, 0.1, 0.2]],
    ["line", [1, 1, 1, 0.08]],
    ["gain", [0.36, 0.66, 0.36, 1]],
    ["loss", [0.86, 0.27, 0.25, 1]],
    ["warn", [0.93, 0.75, 0.2, 1]],
    ["tooltipBg", [0.03, 0.03, 0.03, 0.96]],
    ["inspectBg", [0.06, 0.06, 0.06, 0.98]],
    ["info", [0.38, 0.56, 0.76, 1]],
    ["barTrack", [1, 1, 1, 0.1]],
    ["barFill", [0.84, 0.54, 0.1, 1]],
    ["button", [1, 1, 1, 0.07]],
    ["buttonHover", [1, 1, 1, 0.16]],
    ["buttonText", [0.88, 0.88, 0.88, 1]],
    ["keyBg", [1, 1, 1, 0.14]],
    ["keyText", [1, 1, 1, 1]],
    ["keyRound", false],
    ["cameraDefault", true]
]
