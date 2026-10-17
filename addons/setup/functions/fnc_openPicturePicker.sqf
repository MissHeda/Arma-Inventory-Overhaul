#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the picture picker over the wizard (fnc_popover, in the middle of the screen over a dimmed wizard): a
 * search over every picture of the game's items with a page of thumbnails to click, and a field for any texture
 * path (fnc_drawPicturePicker). A click picks, a second click or "Use picture" takes it.
 *
 * It opens on the picture in use - ringed, on its page - and on the chip of the class's kind (items, gear,
 * vehicles and boxes; "All" for a class the index does not list), so what a class has now is what is seen first.
 * The picture in use is matched by its whole path (fnc_pictureKey): no card is ringed unless it is that file.
 * For a crate or vehicle with no picture set it is the editor's picture, which is what the inventory draws.
 *
 * Arguments:
 * 0: The picture set now, "" for none - it fills the path field <STRING> (default: "")
 * 1: Code run when a picture is taken, called with [path, arguments] <CODE>
 * 2: Arguments <ANY> (default: [])
 * 3: The picture in use, the one set else config's <STRING> (default: the one set, "" for none)
 * 4: The class it is for, "" for none; "#category" for the picture of a category - the picker then has the chip of this mod's own icons <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["", {params ["_path"]; systemChat _path}] call einv_setup_fnc_openPicturePicker;
 *
 * Public: No
 */

disableSerialization;

params [["_current", "", [""]], ["_code", {}, [{}]], ["_arguments", []], ["_inUse", "", [""]], ["_class", "", [""]]];

// Without word of one, the set picture is the one in use.
if (_inUse isEqualTo "") then {
    _inUse = _current;
};

// The chip of the class's kind, from the class index; "all" where it does not list the class. For a category (the class "#category")
// the chip of this mod's own icons: it needs no catalog, and the picture in use is ringed without it.
private _forCategory = _class isEqualTo "#category";
private _row = ((uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["byClass", createHashMap]) getOrDefault [toLowerANSI _class, []];
private _chip = ["all", [_row param [ROW_KIND, ""]] call FUNC(pictureCategory)] select (_row isNotEqualTo []);

if (_forCategory) then {
    _chip = "icons";
};

// A crate or a vehicle with no picture of its own is drawn by the picture the editor has of it (editorPreview),
// not by the config picture the Picture row names - so that is the one in use, and the one ringed.
if (_current isEqualTo "" && {_chip isEqualTo "vehicles"}) then {
    private _preview = [getText (configFile >> "CfgVehicles" >> _class >> "editorPreview")] call EFUNC(gui,safePicture);

    if (_preview isNotEqualTo "") then {
        _inUse = _preview;
    };
};

// text - the search; chip - "icons" (a picker for a category: this mod's own icons), "items", "gear", "vehicles" or "all"; icons - the
// picker is for a category and has the chip of icons; page; picked - the thumbnail clicked, at the
// start the picture in use; reveal - turn to the page of the picture picked as soon as the catalog is read; custom -
// the path field; source - which of the two counts, "list" or "custom"; last - the last click, [path, time], for
// the double click; customOk - the path field holds a file the game has
GVAR(picker) = createHashMapFromArray [
    ["text", ""], ["chip", _chip], ["page", 0], ["picked", _inUse], ["reveal", _inUse isNotEqualTo "" && {!_forCategory}], ["custom", _current], ["source", "list"],
    ["icons", _forCategory],
    ["last", ["", 0]], ["customOk", false], ["code", _code], ["arguments", _arguments]
];

[uiNamespace getVariable [QGVAR(display), displayNull], [], [SQUARE(UNIT * 34), UNIT * 22.4], LLSTRING(Pic_Title), {
    params ["_display", "_inner", "_theme"];

    uiNamespace setVariable [QGVAR(pickerArgs), [_display, _inner, _theme]];

    ["all"] call FUNC(drawPicturePicker);
}, [], [], "picker"] call FUNC(popover);
