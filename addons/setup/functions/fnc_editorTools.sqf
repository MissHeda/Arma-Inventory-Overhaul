#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The two buttons in the corner of an editor of the Items and Containers steps (fnc_drawItemEditor,
 * fnc_drawCellEditor): Export, whose box under the button asks what for (fnc_openExportChoice): the config
 * lines of the class - or of the whole tree, when the edit is for one - for a mod's config, or the layout alone
 * to share (fnc_exportClasses); and Import, whose box under the button takes such lines, a layout or rules and
 * applies them (fnc_openClassImport) - to the class selected here, or to the classes the text names.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create them in <CONTROL>
 * 2: Where the buttons end on the right, and their top and height, relative to the group [right, top, height] <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Step: "items" or "containers" <STRING>
 * 5: Class <STRING>
 * 6: The edit is for the class and everything built on it <BOOL>
 *
 * Return Value:
 * How much room the two buttons take, with the space between them <NUMBER>
 *
 * Example:
 * private _taken = [_display, _box, [0.5, 0.02, 0.03], _theme, "containers", "B_Carryall_blk", false] call einv_setup_fnc_editorTools;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_place", "_theme", ["_mode", "items", [""]], ["_class", "", [""]], ["_tree", false, [false]]];
_place params ["_right", "_top", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _gap = SQUARE(UNIT * 0.2);
private _exportW = ACTION_W(LLSTRING(Export),_height,true,_font);
private _importW = ACTION_W(LLSTRING(Import),_height,true,_font);
private _importX = _right - _importW;
private _exportX = _importX - _gap - _exportW;

// The boxes open under their buttons.
private _exportControls = [
    _display, _parent, [_exportX, _top, _exportW, _height], LLSTRING(Export), UI_TEX(icon_export_ca), _theme, {}, [], true, "",
    [LLSTRING(Tools_ExportTip), LLSTRING(Tools_ExportTipTree)] select _tree
] call FUNC(uiAction);
private _exportHit = _exportControls select (count _exportControls - 1);

_exportHit setVariable [QGVAR(action), [{
    params ["_hit", "_mode", "_class", "_tree"];

    [uiNamespace getVariable [QGVAR(display), displayNull], [_hit] call FUNC(screenRect), _mode, _class, _tree] call FUNC(openExportChoice);
}, [_exportHit, _mode, _class, _tree]]];

private _controls = [_display, _parent, [_importX, _top, _importW, _height], LLSTRING(Import), UI_TEX(icon_import_ca), _theme, {}, [], true, "", LLSTRING(Tools_ImportTip)] call FUNC(uiAction);
private _hit = _controls select (count _controls - 1);

_hit setVariable [QGVAR(action), [{
    params ["_hit", "_mode", "_class", "_tree"];

    [uiNamespace getVariable [QGVAR(display), displayNull], [_hit] call FUNC(screenRect), _class, _tree] call FUNC(openClassImport);
}, [_hit, _mode, _class, _tree]]];

_exportW + _gap + _importW
