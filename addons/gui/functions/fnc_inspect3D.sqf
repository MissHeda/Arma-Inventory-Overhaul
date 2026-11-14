#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda, after KPblM Item Preview by Dimon UA (KPBLM, Workshop 3822903400) - its showcase scene, included with the
 * author's permission
 * The inspect card's 3D view (fnc_drawInspect): the item in a small scene of its own far off the map (INSPECT_3D_PLACE) - a
 * dark sphere round it and three lights, key, fill and rim - filmed by a camera of its own into a texture (render to texture,
 * INSPECT_3D_TARGET) that the card shows in its picture box. The window's own view stays as it is. Held and dragged in the box
 * the camera goes round the item (fnc_onFrame), the wheel brings it nearer or farther, a double click puts it back.
 *
 * A weapon lies on a scripted weapon holder with the attachments it has (as fnc_getContents gives them, the holder's own
 * format), else with what its config fits on it; gear the holder shows the right way up - uniforms, vests, headgear - lies
 * on it too. What the holder will not take or shows upside down - backpacks, glasses, magazines, small items - stands as the
 * model alone, turned as KPBLM measured it. The camera aims at the weapon's base on the holder, gear a little higher. The
 * frame is the item's size, at most INSPECT_3D_FRAME. The lights are what shows it in the dark; the aperture is left to the engine - set,
 * it lit or darkened the whole world behind the window as well.
 *
 * The state is GVAR(scene3D): the class and attachments it shows, the camera and where it stands, the render target it films
 * into, the lights, every object made, the target [ASL], the turn (dir, pitch), the distance and its limits - and for the
 * modding view where the weapon's parts sit (fnc_weaponPoints). Started again for the same weapon with other parts, only the
 * holder is fitted out anew: the view stays as it was turned.
 *
 * The Attachments view ("side") starts side on, as Tarkov's weapon builds and Reforger's inspection show a weapon: once the
 * weapon's muzzle is known (fnc_placeHotspots asks "face"), the camera stands square to the barrel with the muzzle to the right,
 * and it tilts at most INSPECT_3D_SIDE_TILT. A part the player points at in its list is shown on the weapon for as long as
 * the mouse is on it ("preview", as Tarkov does) - only on the holder, nothing is moved.
 *
 * While a scene stands, the Picture-in-Picture view distance is INSPECT_3D_PIP_DISTANCE, the player's own given back with
 * "stop".
 *
 * A weapon looked at plainly starts as its card shows it and is turned, zoomed and moved as the player's own view of that weapon
 * (fnc_weaponView, fnc_viewCamera; Mia, 0.7.13): kept per weapon, and the card shows the weapon the same way at once.
 *
 * Arguments:
 * 0: What to do <STRING>
 *    "start"   the scene for the item, unless it stands for it already - the one before goes (arguments: [class, attachments,
 *              render target, side on]); standing, it only films into the target it is given now
 *    "stop"    the scene goes: camera, lights, objects
 *    "turn"    the camera goes round by how far the mouse moved, a share of the screen (arguments: [across, down])
 *    "zoom"    nearer for a turn of the wheel up, farther for one down (arguments: [turn])
 *    "pan"     the camera and what it looks at move across and up or down, as the middle mouse button drags them - the item
 *              moves with the mouse, at most its frame away from where it was (arguments: [across, down])
 *    "reset"   the view the scene started with - a weapon looked at plainly: from its left side, fitted, and its own view goes
 *    "side"    a weapon looked at plainly, straight from its left side or its right, fitted (arguments: [0 or 180])
 *    "centre"  a weapon's own middle - with what it carries (fnc_weaponBounds) - is what the camera looks at and turns round,
 *              not its grip, and the view starts so far off that the whole weapon fits the box (fnc_fitView); asked by the
 *              scene itself once the holder's model is loaded, and when the weapon's parts change
 *    "face"    side on to the barrel, the muzzle to the right - the start of the Attachments view (arguments: [muzzle ASL])
 *    "preview" the holder with one part changed, for a look; [] puts back what the scene shows (arguments: [[index in the
 *              attachments, value] or [], the tile that asks - a put back from another tile is ignored])
 * 1: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["start", ["arifle_MX_F", []]] call aio_gui_fnc_inspect3D;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_arguments", [], [[]]]];

private _scene = GVAR(scene3D);

// The camera where the turn and the distance put it, looking at the item, and the lights round it with it.
private _fnc_camera = {
    private _camera = _scene getOrDefault ["camera", objNull];

    if (isNull _camera) exitWith {};

    private _target = _scene get "target";
    private _dir = _scene get "dir";
    private _pitch = _scene get "pitch";
    private _distance = _scene get "distance";
    private _across = (cos _pitch) * _distance;
    private _cameraPos = _target vectorAdd [(sin _dir) * _across, (cos _dir) * _across, (sin _pitch) * _distance];

    // The scene is in ASL, the camera takes AGL.
    _camera camSetPos (ASLToAGL _cameraPos);
    _camera camSetTarget (ASLToAGL _target);
    _camera camSetFov INSPECT_3D_FOV;
    _camera camCommit 0;

    // Where it films from, for the modding view's points (fnc_placeHotspots).
    _scene set ["cameraPos", _cameraPos];

    (_scene get "lights") params ["_key", "_fill", "_rim"];

    private _side = [cos _dir, -(sin _dir), 0];

    // Key above and left of the camera, fill to the right a little lower, rim behind the item and above it.
    _key setPosASL ((_cameraPos vectorAdd (_side vectorMultiply (-0.5 * _distance))) vectorAdd [0, 0, 0.4 * _distance]);
    _fill setPosASL ((_cameraPos vectorAdd (_side vectorMultiply (0.7 * _distance))) vectorAdd [0, 0, -0.1 * _distance]);
    _rim setPosASL ((_target vectorAdd ((_target vectorDiff _cameraPos) vectorMultiply 0.8)) vectorAdd [0, 0, 0.5 * _distance]);
};

// A weapon as the holder takes it, [class, muzzle, pointer, optic, magazine, magazine, bipod]: with what it carries, else as its
// config fits it out - a magazine full: some belt-fed weapons show their box by the rounds.
private _fnc_fitOut = {
    params ["_class", "_attachments"];

    private _itemConfig = configFile >> "CfgWeapons" >> _class;

    _attachments params ["", ["_muzzle", ""], ["_pointer", ""], ["_optic", ""], ["_magazine", []], ["_magazine2", []], ["_bipod", ""]];

    if (_attachments isEqualTo []) then {
        private _linked = _itemConfig >> "LinkedItems";

        _muzzle = getText (_linked >> "LinkedItemsMuzzle" >> "item");
        _pointer = getText (_linked >> "LinkedItemsAcc" >> "item");
        _optic = getText (_linked >> "LinkedItemsOptic" >> "item");
        _bipod = getText (_linked >> "LinkedItemsUnder" >> "item");

        private _magazines = getArray (_itemConfig >> "magazines");

        if (_magazines isNotEqualTo []) then {
            private _first = _magazines select 0;
            _magazine = [_first, (getNumber (configFile >> "CfgMagazines" >> _first >> "count")) max 1];
        };
    };

    if !(_magazine isEqualType [] && {count _magazine >= 2} && {(_magazine param [0, ""]) isNotEqualTo ""}) then {_magazine = []};
    if !(_magazine2 isEqualType [] && {count _magazine2 >= 2} && {(_magazine2 param [0, ""]) isNotEqualTo ""}) then {_magazine2 = []};

    [_class, _muzzle, _pointer, _optic, _magazine, _magazine2, _bipod]
};

// The holder fitted out anew with these parts - the same weapon (fnc_fitOut's format).
private _fnc_refit = {
    params ["_parts"];

    private _holder = (_scene get "objects") param [1, objNull];

    if (isNull _holder) exitWith {};

    private _fitted = [_scene get "class", _parts] call _fnc_fitOut;

    clearWeaponCargo _holder;
    clearMagazineCargo _holder;
    _holder addWeaponWithAttachmentsCargo [_fitted, 1];
    _scene set ["fitted", _fitted];
};

// A weapon looked at plainly - not in the Attachments view, which keeps its side on - is shown by the player's own view of it
// (fnc_weaponView): the scene's "view" [turn, pitch, zoom, across, up] from the side view "sideDir", the muzzle to the left as
// its card shows it. Turning, zooming and moving change the view, and the camera is made of it (fnc_viewCamera).
private _fnc_viewed = {
    count _scene > 0 && {_scene getOrDefault ["weapon", false]} && {!(_scene getOrDefault ["side", false])} && {"sideDir" in _scene}
};

// What the box holds of the picture, across and up and down from its middle.
private _fnc_tans = {
    (uiNamespace getVariable [QGVAR(inspect3DShown), [1, 1]]) params [["_shownX", 1], ["_shownY", 1]];

    [CAMERA_TAN * INSPECT_3D_ASPECT * (_shownX max 0.05), CAMERA_TAN * (_shownY max 0.05)]
};

// The camera where the view puts it. False while the weapon's box is not known.
private _fnc_view = {
    private _corners = [_scene] call FUNC(weaponBounds);

    if (isNil "_corners" || {_corners isEqualTo []}) exitWith {false};

    (call _fnc_tans) params ["_tanH", "_tanV"];

    ([_corners, _scene get "sideDir", _scene get "view", _tanH, _tanV, INSPECT_3D_ROOM] call FUNC(viewCamera)) params ["_target", "_distance", "_dir", "_pitch"];

    _scene set ["target", _target];
    _scene set ["origin", +_target];
    _scene set ["distance", (_distance max 0.08) min 8];
    _scene set ["dir", _dir];
    _scene set ["pitch", _pitch];

    call _fnc_camera;

    true
};

// The view is the weapon's own from now on, and its card shows it (fnc_weaponView - not with its "Show view on slot" off).
private _fnc_keep = {
    if !(["shown", _scene get "class"] call FUNC(weaponView)) exitWith {};

    ["set", _scene get "class", _scene get "view"] call FUNC(weaponView);
    ["view", [_scene get "class"]] call FUNC(cardScene);
};

switch (_mode) do {
    case "start": {
        _arguments params [["_class", "", [""]], ["_attachments", [], [[]]], ["_target3D", INSPECT_3D_TARGET, [""]], ["_side", false, [false]]];

        if (_class isEqualTo "") exitWith {};

        private _running = (_scene getOrDefault ["class", ""]) isEqualTo _class && {!isNull (_scene getOrDefault ["camera", objNull])};

        // A card of another size shows another target: the camera films into that one now.
        if (_running && {(_scene getOrDefault ["target3D", ""]) isNotEqualTo _target3D}) then {
            private _camera = _scene get "camera";

            _camera cameraEffect ["Terminate", "Back", _scene get "target3D"];
            _camera cameraEffect ["Internal", "Back", _target3D];
            _scene set ["target3D", _target3D];
        };

        // Inspect and Attachments of the same weapon share the scene: from one to the other, the view starts as that card's does.
        if (_running && {(_scene getOrDefault ["side", false]) isNotEqualTo _side}) then {
            private _pitch = [15, INSPECT_3D_SIDE_PITCH] select _side;

            _scene set ["side", _side];
            _scene set ["facing", _side];
            _scene set ["dir", 45];
            _scene set ["pitch", _pitch];
            _scene set ["startDir", 45];
            _scene set ["startPitch", _pitch];

            call _fnc_camera;

            // Plainly again: the weapon's own view.
            if (!_side) then {
                ["centre"] call FUNC(inspect3D);
            };
        };

        if (_running && {(_scene getOrDefault ["attachments", []]) isEqualTo _attachments}) exitWith {};

        // The same weapon on the holder with other parts - one put on or taken off in the modding view (fnc_drawHotspots): only
        // what lies on the holder changes, the view stays as the player turned it.
        if (_running && {_scene getOrDefault ["onHolder", false]}) exitWith {
            [_attachments] call _fnc_refit;
            _scene set ["attachments", +_attachments];
            _scene set ["previewing", false];

            // What the view turns round is the middle of the weapon as it is fitted out now.
            ["centre"] call FUNC(inspect3D);
        };

        ["stop"] call FUNC(inspect3D);

        _scene = createHashMapFromArray [["class", _class], ["attachments", +_attachments], ["target3D", _target3D], ["side", _side]];
        GVAR(scene3D) = _scene;

        // The world round the scene is not looked at: the least view distance the engine takes for it, the player's own kept.
        if (isNil QGVAR(pipDistance)) then {
            GVAR(pipDistance) = getPiPViewDistance;
        };

        setPiPViewDistance INSPECT_3D_PIP_DISTANCE;

        private _objects = [];
        _scene set ["objects", _objects];

        // The sphere, about 125 m round: the holder has to stand inside it.
        private _sceneBase = INSPECT_3D_PLACE + [((getTerrainHeightASL INSPECT_3D_PLACE) max 0) + 300];
        private _sphere = "Sphere_3DEN" createVehicleLocal [0, 0, 0];
        _sphere setPosASL _sceneBase;

        {
            _sphere setObjectTexture [_x, "#(argb,8,8,3)color(0.05,0.055,0.065,1)"];
        } forEach [0, 1];

        _objects pushBack _sphere;

        private _holderPos = _sceneBase vectorAdd [0, 0, 100];
        private _holder = "GroundWeaponHolder_Scripted" createVehicleLocal [0, 0, 0];
        _holder setPosASL _holderPos;
        _holder setVectorDirAndUp [[0, 0, 1], [0, 1, 0]];
        _objects pushBack _holder;

        private _weapons = configFile >> "CfgWeapons";
        private _itemConfig = _weapons >> _class;
        private _isWeapon = (["Rifle", "Pistol", "Launcher"] findIf {_class isKindOf [_x, _weapons]}) >= 0
            || {getNumber (_itemConfig >> "type") == 2};

        // What the holder takes at all: weapons and what is worn from CfgWeapons; binoculars and night vision it turns down,
        // as it does backpacks, glasses and magazines.
        private _holderTakes = _isWeapon || {isClass _itemConfig && {!(_class isKindOf ["Binocular", _weapons])}};

        // A weapon with what it carries, else as its config fits it out.
        ([_class, _attachments] call _fnc_fitOut) params ["", "_muzzle", "_pointer", "_optic", "_magazine", "_magazine2", "_bipod"];

        // The model, where the class lives - a magazine's real one rather than the box it lies on the ground as (fnc_itemModel).
        private _model = [_class] call FUNC(itemModel);

        // The base of a weapon on the holder - the proxy every weapon of every mod is put on. Gear on the holder hangs above it,
        // by a fixed lift: its box is blown up to the whole body's (a vest's, KPBLM measured 0.25 m).
        private _fnc_base = {
            params ["_lift"];

            private _proxy = _holder selectionPosition ["proxy:\a3\characters_f\proxies\weapon.001", 0.5];

            // The holder's model is not loaded yet: nothing rather than its own position.
            if (_proxy isEqualTo [0, 0, 0]) exitWith {[]};

            (_holder modelToWorldWorld _proxy) vectorAdd [0, 0, _lift]
        };

        private _target = +_holderPos;
        private _frame = INSPECT_3D_FRAME;

        // A uniform as it is worn, not the bundle it lies on the ground as: the soldier class it dresses (ItemInfo uniformClass),
        // made from its class so its textures are the uniform's - and framed whole, as tall as it is.
        private _wornClass = if (getNumber (_itemConfig >> "ItemInfo" >> "type") == 801) then {
            getText (_itemConfig >> "ItemInfo" >> "uniformClass")
        } else {
            ""
        };

        private _worn = if (_wornClass isNotEqualTo "" && {isClass (configFile >> "CfgVehicles" >> _wornClass)}) then {
            createSimpleObject [_wornClass, _holderPos, true]
        } else {
            objNull
        };

        // Standing, a body is tall where the view is wide: framed by its height (a share the box shows up and down, as the field
        // of view gives it), not by the width a weapon is. A uniform that cannot be made so lies there as its model.
        if (!isNull _worn) then {
            _objects pushBack _worn;

            (0 boundingBoxReal _worn) params ["_boxMin", "_boxMax"];

            _target = _worn modelToWorldWorld ((_boxMin vectorAdd _boxMax) vectorMultiply 0.5);
            _frame = (((_boxMax select 2) - (_boxMin select 2)) max 1) * INSPECT_3D_TALL;
        } else {
            if (_model isNotEqualTo "") then {
                private _probe = createSimpleObject [_model, [0, 0, 0], true];

                if (isNull _probe) exitWith {};

                (0 boundingBoxReal _probe) params ["_boxMin", "_boxMax"];
                deleteVehicle _probe;

                private _middle = (_boxMin vectorAdd _boxMax) vectorMultiply 0.5;
                private _extent = _boxMax vectorDiff _boxMin;
                private _size = vectorMagnitude _extent;

                _frame = (_size max 0.1) min INSPECT_3D_FRAME;

                // On the holder: weapons, and gear whose box is blown up past the frame - it stands right there. Small things from
                // CfgWeapons (a radio, a compass) the holder lays upside down: they stand as their model, as magazines do.
                private _onHolder = _holderTakes && {_isWeapon || {_size > INSPECT_3D_FRAME}};

                if (_onHolder) then {
                    _holder addWeaponWithAttachmentsCargo [[_class, _muzzle, _pointer, _optic, _magazine, _magazine2, _bipod], 1];
                    _scene set ["onHolder", true];
                    _scene set ["weapon", _isWeapon];
                    _scene set ["fitted", [_class, _muzzle, _pointer, _optic, _magazine, _magazine2, _bipod]];

                    private _base = [[0.25, 0] select _isWeapon] call _fnc_base;

                    if (_base isNotEqualTo []) then {
                        _target = _base;
                    };
                } else {
                    private _base = [0] call _fnc_base;
                    private _placed = [_base, _holderPos] select (_base isEqualTo []);
                    private _prop = createSimpleObject [_model, _placed, true];

                    // A magazine is modelled as it sits in its weapon: stood up, its mouth up, by the axis it is longest along. A small
                    // thing from CfgWeapons laid out as worn hangs below its base, its top on local -z: turned half round its thin axis.
                    private _turn = [];

                    if (isClass (configFile >> "CfgMagazines" >> _class)) then {
                        _turn = [[[0, 1, 0], [0, 0, 1]], [[0, 0, -1], [0, -1, 0]]] select (abs (_extent select 1) >= abs (_extent select 2));
                    } else {
                        if (abs (_extent select 2) > abs (_extent select 1) && {(_middle select 2) < 0}) then {
                            _turn = [[0, 1, 0], [0, 0, -1]];
                        };
                    };

                    if (_turn isNotEqualTo []) then {
                        _prop setVectorDirAndUp _turn;
                    };

                    _objects pushBack _prop;

                    // Aimed at the middle of the model as it stands now - moving a turned simple object would undo its turn.
                    private _seen = _prop modelToWorldWorld _middle;

                    if (count _seen == 3 && {vectorMagnitude (_seen vectorDiff _placed) < 3}) then {
                        _target = _seen;
                    };
                };
            };
        };

        _scene set ["target", _target];
        _scene set ["origin", +_target];
        _scene set ["frame", _frame];

        // The lights, placed with the camera.
        // Without falloff (INSPECT_3D_LIGHT_REACH): with a constant falloff of 1 they lit nothing at all - by day the sun alone
        // showed the item, at night and at dusk the picture was black (measured in game, 0.7.25). Their strength is set for the
        // dark; by day, with the camera's exposure down, they add next to nothing.
        private _lights = [[1, [1, 0.97, 0.92], [1, 0.97, 0.92]], [0.4, [0.6, 0.7, 0.9], [0.7, 0.8, 1]], [0.67, [1, 1, 1], [1, 0.9, 0.8]]] apply {
            _x params ["_share", "_ambient", "_colour"];

            private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
            _light setPosASL _target;
            _light setLightIntensity (INSPECT_3D_LIGHT * _share);
            _light setLightAmbient _ambient;
            _light setLightColor _colour;
            _light setLightUseFlare false;
            _light setLightDayLight true;
            _light setLightAttenuation INSPECT_3D_LIGHT_REACH;
            _objects pushBack _light;

            _light
        };

        _scene set ["lights", _lights];

        // A little above the item, from the front left; near enough for its size.
        private _distance = ((_frame * INSPECT_3D_DISTANCE) max 0.25) min 6;

        // Side on comes once the muzzle is known ("face"): until then, and for everything but the Attachments view, the front left.
        private _pitch = [15, INSPECT_3D_SIDE_PITCH] select _side;

        _scene set ["dir", 45];
        _scene set ["pitch", _pitch];
        _scene set ["startDir", 45];
        _scene set ["startPitch", _pitch];
        _scene set ["facing", _side];

        // A weapon looked at plainly starts as its card shows it ("centre", once the holder's model is there): until then from
        // where most weapons lie side on, so the picture does not swing round a moment later.
        if (!_side && {_scene getOrDefault ["weapon", false]}) then {
            _scene set ["dir", -180];
            _scene set ["pitch", CARD_3D_PITCH];
        };
        _scene set ["distance", _distance];
        _scene set ["start", _distance];
        _scene set ["near", _distance * 0.3];
        _scene set ["far", _distance * 3];

        private _camera = "camera" camCreate (ASLToAGL _target);
        _camera cameraEffect ["Internal", "Back", _target3D];
        _camera camSetFocus [-1, -1];
        _scene set ["camera", _camera];

        call _fnc_camera;

        // A weapon turns round its own middle, not round its grip: asked for once the holder's model is there ("centre").
        if (_scene getOrDefault ["weapon", false]) then {
            [
                {
                    params ["_scene"];

                    !(GVAR(scene3D) isEqualRef _scene) || {isNull (_scene getOrDefault ["camera", objNull])} || {!isNil {[_scene] call FUNC(weaponBounds)}}
                },
                {
                    params ["_scene"];

                    if (GVAR(scene3D) isEqualRef _scene && {!isNull (_scene getOrDefault ["camera", objNull])}) then {
                        ["centre"] call FUNC(inspect3D);
                    };
                },
                [_scene],
                5
            ] call CBA_fnc_waitUntilAndExecute;
        };
    };
    case "centre": {
        if (count _scene == 0 || {!(_scene getOrDefault ["weapon", false])}) exitWith {};

        private _corners = [_scene] call FUNC(weaponBounds);

        if (isNil "_corners" || {_corners isEqualTo []}) exitWith {};

        // Looked at plainly: by the player's own view of this weapon, from the side its card shows - the muzzle to the left.
        if !(_scene getOrDefault ["side", false]) exitWith {
            if !("sideDir" in _scene) then {
                private _holder = (_scene get "objects") param [1, objNull];
                private _base = _holder modelToWorldWorld (_holder selectionPosition ["proxy:\a3\characters_f\proxies\weapon.001", 0.5]);
                private _muzzle = ([_scene] call FUNC(weaponPoints));

                _muzzle = if (isNil "_muzzle") then {[]} else {_muzzle getOrDefault ["muzzle", []]};

                private _sideDir = -180;

                if (count _muzzle == 3) then {
                    private _barrel = _muzzle vectorDiff _base;
                    _barrel set [2, 0];

                    if (vectorMagnitude _barrel >= 0.05) then {
                        _barrel = vectorNormalized _barrel;
                        _sideDir = (-(_barrel select 1)) atan2 (_barrel select 0);
                    };
                };

                _scene set ["sideDir", _sideDir];
                _scene set ["view", ["get", _scene get "class"] call FUNC(weaponView)];
            };

            call _fnc_view;
        };

        // The whole weapon in the middle of the box and fitted to it from where the view starts - the front left, or side on.
        (uiNamespace getVariable [QGVAR(inspect3DShown), [1, 1]]) params [["_shownX", 1], ["_shownY", 1]];

        ([
            _corners, _scene getOrDefault ["startDir", 45], _scene getOrDefault ["startPitch", 15],
            CAMERA_TAN * INSPECT_3D_ASPECT * (_shownX max 0.05) * INSPECT_3D_ROOM, CAMERA_TAN * (_shownY max 0.05) * INSPECT_3D_ROOM
        ] call FUNC(fitView)) params ["_centre", "_distance"];

        _distance = (_distance max 0.25) min 6;

        // Where the player moved the view to stays as far from the middle as it was, and his own zoom stays his.
        private _moved = (_scene get "target") vectorDiff (_scene get "origin");
        private _zoomed = (_scene get "distance") / ((_scene get "start") max 0.01);

        _scene set ["origin", _centre];
        _scene set ["target", _centre vectorAdd _moved];
        _scene set ["start", _distance];
        _scene set ["near", _distance * 0.3];
        _scene set ["far", _distance * 3];
        _scene set ["distance", _distance * _zoomed];

        call _fnc_camera;
    };
    case "stop": {
        if (count _scene == 0) exitWith {};

        private _camera = _scene getOrDefault ["camera", objNull];

        // Destroying a camera does not end what it films into.
        if (!isNull _camera) then {
            _camera cameraEffect ["Terminate", "Back", _scene getOrDefault ["target3D", INSPECT_3D_TARGET]];
            camDestroy _camera;
        };

        if (!isNil QGVAR(pipDistance)) then {
            setPiPViewDistance GVAR(pipDistance);
            GVAR(pipDistance) = nil;
        };

        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach (_scene getOrDefault ["objects", []]);

        GVAR(scene3D) = createHashMap;
        GVAR(inspect3DTurn) = [];
        GVAR(inspect3DPan) = [];

        // What the player made of his weapons' views is written down (fnc_weaponView).
        ["save"] call FUNC(weaponView);
    };
    case "turn": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_across", 0, [0]], ["_down", 0, [0]]];

        if (call _fnc_viewed) exitWith {
            private _view = _scene get "view";

            _view set [0, (_view select 0) + _across * INSPECT_3D_TURN_ACROSS];
            _view set [1, (((_view select 1) + _down * INSPECT_3D_TURN_DOWN) max -80) min 80];

            call _fnc_view;
            call _fnc_keep;
        };

        // The item follows the mouse: dragged to the right, its front turns to the right.
        _scene set ["dir", (_scene get "dir") + _across * INSPECT_3D_TURN_ACROSS];
        // Side on, it tilts only so far that the parts round it stay readable.
        private _tilt = [80, INSPECT_3D_SIDE_TILT] select (_scene getOrDefault ["side", false]);

        _scene set ["pitch", (((_scene get "pitch") + _down * INSPECT_3D_TURN_DOWN) max -_tilt) min _tilt];

        call _fnc_camera;
    };
    case "zoom": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_turn", 0, [0]]];

        if (_turn == 0) exitWith {};

        if (call _fnc_viewed) exitWith {
            private _view = _scene get "view";

            _view set [2, (((_view select 2) * (1.15 ^ ((_turn max -6) min 6))) max WEAPON_VIEW_ZOOM_MIN) min WEAPON_VIEW_ZOOM_MAX];

            call _fnc_view;
            call _fnc_keep;
        };

        // By how far the wheel turned: several notches in one frame come as one turn of that many.
        private _distance = (_scene get "distance") / (1.15 ^ ((_turn max -6) min 6));

        _scene set ["distance", ((_distance max (_scene get "near")) min (_scene get "far"))];

        call _fnc_camera;
    };
    case "pan": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_across", 0, [0]], ["_down", 0, [0]]];

        // The weapon goes with the mouse: the camera's aim the other way, in half pictures at the fitted distance - less the
        // nearer it is zoomed.
        if (call _fnc_viewed) exitWith {
            private _view = _scene get "view";

            (call _fnc_tans) params ["_tanH", "_tanV"];

            private _zoom = (_view select 2) max WEAPON_VIEW_ZOOM_MIN;

            _view set [3, (((_view select 3) - _across * INSPECT_3D_PAN / (_zoom * _tanH)) max -WEAPON_VIEW_MOVE) min WEAPON_VIEW_MOVE];
            _view set [4, (((_view select 4) + _down * INSPECT_3D_PAN / (_zoom * _tanV)) max -WEAPON_VIEW_MOVE) min WEAPON_VIEW_MOVE];

            call _fnc_view;
            call _fnc_keep;
        };

        private _dir = _scene get "dir";
        private _distance = _scene get "distance";
        private _side = [cos _dir, -(sin _dir), 0];
        private _origin = _scene get "origin";

        // Dragged right, the item goes right: the camera and its target go left - _side points to the camera's left (it looks
        // along -[sin dir, cos dir]). Dragged down, they go up.
        private _target = ((_scene get "target") vectorAdd (_side vectorMultiply (_across * _distance * INSPECT_3D_PAN)))
            vectorAdd [0, 0, _down * _distance * INSPECT_3D_PAN];
        private _offset = _target vectorDiff _origin;
        private _limit = _scene getOrDefault ["frame", INSPECT_3D_FRAME];

        if (vectorMagnitude _offset > _limit) then {
            _target = _origin vectorAdd ((vectorNormalized _offset) vectorMultiply _limit);
        };

        _scene set ["target", _target];

        call _fnc_camera;
    };
    // A weapon looked at plainly, straight from its left side (turn 0) or its right (180), fitted (the buttons under the box).
    case "side": {
        if !(call _fnc_viewed) exitWith {};

        _arguments params [["_turn", 0, [0]]];

        _scene set ["view", [_turn, CARD_3D_PITCH, 1, 0, 0]];

        call _fnc_view;
        call _fnc_keep;
    };
    case "reset": {
        if (count _scene == 0) exitWith {};

        // A weapon's own view goes: plainly from the left side, as its card shows any weapon.
        if (call _fnc_viewed) exitWith {
            _scene set ["view", +WEAPON_VIEW_PLAIN];

            call _fnc_view;
            call _fnc_keep;
        };

        _scene set ["target", +(_scene get "origin")];
        _scene set ["dir", _scene getOrDefault ["startDir", 45]];
        _scene set ["pitch", _scene getOrDefault ["startPitch", 15]];
        _scene set ["distance", _scene get "start"];

        call _fnc_camera;
    };
    case "face": {
        if (count _scene == 0 || {!(_scene getOrDefault ["facing", false])}) exitWith {};

        _arguments params [["_muzzle", [], [[]]]];

        // Asked once: whatever comes of it, the view is the player's to turn from here.
        _scene set ["facing", false];

        if (count _muzzle != 3) exitWith {};

        // The barrel, level: from the weapon's base on the holder to its muzzle - not from what the view turns round, which lies
        // beside the barrel (the weapon's middle, or the holder's own place before its model is loaded: the MX stood 11 degrees
        // off its side, measured in game, 0.7.13).
        private _holder = (_scene getOrDefault ["objects", []]) param [1, objNull];
        private _base = if (isNull _holder) then {[0, 0, 0]} else {_holder selectionPosition ["proxy:\a3\characters_f\proxies\weapon.001", 0.5]};
        private _from = if (_base isEqualTo [0, 0, 0]) then {_scene get "origin"} else {_holder modelToWorldWorld _base};
        private _barrel = _muzzle vectorDiff _from;
        _barrel set [2, 0];

        // Too short to tell - a model whose muzzle sits at its base: the front left stays.
        if (vectorMagnitude _barrel < 0.05) exitWith {};

        _barrel = vectorNormalized _barrel;

        // The camera looks along -[sin dir, cos dir]; its right is [-cos dir, sin dir]. The barrel to the right:
        // sin dir = barrel y, cos dir = -barrel x.
        private _dir = (_barrel select 1) atan2 -(_barrel select 0);

        _scene set ["dir", _dir];
        _scene set ["startDir", _dir];

        call _fnc_camera;

        // Side on the weapon is wider across the box than from the front left: fitted to it anew.
        ["centre"] call FUNC(inspect3D);
    };
    case "preview": {
        if (count _scene == 0 || {!(_scene getOrDefault ["onHolder", false])}) exitWith {};

        _arguments params [["_change", [], [[]]], ["_from", controlNull, [controlNull]]];

        // Put back: only when something else was shown, and only by the tile that showed it - the mouse may come onto the next
        // tile before it is heard leaving this one.
        if (_change isEqualTo []) exitWith {
            if (!(_scene getOrDefault ["previewing", false])) exitWith {};
            if (!isNull _from && {_from isNotEqualTo (_scene getOrDefault ["previewBy", controlNull])}) exitWith {};

            _scene set ["previewing", false];
            [_scene get "attachments"] call _fnc_refit;
        };

        // [index, value]: the part put into what the scene shows now, not into what it showed when the tiles were made.
        _change params [["_index", -1, [0]], ["_value", ""]];

        private _parts = +(_scene getOrDefault ["attachments", []]);

        if (count _parts < 7 || {_index < 1}) exitWith {};

        _parts set [_index, _value];
        _scene set ["previewing", true];
        _scene set ["previewBy", _from];
        [_parts] call _fnc_refit;
    };
};
