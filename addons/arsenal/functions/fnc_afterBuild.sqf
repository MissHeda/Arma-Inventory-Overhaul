#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * After every build of the window (the "afterBuild" hook): ACE's lists of what is carried are read again,
 * the counts and marks of the catalog follow, weapon parts that changed are announced, the ring round the
 * target is drawn, what was just added flashes, and the textures of a uniform or backpack from ACE Arsenal
 * Extended are applied.
 *
 * ACE's unique items are the ones the soldier carries and the arsenal does not offer (updateUniqueItemsList
 * reads what he carries now). What was worked out about that (GVAR(uniqueCache)) is void then.
 *
 * Where the last add landed (GVAR(pendingFlash)) is a list of places as einv_gui_fnc_findTile takes them -
 * [container, class, row, col, cells, compartment] each, or one such place - and lights up once, as a tile
 * landed by a drag does in the inventory. The list is emptied by it.
 *
 * The soldier keeps showing the weapon he was last given (fnc_showItem): held in his hand again after a
 * build that changed things, or lowered when it has gone.
 *
 * While the panels are hidden (GVAR(hidden), Backspace) every control but the dim layer, the first control and
 * the sink for the cursor is hidden again after each build, and nothing is left to point at: the grids, slots,
 * zones and panels the build registered are forgotten. A small hint says how to bring the panels back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_afterBuild;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _center = GVAR(center);

if (isNull _center) exitWith {};

// What he carries, and what of that the arsenal does not offer, as ACE reads it for its window.
call ACEFUNC(arsenal,updateCurrentItemsList);
call ACEFUNC(arsenal,updateUniqueItemsList);

GVAR(uniqueCache) = createHashMap;
GVAR(carried) = [_center] call FUNC(carriedCounts);

// The cards show how many he carries, and the favorites.
[true] call FUNC(bindCatalog);

// Parts of a weapon that changed while the weapon stayed: announced as ACE's window announces them. The
// first build only remembers what is there.
[GVAR(lastWeapons) isEqualTo []] call FUNC(weaponEvents);

// The weapon shown last is still in his hand - or he stands at ease, should it have gone.
["keep"] call FUNC(showItem);

// The ring round what the soldier clicked to browse for.
[_display] call FUNC(drawTargets);

// Where the last thing added landed.
private _pending = GVAR(pendingFlash);

if (_pending isNotEqualTo []) then {
    GVAR(pendingFlash) = [];

    {
        [_display, _x, LAND_FLASH_ALPHA, LAND_FLASH] call EFUNC(gui,flashTile);
    } forEach ([[_pending], _pending] select ((_pending select 0) isEqualType []));
};

// ACE Arsenal Extended sets the textures of a uniform or backpack when its panel is filled, which this window
// never does: a model's default option would stay otherwise.
private _gear = [uniform _center, backpack _center];

if (!isNil "aceax_gearinfo_fnc_applyTextureOptions" && {GVAR(lastGear) isNotEqualTo _gear}) then {
    [_center] call (missionNamespace getVariable "aceax_gearinfo_fnc_applyTextureOptions");
};

GVAR(lastGear) = _gear;

// ----- Hidden panels -----

if (!GVAR(hidden)) exitWith {};

private _sink = uiNamespace getVariable [QEGVAR(gui,filterSink), controlNull];

{
    if (isNull ctrlParentControlsGroup _x && {!(ctrlIDC _x in [IDC_DIM, IDC_FIRST])} && {_x isNotEqualTo _sink}) then {
        _x ctrlShow false;
    };
} forEach (allControls _display);

// Nothing to hover or press: the mouse hits no tile, no slot, no column.
uiNamespace setVariable [QEGVAR(gui,grids), []];
uiNamespace setVariable [QEGVAR(gui,slots), []];
uiNamespace setVariable [QEGVAR(gui,zones), []];
EGVAR(gui,panels) = [];

// The way back, on a strip of the window's glass: a key hint on a bare world would vanish over a bright sky.
private _theme = EGVAR(gui,theme);
private _keyH = UNIT * 0.9;
private _pad = SQUARE((FOOT_H - _keyH) / 2);
private _keyText = LLSTRING(Key_Backspace);
private _what = LLSTRING(Key_Show);
private _width = ((_keyText getTextWidth [_theme getOrDefault ["fontBold", "RobotoCondensedBold"], _keyH * 0.56])
    + (_what getTextWidth [_theme getOrDefault ["font", "RobotoCondensed"], _keyH * 0.62])) * TEXT_SLACK + _pad * 3 + SQUARE(_keyH);

[
    _display, controlNull, [CONTENT_X, FOOT_Y, _width, FOOT_H], _theme getOrDefault ["panel", []],
    (_theme getOrDefault ["radius", 0]) min (FOOT_H / 2)
] call EFUNC(gui,uiPanel);

[_display, controlNull, [CONTENT_X + _pad, FOOT_Y + (FOOT_H - _keyH) / 2], _keyText, _what, _theme, _keyH] call EFUNC(gui,uiKeyHint);
