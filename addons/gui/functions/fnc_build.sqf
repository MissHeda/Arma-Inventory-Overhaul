#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Builds everything on the window in the chosen look: clears what was there, reads what the unit wears
 * and carries and what it loots, and draws the header, the look's layout and the footer. Runs again
 * whenever the look, a section's fold or the sections shown change; a change of what some sections hold
 * only draws those again (fnc_refresh).
 *
 * With aio_gui_debugTiming on, the RPT gets how long the build took.
 *
 * Last come what floats over the columns - the open kits' windows where they were, then the name at the
 * mouse and the inspect card (fnc_drawWindows, fnc_drawTopLayer): controls made later draw over earlier
 * ones. Kits never take part in the columns: opening, closing or moving one draws only the windows
 * again, so nothing in the columns moves for it.
 *
 * A uniform, vest or backpack opened from inside a container whose object the engine made anew - a
 * sibling of its class was taken out and the others put back - is found again by its key in the same
 * container and stays open. The loot column shows what the window was opened on, then what lies around
 * (GVAR(nearby), fnc_readNearby) - all ordered by aio_storage_fnc_orderSections. Last of all the moves
 * under way are shown (fnc_drawPending) and the tiles selected (fnc_drawSelection), which survive every
 * build by what they stand for.
 * A repack of magazines in progress is drawn on the tiles last (aio_magazines_fnc_drawJob).
 * The palette popover (fnc_openPaletteMenu) or the size popover (fnc_openSizeMenu), if one was open, is made again after
 * everything else.
 *
 * The layout is looked up by name, so a look that is missing or broken leaves a window with only its
 * header and footer - still one that can be closed - rather than no window at all.
 *
 * A window that attached with hooks (fnc_attach) is asked at five places: the theme and the context may
 * be changed ("theme", "context"), the header, the layout and the footer can be its own ("header",
 * "layout" - the layout answers where its free middle is -, "footer"), and "afterBuild" comes last of all. A top-level
 * control with the id IDC_KEEP survives the sweep, with everything in it; on a display of another mod
 * (the "guest" flag) only what this addon registered is swept. Without hooks the build is exactly the
 * inventory's.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_build;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

if (isNull _display) exitWith {};

// A build a click asked for (fnc_buildSoon) and not yet done is this one: it draws what the state is now.
["build"] call FUNC(coalesceDrop);

private _start = diag_tickTime;

// For the tester's numbers (aio_gui_debugTiming): when each part of the build ended.
private _timed = missionNamespace getVariable [QGVAR(debugTiming), false];
private _marks = [];

// A rebuild ends any drag: the tiles it pointed at are about to go. The drag's
// timing line (aio_gui_debugTiming) is written first (fnc_logDrag).
call FUNC(logDrag);

GVAR(press) = [];
GVAR(dragging) = false;
GVAR(stripDrag) = [];
ctrlDelete (uiNamespace getVariable [QGVAR(dragCounter), controlNull]);
GVAR(dragTarget) = [];
GVAR(dragGroup) = [];
GVAR(emptyPress) = [];
uiNamespace setVariable [QGVAR(dragFootprints), []];
uiNamespace setVariable [QGVAR(dragShapes), []];
uiNamespace setVariable [QGVAR(dragCorners), []];
uiNamespace setVariable [QGVAR(dragGhosts), []];
uiNamespace setVariable [QGVAR(selectionFrames), []];
GVAR(searchQueue) = [];
GVAR(panels) = [];
GVAR(equipmentRect) = [];
GVAR(storageRect) = [];
GVAR(lootRect) = [];

// The palette popover stays open across a build - what it sets is this build's colours - and is made again at its end; so does
// the size popover, whose sliders build the window at its new size. It is closed here without being written to the profile or to
// CBA (aio_gui_menuRemake, fnc_closeMenu).
private _keptMenu = [
    "", GVAR(menuFor) param [0, ""]
] select (!isNull ((uiNamespace getVariable [QGVAR(menu), []]) param [0, controlNull]) && {(GVAR(menuFor) param [0, ""]) in ["palette", "size"]});

GVAR(menuRemake) = _keptMenu isNotEqualTo "";
[] call FUNC(closeMenu);
GVAR(menuRemake) = false;

// The sizes this build is made at (fnc_sizeDefs): where one changed since the last build (the size popover, CBA's options -
// fnc_sizeChanged), the cell is worked out afresh (fnc_getCell), and the words with it (fnc_textScale).
private _sizes = (call FUNC(sizeDefs)) apply {missionNamespace getVariable [_x select 0, -1]};

if ((uiNamespace getVariable [QGVAR(sizeBuilt), _sizes]) isNotEqualTo _sizes) then {
    uiNamespace setVariable [QGVAR(cell), []];
};

uiNamespace setVariable [QGVAR(sizeBuilt), _sizes];

// The style, by its id - an unknown one falls back to the first.
private _index = (GVAR(styles) findIf {(_x select 0) isEqualTo GVAR(style)}) max 0;
(GVAR(styles) select _index) params ["_id", "_nameKey", "_themeName", "_layoutName"];
GVAR(style) = _id;

// The kit windows go first: their body's scroll is kept for when they are drawn again, at the end.
call FUNC(clearWindows);

// Built again in the same look, each column stays where the player scrolled it - by its id, in screen
// height from the top (fnc_scrollPixels): a column that comes or goes beside it, or grows or shrinks
// above what is shown, does not move what the player looked at. Groups with no id - the kit windows,
// the inspect card - are no columns.
private _scroll = createHashMap;

// A column that was scrolled keeps its panel, its title and its scroll group when it is drawn again in the same place with the
// same words (fnc_drawColumn): a group made anew shows its top until a frame later. Not on another mod's display, where only
// the window's own controls are ours to keep (the "guest" flag, ACE Arsenal's).
private _guest = ["guest", [], false] call FUNC(hook);
private _keep = createHashMap;

if ((GVAR(theme) getOrDefault ["id", ""]) isEqualTo _id) then {
    {
        if (isNull _x || {ctrlType _x != 15}) then {continue};

        private _column = _x getVariable [QGVAR(column), ""];

        if (_column isNotEqualTo "") then {
            private _pixels = [_x] call FUNC(scrollPixels);

            _scroll set [_column, _pixels];

            if (_pixels > 0 && {_guest isNotEqualTo true} && {(_x getVariable [QGVAR(columnKey), []]) isNotEqualTo []}) then {
                _keep set [_column, [_x, _x getVariable [QGVAR(columnParts), []], _x getVariable [QGVAR(columnKey), []]]];
            };
        };
    } forEach (uiNamespace getVariable [QGVAR(created), []]);
};

// What a column left from the last drawing and what it was scrolled to, for fnc_drawColumn - the controls it keeps are not swept
// below.
uiNamespace setVariable [QGVAR(keepColumns), _keep];
uiNamespace setVariable [QGVAR(keepPixels), _scroll];

private _keptControls = [];

{
    _keptControls pushBack (_y select 0);
    _keptControls append (_y select 1);
} forEach _keep;

// Whatever was still to be scrolled belonged to the groups that go now.
uiNamespace setVariable [QGVAR(scrollRestore), []];

// Typing in the search field: the new field gets the cursor back (fnc_drawFilter).
private _filterEdit = uiNamespace getVariable [QGVAR(filterEdit), controlNull];
GVAR(filterFocus) = !isNull _filterEdit && {focusedCtrl _display isEqualTo _filterEdit};

{
    if !(_x in _keptControls) then {
        ctrlDelete _x;
    };
} forEach (uiNamespace getVariable [QGVAR(created), []]);
uiNamespace setVariable [QGVAR(created), []];

// Anything made on the display without being registered goes as well - left behind, it would pile up
// with every rebuild. A group takes its own controls with it. What is kept: the dim layer, the first
// control, and a control a window that attached keeps across builds (IDC_KEEP), and the controls of a
// column kept above. Not on another mod's display this addon is only a guest on (the "guest" flag, ACE
// Arsenal's): every control there but the registered ones above is that mod's own.
if (_guest isNotEqualTo true) then {
    {
        if (isNull ctrlParentControlsGroup _x && {!(ctrlIDC _x in [IDC_DIM, IDC_FIRST, IDC_KEEP])} && {!(_x in _keptControls)}) then {
            ctrlDelete _x;
        };
    } forEach (allControls _display);
};

if (_timed) then {_marks pushBack ["sweep", diag_tickTime]};

uiNamespace setVariable [QGVAR(grids), []];
uiNamespace setVariable [QGVAR(foldAreas), []];
uiNamespace setVariable [QGVAR(pageAreas), []];
uiNamespace setVariable [QGVAR(zones), []];
uiNamespace setVariable [QGVAR(slots), []];

// The slots' drag highlights (fnc_glowSlot) went with the sweep above - but for a control a window that
// attached keeps its group across builds: those are deleted here. They are made again, ahead of time, by
// fnc_warmTargets.
{
    {ctrlDelete _x} forEach (_y select 1);
} forEach (uiNamespace getVariable [QGVAR(glowCache), createHashMap]);

uiNamespace setVariable [QGVAR(glowCache), createHashMap];
uiNamespace setVariable [QGVAR(glowNext), 0];
uiNamespace setVariable [QGVAR(dragGlow), []];
uiNamespace setVariable [QGVAR(sectionInfo), []];
uiNamespace setVariable [QGVAR(sortButtons), []];
uiNamespace setVariable [QGVAR(parts), createHashMap];

// The weight registries, drawn into again by the sections and the weight card (fnc_drawSection,
// fnc_drawEquipmentCards): what the hint explains, the comparison card and the name at the mouse - their
// controls went with the sweep above.
uiNamespace setVariable [QGVAR(infoAreas), []];
uiNamespace setVariable [QGVAR(weightBar), createHashMap];
uiNamespace setVariable [QGVAR(weightPreview), controlNull];
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];
GVAR(buildCount) = GVAR(buildCount) + 1;
GVAR(hover) = [];
uiNamespace setVariable [QGVAR(hint), controlNull];
uiNamespace setVariable [QGVAR(hoverRing), []];

private _fnc_theme = missionNamespace getVariable [_themeName, 0];

if !(_fnc_theme isEqualType {}) then {
    ERROR_1("Theme function %1 is missing - drawing with the base theme.",_themeName);
    _fnc_theme = FUNC(themeBase);
};

private _theme = call _fnc_theme;

if (isNil "_theme" || {!(_theme isEqualType createHashMap)}) then {
    ERROR_1("Theme function %1 returned no theme - drawing with the base theme.",_themeName);
    _theme = call FUNC(themeBase);
};

_theme set ["id", _id];

if ((_theme getOrDefault ["name", ""]) isEqualTo "") then {
    _theme set ["name", localize _nameKey];
};

// A window that attached may change the colours it needs (the Arsenal's panels are more see-through).
["theme", [_theme]] call FUNC(hook);

// What the window shows. The layouts draw from this, the hover reads the weapons' attachments from it.
private _unit = GVAR(unit);
private _now = diag_tickTime;

// Uniforms, vests and backpacks opened from inside a container, as [class, object, the container it
// lies in, its key there, the key of that container when it was opened from inside one too, when it went
// missing]. The engine makes a new object for one whenever a sibling of its class is taken out and the
// others are put back (aio_storage_fnc_removeSameClass): it is found again by its key - its own id, the
// same on every machine (aio_storage_fnc_entryKey) - in the container it lay in, or in the new object of
// that one. Kept a moment while it is missing - its id may reach this machine after its cargo -, then it
// drops out. A key is only kept while no sibling there shares it. One that left the container it lay in -
// put on, taken into a crate, dropped elsewhere - drops out at once, and so does whatever was opened from
// inside it: its box closes, and one put on shows in the storage column as the worn one it is now.
private _keptOpened = [];
private _gone = [];

// An entry's key where it lies - set by aio_storage_fnc_getContents, made here should it be missing.
private _fnc_keyOf = {
    params ["_entry"];

    private _found = _entry getOrDefault ["key", ""];

    if (_found isEqualTo "") then {[_entry] call EFUNC(storage,entryKey)} else {_found}
};

{
    _x params [["_class", ""], ["_object", objNull], ["_parent", objNull], ["_key", ""], ["_parentKey", ""], ["_lostAt", -1]];

    // The container it lay in was made anew as well: that one was found again just before, by its key.
    if (isNull _parent && {_parentKey isNotEqualTo ""}) then {
        private _index = _keptOpened findIf {!isNull (_x select 1) && {(_x select 3) isEqualTo _parentKey}};

        if (_index >= 0) then {
            _parent = (_keptOpened select _index) select 1;
        };
    };

    // Opened from inside one that left where it lay: it went with it.
    if (!isNull _parent && {_parent in _gone}) then {
        _gone pushBack _object;
        continue;
    };

    private _contents = if (isNull _parent) then {[]} else {[_parent] call EFUNC(storage,getContents)};

    // No longer listed where it lay (everyContainer): put on, moved, or that container is gone. Only while
    // one of its class still lies there may it be that one made anew with its id still on the way - then it
    // is missing, looked for by its key below. A crate looked into through its vehicle's cargo lies in no
    // container: aio_compat_ace_cargo_fnc_pruneOpened sees to those (below).
    if (
        !isNull _object
        && {isNull (_object getVariable [QEGVAR(compat_ace_cargo,openedFrom), objNull])}
        && {_contents findIf {(_x getOrDefault ["container", objNull]) isEqualTo _object} < 0}
    ) then {
        if (_contents findIf {!isNull (_x getOrDefault ["container", objNull]) && {(_x getOrDefault ["class", ""]) == _class}} < 0) then {
            _gone pushBack _object;
            continue;
        };

        _object = objNull;
    };

    if (isNull _object && {_key isNotEqualTo ""}) then {
        private _index = _contents findIf {!isNull (_x getOrDefault ["container", objNull]) && {([_x] call _fnc_keyOf) isEqualTo _key}};

        if (_index >= 0) then {
            _object = (_contents select _index) get "container";

            // Its compartments go by the item's class, as when it was opened (fnc_openNested).
            _object setVariable [QEGVAR(storage,itemClass), _class];
        };
    };

    if (isNull _object) then {
        if (_lostAt < 0) then {
            _lostAt = _now;
        };

        if (_now - _lostAt <= ANSWER_WAIT) then {
            _keptOpened pushBack [_class, objNull, _parent, _key, _parentKey, _lostAt];
        };

        continue;
    };

    // Its key as it lies now - none while a sibling of its class shares it (no id given yet).
    private _index = _contents findIf {(_x getOrDefault ["container", objNull]) isEqualTo _object};

    if (_index >= 0) then {
        private _found = [_contents select _index] call _fnc_keyOf;

        _key = ["", _found] select (_found isNotEqualTo "" && {({([_x] call _fnc_keyOf) isEqualTo _found} count _contents) == 1});
    };

    // Opened from inside another one that is open: that one's key leads to it should both be made anew.
    private _parentIndex = if (isNull _parent) then {-1} else {_keptOpened findIf {(_x select 1) isEqualTo _parent}};
    _parentKey = if (_parentIndex >= 0) then {(_keptOpened select _parentIndex) select 3} else {""};

    _keptOpened pushBack [_class, _object, _parent, _key, _parentKey, -1];
} forEach GVAR(opened);

GVAR(opened) = _keptOpened;

private _ownSections = [_unit] call EFUNC(storage,getSections);
// Crates ACE unloaded meanwhile are no longer looked into through their vehicle (aio_compat_ace_cargo).
if (!isNil QEFUNC(compat_ace_cargo,pruneOpened)) then {
    GVAR(opened) = [GVAR(opened)] call EFUNC(compat_ace_cargo,pruneOpened);
};

private _lootSections = [GVAR(container), GVAR(secondary), GVAR(opened) select {!isNull (_x select 1)}, GVAR(nearby)] call EFUNC(storage,getLootSections);

// What is locked to this player: its name and why, nothing of what it holds (aio_locks).
_lootSections = [_unit, _lootSections, GVAR(opened)] call EFUNC(locks,decorate);

// Containers opened from inside one that is locked now have gone with their section. An entry whose
// object is missing for a moment (null, kept above) stays.
GVAR(opened) = GVAR(opened) select {
    private _object = _x select 1;

    isNull _object || {_lootSections findIf {(_x getOrDefault ["container", objNull]) isEqualTo _object} >= 0}
};

// ACE cargo: what is loaded into a vehicle or crate, right under it (aio_compat_ace_cargo).
if (!isNil QEFUNC(compat_ace_cargo,getSections)) then {
    _lootSections = [_lootSections] call EFUNC(compat_ace_cargo,getSections);
};

// Ground holders with nothing in them are already left out, so any section left means looting - what lies
// around counts as well. Open kits of Enhanced First Aid Kits and its pouches are none of it: they have
// windows of their own (fnc_drawWindows), so opening one never brings the loot column in or changes what
// it shows.
private _context = createHashMapFromArray [
    ["unit", _unit],
    ["container", GVAR(container)],
    ["secondary", GVAR(secondary)],
    ["equipment", [_unit] call EFUNC(storage,getEquipment)],
    ["ownSections", _ownSections],
    ["lootSections", _lootSections],
    ["looting", _lootSections isNotEqualTo []]
];

// ... and what it shows (the Arsenal's storage column also holds the containers opened inside the
// soldier's).
["context", [_context]] call FUNC(hook);

GVAR(theme) = _theme;
GVAR(context) = _context;

if (_timed) then {_marks pushBack ["contents", diag_tickTime]};

private _dim = _display displayCtrl IDC_DIM;
_dim ctrlSetBackgroundColor (_theme getOrDefault ["dim", [0, 0, 0, 0.35]]);

// The header and the layout are the look's, unless the window that attached draws its own.
if ("header" in GVAR(hooks)) then {
    ["header", [_display, _theme]] call FUNC(hook);
} else {
    [_display, _theme] call FUNC(drawHeader);
};

private _rect = [];
private _fnc_layout = missionNamespace getVariable [_layoutName, 0];

if ("layout" in GVAR(hooks)) then {
    _rect = ["layout", [_display, _theme, _context], []] call FUNC(hook);

    if (!(_rect isEqualType []) || {count _rect != 4}) then {
        _rect = [];
    };
} else {
    if (_fnc_layout isEqualType {}) then {
        _rect = [_display, _theme, _context] call _fnc_layout;

        if (isNil "_rect" || {!(_rect isEqualType [])} || {count _rect != 4}) then {
            _rect = [];
        };
    } else {
        ERROR_1("Layout function %1 is missing - the window shows only its header and footer.",_layoutName);
    };
};

// A column the layout did not draw again - it went, or the window that attached made its own - leaves its kept controls: they go
// now (fnc_drawColumn took what it kept out of the list).
{
    ctrlDelete (_y select 0);

    {ctrlDelete _x} forEach (_y select 1);
} forEach (uiNamespace getVariable [QGVAR(keepColumns), createHashMap]);

uiNamespace setVariable [QGVAR(keepColumns), createHashMap];

// The free middle, where a kit's window likes to open (fnc_placeWindow).
GVAR(middle) = _rect;

if (_timed) then {_marks pushBack ["columns", diag_tickTime]};

// The footer is the look's too, unless the window that attached puts its own (or none) in its place.
if ("footer" in GVAR(hooks)) then {
    ["footer", [_display, _theme]] call FUNC(hook);
} else {
    [_display, _theme] call FUNC(drawFooter);
};

// What is still to be searched, one container after the other, each from the top left.
call FUNC(sortSearch);

// What is being searched is told in the caption line of its box (fnc_updateStatus, from fnc_drawPending below).

// The scrolling columns take the clicks over them, so they report the mouse buttons as the display does.
// A group kept from the last build (IDC_KEEP) has them already - it must not collect more. A guest only
// hooks the groups it made: the other mod's groups keep their clicks to themselves.
{
    if (ctrlType _x == 15 && {!(_x getVariable [QGVAR(hooked), false])}) then {
        _x setVariable [QGVAR(hooked), true];
        _x ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
        _x ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
        _x ctrlAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];
    };
} forEach ([allControls _display, uiNamespace getVariable [QGVAR(created), []]] select (_guest isEqualTo true));

// A frame later (fnc_onFrame): right after its controls are made a group does not know its height yet,
// and the engine puts it back to the top (seen in the game after every move, 2026-10-08).
{
    if (isNull _x || {ctrlType _x != 15}) then {continue};

    private _pixels = _scroll getOrDefault [_x getVariable [QGVAR(column), ""], 0];

    if (_pixels > 0) then {
        (uiNamespace getVariable [QGVAR(scrollRestore), []]) pushBack [_x, _pixels, diag_frameNo];
    };
} forEach (uiNamespace getVariable [QGVAR(created), []]);

if (_timed) then {_marks pushBack ["footer", diag_tickTime]};

// The open kits' windows where they were, then the name at the mouse and the inspect card over them -
// with the search field's fading and the hover (fnc_drawTopLayer).
[_display] call FUNC(drawWindows);

if (_timed) then {_marks pushBack ["kit windows and top layer", diag_tickTime]};

// Drift is only reported for what is drawn: a holder no grid shows any more - closed, folded away, gone
// - is nobody's to report now (fnc_drawCompartments notes the others).
private _shown = (uiNamespace getVariable [QGVAR(grids), []]) apply {_x getOrDefault ["holder", objNull]};
GVAR(drift) = GVAR(drift) select {(_x select 0) in _shown};

// Moves under way: their tiles fade and cannot be lifted, the cells they go to are outlined - nothing
// shows in its new place before it got there (fnc_drawPending).
call FUNC(drawPending);

// The tiles selected, in a frame of the accent colour: found again by what they stand for, so they
// survive this build - those that went or are under way drop out (fnc_selectionTiles).
[] call FUNC(drawSelection);

if (_timed) then {_marks pushBack ["under way and selection", diag_tickTime]};

// What it was built from, so fnc_onFrame sees when that changes.
GVAR(signatureParts) = call FUNC(getSignature);

if (_timed) then {_marks pushBack ["signature", diag_tickTime]};

// A repack in progress shows on the tiles built just now (aio_magazines).
if (!isNil QEFUNC(magazines,drawJob)) then {
    [_display] call EFUNC(magazines,drawJob);
};

// The window that attached has the last word: its own controls, counts and marks on what was just built.
["afterBuild", [_display]] call FUNC(hook);

// The palette or size popover, over everything just built; a slider held in it stays held (fnc_paletteSlide, fnc_sizeSlide).
if (_keptMenu isEqualTo "palette") then {
    [_display] call FUNC(openPaletteMenu);
};

if (_keptMenu isEqualTo "size") then {
    [_display] call FUNC(openSizeMenu);
};

// For the tester's numbers (aio_gui_debugTiming).
if (_timed) then {
    private _took = ((diag_tickTime - _start) * 1000) toFixed 1;
    private _all = allControls _display;
    private _shown = {ctrlShown _x} count _all;

    // How many of each class: what the engine has to go through every frame, shown or not.
    private _byClass = createHashMap;

    {
        private _name = ctrlClassName _x;

        _byClass set [_name, (_byClass getOrDefault [_name, 0]) + 1];
    } forEach _all;

    private _classes = (toArray _byClass) apply {[_x select 1, _x select 0]};

    _classes sort false;

    private _top = (_classes select [0, 8]) apply {format ["%1 %2", _x select 1, _x select 0]};
    private _total = count _all;

    INFO_4("timing: build %1 ms (%2 controls on the display, %3 of them shown: %4)",_took,_total,_shown,_top joinString ", ");

    // Where the build's time went, part by part.
    private _from = _start;
    private _parts = _marks apply {
        _x params ["_name", "_at"];

        private _part = format ["%1 %2", _name, ((_at - _from) * 1000) toFixed 1];

        _from = _at;
        _part
    };

    INFO_1("timing: build parts (ms) - %1",_parts joinString ", ");
};
