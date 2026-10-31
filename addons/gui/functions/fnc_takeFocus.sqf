#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * While something is held (an item, a hotbar binding): the focus goes to the search field's sink
 * (fnc_drawFilter), whatever has it - even with a mouse button down, where fnc_onFrame leaves a button
 * alone so its click comes. A drag needs no click of a control, and the engine draws the control that has
 * the focus - with the group it lies in - over every other: a column that kept the focus from the press
 * lay over the dragged picture, the green or red footprint and the name at the mouse. A field being typed
 * in keeps it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * The focus was moved <BOOL>
 *
 * Example:
 * [_display] call aio_gui_fnc_takeFocus;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

private _focus = focusedCtrl _display;
private _sink = uiNamespace getVariable [QGVAR(filterSink), controlNull];

if (isNull _sink || {isNull _focus} || {_focus isEqualTo _sink} || {ctrlType _focus in [2, 4]}) exitWith {false};

ctrlSetFocus _sink;

true
