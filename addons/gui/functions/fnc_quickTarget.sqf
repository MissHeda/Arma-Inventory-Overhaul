#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The container the player picked as where quick moves go (Mia, after 0.6.73): a click on a free cell of a container's grid picks it -
 * a crate of five around, the vest, a pile -, a click on a free cell of it again lets it go, and the window closing forgets it
 * (aio_gui_quickTarget, fnc_onMouseButton). Its caption line shows a crosshair while it is picked (fnc_drawSection, the setting
 * aio_gui_quickTargetIcon). A double click and the quick move key (fnc_quickMove, fnc_quickMoveGroup) put what they move into it
 * first, whichever side it comes from; an item that lies in it already goes the usual way.
 *
 * Answered only while it is shown in a grid of the window and the player may put into it (fnc_checkTouch).
 *
 * Arguments:
 * 0: Where the items come from - the picked container is no target for its own items <ARRAY of OBJECTs>
 *
 * Return Value:
 * [container, root] - [] for none <ARRAY>
 *
 * Example:
 * [[vestContainer player]] call aio_gui_fnc_quickTarget;
 *
 * Public: No
 */

params [["_sources", [], [[]]]];

private _target = missionNamespace getVariable [QGVAR(quickTarget), objNull];

if (isNull _target || {_target in _sources} || {!(call FUNC(isInventoryMode))}) exitWith {[]};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _index = _grids findIf {
    (_x getOrDefault ["container", objNull]) isEqualTo _target && {!(_x getOrDefault ["virtual", true])}
    && {(_x getOrDefault ["kit", ""]) isEqualTo ""} && {!(_x getOrDefault ["overflow", false])}
};

if (_index < 0 || {([_target, "items"] call FUNC(checkTouch)) isNotEqualTo ""}) exitWith {[]};

private _unit = GVAR(unit);
private _root = [(_grids select _index) getOrDefault ["root", objNull], _unit] select (_target in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]);

[_target, _root]
