#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The box of a container as the inventory window draws it (aio_gui_fnc_drawSection): a square with the picture of
 * the class - a crate or vehicle with the picture the rules give it, else the one the editor has of it
 * (editorPreview), a uniform, vest or backpack with its picture as a slot shows it - drawn by the class's icon=,
 * larger, smaller or moved, and cut to the box (aio_gui_fnc_uiBoxPicture). For the Containers step, which shows
 * the box with the picture as it would be once Apply wrote it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: The box [x, y, w, h] <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Class <STRING>
 * 5: The picture to show instead of the editor's: the one set in the working copy, else - for a uniform, vest or
 *    backpack - config's; "" for the editor's own <STRING>
 * 6: How it is drawn, [scale, across, down] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _box, [0.1, 0.1, 0.1, 0.1], _theme, "B_CargoNet_01_ammo_F", "", [1.4, 0, 0]] call aio_setup_fnc_drawBoxPreview;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_class", "", [""]], ["_own", "", [""]], ["_icon", ICON_PLAIN, [[]]]
];

private _kind = ([_class] call EFUNC(items,getFacts)) getOrDefault ["kind", ""];
private _preview = "";

if (_kind in ["crate", "vehicle"]) then {
    _preview = [getText (configFile >> "CfgVehicles" >> _class >> "editorPreview")] call EFUNC(gui,safePicture);
};

private _radius = (_theme getOrDefault ["radius", 0]) min ((_rect select 3) / 4);

if (([_display, _parent, _rect, _theme, _own, _preview, _icon, _radius, false] call EFUNC(gui,uiBoxPicture)) isEqualTo []) then {
    _rect params ["_left", "_top", "_width", "_height"];

    [_display, _parent, _rect, _theme getOrDefault ["slot", [1, 1, 1, 0.06]], _radius, _theme getOrDefault ["slotBorder", []]] call EFUNC(gui,uiPanel);
    [
        _display, _parent, [_left + _width * 0.25, _top + _height * 0.25, _width * 0.5, _height * 0.5], UI_TEX(icon_crate_ca),
        _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]]
    ] call EFUNC(gui,uiIcon);
};
