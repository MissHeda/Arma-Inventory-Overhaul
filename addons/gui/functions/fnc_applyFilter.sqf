#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Fades every tile whose item does not match the search field (GVAR(filter), fnc_drawFilter) - by its
 * name or short name as the window shows them (fnc_matchesFilter) - and brings back every tile that does.
 * Items not searched yet match nothing: what they are is not known. An empty field shows everything. The
 * tiles of a source grid (fnc_createGrid) are never faded, and a window that attached is told afterwards
 * (the "filter" hook).
 *
 * A section folded away to its caption (fnc_drawSection) shows no tile to fade, so with text in the field
 * its caption tab is tinted in the soft accent colour when something searched in it matches - the player
 * knows which crate to unfold.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_applyFilter;
 *
 * Public: No
 */

disableSerialization;

private _filter = toLower GVAR(filter);

{
    // A place things come from (a source grid, as the Arsenal panel makes of ACE's list) holds no container: the search leaves it alone.
    if ((_x getOrDefault ["source", ""]) isNotEqualTo "") then {continue};

    {
        private _tile = _x;
        private _match = _filter isEqualTo "" || {
            !(_tile getOrDefault ["hidden", false]) && {[_tile getOrDefault ["class", ""]] call FUNC(matchesFilter)}
        };

        private _fade = [FILTER_FADE, 0] select _match;

        {
            _x ctrlSetFade _fade;
            _x ctrlCommit FILTER_TIME;
        } forEach (_tile getOrDefault ["controls", []]);
    } forEach (_x getOrDefault ["tiles", []]);
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

// ----- The caption tabs of folded sections -----

{
    private _info = _x;

    if !(_info getOrDefault ["folded", false]) then {continue};

    private _holder = _info getOrDefault ["holder", objNull];
    private _tab = _info getOrDefault ["tab", []];
    private _tint = false;

    if (_filter isNotEqualTo "" && {!isNull _holder}) then {
        // What is searched in there, in the order it lies - the rest is not known to match anything.
        private _placed = ([_holder, [_holder] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";

        [_holder, _placed, false] call FUNC(markHidden);

        _tint = _placed findIf {
            !(_x getOrDefault ["hidden", false]) && {[_x getOrDefault ["class", ""]] call FUNC(matchesFilter)}
        } >= 0;
    };

    private _color = [
        _info getOrDefault ["tabColor", [0, 0, 0, 0.5]],
        GVAR(theme) getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]]
    ] select _tint;

    {
        _x ctrlSetBackgroundColor _color;
    } forEach _tab;
} forEach (uiNamespace getVariable [QGVAR(sectionInfo), []]);

// The window that attached may show what matches the search in its own places.
["filter", []] call FUNC(hook);
