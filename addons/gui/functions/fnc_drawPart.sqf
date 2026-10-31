#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws a piece of the window that can be drawn again on its own later (fnc_redrawPart) - in its place and
 * under everything made after it. Controls made later draw over earlier ones, the only z-order the engine
 * has, so a piece made anew at the end of the display would lie over the kit windows, the name at the mouse
 * and the inspect card. Instead it is drawn in a group of its own that the build makes where the piece
 * belongs; a redraw deletes only the group inside it and draws into a new one.
 *
 * Used for what follows what the unit carries in the equipment column - the weight card and the hotbar's
 * counts (fnc_drawEquipmentCards) - so a move into or out of the backpack draws those again, not the window
 * (fnc_refresh). Like the columns and the kit windows, both groups report the mouse buttons and the wheel
 * as the display does: lying over the column, they take them in its place (fnc_onMouseButton, fnc_onMouseZ).
 *
 * The parts of a build are kept in uiNamespace parts, key -> [outer group, inner group, code, arguments,
 * position], emptied by every build.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Key the part is drawn again by <STRING>
 * 2: Controls group to draw in, or controlNull for the display <CONTROL>
 * 3: Position [x, y, w, h] - in that group, or on the screen <ARRAY>
 * 4: Code that draws it, called with [display, group, position in the group, arguments...] <CODE>
 * 5: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * Drawn <BOOL>
 *
 * Example:
 * [_display, "weight", controlNull, _rect, {_this call einv_gui_fnc_drawWeightCard}, [player, _theme]] call einv_gui_fnc_drawPart;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_key", "", [""]], ["_parent", controlNull, [controlNull]], ["_rect", [], [[]], 4], ["_code", {}, [{}]], ["_args", [], [[]]]];

if (isNull _display || {_key isEqualTo ""}) exitWith {false};

private _outer = [_display, "EINV_Group", _parent, _rect] call FUNC(uiCreate);

// The build hooks every group it finds (fnc_build): this one has its handlers already.
_outer setVariable [QGVAR(hooked), true];
_outer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
_outer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
_outer ctrlAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];

private _parts = uiNamespace getVariable [QGVAR(parts), createHashMap];
_parts set [_key, [_outer, controlNull, _code, _args, _rect]];
uiNamespace setVariable [QGVAR(parts), _parts];

[_key] call FUNC(redrawPart)
