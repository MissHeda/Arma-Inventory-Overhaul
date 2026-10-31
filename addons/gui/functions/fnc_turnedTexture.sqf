#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A picture turned a quarter clockwise, as a texture of its own: square, transparent round it, the picture in
 * its own shape (issue #28). fnc_uiPictureTurned shows it on a plain square control - nothing on the screen is
 * turned any more.
 *
 * Why: ctrlSetAngle turns in the screen's UI units, which are not square (4:3 to the pixels), and cuts what it
 * draws to the control's rectangle before the turn - a rifle came out short and fat however the control was
 * sized. Inside a texture drawn by a display of its own (ui-to-texture, #(argb,W,H,1)ui(AIO_TurnTexture,name))
 * the units are the texture's pixels, square when the texture is, and a square control turned in it is turned
 * exactly. That needs a square picture, so it takes two textures per picture, made once per game session:
 *   aio_turn_sq_N   the picture fitted into a square in its own shape (AIO_Picture), not turned
 *   aio_turn_rot_N  that square texture on a square control, turned a quarter - what is shown
 * How the engine treats them, as measured in game (2.22):
 * - The display behind such a texture comes into being once a control shows the texture, and is dropped and
 *   made again empty when nothing shows it for a while: each call checks both and fills what is empty.
 * - A texture that only another texture shows is never drawn. So the inner one is also shown on the screen, by
 *   one keeper per picture and display: a single pixel in the display's corner, all but transparent.
 * - The outer one reads the inner one when it takes it as its text: once the inner one is drawn, the outer one
 *   takes it anew and is drawn again (drawn again only, it keeps showing what it read before). That is done on
 *   every call, filled or not: a new control showing the texture starts blank until the display is drawn again.
 * - fnc_syncTurned calls this again twice a second for what it shows, so a display the engine dropped and made
 *   again empty is filled again.
 *
 * Arguments:
 * 0: The display the turned picture shows on <DISPLAY>
 * 1: The picture's texture <STRING>
 * 2: For a control that shows it for the first time - drawn again even when nothing was empty; false only fills
 *    what is empty (fnc_syncTurned's check) <BOOL> (default: true)
 *
 * Return Value:
 * The turned texture, for ctrlSetText <STRING>
 *
 * Example:
 * [_display, getText (configFile >> "CfgWeapons" >> "arifle_MX_F" >> "picture")] call aio_gui_fnc_turnedTexture;
 *
 * Public: No
 */

#define TURN_RES 512

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_texture", "", [""]], ["_fresh", true, [true]]];

private _known = uiNamespace getVariable [QGVAR(turnedTextures), createHashMap];
private _key = toLowerANSI _texture;
private _index = _known getOrDefault [_key, -1];

if (_index < 0) then {
    _index = count _known;
    _known set [_key, _index];
    uiNamespace setVariable [QGVAR(turnedTextures), _known];
};

private _inner = format ["aio_turn_sq_%1", _index];
private _outer = format ["aio_turn_rot_%1", _index];
private _innerTexture = format ["#(argb,%1,%1,1)ui(AIO_TurnTexture,%2)", TURN_RES, _inner];

// The keeper: the inner texture on the screen, so the engine draws it.
if (!isNull _display) then {
    private _keepers = _display getVariable [QGVAR(turnKeepers), createHashMap];

    if (isNull (_keepers getOrDefault [_inner, controlNull])) then {
        private _keeper = _display ctrlCreate ["AIO_PictureTurned", -1];
        _keeper ctrlSetPosition [safeZoneX, safeZoneY, pixelW, pixelH];
        _keeper ctrlSetText _innerTexture;
        _keeper ctrlSetTextColor [1, 1, 1, 0.01];
        _keeper ctrlEnable false;
        _keeper ctrlCommit 0;

        _keepers set [_inner, _keeper];
        _display setVariable [QGVAR(turnKeepers), _keepers];
    };
};

[{
    params ["_inner", "_outer"];

    !isNull (findDisplay _inner) && {!isNull (findDisplay _outer)}
}, {
    params ["_inner", "_outer", "_innerTexture", "_texture", "_fresh"];

    private _innerDisplay = findDisplay _inner;
    private _outerDisplay = findDisplay _outer;
    private _filled = false;

    if ((_innerDisplay getVariable [QGVAR(turnedOf), ""]) isNotEqualTo _texture) then {
        {ctrlDelete _x} forEach allControls _innerDisplay;

        private _picture = _innerDisplay ctrlCreate ["AIO_Picture", -1];
        _picture ctrlSetPosition [0, 0, 1, 1];
        _picture ctrlSetText ([_texture] call FUNC(safePicture));
        _picture ctrlCommit 0;

        _innerDisplay setVariable [QGVAR(turnedOf), _texture];
        displayUpdate _innerDisplay;
        _filled = true;
    };

    if ((_outerDisplay getVariable [QGVAR(turnedOf), ""]) isNotEqualTo _texture) then {
        {ctrlDelete _x} forEach allControls _outerDisplay;

        private _picture = _outerDisplay ctrlCreate ["AIO_PictureTurned", -1];
        _picture ctrlSetPosition [0, 0, 1, 1];
        _picture ctrlSetText _innerTexture;
        _picture ctrlCommit 0;
        _picture ctrlSetAngle [90, 0.5, 0.5, true];

        _outerDisplay setVariable [QGVAR(turnedOf), _texture];
        _filled = true;
    };

    // Filled or not: a control that shows the texture for the first time gets a texture of its own from the engine,
    // empty until the display is drawn again (the turned pictures went blank after a right click redrew the tiles).
    if (!_filled && {!_fresh}) exitWith {};

    if (!_filled) then {
        displayUpdate _innerDisplay;
    };

    // The outer one takes the inner texture anew once that is drawn: a moment later, and once more for a slow frame.
    private _retake = {
        if (isNull _this) exitWith {};

        {
            if ((ctrlText _x) isNotEqualTo "") then {
                _x ctrlSetText ctrlText _x;
                _x ctrlCommit 0;
                _x ctrlSetAngle [90, 0.5, 0.5, true];
            };
        } forEach allControls _this;

        displayUpdate _this;
    };

    // The very next frames first: a tile turned with R while dragged showed blank for a tenth of a second before (it flickered).
    [_retake, _outerDisplay] call CBA_fnc_execNextFrame;
    [_retake, _outerDisplay, 2] call CBA_fnc_execAfterNFrames;
    [_retake, _outerDisplay, 0.1] call CBA_fnc_waitAndExecute;
    [_retake, _outerDisplay, 0.6] call CBA_fnc_waitAndExecute;
}, [_inner, _outer, _innerTexture, _texture, _fresh], 5] call CBA_fnc_waitUntilAndExecute;

format ["#(argb,%1,%1,1)ui(AIO_TurnTexture,%2)", TURN_RES, _outer]
