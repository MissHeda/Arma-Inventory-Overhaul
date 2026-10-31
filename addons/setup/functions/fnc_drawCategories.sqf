#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The card "Categories" of the General step: the categories items are sorted into - the strip at the side of a loot box lists them,
 * a compartment can take only some of them (the Containers step) and an item is put in them at the Items step. A row each:
 *   - its picture as the window draws it (the one the setup gave it, else the one this mod ships; a star for one of the setup's own
 *     with none), a field with its name (applied on Return or when the cursor leaves it: fnc_renameCategory), "Built in" or its id,
 *     "Picture..." - the picture picker (fnc_openPicturePicker) on its chip of this mod's icons -, a button back to the shipped
 *     name and picture (built-in ones) or to the star (the setup's own), and for the setup's own a cross that deletes it after
 *     a question (fnc_deleteCategory takes it out of every item and compartment that names it).
 *   - after the name the colour of its items' tiles (color=, fnc_setCategoryColours): its swatch and hex digits, or "Default"
 *     for the look's own colour. A click opens the colour picker (fnc_openColourPicker) - the square and the hue strip of the
 *     window's colour panel -, Apply writes the colour, Default takes it away (issue #33; the switches and the mass edit row
 *     of 0.6.x are gone).
 *   - the row to add one: a name field and Add (fnc_addCategory). The eight built-in ones can be renamed and given another
 *     picture, not removed; at most MAX_CUSTOM_CATEGORIES of the setup's own.
 * All of it is the statements category=ID > name=... picture=... of the rules text (aio_items_fnc_parseRules), so it saves,
 * exports and imports with the rules, and the list of changes words it (fnc_describeRule).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The General step's scroll group <CONTROL>
 * 2: The card's place [x, y, w], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: A group to measure texts in <CONTROL>
 *
 * Return Value:
 * The height the card took <NUMBER>
 *
 * Example:
 * [_display, _page, [_padX, _cursorY, _innerW], _theme, _probe] call aio_setup_fnc_drawCategories;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_page", "_rect", "_theme", "_probe"];
_rect params ["_padX", "_top", "_innerW"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);

private _cardX = _padX + CARD_PAD_X;
private _cardW = _innerW - CARD_PAD_X * 2;
private _cardTop = CARD_PAD_Y + CARD_CAPTION_H + UNIT * 0.15;
private _rowH = UNIT * 1.2;
private _rowGap = UNIT * 0.35;
private _gap = SQUARE(UNIT * 0.3);

private _ids = [GVAR(draftRules)] call EFUNC(items,categories);
private _canAdd = ({!(_x in ITEM_GROUPS)} count _ids) < MAX_CUSTOM_CATEGORIES;

private _help = LLSTRING(Categories_Help);
private _helpH = [_display, _probe, [0, 0, _cardW], _help, TEXT_SMALL, _colorText2, _font] call FUNC(uiText);
private _height = _cardTop + _helpH + UNIT * 0.3 + (count _ids + 1) * (_rowH + _rowGap) - _rowGap + CARD_PAD_Y;

private _contentY = [_display, _page, [_padX, _top, _innerW, _height], LLSTRING(Categories_Title), _theme] call FUNC(uiCard);

[_display, _page, [_cardX, _contentY, _cardW], _help, TEXT_SMALL, _colorText2, _font] call FUNC(uiText);

private _rowY = _contentY + _helpH + UNIT * 0.3;
private _pictureLabel = LLSTRING(Categories_Picture);
private _pictureW = (ACTION_W(_pictureLabel,_rowH,true,_font)) max SQUARE(UNIT * 3.8);
private _idW = SQUARE(UNIT * 6.5);
private _squareW = SQUARE(_rowH);
private _colourW = SQUARE(UNIT * 6.4);
private _nameW = _cardW - _squareW - _idW - _colourW - _pictureW - _squareW * 2 - _gap * 6;

// The tiles' colour as a swatch: the setup's colour, else the look's own of the category's tiles (a plain grey for one of the
// setup's own, whose items take their built-in category's).
private _plainTiles = (call EFUNC(gui,theme)) getOrDefault ["tileBg", []];
private _builtinTile = createHashMapFromArray [
    ["weapon", CATEGORY_WEAPON], ["ammo", CATEGORY_AMMO], ["grenade", CATEGORY_AMMO], ["gear", CATEGORY_GEAR],
    ["medical", CATEGORY_MEDICAL], ["food", CATEGORY_MISC], ["tool", CATEGORY_MISC], ["misc", CATEGORY_MISC]
];

{
    private _id = _x;
    private _info = [_id, GVAR(draftRules)] call EFUNC(items,categoryInfo);
    private _builtin = _info get "builtin";
    private _rowX = _cardX;

    // Its picture, as the window draws it.
    [_display, _page, [_rowX, _rowY, _squareW, _rowH], [1, 1, 1, 0.06], _radius] call EFUNC(gui,uiPanel);
    [
        _display, _page, [_rowX + _squareW * 0.18, _rowY + _rowH * 0.18, _squareW * 0.64, _rowH * 0.64],
        [_id, GVAR(draftRules)] call EFUNC(gui,groupTexture), _colorText2
    ] call EFUNC(gui,uiIcon);
    _rowX = _rowX + _squareW + _gap;

    [_display, _page, [_rowX, _rowY, _nameW, _rowH], _info get "name", LLSTRING(Categories_NamePlaceholder), _theme, {
        params ["_text", "_id"];

        [_id, _text] call FUNC(renameCategory);
    }, _id, LLSTRING(Categories_NameTip)] call FUNC(uiField);
    _rowX = _rowX + _nameW + _gap;

    // The tiles' colour: its swatch and hex digits ("Default" for none), one button that opens the colour picker.
    private _own = _info get "color";
    private _plain = ((_plainTiles param [_builtinTile getOrDefault [_id, CATEGORY_MISC], [0.15, 0.15, 0.15, 0.92]]) select [0, 3]);
    private _swatch = if (count _own >= 3) then {_own + [1]} else {_plain + [1]};
    private _swatchW = SQUARE(_rowH * 0.62);
    private _colourFill = [1, 1, 1, 0.06];
    private _colourSurface = [_display, _page, [_rowX, _rowY, _colourW, _rowH], _colourFill, _radius] call EFUNC(gui,uiPanel);
    private _swatchX = _rowX + SQUARE(_rowH * 0.19);

    [_display, _page, [_swatchX, _rowY + _rowH * 0.19, _swatchW, _rowH * 0.62], [1, 1, 1, 0.25], _radius] call EFUNC(gui,uiPanel);
    [
        _display, _page, [_swatchX + pixelW, _rowY + _rowH * 0.19 + pixelH, _swatchW - pixelW * 2, _rowH * 0.62 - pixelH * 2], _swatch, _radius
    ] call EFUNC(gui,uiPanel);

    private _colourText = [LLSTRING(Colour_Default), toUpper (_info get "colorSet")] select ((_info get "colorSet") isNotEqualTo "");
    private _colourTextX = _swatchX + _swatchW + SQUARE(UNIT * 0.3);

    [
        _display, _page, [_colourTextX, _rowY, _rowX + _colourW - _colourTextX, _rowH], _colourText, TEXT_SMALL,
        [_muted, _colorText2] select ((_info get "colorSet") isNotEqualTo ""), _font, 0
    ] call EFUNC(gui,uiLabel);

    [_display, _page, [_rowX, _rowY, _colourW, _rowH], _colourSurface, _colourFill, [1, 1, 1, 0.12], {
        params ["_id", "_plain"];

        private _info = [_id, GVAR(draftRules)] call EFUNC(items,categoryInfo);

        // The picker opens at the mouse: the button lies in a scrolled page, the mouse is on the screen already.
        getMousePosition params ["_mouseX", "_mouseY"];

        [uiNamespace getVariable [QGVAR(display), displayNull], [_mouseX - UNIT, _mouseY - UNIT * 0.5, UNIT * 2, UNIT], _info get "name", _info get "colorSet", _plain, {
            params ["_hex", "_id"];

            [[_id], _hex] call FUNC(setCategoryColours);
        }, _id] call FUNC(openColourPicker);
    }, [_id, _plain], true, LLSTRING(Categories_ColourTip)] call FUNC(uiHit);
    _rowX = _rowX + _colourW + _gap;

    [
        _display, _page, [_rowX, _rowY, _idW, _rowH], [LLSTRING(Categories_BuiltIn), _id] select !_builtin, TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);
    _rowX = _rowX + _idW + _gap;

    [_display, _page, [_rowX, _rowY, _pictureW, _rowH], _pictureLabel, UI_TEX(icon_style_ca), _theme, {
        params ["_id"];

        private _info = [_id, GVAR(draftRules)] call EFUNC(items,categoryInfo);

        [_info get "pictureSet", {
            params ["_path", "_id"];

            [_id, createHashMapFromArray [["picture", _path]]] call FUNC(setCategory);
        }, _id, _info get "picture", "#category"] call FUNC(openPicturePicker);
    }, _id, true, "", LLSTRING(Categories_PictureTip)] call FUNC(uiAction);
    _rowX = _rowX + _pictureW + _gap;

    // Back to what it was: a built-in category to the name and picture this mod ships, one of the setup's own to the star.
    if ((_builtin && {(_info get "nameSet") isNotEqualTo "" || {(_info get "pictureSet") isNotEqualTo ""}}) || {(_info get "colorSet") isNotEqualTo ""} || {!_builtin && {(_info get "pictureSet") isNotEqualTo ""}}) then {
        [_display, _page, [_rowX, _rowY, _rowH, _rowH], _theme, {
            params ["_id"];

            [_id, createHashMapFromArray ([[["picture", ""]], [["name", ""], ["picture", ""]]] select (_id in ITEM_GROUPS))] call FUNC(setCategory);
            [[_id], ""] call FUNC(setCategoryColours);
        }, _id, [LLSTRING(Categories_ResetPicture), LLSTRING(Categories_ResetBuiltIn)] select _builtin] call FUNC(uiReset);
    };

    _rowX = _rowX + _squareW + _gap;

    if (!_builtin) then {
        [_display, _page, [_rowX, _rowY, _rowH, _rowH], "", UI_TEX(icon_close_ca), _theme, {
            params ["_id"];

            [
                uiNamespace getVariable [QGVAR(display), displayNull],
                format [LLSTRING(Categories_DeleteConfirm), (([_id, GVAR(draftRules)] call EFUNC(items,categoryInfo)) get "name")],
                LLSTRING(Categories_DeleteYes), {
                    params ["_id"];

                    [_id] call FUNC(deleteCategory);
                }, _id, "", [], "", "danger"
            ] call FUNC(confirm);
        }, _id, true, "ghost", LLSTRING(Categories_Delete)] call FUNC(uiAction);
    };

    _rowY = _rowY + _rowH + _rowGap;
} forEach _ids;

// The row to add one.
private _addLabel = LLSTRING(Categories_Add);
private _addW = (ACTION_W(_addLabel,_rowH,true,_font)) max SQUARE(UNIT * 3.8);

[
    _display, _page, [_cardX, _rowY, _cardW - _addW - _gap, _rowH], missionNamespace getVariable [QGVAR(newCategory), ""],
    LLSTRING(Categories_AddPlaceholder), _theme, {
        params ["_text", "_submitted"];

        missionNamespace setVariable [QGVAR(newCategory), _text];

        if (_submitted) then {
            [_text] call FUNC(addCategory);
        };
    }, [], false, _canAdd
] call FUNC(uiEdit);

[_display, _page, [_cardX + _cardW - _addW, _rowY, _addW, _rowH], _addLabel, UI_TEX(icon_plus_ca), _theme, {
    [missionNamespace getVariable [QGVAR(newCategory), ""]] call FUNC(addCategory);
}, [], _canAdd, "accent", [format [LLSTRING(Categories_Max), MAX_CUSTOM_CATEGORIES], LLSTRING(Categories_AddTip)] select _canAdd] call FUNC(uiAction);

_height
