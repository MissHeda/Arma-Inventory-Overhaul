#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The section drawer for a column (fnc_drawColumn): a container as a block. A caption
 * tab on top - TACTICAL RIG, POCKETS, BACKPACK, or the crate's, the ground's or the body's name - with
 * the weight of what it holds on the right; under it a square box with the container's picture and short name, and to
 * its right the grid with a tile for every entry.
 *
 * The grid is Tarkov's: dark squares between lighter lines. The cells (fnc_createGrid) lie a pixel
 * apart over a lighter surface that shows through the gaps. The compartments are laid out and drawn by
 * fnc_flowCompartments and fnc_drawCompartments, which a kit's window (fnc_drawWindow) shares.
 *
 * What the contents weigh is told on the right of the caption (fnc_loadText) and in the hint over it
 * (fnc_infoHint) - nothing more: weight limits no container, its free cells do, so there is no bar, no
 * warning colour and no "full" mark. The hairline under the caption is all the line has.
 *
 * The words and the rows that hold them - the caption line, its tab and buttons, the weight, the box's name, the
 * fold line - are measured in TEXT_UNIT, so they grow with the tile scale as the cells do (fnc_textScale). In the
 * loot column a uniform, vest or backpack says whose it is ("Backpack - Miller", fnc_ownerName), and the tab, the
 * fold line and the hairline take the theme's loot colours (lootTab, lootLine) where it has them: what is someone
 * else's never reads as the player's own (issue 7).
 *
 * A box of the loot column this player has to search and has not opened yet is sealed (fnc_isSealed, issues 6 and 16, as
 * in Tarkov): a body's or a living person's uniform, vest or backpack, a crate, a vehicle's cargo, a pile, a bag lying
 * about, one opened from inside a container, and a body's that was dropped unsearched. Beside its box one block of
 * SEAL_ROWS cells by STORAGE_COLS, hatched, "UNSEARCHED", with a ring and a line that say what its search does
 * (fnc_updateStatus) - no grid, no tiles, no weight, no Sort, no load hint, no strip, whatever it really holds
 * and however big it is. Its seal alone is queued (fnc_markHidden); the caption line's chip searches, stops and resumes
 * it, and with "Search starts on click" a click on the block starts it. When the seal is done - about two seconds - the
 * window is built with the real grid, every item a hatched footprint, and the items are found one by one. The block
 * takes nothing: a drag held over it is refused there with "Search it first" (fnc_animateStatus).
 *
 * Its caption tab folds the section away (fnc_toggleSection); a uniform, vest or backpack opened from
 * inside a container gets a cross to close it (fnc_closeNested) - both by the section's container. The
 * box of a unit's uniform, vest or backpack is that unit's slot - right click and drag work on it; the
 * box of one opened from inside a container stands for its tile there, dragged and hinted like it. A
 * crate or vehicle shows the picture the editor has of it.
 *
 * A section starts folded when it says so ("folded": the crates found lying around) - the player's own
 * clicks on the tab are kept in GVAR(collapsed) as a change from that, so folding it again goes back to
 * the start. Folded, it keeps its caption line, weight and button.
 *
 * Beside the tab a button acts on the whole section, as high as the tab and in the caption's own size:
 * "Sort: Name" lays out its grid anew by the order the player has chosen and each click steps to the next
 * one - name, weight, size, type (fnc_sortHolder, fnc_sortChip: the label changes in place on every Sort
 * button, which is as wide as the widest label, fnc_sortButtons). The only way to sort: the context menu has
 * no row for it. Only the inventory has it (fnc_isInventoryMode), on every container the player may change -
 * a section that holds no grid of its own, a body's gear, has none; it is drawn disabled while a move of this
 * section is under way. Its label is centred by the engine in the width fnc_buttonWidth gives (fnc_uiButton,
 * "centred"). The tab gives up room to it down to three characters; below that the button is left out.
 *
 * A tall compartment in the loot column - a crate's or a vehicle's, up to MAX_ROWS rows - shows its rows
 * down to the last one in use and two more (fnc_viewBlocks); the empty rows below fold into one line under the grid,
 * "+32 empty rows (256 cells)", that opens them and folds them away again (fnc_toggleRows). Far less to
 * scroll through, and nothing of the room hidden (Mia, 0.2.3).
 * A drag let go on that line or on the box lays the item down in the first free spot, the folded rows too
 * (fnc_updateDrag).
 * Taller than a page (the client setting aio_gui_pageRows), the compartment is cut into pages instead: a bar under it
 * turns them, the fold line is not drawn and the pages end two rows after the last in use (fnc_pageRanges,
 * fnc_drawPageBar); a drop on the box or on the bar's name lies in the first free spot as on the fold line.
 *
 * Four kinds of section are drawn their own way:
 *   "drawer"            - a function name: another addon draws it (ACE cargo's cards,
 *                         aio_compat_ace_cargo_fnc_drawSection), called with this function's six
 *                         arguments and returning the height used
 *   "placeholder" true  - a uniform, vest or backpack the unit does not have: the box, empty and
 *                         hatched, and no grid; with an "owner" (the unit) the box is that unit's slot
 *                         of the section's id - right click and drop work on it, to put one on
 *   "worn" with "unit"  - a body's gear: its compact paper doll (fnc_drawEquipmentDoll) instead of
 *                         a grid of what it wears
 *   "locked" true       - locked to this player (aio_locks_fnc_decorate): the caption with a padlock
 *                         and "notice", why, in one muted line - nothing of what it holds;
 *                         "lockedObject" is the object behind it
 * A section the player may open only because of who they are brings "lockTip": an open padlock left of
 * the weight, with that text as its tooltip.
 *
 * A section may bring what its grid shows along rather than have it read from its container
 * (fnc_drawCompartments):
 *   "entries"   - what it shows; a grid of them is "virtual" unless the section says otherwise
 *   "virtual"   - false: things move in and out of its grid like a container's
 *   "kit"       - the kit class its grid stands for (aio_compat_efak)
 *   "layoutKey" - where its layout is kept (aio_storage_fnc_getLayout)
 *   "side"      - "own" or "loot" (the column it is in, when left out)
 *   "folded"    - starts folded
 *   "foldKey"   - a string the tab folds it by where it has no container (the Arsenal's kit sections)
 *   "root"      - whose locality decides who may change it
 *   "tabIcon"   - a small picture before the caption's text, in its colour (the Arsenal's staging crate)
 *   "box"       - false: no box with the container's picture, the grid at the section's left edge (the
 *                 Arsenal's panel, whose title band shows the container)
 * An open kit of Enhanced First Aid Kits is no section of a column any more: it opens in a window of
 * its own (fnc_drawWindow), so opening or closing one never moves anything in the columns.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in - the column's <CONTROL>
 * 2: Top of the section in the group <NUMBER>
 * 3: Width the section may take <NUMBER>
 * 4: Section, see aio_storage_fnc_getSections <HASHMAP>
 * 5: Theme <HASHMAP>
 *
 * Return Value:
 * Height used <NUMBER>
 *
 * Example:
 * [_display, _group, 0, 0.3, _section, _theme] call aio_gui_fnc_drawSection;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_top", "_width", "_section", "_theme"];

// A section another addon draws (ACE cargo's cards): its function takes the same six arguments and
// returns the height used.
private _drawer = _section getOrDefault ["drawer", ""];

if (_drawer isNotEqualTo "") exitWith {
    private _height = _this call (missionNamespace getVariable [_drawer, {}]);

    if (isNil "_height" || {!(_height isEqualType 0)}) then {0} else {_height}
};

private _id = _section getOrDefault ["id", ""];
private _placeholder = _section getOrDefault ["placeholder", false];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _colorLine = _theme getOrDefault ["line", [1, 1, 1, 0.07]];

// ---------------------------------------------------------------------------
// The block: the box as wide as three cells where the column has the room, the grid beside it, both
// centred in the column. Too narrow for a box of one and a half cells, the grid stands alone. A section
// that says "box" false has none and its grid starts at its left edge: the Arsenal's panel names and
// pictures the container in its own title band already.
// ---------------------------------------------------------------------------
(call FUNC(getCell)) params ["_cellW", "_cellH"];

// Every word on the section and every row that holds words grow with the tiles (TEXT_UNIT, fnc_textScale): the caption
// line, its chips and buttons, the weight, the box's name, the fold line.
private _textUnit = TEXT_UNIT;

private _gridW = STORAGE_COLS * _cellW;
private _gapX = SQUARE(UNIT * 0.35);
private _wantsBox = _section getOrDefault ["box", true];

// The strip of categories at the side of what is looted (fnc_drawGroupStrip): between the box and the grid, a slim column
// and a gap. It takes its room from the box - which gives way in half cells - and from nothing else, so the grid keeps
// its width; where the column has not even that to spare there is no strip. Only for a container with a grid of its own in
// the loot column (the player's own containers are small, a kit's grid and the Arsenal's panel are no loot).
// A box of the loot column this player has to search and has not opened yet (fnc_isSealed, issues 6 and 16): one block of
// a fixed size where the grid would be, and nothing of the container's real size or contents anywhere - no strip, no
// weight, no buttons, no hint of its load. Not a section that brings what it shows along (the Arsenal's, a kit's).
private _sealed = !_placeholder && {(_section getOrDefault ["side", _parent getVariable [QGVAR(column), ""]]) isEqualTo "loot"}
    && {_id in ["uniform", "vest", "backpack", "container", "ground"]} && {!(_section getOrDefault ["locked", false])}
    && {!("entries" in _section)} && {call FUNC(isInventoryMode)}
    && {[_section getOrDefault ["container", objNull]] call FUNC(isSealed)};

private _stripW = SQUARE(UNIT * 1);
private _stripOn = !_placeholder && {!_sealed} && {_wantsBox} && {(_section getOrDefault ["side", _parent getVariable [QGVAR(column), ""]]) isEqualTo "loot"}
    && {!isNull (_section getOrDefault ["container", objNull])} && {!(_section getOrDefault ["virtual", "entries" in _section])}
    && {!(_section getOrDefault ["locked", false])} && {_id in ["ground", "container", "uniform", "vest", "backpack"]}
    && {call FUNC(isInventoryMode)} && {(_width - _gridW - _gapX) >= (_stripW + _gapX)};
private _stripExtra = [0, _stripW + _gapX] select _stripOn;
private _boxCells = (floor (((_width - _gridW - _gapX - _stripExtra) / _cellW) * 2) / 2) min 3;
private _hasBox = _wantsBox && {_boxCells >= 1.5};
private _boxW = [0, _boxCells * _cellW] select _hasBox;
private _boxH = [0, _boxCells * _cellH] select _hasBox;
private _blockW = _gridW + ([0, _boxW + _gapX] select _hasBox) + _stripExtra;
// One pixel in from the left for the panel's block: drawCompartments outlines a pixel outside its cells,
// which the scroll group would clip at 0.
private _blockX = [pixelW, ((_width - _blockW) / 2) max 0] select _wantsBox;

// A body: its paper doll, as wide as the blocks under it.
private _body = _section getOrDefault ["unit", objNull];

if (_id isEqualTo "worn" && {!isNull _body}) exitWith {
    [_display, _parent, [_blockX, _top, _blockW min _width, -1], [_body] call EFUNC(storage,getEquipment), _theme, true, _body] call FUNC(drawEquipmentDoll)
};

// Locked to this player (aio_locks_fnc_decorate): the caption with a padlock where the chevron would
// be, why in one muted line - and nothing of what is inside: no box, no grid, no load, no button.
if (_section getOrDefault ["locked", false]) exitWith {
    private _lineH = _textUnit * 0.62;
    private _lineSize = _textUnit * 0.46;
    private _tabPad = SQUARE(_lineH * 0.5);
    private _lockW = SQUARE(_lineH);
    private _notice = _section getOrDefault ["notice", ""];
    private _captionText = [_section getOrDefault ["title", ""], _theme] call FUNC(caption);
    private _shown = [_captionText, _blockW - _tabPad - _lockW, _fontBold, _lineSize] call FUNC(fitText);
    private _tabW = (((_shown getTextWidth [_fontBold, _lineSize]) * TEXT_SLACK) + _tabPad + _lockW) min _blockW;
    private _iconH = _lineH * 0.6;

    [
        _display, _parent, [_blockX, _top, _tabW, _lineH], _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]],
        (_theme getOrDefault ["radius", 0]) min (_lineH / 2)
    ] call FUNC(uiPanel);
    [
        _display, _parent, [_blockX + (_lockW - SQUARE(_iconH)) / 2 + SQUARE(_lineH * 0.15), _top + (_lineH - _iconH) / 2, SQUARE(_iconH), _iconH],
        UI_TEX(icon_lock_ca), _colorText2
    ] call FUNC(uiIcon);
    [_display, _parent, [_blockX + _lockW, _top, _tabW - _lockW, _lineH], _shown, _lineSize, _colorText2, _fontBold, 2, "tab"] call FUNC(uiLabel);

    // Why, when the mouse rests on the tab.
    private _tip = [_display, "AIO_Hitbox", _parent, [_blockX, _top, _tabW, _lineH]] call FUNC(uiCreate);
    [_tip, _notice] call FUNC(setTooltip);

    [_display, _parent, [_blockX, _top + _lineH, _blockW, pixelH], _colorLine] call FUNC(uiPanel);

    [
        _display, _parent, [_blockX, _top + _lineH + UNIT * 0.25, _blockW, _textUnit * 0.62],
        [_notice, _blockW, _font, _lineSize] call FUNC(fitText), _lineSize, _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _font, 0, "hint"
    ] call FUNC(uiLabel);

    _lineH + UNIT * 0.25 + _textUnit * 0.7
};

// ---------------------------------------------------------------------------
// What it holds - nothing to read for a placeholder.
// ---------------------------------------------------------------------------
private _entries = [];
private _layout = createHashMap;

// Which column it is in: the unit's own storage or what it loots (fnc_drawColumn names the group).
private _side = _section getOrDefault ["side", ""];

if (_side isEqualTo "") then {
    _side = switch (_parent getVariable [QGVAR(column), ""]) do {
        case "storage": {"own"};
        case "loot": {"loot"};
        default {""};
    };

    _section set ["side", _side];
};

if (!_placeholder) then {
    private _container = _section getOrDefault ["container", objNull];

    _entries = if ("entries" in _section) then {
        _section get "entries"
    } else {
        [_container] call EFUNC(storage,getContents)
    };

    _layout = [_section getOrDefault ["layoutKey", _container], _entries] call EFUNC(storage,getLayout);

    // Single slots that grow are as large as the item in them, the others make room (fnc_growSlots).
    _layout = [_layout] call FUNC(growSlots);
};

// A canvas (compartments with a pos) is wider than STORAGE_COLS cells where seams open it between two of
// them (fnc_flowCompartments): the grid takes that room and the box gives way - smaller, or none at all
// where less than one and a half cells are left. Folding rows (fnc_viewBlocks) changes no width.
if (!_sealed && {(_layout getOrDefault ["blocks", []]) findIf {(_x param [3, []]) isNotEqualTo []} >= 0}) then {
    _gridW = (STORAGE_COLS * _cellW) max (([_layout] call FUNC(flowCompartments)) select 2);
    _stripOn = _stripOn && {(_width - _gridW - _gapX) >= (_stripW + _gapX)};
    _stripExtra = [0, _stripW + _gapX] select _stripOn;
    _boxCells = (floor (((_width - _gridW - _gapX - _stripExtra) / _cellW) * 2) / 2) min 3;
    _hasBox = _wantsBox && {_boxCells >= 1.5};
    _boxW = [0, _boxCells * _cellW] select _hasBox;
    _boxH = [0, _boxCells * _cellH] select _hasBox;
    _blockW = _gridW + ([0, _boxW + _gapX] select _hasBox) + _stripExtra;
    _blockX = [pixelW, ((_width - _blockW) / 2) max 0] select _wantsBox;
};

// ---------------------------------------------------------------------------
// Caption line: the tab on the left, the weight of the contents on the right, a hairline under both.
// ---------------------------------------------------------------------------
private _caption = switch (_id) do {
    case "vest": {LLSTRING(Tarkov_TacticalRig)};
    case "uniform": {LLSTRING(Tarkov_Pockets)};
    case "backpack": {LLSTRING(Tarkov_Backpack)};
    default {_section getOrDefault ["title", ""]};
};

// A sealed pile is "Ground" alone: "Ground - Rifle" would name what lies in it.
if (_sealed && {_id isEqualTo "ground"}) then {
    _caption = LELSTRING(storage,Ground);
};

// What someone else wears says whose it is (issue 7: a body's "Backpack" read as the player's own): "Backpack -
// Miller" in the loot column, the player's own stay "Backpack".
private _loot = _side isEqualTo "loot";

if (_loot && {_id in ["uniform", "vest", "backpack"]}) then {
    private _wearer = ([_section getOrDefault ["container", objNull]] call EFUNC(storage,getOwner)) select 0;
    private _wearerName = [_wearer] call FUNC(ownerName);

    if (_wearerName isNotEqualTo "") then {
        _caption = format [LLSTRING(Section_OwnedBy), _caption, _wearerName];
    };
};

// The caption line (CAPTION_LINE) is a button row: the tab, the buttons and the cross are on it, each hit area its own
// drawing and two pixels.
private _lineH = _textUnit * CAPTION_LINE;
private _lineSize = _textUnit * 0.46;

// The buttons on the line (Sort and the activity chip) are a little lower than the line and stand in
// the middle of it, a clear gap above the line under it and above the container's top edge; their hit area is the button
// and two pixels each way. The caption's own tab is one of them (Mia, 0.5.7): the same height, the same text size and the same
// round ends - a pill with the fold arrow in its left end - and so is every other chip of the line.
private _buttonH = _textUnit * 0.6;
private _buttonTop = _top + (_lineH - _buttonH) / 2;
private _buttonSize = _textUnit * TEXT_REF;
private _chipRadius = (_theme getOrDefault ["radius", 0]) min (_buttonH / 2);
private _tabPad = SQUARE(_buttonH * 0.9);
private _hitPx = [pixelW * 2, pixelH * 2, pixelW * 2, pixelH * 2];

private _load = "";

if (!_placeholder && {!_sealed}) then {
    _load = [_entries] call FUNC(loadText);
};

// A click on the tab folds the section away to this line, or opens it again (fnc_toggleSection); one
// opened from inside a container (fnc_openNested) has a cross to close it at the end of the line. Both
// go by the section's container - a section with none folds and closes not at all. Folded is what the
// section starts as, changed by the player's own clicks (GVAR(collapsed)).
private _sectionContainer = _section getOrDefault ["container", objNull];

// What a click on the tab folds by: the container, else the section's own "foldKey" (a string: the Arsenal's
// kit sections, whose grid has no container).
private _foldKey = _section getOrDefault ["foldKey", _sectionContainer];
private _foldable = !isNull _sectionContainer || {_foldKey isEqualType "" && {_foldKey isNotEqualTo ""}};
private _collapsed = _foldable && {(_section getOrDefault ["folded", false]) isNotEqualTo (_foldKey in GVAR(collapsed))};
private _nested = !isNull _sectionContainer && {GVAR(opened) findIf {(_x select 1) isEqualTo _sectionContainer} >= 0};
private _chevronW = [0, SQUARE(_buttonH * 0.95)] select _foldable;
private _closeW = [0, SQUARE(_lineH)] select _nested;

// A small picture before the caption's text, where the section brings one ("tabIcon" - the Arsenal's
// staging space has a crate).
private _tabIcon = _section getOrDefault ["tabIcon", ""];
private _tabIconW = [0, SQUARE(_buttonH * 0.95)] select (_tabIcon isNotEqualTo "");

// Open to this player only because of who they are (aio_locks_fnc_decorate): an open padlock left of
// the weight says so when the mouse rests on it.
private _lockTip = _section getOrDefault ["lockTip", ""];
private _lockW = [0, SQUARE(_lineH)] select (_lockTip isNotEqualTo "");

// ---------------------------------------------------------------------------
// The button beside the tab: Sort, for a container the player may change - on every grid of its own, so also on an empty one.
// ---------------------------------------------------------------------------
private _sortable = false;
private _busy = false;

if (
    !_placeholder && {!_sealed} && {!isNull _sectionContainer} && {_id in ["ground", "container", "uniform", "vest", "backpack"]}
    && {_side in ["own", "loot"]} && {call FUNC(isInventoryMode)}
    && {([_sectionContainer, "items"] call FUNC(checkTouch)) isEqualTo ""}
) then {
    // A section that only shows what it is given has no grid of its own to sort.
    _sortable = !(_section getOrDefault ["virtual", "entries" in _section]);

    // A move that takes from this section is under way: a second press would plan the same things twice.
    // A HashMap: _y is a move's record, its sources first.
    {
        if (((_y param [0, []]) findIf {(_x param [0, objNull]) isEqualTo _sectionContainer}) >= 0) exitWith {
            _busy = true;
        };
    } forEach GVAR(inFlight);
};

// What it is meant to be - the tab may give the button up for lack of room below. The caption line is
// _buttonH high and in the middle of the line (the tab and the cross are _lineH high): the labels are a little smaller
// than the tab's. A button is [id, label, icon, width]; they stand in this order beside the tab, and for
// lack of room the last one goes first.
private _buttonGap = SQUARE(_textUnit * 0.3);
private _buttons = [];

if (_sortable) then {
    // "Sort: Name", the order the player sorts by now; as wide as the widest of its labels, so a click that
    // steps to the next order changes the words in place and nothing on the line moves (fnc_sortChip).
    ([_buttonH, _buttonSize, _theme] call FUNC(sortChip)) params ["_sortLabel", "_sortIcon", "_sortW"];

    _buttons pushBack ["sort", _sortLabel, _sortIcon, _sortW];
};

// What the buttons take, each with the gap before it.
private _fnc_buttonsW = {
    private _sum = 0;

    {
        _sum = _sum + (_x select 3) + _buttonGap;
    } forEach _buttons;

    _sum
};

private _loadW = [0, (_load getTextWidth [_font, _lineSize]) * TEXT_SLACK + SQUARE(_textUnit * 0.3)] select (_load isNotEqualTo "");

// How many characters of a shortened text are left of it.
private _fnc_chars = {
    params ["_text"];

    private _count = count _text;

    [_count, _count - 3] select (_count >= 3 && {(_text select [_count - 3]) isEqualTo "..."})
};

private _captionText = [_caption, _theme] call FUNC(caption);
private _tabRoom = _blockW - _loadW - _closeW - _lockW - (call _fnc_buttonsW);
private _shown = [_captionText, _tabRoom - _tabPad - _chevronW - _tabIconW, _fontBold, _buttonSize] call FUNC(fitText);

// The tab gives up room to the buttons down to three characters - and the last button is left out below
// that, then the one before it.
while {_buttons isNotEqualTo [] && {([_shown] call _fnc_chars) < (3 min count _captionText)}} do {
    _buttons deleteAt (count _buttons - 1);
    _tabRoom = _blockW - _loadW - _closeW - _lockW - (call _fnc_buttonsW);
    _shown = [_captionText, _tabRoom - _tabPad - _chevronW - _tabIconW, _fontBold, _buttonSize] call FUNC(fitText);
};

private _tabW = (((_shown getTextWidth [_fontBold, _buttonSize]) * TEXT_SLACK) + _tabPad + _chevronW + _tabIconW) min _tabRoom;
private _tabColor = _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]];

// What is looted has a tab and a hairline of its own colour where the theme gives one (lootTab, lootLine), so a caption in
// the loot column never reads as one of the player's own; [] keeps the plain ones.
if (_loot) then {
    private _lootTab = _theme getOrDefault ["lootTab", []];
    private _lootLine = _theme getOrDefault ["lootLine", []];

    if (_lootTab isNotEqualTo []) then {
        _tabColor = _lootTab;
    };

    if (_lootLine isNotEqualTo []) then {
        _colorLine = _lootLine;
    };
};

private _tab = [];

if (_shown isNotEqualTo "") then {
    _tab = [_display, _parent, [_blockX, _buttonTop, _tabW, _buttonH], _tabColor, _chipRadius] call FUNC(uiPanel);

    // The words in the middle of the pill, set as the buttons' are (fnc_uiButton, "centred"): the line of capitals in the middle of its height.
    [
        _display, _parent,
        [_blockX + _chevronW + _tabIconW, _buttonTop + _buttonH / 2 - TEXT_MID * _buttonSize, _tabW - _chevronW - _tabIconW, TEXT_MID * _buttonSize * 2],
        _shown, _buttonSize, _colorText2, _fontBold, 2, "tab"
    ] call FUNC(uiLabel);

    if (_tabIconW > 0) then {
        private _tabIconH = _buttonH * 0.62;

        [
            _display, _parent, [_blockX + _chevronW + (_tabIconW - SQUARE(_tabIconH)) / 2, _buttonTop + (_buttonH - _tabIconH) / 2, SQUARE(_tabIconH), _tabIconH],
            _tabIcon, _colorText2
        ] call FUNC(uiIcon);
    };
};

// What a later draw of this section's tiles needs to find again (fnc_redrawTiles, fnc_applyFilter), and
// whether its button was drawn held back for a move under way (fnc_refresh builds once none is left).
private _info = createHashMapFromArray [
    ["holder", _sectionContainer], ["id", _id], ["side", _side], ["folded", _collapsed], ["tab", _tab],
    ["tabColor", _tabColor], ["load", controlNull],
    ["caption", _caption], ["busy", _busy], ["sealed", _sealed]
];

private _infoIndex = -1;

// Only a section with a container is one the status chips, filters and moves look up by it.
if (!isNull _sectionContainer && {!_placeholder}) then {
    _infoIndex = (uiNamespace getVariable [QGVAR(sectionInfo), []]) pushBack _info;
};

if (_chevronW > 0) then {
    private _iconH = _buttonH * 0.56;

    [
        _display, _parent, [_blockX + (_chevronW - SQUARE(_iconH)) / 2 + SQUARE(_buttonH * 0.12), _buttonTop + (_buttonH - _iconH) / 2, SQUARE(_iconH), _iconH],
        [UI_TEX(icon_chevron_down_ca), UI_TEX(icon_chevron_right_ca)] select _collapsed, _colorText2
    ] call FUNC(uiIcon);

    // The drawn pill and two pixels round it.
    private _toggle = [
        _display, "AIO_Hitbox", _parent, [_blockX - pixelW * 2, _buttonTop - pixelH * 2, (_tabW max _chevronW) + pixelW * 4, _buttonH + pixelH * 4]
    ] call FUNC(uiCreate);
    [_toggle, LLSTRING(Section_Toggle)] call FUNC(setTooltip);
    _toggle setVariable [QGVAR(key), _foldKey];
    _toggle ctrlAddEventHandler ["ButtonClick", {
        [{_this call FUNC(toggleSection)}, [(_this select 0) getVariable [QGVAR(key), objNull]]] call FUNC(later);
    }];
};

// The buttons, a gap right of the tab and of each other, as high as the tab, their labels centred. A click
// finds the section again by its place in the list of what the sections drew, in this build
// (GVAR(buildCount)); the code runs when the button is pressed, with nothing of this function around it.
private _fnc_click = {
    params ["_direction", "_buttonId"];

    if (_direction != 1) exitWith {};

    (_buttonId splitString "|") params ["_kind", "_at", ["_build", ""]];

    // The click runs a frame later (fnc_uiButton): a window built again meanwhile has other
    // sections at those places - the click is void then.
    if (_build isNotEqualTo str GVAR(buildCount)) exitWith {};

    private _holder = ((uiNamespace getVariable [QGVAR(sectionInfo), []]) param [parseNumber _at, createHashMap]) getOrDefault ["holder", objNull];

    if (isNull _holder) exitWith {};

    switch (_kind) do {
        // Sort steps its order at each click and sends one request (fnc_sortHolder).
        case "sort": {[_holder, objNull, true] call FUNC(sortHolder)};
    };
};

private _buttonX = _blockX + _tabW + _buttonGap;

{
    _x params ["_kind", "_label", "_icon", "_buttonW"];

    private _button = [
        _display, _parent, [_buttonX, _buttonTop, _buttonW, _buttonH], format ["%1|%2|%3", _kind, _infoIndex, GVAR(buildCount)],
        _label, _icon, _theme, _fnc_click, _busy, _buttonSize, true, _hitPx
    ] call FUNC(uiButton);

    // What it does, when the mouse rests on it: what its next click sorts by (fnc_sortText), kept up to date as the
    // order changes (fnc_sortButtons).
    [(_button select -1), (([GVAR(sortMode)] call FUNC(sortText)) select 1)] call FUNC(setTooltip);
    [_button] call FUNC(sortButtons);

    _buttonX = _buttonX + _buttonW + _buttonGap;
} forEach _buttons;

// Where the activity chip goes (fnc_updateStatus): right of the buttons, as high as they are and in the middle of the line, up to
// the weight - and over the weight where that is too little room for the ring, a few words and the button.
if (_foldable && {!_placeholder} && {call FUNC(isInventoryMode)}) then {
    private _chipLeft = _buttonX max (_blockX + _tabW + _buttonGap);
    private _chipRight = _blockX + _blockW - _closeW - _lockW - _buttonGap;
    private _beside = _blockX + _blockW - _closeW - _loadW - _lockW - _buttonGap - _chipLeft;
    private _wanted = SQUARE(_buttonH) * 2 + ((format [LLSTRING(Status_Search), "0:00"]) getTextWidth [_fontBold, _buttonSize]) * TEXT_SLACK;
    private _room = [_chipRight - _chipLeft, _beside] select (_beside >= _wanted);

    if (_room >= _wanted * 0.85) then {
        _info set ["statusParent", _parent];
        _info set ["statusRect", [_chipLeft, _buttonTop, _room, _buttonH]];
        _info set ["statusSize", _buttonSize];
        _info set ["statusCover", _beside < _wanted];
    };
};

// The weight of what it holds, right-aligned on the caption line.
if (_load isNotEqualTo "") then {
    private _labelRect = [_blockX + _blockW - _closeW - _loadW, _top, _loadW, _lineH];

    _info set ["load", [_display, _parent, _labelRect, _load, _lineSize, _colorText2, _font, 1, -1] call FUNC(uiLabel)];
};

// The open padlock, left of the weight.
if (_lockTip isNotEqualTo "") then {
    private _iconH = _lineH * 0.6;
    private _lockX = _blockX + _blockW - _closeW - _loadW - _lockW;

    [
        _display, _parent, [_lockX + (_lockW - SQUARE(_iconH)) / 2, _top + (_lineH - _iconH) / 2, SQUARE(_iconH), _iconH],
        UI_TEX(icon_lock_open_ca), _colorText2
    ] call FUNC(uiIcon);

    private _lockHit = [_display, "AIO_Hitbox", _parent, [_lockX, _top, _lockW, _lineH]] call FUNC(uiCreate);
    [_lockHit, _lockTip] call FUNC(setTooltip);
};

// The hint over the caption line says what the contents weigh (fnc_infoHint).
if (!isNull _sectionContainer && {!_placeholder} && {!_sealed}) then {
    private _captionAnchor = createHashMapFromArray [["rel", [_blockX, _top]], ["parent", _parent]];
    ([_captionAnchor] call FUNC(gridOrigin)) params ["_captionX", "_captionY"];

    (uiNamespace getVariable [QGVAR(infoAreas), []]) pushBack [
        [_captionX, _captionY, _blockW, _lineH], "", "", _captionAnchor, "load", [_sectionContainer, _caption]
    ];
};

if (_nested) then {
    private _iconH = _lineH * 0.7;
    private _closeX = _blockX + _blockW - _closeW;

    [_display, _parent, [_closeX + (_closeW - SQUARE(_iconH)) / 2, _top + (_lineH - _iconH) / 2, SQUARE(_iconH), _iconH], UI_TEX(icon_close_ca), _colorText2] call FUNC(uiIcon);

    private _close = [
        _display, "AIO_Hitbox", _parent, [_closeX - pixelW * 2, _top - pixelH * 2, _closeW + pixelW * 4, _lineH + pixelH * 4]
    ] call FUNC(uiCreate);
    [_close, LLSTRING(Section_Close)] call FUNC(setTooltip);
    _close setVariable [QGVAR(key), _sectionContainer];
    _close ctrlAddEventHandler ["ButtonClick", {
        [{_this call FUNC(closeNested)}, [(_this select 0) getVariable [QGVAR(key), objNull]]] call FUNC(later);
    }];
};

// The hairline under the caption.
[_display, _parent, [_blockX, _top + _lineH, _blockW, pixelH], _colorLine] call FUNC(uiPanel);

// Folded away: the caption line is all there is.
if (_collapsed) exitWith {_lineH + UNIT * 0.25};

private _bodyTop = _top + _lineH + UNIT * 0.25;

// A tall compartment of what is looted - a crate's, a vehicle's - shows its rows down to the last one in
// use and a little more; the empty rows below fold into a line under the grid (fnc_viewBlocks). The view
// only: the layout and the places stay the whole container's. The unit's own storage shows all of its
// rows, where the player arranges what he carries.
private _view = if (isNull _sectionContainer || {_placeholder} || {_sealed} || {_side isNotEqualTo "loot"}) then {
    [[], 0, false, 0, []]
} else {
    [_layout, _sectionContainer] call FUNC(viewBlocks)
};
_view params ["_viewBlocks", "_hiddenRows", "_rowsFoldable", "_hiddenCells", ["_paging", []]];

// A compartment taller than a page (aio_gui_pageRows) is cut into pages with a bar under it (fnc_drawPageBar); the
// bar takes room in the flow, below the page's rows. Its page is as tall as the tallest of its pages, so turning one
// never moves what lies below.
private _anyPaged = _paging findIf {_x isNotEqualTo []} >= 0;

// Whether the line is there - a later draw of the tiles alone (fnc_redrawTiles) must not change that.
_info set ["foldable", _rowsFoldable];

private _drawLayout = _layout;

if (_rowsFoldable || {_anyPaged}) then {
    _drawLayout = createHashMap;
    _drawLayout merge _layout;
    _drawLayout set ["blocks", _viewBlocks];
    _drawLayout set ["paging", _paging];
};

// The compartments (aio_storage_fnc_getBlocks), side by side as far as STORAGE_COLS cells reach, then
// on the next line - and, should anything not fit any of them, a line of its own for that. A paged one takes the room
// of its tallest page and its bar.
private _flowLayout = _drawLayout;

if (_anyPaged) then {
    _flowLayout = createHashMap;
    _flowLayout merge _drawLayout;
    private _flowBlocks = [];

    {
        private _pageOf = _paging param [_forEachIndex, []];

        if (_pageOf isEqualTo []) then {
            _flowBlocks pushBack _x;
        } else {
            _x params ["_cols", "", "_holes", "_pos"];

            _flowBlocks pushBack [
                _cols, selectMax ((_pageOf select 1) apply {(_x param [2, _x select 1]) - (_x select 0)}) + PAGE_RESERVE(_cellW) / _cellH, _holes, _pos
            ];
        };
    } forEach _viewBlocks;

    _flowLayout set ["blocks", _flowBlocks];
};

([_flowLayout] call FUNC(flowCompartments)) params ["_places", "_blocksH"];

// Sealed: no compartment is drawn, the block is as high as SEAL_ROWS cells whatever the container holds.
if (_sealed) then {
    _places = [];
    _blocksH = SEAL_ROWS * _cellH;
};

private _gridX = _blockX + ([0, _boxW + _gapX] select _hasBox) + _stripExtra;

// ---------------------------------------------------------------------------
// The box
// ---------------------------------------------------------------------------
if (_hasBox) then {
    private _boxRect = [_blockX, _bodyTop, _boxW, _boxH];
    private _class = _section getOrDefault ["class", ""];

    // No item behind a crate, the ground or a body's gear: a plain box with what it is - a crate or a
    // vehicle with the picture the editor shows of it (editorPreview), else its icon.
    if (_class isEqualTo "" && {!_placeholder}) exitWith {
        private _icon = switch (_id) do {
            case "ground": {UI_TEX(icon_ground_ca)};
            case "container": {UI_TEX(icon_crate_ca)};
            case "worn": {UI_TEX(icon_person_ca)};
            default {UI_TEX(icon_inventory_ca)};
        };

        private _preview = "";
        private _own = "";
        private _boxIcon = ICON_PLAIN;

        // Whether the file is there is asked once per path (fnc_safePicture keeps the answer): a build asked
        // the disk for every crate's picture again.
        if (_id isEqualTo "container" && {!isNull _sectionContainer}) then {
            _preview = [getText (configOf _sectionContainer >> "editorPreview")] call FUNC(safePicture);

            // What the rules make of the class (picture=, icon=): a picture of their own instead of the editor's,
            // and either one larger, smaller or moved inside the box.
            private _boxInfo = [typeOf _sectionContainer] call EFUNC(items,getInfo);
            private _ruled = _boxInfo getOrDefault ["pictureOverride", ""];

            if (_ruled isNotEqualTo "" && {(_boxInfo getOrDefault ["picture", ""]) == _ruled}) then {
                _own = [_ruled] call FUNC(safePicture);
            };

            _boxIcon = _boxInfo getOrDefault ["icon", ICON_PLAIN];
        };

        private _boxRadius = (_theme getOrDefault ["radius", 0]) min (_boxH / 4);

        [_display, _parent, _boxRect, _theme getOrDefault ["slot", [1, 1, 1, 0.06]], _boxRadius, _theme getOrDefault ["slotBorder", []]] call FUNC(uiPanel);

        // The picture of the rules or the editor's (fnc_uiBoxPicture), else the icon of what the box is.
        if (([_display, _parent, _boxRect, _theme, _own, _preview, _boxIcon, _boxRadius] call FUNC(uiBoxPicture)) isEqualTo []) then {
            [_display, _parent, [_blockX + _boxW * 0.25, _bodyTop + _boxH * 0.25, _boxW * 0.5, _boxH * 0.5], _icon, _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]]] call FUNC(uiIcon);
        };
    };

    // A uniform, vest or backpack is a slot like the doll's, so the hint names it - or, while the unit
    // has none, says that it is empty. Its caption is already on the tab above, not again in the box.
    private _icon = switch (_id) do {
        case "vest": {GEAR_ICON(ui_gear_vest_gs)};
        case "uniform": {GEAR_ICON(ui_gear_uniform_gs)};
        case "backpack": {GEAR_ICON(ui_gear_backpack_gs)};
        default {""};
    };

    private _boxTheme = createHashMap;
    _boxTheme merge _theme;
    _boxTheme set ["slotCaption", "none"];

    if (_placeholder) then {
        _boxTheme set ["slotBorder", _colorLine];
    };

    // Whose it is: the box is that unit's slot, so a right click or a drag works on it as on the card.
    private _boxOptions = createHashMapFromArray [["caption", _caption], ["icon", _icon]];
    ([_sectionContainer] call EFUNC(storage,getOwner)) params ["_owner", "_ownerSlot"];

    if (!isNull _owner && {_ownerSlot isEqualTo _id}) then {
        _boxOptions set ["slot", _id];
        _boxOptions set ["unit", _owner];
    };

    // Opened from inside a container (fnc_openNested), nobody wears it: the box stands for its tile there,
    // lifted and hinted as that tile (fnc_boxTile) - the same drag, wherever it is let go.
    if (_nested && {isNull _owner}) then {
        _boxOptions set ["container", _sectionContainer];
    };

    // A placeholder has no container to name its owner: it brings the unit itself.
    private _placeholderOwner = _section getOrDefault ["owner", objNull];

    if (_placeholder && {!isNull _placeholderOwner}) then {
        _boxOptions set ["slot", _id];
        _boxOptions set ["unit", _placeholderOwner];
    };

    [_display, _parent, _boxRect, _class, _boxOptions, _boxTheme] call FUNC(drawSlot);

    if (_class isEqualTo "") exitWith {};

    private _padY = (_boxH * 0.08) min (UNIT * 0.25);
    private _padX = SQUARE(_padY);
    private _name = [[_class, true] call FUNC(itemName), _boxW - _padX * 2, _font, _lineSize] call FUNC(fitText);

    [_display, _parent, [_blockX + _padX, _bodyTop + _padY * 0.5, _boxW - _padX * 2, _lineH], _name, _lineSize, _colorText2, _font, 1, "name"] call FUNC(uiLabel);
};

// ---------------------------------------------------------------------------
// The compartments and their tiles
// ---------------------------------------------------------------------------
if (_sealed) then {
    // The block: as wide as a grid of STORAGE_COLS cells and SEAL_ROWS high, on the caption's surface (the loot tint where the
    // theme has one, issue 7) with the hatching of what is not searched. The hatching fills the block to its edges and leaves out
    // the round corners (fnc_uiHatch's boxes, cut along the curve pixel line by pixel line) -
    // square stripes in the round corners stood out, and a corner's width kept free at both sides framed the stripes.
    // "UNSEARCHED" in the middle, a ring over it that goes round while this box is searched, and one line under it that says
    // what the search does - written by fnc_updateStatus (the "seal" of the section's info), the ring turned by
    // fnc_animateStatus.
    private _sealW = STORAGE_COLS * _cellW - pixelW;
    private _sealH = SEAL_ROWS * _cellH - pixelH;
    private _sealRadius = (_theme getOrDefault ["radius", 0]) min (_sealH / 4);
    private _stripe = +_colorLine;

    _stripe set [3, ((_stripe select 3) * 1.8) min 0.2];

    [_display, _parent, [_gridX, _bodyTop, _sealW, _sealH], _tabColor, _sealRadius] call FUNC(uiPanel);
    // The bands: the middle edge to edge, and above and below it one line of pixels each, as wide as the round corners leave it -
    // so the stripes follow the curve rather than leaving a square cut out of each corner.
    private _radiusPx = round (_sealRadius / pixelH);
    private _clips = [[_gridX, _bodyTop + _radiusPx * pixelH, _sealW, _sealH - _radiusPx * pixelH * 2]];

    for "_row" from 0 to (_radiusPx - 1) do {
        private _dy = _radiusPx - _row - 0.5;
        private _inset = (_radiusPx - sqrt ((_radiusPx ^ 2 - _dy ^ 2) max 0)) * pixelW;

        _clips pushBack [_gridX + _inset, _bodyTop + _row * pixelH, _sealW - _inset * 2, pixelH];
        _clips pushBack [_gridX + _inset, _bodyTop + _sealH - (_row + 1) * pixelH, _sealW - _inset * 2, pixelH];
    };

    [_display, _parent, [_gridX, _bodyTop, _sealW, _sealH], _stripe, _clips] call FUNC(uiHatch);

    private _ringH = _textUnit * 0.95;
    private _wordSize = _textUnit * 0.62;
    private _lineSmall = _textUnit * TEXT_REF;
    private _stackH = _ringH + _textUnit * 0.15 + _wordSize * 1.2 + _lineSmall * 1.3;
    private _stackTop = _bodyTop + (((_sealH - _stackH) / 2) max 0);
    private _ringRect = [_gridX + (_sealW - SQUARE(_ringH)) / 2, _stackTop, SQUARE(_ringH), _ringH];

    [_display, _parent, _ringRect, SEARCH_RING(SEARCH_FRAMES), _theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]] call FUNC(uiIcon);

    private _arc = [_display, _parent, _ringRect, SEARCH_RING(STATUS_ARC), _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] call FUNC(uiIcon);
    _arc ctrlShow false;

    private _wordTop = _stackTop + _ringH + _textUnit * 0.15;

    [
        _display, _parent, [_gridX, _wordTop, _sealW, _wordSize * 1.2],
        [toUpper LLSTRING(Seal_Unsearched), _sealW, _fontBold, _wordSize] call FUNC(fitText), _wordSize, _colorText2, _fontBold, 2, "hint"
    ] call FUNC(uiLabel);

    private _sealLine = [
        _display, _parent, [_gridX, _wordTop + _wordSize * 1.2, _sealW, _lineSmall * 1.3], "", _lineSmall,
        _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _font, 2
    ] call FUNC(uiLabel);

    // A drag held over the block is refused there (fnc_animateStatus): a film in the loss colour, hidden until then, and
    // where the block and its column lie, to find it on the screen as the column scrolls.
    private _loss = +(_theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]);

    _loss set [3, 0.18];

    private _film = [_display, _parent, [_gridX, _bodyTop, _sealW, _sealH], _loss, _sealRadius] call FUNC(uiPanel);

    {_x ctrlShow false} forEach _film;

    (ctrlPosition _parent) params ["_frameX", "_frameY", "_frameW", "_frameH"];

    _info set ["seal", createHashMapFromArray [
        ["arc", _arc], ["line", _sealLine], ["width", _sealW], ["size", _lineSmall], ["state", ""], ["words", ""], ["film", _film],
        ["anchor", createHashMapFromArray [["rel", [_gridX, _bodyTop]], ["parent", _parent]]], ["blockSize", [_sealW, _sealH]],
        ["frame", createHashMapFromArray [["rel", [_frameX, _frameY]], ["parent", ctrlParentControlsGroup _parent]]],
        ["frameSize", [_frameW, _frameH]]
    ]];

    // With "Search starts on click" a click on the block starts or resumes its search, as the chip's Search button does;
    // it never stops it (the chip's cross does).
    if (GVAR(searchOnClick)) then {
        private _sealHit = [_display, "AIO_Hitbox", _parent, [_gridX, _bodyTop, _sealW, _sealH]] call FUNC(uiCreate);

        [_sealHit, LLSTRING(Status_StartSearch)] call FUNC(setTooltip);
        _sealHit setVariable [QGVAR(key), _sectionContainer];
        _sealHit ctrlAddEventHandler ["ButtonClick", {
            [{
                params ["_holder"];

                if (_holder in GVAR(searchPaused)) then {
                    [_holder, "search"] call FUNC(stopStatus);
                };
            }, [(_this select 0) getVariable [QGVAR(key), objNull]]] call FUNC(later);
        }];
    };

    // Its seal is queued alone (fnc_markHidden) and waits for the click with "Search starts on click"; the seal's end
    // builds the window with the real grid, whose items are queued then (fnc_animateSearch).
    [_sectionContainer, _layout getOrDefault ["entries", []], true, true] call FUNC(markHidden);
} else {
    [_display, _parent, [_gridX, _bodyTop], _section, _drawLayout, _places, _theme] call FUNC(drawCompartments);
};

private _used = (_bodyTop - _top) + (_boxH max _blocksH);

// The strip of categories between the box and the grid: as high as the box or the grid, and never so small that its
// pictures get smaller than STRIP_ICON_MIN of a UNIT (the section grows then).
if (_stripOn) then {
    private _pitch = (((_boxH max _blocksH) / 8) max (UNIT * STRIP_ICON_MIN)) min (UNIT * STRIP_ICON);

    [
        _display, _parent, [_gridX - _stripExtra, _bodyTop, _stripW, _pitch * 8], _sectionContainer, _info, _theme
    ] call FUNC(drawGroupStrip);

    _used = _used max ((_bodyTop - _top) + _pitch * 8);
};

// ---------------------------------------------------------------------------
// The empty rows folded away: one line under the grid that says how many and opens them - or, opened,
// folds them away again (fnc_toggleRows).
// ---------------------------------------------------------------------------
// A drop on the box of a paged container, or on the middle of its bar, is laid down in its first free spot, whatever page
// it is on (fnc_updateDrag, GVAR(foldAreas)) - the outer parts of the bar turn the page instead (PAGE_ZONE).
if (_anyPaged && {!isNull _sectionContainer}) then {
    private _areas = uiNamespace getVariable [QGVAR(foldAreas), []];

    if (_hasBox) then {
        _areas pushBack createHashMapFromArray [["rel", [_blockX, _bodyTop]], ["parent", _parent], ["size", [_boxW, _boxH]], ["container", _sectionContainer]];
    };

    {
        if (_x isEqualTo []) then {continue};

        private _place = _places param [_forEachIndex, []];

        if (_place isEqualTo []) then {continue};

        (_viewBlocks select _forEachIndex) params ["_pagedCols"];

        private _pageTall = selectMax ((_x select 1) apply {(_x param [2, _x select 1]) - (_x select 0)});
        private _barTop = PAGE_BAR_TOP(_bodyTop + (_place select 1),_pageTall,_cellW,_cellH);
        private _barH = UNIT * PAGE_BAR_H;
        private _barW = _pagedCols * _cellW - pixelW;

        _areas pushBack createHashMapFromArray [
            ["rel", [_gridX + (_place select 0) + _barW * PAGE_ZONE, _barTop]], ["parent", _parent],
            ["size", [_barW * (1 - 2 * PAGE_ZONE), _barH]], ["container", _sectionContainer]
        ];
    } forEach _paging;

    uiNamespace setVariable [QGVAR(foldAreas), _areas];
};

if (_rowsFoldable) then {
    private _rowsTop = _top + _used + UNIT * 0.15;
    private _rowsText = if (_hiddenRows > 0) then {
        format [LLSTRING(Rows_Show), _hiddenRows, _hiddenCells]
    } else {
        LLSTRING(Rows_Hide)
    };
    private _iconH = _lineH * 0.6;
    private _iconW = SQUARE(_iconH);
    private _rowsW = (STORAGE_COLS * _cellW) min (_blockX + _blockW - _gridX);

    [
        _display, _parent, [_gridX, _rowsTop, _rowsW, _lineH], _tabColor,
        (_theme getOrDefault ["radius", 0]) min (_lineH / 2)
    ] call FUNC(uiPanel);

    [
        _display, _parent, [_gridX + SQUARE(_lineH * 0.2), _rowsTop + (_lineH - _iconH) / 2, _iconW, _iconH],
        [UI_TEX(icon_chevron_down_ca), UI_TEX(icon_chevron_right_ca)] select (_hiddenRows == 0), _colorText2
    ] call FUNC(uiIcon);

    private _textX = _gridX + SQUARE(_lineH * 0.4) + _iconW;
    private _textW = _rowsW - (_textX - _gridX) - SQUARE(_lineH * 0.2);

    [
        _display, _parent, [_textX, _rowsTop, _textW, _lineH],
        [[_rowsText, _theme] call FUNC(caption), _textW, _font, _lineSize] call FUNC(fitText), _lineSize, _colorText2, _font, 0, "hint"
    ] call FUNC(uiLabel);

    private _rowsToggle = [
        _display, "AIO_Hitbox", _parent, [_gridX - pixelW * 2, _rowsTop - pixelH * 2, _rowsW + pixelW * 4, _lineH + pixelH * 4]
    ] call FUNC(uiCreate);
    [_rowsToggle, LLSTRING(Rows_Tooltip)] call FUNC(setTooltip);
    _rowsToggle setVariable [QGVAR(key), _sectionContainer];
    _rowsToggle ctrlAddEventHandler ["ButtonClick", {
        [{_this call FUNC(toggleRows)}, [(_this select 0) getVariable [QGVAR(key), objNull]]] call FUNC(later);
    }];

    // Where a drag may let go to have it laid down in the rows folded away: this line and the box of the container
    // (fnc_updateDrag, GVAR(foldAreas) - "rel" and "parent" as fnc_gridOrigin takes them, "size", "container").
    if (_hiddenRows > 0) then {
        private _areas = uiNamespace getVariable [QGVAR(foldAreas), []];

        _areas pushBack createHashMapFromArray [["rel", [_gridX, _rowsTop]], ["parent", _parent], ["size", [_rowsW, _lineH]], ["container", _sectionContainer]];

        if (_hasBox) then {
            _areas pushBack createHashMapFromArray [["rel", [_blockX, _bodyTop]], ["parent", _parent], ["size", [_boxW, _boxH]], ["container", _sectionContainer]];
        };

        uiNamespace setVariable [QGVAR(foldAreas), _areas];
    };

    _used = _used + UNIT * 0.15 + _lineH;
};

_used
