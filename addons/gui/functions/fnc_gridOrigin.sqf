#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a grid's top left corner is on the screen right now. A grid in a scrolling column moves with
 * its scroll, so this is asked again each time rather than kept. Its cells lie where their columns and
 * rows start from that corner (fnc_createGrid "colX", "rowY"), which never changes.
 *
 * Climbs from the grid's group through every group around it, adding their positions and taking off
 * how far each is scrolled: its scroll bar's place (ctrlScrollValues, 0 to 1) times how much of its
 * content does not fit. The content's height is the one fnc_drawColumn stored on the group; a group
 * without it does not scroll.
 *
 * A group made only this frame is still at the top; the scroll it gets back on the next frame
 * (QGVAR(scrollRestore), fnc_scrollPixels) counts already. A press that brings a kit window to the top
 * draws it anew (fnc_raiseWindow) and is then worked out on the new body in the same handler: it has to
 * find the tile that lay under the mouse in the scrolled body the player clicked, not in an unscrolled
 * one.
 *
 * Also works for anything with a "rel" and a "parent", like a slot (fnc_drawSlot).
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 *
 * Return Value:
 * [x, y] on the screen <ARRAY>
 *
 * Example:
 * [_grid] call aio_gui_fnc_gridOrigin;
 *
 * Public: No
 */

disableSerialization;

params ["_grid"];
(_grid get "rel") params ["_originX", "_originY"];

private _group = _grid getOrDefault ["parent", controlNull];

while {!isNull _group} do {
    (ctrlPosition _group) params ["_groupX", "_groupY", "", "_groupH"];

    private _contentH = _group getVariable [QGVAR(contentH), _groupH];

    // No further than the content lets it - as fnc_onFrame puts a pending scroll back.
    private _scrolled = ([_group] call FUNC(scrollPixels)) min ((_contentH - _groupH) max 0);

    _originX = _originX + _groupX;
    _originY = _originY + _groupY - _scrolled;
    _group = ctrlParentControlsGroup _group;
};

[_originX, _originY]
