#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Builds the open window again for a click that changed what it shows - a section folded or opened, the empty rows of a
 * container, a container opened or closed inside another - without one build per click: the first click builds at
 * once, the clicks that follow within the rest of that build (fnc_coalesce, key "build") are one build more, with the state
 * the last of them left. A build done meanwhile by anything else (fnc_build) takes the waiting one's place.
 *
 * The caller changes its state first (GVAR(collapsed), ...) and then calls this; like fnc_build it must
 * not be called from inside the event of a control the build deletes (fnc_later).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_buildSoon;
 *
 * Public: No
 */

["build", {
    disableSerialization;

    private _display = uiNamespace getVariable [QGVAR(display), displayNull];

    if (!isNull _display) then {
        [_display] call FUNC(build);
    };
}, [], COALESCE_GAP] call FUNC(coalesce);
