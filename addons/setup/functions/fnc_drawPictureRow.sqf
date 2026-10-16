#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The row "Picture" of the Items and Containers steps, under the name: the texture path the item shows - a
 * read-only field (the picture set for it, else config's own in the muted ink, with the end of a long path kept
 * and its beginning cut), "Pick..." which opens the picture picker (fnc_openPicturePicker; a click on the field
 * does the same), and Reset to take the set picture away (enabled while one is set). Nothing is written here:
 * the code gets the path and puts it into the editor's working copy, and Apply writes picture=.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Width of the label at the left <NUMBER>
 * 5: The picture set for the item in the working copy, "" for none <STRING>
 * 6: The picture its config names, "" for none <STRING>
 * 7: Code, called with [path, arguments] when a picture is taken - "" for Reset <CODE>
 * 8: Arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _box, [0, 0, 0.4, 0.03], _theme, 0.08, "", "\A3\x_ca.paa", {params ["_path"]}] call einv_setup_fnc_drawPictureRow;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_labelW", 0, [0]], ["_work", "", [""]], ["_config", "", [""]],
    ["_code", {}, [{}]], ["_arguments", []]
];
_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _gap = SQUARE(UNIT * 0.3);

[_display, _parent, [_left, _top, _labelW, _height], LLSTRING(Items_PictureField), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

// Reset at the right end, Pick... before it.
private _resetText = LLSTRING(Items_PictureReset);
private _chipH = _height * 0.85;
private _resetW = SQUARE(_chipH * 0.9) + (_resetText getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;
private _resetX = _left + _width - _resetW;
private _pickText = LLSTRING(Items_PickButton);
private _pickW = ACTION_W(_pickText,_height,false,_font);
private _pickX = _resetX - _gap - _pickW;
private _fieldX = _left + _labelW;
private _fieldW = _pickX - _gap - _fieldX;

// What picking does: the picker, with the code and the arguments that come back with the path.
private _open = {
    params ["_work", "_code", "_arguments"];

    [_work, _code, _arguments] call FUNC(openPicturePicker);
};

// The field: a film with the path on it, the end of a long one kept.
private _shown = [_config, _work] select (_work isNotEqualTo "");
private _text = _shown;

if (_shown isEqualTo "") then {
    _text = LLSTRING(Items_PictureNone);
} else {
    private _padX = SQUARE(_height * 0.3);
    private _room = _fieldW - _padX * 2;
    private _size = _height * 0.5;

    if ((_shown getTextWidth [_font, _size]) * TEXT_SLACK > _room) then {
        private _keep = (floor ((count _shown) * _room / ((_shown getTextWidth [_font, _size]) * TEXT_SLACK))) - 3;

        _text = "..." + (_shown select [(count _shown) - (_keep max 1)]);

        while {_keep > 1 && {(_text getTextWidth [_font, _size]) * TEXT_SLACK > _room}} do {
            _keep = _keep - 1;
            _text = "..." + (_shown select [(count _shown) - _keep]);
        };
    };
};

private _surface = [_display, _parent, [_fieldX, _top, _fieldW, _height], _theme getOrDefault ["button", [1, 1, 1, 0.08]], (_theme getOrDefault ["radius", 0]) min (_height / 2)] call EFUNC(gui,uiPanel);

[
    _display, _parent, [_fieldX + SQUARE(_height * 0.3), _top, _fieldW - SQUARE(_height * 0.3) * 2, _height], _text, _height * 0.5,
    [_muted, _colorText] select (_work isNotEqualTo ""), _font, 0
] call EFUNC(gui,uiLabel);

[
    _display, _parent, [_fieldX, _top, _fieldW, _height], _surface, _theme getOrDefault ["button", [1, 1, 1, 0.08]],
    _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]], _open, [_work, _code, _arguments], true,
    [LLSTRING(Items_PictureConfigTip), LLSTRING(Items_PictureOwnTip)] select (_work isNotEqualTo "")
] call FUNC(uiHit);

[_display, _parent, [_pickX, _top, _pickW, _height], _pickText, "", _theme, _open, [_work, _code, _arguments], true, "", LLSTRING(Items_PickTip)] call FUNC(uiAction);

[_display, _parent, [_resetX, _top + (_height - _chipH) / 2, _resetW, _chipH], _resetText, false, _theme, {
    params ["", "_pack"];
    _pack params ["_code", "_arguments"];

    ["", _arguments] call _code;
}, [_code, _arguments], _work isNotEqualTo ""] call FUNC(uiChip);
