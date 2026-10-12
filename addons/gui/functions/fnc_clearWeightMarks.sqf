#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes back what lifting something showed about weight (fnc_markWeight): the previews on the load bars and
 * the weight card are deleted, the cells that turned red go back to the colour their section drew them in,
 * and every load text reads as before with its icon and chip; the drag's hint is forgotten, so the next one
 * writes its own. First thing when a drag ends. A build needs
 * nothing of this - it deletes the controls and empties the registry.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_clearWeightMarks;
 *
 * Public: No
 */

disableSerialization;

ctrlDelete (uiNamespace getVariable [QGVAR(weightPreview), controlNull]);
uiNamespace setVariable [QGVAR(weightPreview), controlNull];
uiNamespace setVariable [QGVAR(dragExternal), false];
GVAR(dragHintShown) = [];

{
    private _record = _x;

    ctrlDelete (_record getOrDefault ["preview", controlNull]);
    _record set ["preview", controlNull];

    {
        _x ctrlSetBackgroundColor (_record get "cellColor");
    } forEach (_record getOrDefault ["tinted", []]);

    _record set ["tinted", []];

    private _label = _record getOrDefault ["label", controlNull];

    if (_record getOrDefault ["worded", false] && {!isNull _label}) then {
        _label ctrlSetText (_record get "text");
        _label ctrlSetTextColor (_record get "color");
        _label ctrlSetPosition (_record get "labelRect");
        _label ctrlCommit 0;

        {_x ctrlShow true} forEach (_record get "extras");
    };

    _record set ["worded", false];
} forEach (uiNamespace getVariable [QGVAR(loadBars), []]);
