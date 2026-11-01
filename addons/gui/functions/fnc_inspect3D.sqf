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
 * frame is the item's size, at most INSPECT_3D_FRAME. The lights shine by day too; the aperture is left to the engine - set,
 * it lit or darkened the whole world behind the window as well.
 *
 * The modding view (Modify, #56) leaves the player's own view where it is, the world round the window as it was (Mia: "is
 * there really no way that we don't have to hide Arma in the background?"): the weapon and its parts are put right in
 * front of the player's camera on a weapon holder of this machine's own, where they show through the card's hole (fnc_drawInspect) - with
 * a small light of their own and a dark plate behind them that fills the hole. The view is a camera of its own right where
 * the player's eye is, looking the same way with the same field of view - the world looks as it did, but the first person
 * weapon, which the game draws over everything however close anything is, is not drawn. The weapon is made small and put
 * as much closer (INSPECT_3D_NEAR_SCALE): nothing of the world gets between. The objects follow the camera every frame
 * ("follow", fnc_onFrame), turned, moved and zoomed as the scene far off would be: a camera going round the weapon, its
 * view mapped onto the line from the player's eye through the hole's middle, the weapon as far off along it as makes it as
 * large as the texture showed it. The places come from the weapon's model: its parts on its proxies (fnc_weaponPoints).
 * Where something stands in the way - a wall closer than the weapon would be - and in a vehicle, it falls back to the
 * scene far off, filmed with the game's own camera: the main view itself goes to the scene, at the
 * game's full quality - a texture of Picture-in-Picture is far coarser (Mia: "make it render exactly like a normal weapon"). The
 * window lets it show through a hole in the card where the picture would be (fnc_drawInspect). The camera then aims so the
 * item sits in the middle of that hole, as large as it would be in the texture: its field of view is the texture's, grown by
 * how much higher the screen is than the hole, and it is turned off the item by where the hole lies on the screen. What the
 * player's view was on - their own unit, a vehicle, a remote unit, and in which view - comes back when the scene goes.
 *
 * The state is GVAR(scene3D): the class and attachments it shows, the camera and where it stands, the lights, every object
 * made, the target [ASL], the turn (dir, pitch), the distance and its limits, the hole on the screen for the main view - and
 * for the modding view where the weapon's parts sit (fnc_weaponPoints). Started again for the same weapon with other parts,
 * only the holder is fitted out anew: the view stays as it was turned.
 *
 * Arguments:
 * 0: What to do <STRING>
 *    "start"   the scene for the item, unless it stands for it already - the one before goes (arguments: [class, attachments,
 *              the hole [x, y, w, h] on the screen to film into with the main view, [] for the texture])
 *    "stop"    the scene goes: camera, lights, objects
 *    "turn"    the camera goes round by how far the mouse moved, a share of the screen (arguments: [across, down])
 *    "zoom"    nearer for a turn of the wheel up, farther for one down (arguments: [turn])
 *    "pan"     the camera and what it looks at move across and up or down, as the middle mouse button drags them - the item
 *              moves with the mouse, at most its frame away from where it was (arguments: [across, down])
 *    "follow"  the near view after the player's camera, every frame (fnc_onFrame)
 *    "reset"   the view the scene started with
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

// The player's camera and the line from it through the hole's middle - [camera ASL, the line, the camera's up, how far along it
// the weapon is as large as the texture showed it at the distance given, the tangent of half the hole's height], [] where the
// screen cannot say. The screen's measure comes from the game itself: where points a tenth off the camera's axis land.
private _fnc_nearFrame = {
    params ["_hole", "_distance"];
    _hole params ["_holeX", "_holeY", "_holeW", "_holeH"];

    private _camera = AGLToASL (positionCameraToWorld [0, 0, 0]);
    private _forward = (AGLToASL (positionCameraToWorld [0, 0, 1])) vectorDiff _camera;
    private _right = (AGLToASL (positionCameraToWorld [1, 0, 0])) vectorDiff _camera;
    private _up = (AGLToASL (positionCameraToWorld [0, 1, 0])) vectorDiff _camera;
    private _middle = worldToScreen (positionCameraToWorld [0, 0, 1]);
    private _across = worldToScreen (positionCameraToWorld [0.1, 0, 1]);
    private _upward = worldToScreen (positionCameraToWorld [0, 0.1, 1]);

    if (_middle isEqualTo [] || {_across isEqualTo []} || {_upward isEqualTo []}) exitWith {[]};

    private _perX = ((_across select 0) - (_middle select 0)) / 0.1;
    private _perY = ((_middle select 1) - (_upward select 1)) / 0.1;

    if (_perX <= 0 || {_perY <= 0}) exitWith {[]};

    private _rayX = ((_holeX + _holeW / 2) - (_middle select 0)) / _perX;
    private _rayY = ((_middle select 1) - (_holeY + _holeH / 2)) / _perY;
    private _ray = vectorNormalized ((_forward vectorAdd (_right vectorMultiply _rayX)) vectorAdd (_up vectorMultiply _rayY));
    private _tanHole = (_holeH / 2) / _perY;

    [_camera, _ray, vectorNormalized _up, (_distance * INSPECT_3D_FOV / _tanHole) max 0.2, _tanHole]
};

// The near view in place: the weapon, its parts, the plate and the light where the camera, the turn and the distance put them,
// and the parts' points in the world (fnc_placeHotspots). Seen along the line through the hole as a camera going round the
// weapon (dir, pitch from the weapon's side) would see it: the model's axes taken from that camera's frame into the line's.
private _fnc_near = {
    private _frame = [_scene get "main", _scene get "distance"] call _fnc_nearFrame;

    if (_frame isEqualTo []) exitWith {};

    _frame params ["_camera", "_forward", "_cameraUp", "_away", "_tanHole"];

    private _right = vectorNormalized (_forward vectorCrossProduct _cameraUp);
    private _up = _right vectorCrossProduct _forward;
    private _dir = _scene get "dir";
    private _pitch = _scene get "pitch";
    private _seenFrom = [(sin _dir) * (cos _pitch), (cos _dir) * (cos _pitch), sin _pitch];
    private _lookV = _seenFrom vectorMultiply -1;
    private _rightV = vectorNormalized (_lookV vectorCrossProduct [0, 0, 1]);
    private _upV = _rightV vectorCrossProduct _lookV;

    private _fnc_map = {
        params ["_vector"];

        ((_right vectorMultiply (_vector vectorDotProduct _rightV)) vectorAdd (_up vectorMultiply (_vector vectorDotProduct _upV)))
            vectorAdd (_forward vectorMultiply (_vector vectorDotProduct _lookV))
    };

    // Small and as much closer: every place in the model shrinks with it (setObjectScale scales round the object's origin).
    private _scale = INSPECT_3D_NEAR_SCALE;
    private _origin = (_camera vectorAdd (_forward vectorMultiply (_away * _scale))) vectorDiff (([_scene get "target"] call _fnc_map) vectorMultiply _scale);

    // The weapon lies on a holder of its own, with its parts - as on the ground, where the game shows no muzzle flash, which a
    // muzzle device made a simple object of its own shows. The holder turned and put so its weapon proxy brings the weapon's model
    // where it goes: each of the holder's axes is the weapon's axes weighed by how the proxy lies on the holder.
    (_scene get "proxy") params ["_base", "_proxyDir", "_proxyUp"];

    private _proxyRight = _proxyDir vectorCrossProduct _proxyUp;
    private _weaponRight = [[1, 0, 0]] call _fnc_map;
    private _weaponDir = [[0, 1, 0]] call _fnc_map;
    private _weaponUp = [[0, 0, 1]] call _fnc_map;
    private _fnc_holderAxis = {
        params ["_index"];

        ((_weaponRight vectorMultiply (_proxyRight select _index)) vectorAdd (_weaponDir vectorMultiply (_proxyDir select _index)))
            vectorAdd (_weaponUp vectorMultiply (_proxyUp select _index))
    };
    private _holderX = [0] call _fnc_holderAxis;
    private _holderY = [1] call _fnc_holderAxis;
    private _holderZ = [2] call _fnc_holderAxis;
    private _holder = _scene get "holder";

    // Turned first: a turn sets the scale back.
    _holder setVectorDirAndUp [_holderY, _holderZ];
    _holder setPosWorld (_origin vectorDiff (
        (((_holderX vectorMultiply (_base select 0)) vectorAdd (_holderY vectorMultiply (_base select 1))) vectorAdd (_holderZ vectorMultiply (_base select 2)))
        vectorMultiply _scale
    ));
    _holder setObjectScale _scale;

    // Two squares side by side, as high as the hole where they stand, behind the weapon: the hole is twice as wide as high.
    private _behind = (_away + (_scene get "frame") * 0.6) * _scale;
    private _side = 2.2 * _behind * _tanHole;

    {
        _x params ["_plate", "_shift"];

        _plate setVectorDirAndUp [_forward, _up];
        _plate setPosWorld ((_camera vectorAdd (_forward vectorMultiply _behind)) vectorAdd (_right vectorMultiply (_shift * _side)));
        _plate setObjectScale _side;
    } forEach (_scene get "plates");

    private _lightAway = _away * _scale;

    (_scene get "light") setPosASL (
        ((_camera vectorAdd (_forward vectorMultiply (_lightAway * 0.4))) vectorAdd (_up vectorMultiply (_lightAway * 0.5))) vectorAdd (_right vectorMultiply (_lightAway * -0.4))
    );

    private _points = createHashMap;

    {
        _points set [_x, _origin vectorAdd (([_y] call _fnc_map) vectorMultiply _scale)];
    } forEach ([_scene, true] call FUNC(weaponPoints));

    _scene set ["points", _points];
    _scene set ["cameraPos", _camera];
};

// The camera where the turn and the distance put it, looking at the item, and the lights round it with it - in the near view,
// the weapon where they put it.
private _fnc_camera = {
    if (_scene getOrDefault ["close", false]) exitWith {call _fnc_near};

    private _camera = _scene getOrDefault ["camera", objNull];

    if (isNull _camera) exitWith {};

    private _target = _scene get "target";
    private _dir = _scene get "dir";
    private _pitch = _scene get "pitch";
    private _distance = _scene get "distance";
    private _across = (cos _pitch) * _distance;
    private _cameraPos = _target vectorAdd [(sin _dir) * _across, (cos _dir) * _across, (sin _pitch) * _distance];

    private _aim = _target;
    private _fov = INSPECT_3D_FOV;
    private _hole = _scene getOrDefault ["main", []];

    // The main view: the item in the middle of the hole. Seen from the camera, the item lies that far off the middle of the
    // screen - across by the screen's width times the field of view, up by its height -, so the camera looks past it by as
    // much. Worked out in a few steps, as the frame turns with where it looks.
    if (count _hole == 4) then {
        _hole params ["_holeX", "_holeY", "_holeW", "_holeH"];

        _fov = INSPECT_3D_FOV * safezoneH / (_holeH max pixelH);

        private _tanH = _fov * (getResolution select 4);
        private _offX = ((_holeX + _holeW / 2) - (safezoneX + safezoneW / 2)) / (safezoneW / 2);
        private _offY = ((safezoneY + safezoneH / 2) - (_holeY + _holeH / 2)) / (safezoneH / 2);
        private _toItem = vectorNormalized (_target vectorDiff _cameraPos);
        private _forward = _toItem;

        for "_i" from 1 to 4 do {
            private _right = vectorNormalized (_forward vectorCrossProduct [0, 0, 1]);
            private _up = _right vectorCrossProduct _forward;

            _forward = vectorNormalized (
                (_toItem vectorMultiply (1 / ((_toItem vectorDotProduct _forward) max 0.1)))
                vectorDiff (_right vectorMultiply (_offX * _tanH)) vectorDiff (_up vectorMultiply (_offY * _fov))
            );
        };

        _aim = _cameraPos vectorAdd (_forward vectorMultiply _distance);
    };

    // The scene is in ASL, the camera takes AGL.
    _camera camSetPos (ASLToAGL _cameraPos);
    _camera camSetTarget (ASLToAGL _aim);
    _camera camSetFov _fov;
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

switch (_mode) do {
    case "start": {
        _arguments params [["_class", "", [""]], ["_attachments", [], [[]]], ["_hole", [], [[]]]];

        if (_class isEqualTo "") exitWith {};

        // The near view of the same weapon: into another hole it only moves, with other parts only those are made anew - the
        // view stays as it was turned.
        if ((_scene getOrDefault ["class", ""]) isEqualTo _class && {_scene getOrDefault ["close", false]} && {_hole isNotEqualTo []}) exitWith {
            _scene set ["main", +_hole];

            if ((_scene getOrDefault ["attachments", []]) isNotEqualTo _attachments) then {
                private _holder = _scene get "holder";

                clearWeaponCargo _holder;
                clearMagazineCargo _holder;
                _holder addWeaponWithAttachmentsCargo [[_class, _attachments] call _fnc_fitOut, 1];
                _scene set ["attachments", +_attachments];
            };

            call _fnc_near;
        };

        // A weapon in the near view, where nothing stands closer to the camera than it would - else the scene far off below.
        private _weaponModel = [_class] call FUNC(itemModel);
        private _isWeapon = (["Rifle", "Pistol", "Launcher"] findIf {_class isKindOf [_x, configFile >> "CfgWeapons"]}) >= 0;
        // On foot: in a vehicle the eye sits among its insides.
        private _nearFrame = if (_hole isNotEqualTo [] && {_isWeapon} && {_weaponModel isNotEqualTo ""} && {vehicle player isEqualTo player}) then {
            [_hole, (INSPECT_3D_FRAME * INSPECT_3D_DISTANCE) max 0.25] call _fnc_nearFrame
        } else {
            []
        };

        if (_nearFrame isNotEqualTo []) then {
            _nearFrame params ["_camera", "_ray", "", "_away"];

            private _blocked = lineIntersectsSurfaces [
                _camera, _camera vectorAdd (_ray vectorMultiply ((_away + INSPECT_3D_FRAME) * INSPECT_3D_NEAR_SCALE)), player, vehicle player, true, 1, "VIEW", "FIRE"
            ];

            if (_blocked isNotEqualTo []) then {
                _nearFrame = [];
            };
        };

        if (_nearFrame isNotEqualTo []) exitWith {
            ["stop"] call FUNC(inspect3D);

            _scene = createHashMapFromArray [["class", _class], ["attachments", +_attachments], ["main", +_hole], ["close", true]];
            GVAR(scene3D) = _scene;

            private _objects = [];
            _scene set ["objects", _objects];

            // A camera where the player's eye is, the same way, the same field of view - taken as the screen shows it.
            private _eye = positionCameraToWorld [0, 0, 0];
            private _ahead = positionCameraToWorld [0, 0, 10];
            private _middle = worldToScreen (positionCameraToWorld [0, 0, 1]);
            private _upward = worldToScreen (positionCameraToWorld [0, 0.1, 1]);
            private _camera = "camera" camCreate _eye;

            _scene set ["before", [cameraOn, cameraView]];
            _camera camSetPos _eye;
            _camera camSetTarget _ahead;
            _camera camSetFov ((safezoneH / 2) / ((((_middle select 1) - (_upward select 1)) / 0.1) max 0.01));
            _camera camCommit 0;
            _camera cameraEffect ["Internal", "Back"];
            _scene set ["camera", _camera];

            // Seen from the eye, the player's own head and weapon would stand in the way: hidden for this machine while it is open.
            private _self = !isObjectHidden player;

            if (_self) then {
                player hideObject true;
            };

            _scene set ["hidSelf", _self];

            // The weapon's size from its model; a suppressor or a bipod reaches out of that box (the distance below).
            private _probe = createSimpleObject [_weaponModel, [0, 0, 0], true];

            (0 boundingBoxReal _probe) params ["_boxMin", "_boxMax"];
            deleteVehicle _probe;

            private _centre = (_boxMin vectorAdd _boxMax) vectorMultiply 0.5;
            private _frame = ((vectorMagnitude (_boxMax vectorDiff _boxMin)) max 0.1) min INSPECT_3D_FRAME;

            _scene set ["target", _centre];
            _scene set ["origin", +_centre];
            _scene set ["frame", _frame];

            // The weapon with its parts on a holder of this machine's own, never loot (aio_nearby, aio_storage_fnc_getNearby). Where
            // the weapon lies on it: read from the holder once its model is there, else as every holder has it.
            private _holder = "GroundWeaponHolder_Scripted" createVehicleLocal [0, 0, 0];
            _holder setVariable ["aio_nearby", false];
            _holder addWeaponWithAttachmentsCargo [[_class, _attachments] call _fnc_fitOut, 1];
            _objects pushBack _holder;
            _scene set ["holder", _holder];

            private _proxy = "proxy:\a3\characters_f\proxies\weapon.001";
            private _base = _holder selectionPosition [_proxy, 0.5];

            _scene set ["proxy", if (_base isEqualTo [0, 0, 0]) then {
                [[0.103135, -0.0114412, -0.617881], [0, -0.003016, 0.999996], [0, 0.999995, 0.003016]]
            } else {
                [_base] + (_holder selectionVectorDirAndUp [_proxy, 0.5])
            }];

            private _plates = [-0.5, 0.5] apply {
                private _plate = createSimpleObject ["UserTexture1m_F", [0, 0, 0], true];
                _plate setObjectTexture [0, "#(argb,8,8,3)color(0.05,0.055,0.065,1)"];
                _objects pushBack _plate;

                [_plate, _x]
            };

            _scene set ["plates", _plates];

            private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
            _light setLightBrightness 1.2;
            _light setLightAmbient [0.9, 0.9, 0.9];
            _light setLightColor [1, 0.97, 0.92];
            _light setLightUseFlare false;
            _light setLightDayLight true;
            _light setLightAttenuation [0, 0, 1, 0.5, 2, 4];
            _objects pushBack _light;
            _scene set ["light", _light];

            // A muzzle device makes the weapon longer at its muzzle: aimed a little that way.
            private _muzzleAt = ([_scene, true] call FUNC(weaponPoints)) getOrDefault ["muzzle", []];

            if ((([_class, _attachments] call _fnc_fitOut) select 1) isNotEqualTo "" && {count _muzzleAt == 3}) then {
                _centre = _centre vectorAdd ((_muzzleAt vectorDiff _centre) vectorMultiply 0.3);
                _scene set ["target", _centre];
                _scene set ["origin", +_centre];
            };

            // The weapon's side, a little from the front and above - a little farther than the model's box asks, for the parts.
            private _distance = ((_frame * INSPECT_3D_DISTANCE * 1.25) max 0.25) min 6;

            _scene set ["dir", INSPECT_3D_NEAR_DIR];
            _scene set ["pitch", 15];
            _scene set ["distance", _distance];
            _scene set ["start", _distance];
            _scene set ["near", _distance * 0.3];
            _scene set ["far", _distance * 3];

            call _fnc_near;
        };

        // The same item filmed the other way - into the texture or the main view - is a scene of its own; into a hole elsewhere on
        // the screen only aims anew.
        private _running = (_scene getOrDefault ["class", ""]) isEqualTo _class && {!isNull (_scene getOrDefault ["camera", objNull])}
            && {((_scene getOrDefault ["main", []]) isEqualTo []) isEqualTo (_hole isEqualTo [])};

        if (_running && {(_scene getOrDefault ["main", []]) isNotEqualTo _hole}) then {
            _scene set ["main", +_hole];
            call _fnc_camera;
        };

        if (_running && {(_scene getOrDefault ["attachments", []]) isEqualTo _attachments}) exitWith {};

        // The same weapon on the holder with other parts - one put on or taken off in the modding view (fnc_drawHotspots): only
        // what lies on the holder changes, the view stays as the player turned it.
        if (_running && {_scene getOrDefault ["onHolder", false]}) exitWith {
            private _holder = (_scene get "objects") param [1, objNull];

            clearWeaponCargo _holder;
            clearMagazineCargo _holder;
            _holder addWeaponWithAttachmentsCargo [[_class, _attachments] call _fnc_fitOut, 1];
            _scene set ["attachments", +_attachments];
        };

        ["stop"] call FUNC(inspect3D);

        _scene = createHashMapFromArray [["class", _class], ["attachments", +_attachments], ["main", +_hole]];
        GVAR(scene3D) = _scene;

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
        private _lights = [[30, [1, 0.97, 0.92], [1, 0.97, 0.92]], [12, [0.6, 0.7, 0.9], [0.7, 0.8, 1]], [20, [1, 1, 1], [1, 0.9, 0.8]]] apply {
            _x params ["_brightness", "_ambient", "_colour"];

            private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
            _light setPosASL _target;
            _light setLightBrightness _brightness;
            _light setLightIntensity (_brightness * 10);
            _light setLightAmbient _ambient;
            _light setLightColor _colour;
            _light setLightUseFlare false;
            _light setLightDayLight true;
            _light setLightAttenuation [0, 1, 0, 0, 20, 40];
            _objects pushBack _light;

            _light
        };

        _scene set ["lights", _lights];

        // A little above the item, from the front left; near enough for its size.
        private _distance = ((_frame * INSPECT_3D_DISTANCE) max 0.25) min 6;

        _scene set ["dir", 45];
        _scene set ["pitch", 15];
        _scene set ["distance", _distance];
        _scene set ["start", _distance];
        _scene set ["near", _distance * 0.3];
        _scene set ["far", _distance * 3];

        private _camera = "camera" camCreate (ASLToAGL _target);

        // Into the main view: what it was on before, to give it back (see "stop").
        if (_hole isEqualTo []) then {
            _camera cameraEffect ["Internal", "Back", INSPECT_3D_TARGET];
        } else {
            _scene set ["before", [cameraOn, cameraView]];
            _camera cameraEffect ["Internal", "Back"];
        };

        _camera camSetFocus [-1, -1];
        _scene set ["camera", _camera];

        call _fnc_camera;
    };
    case "stop": {
        if (count _scene == 0) exitWith {};

        private _camera = _scene getOrDefault ["camera", objNull];

        // Destroying a camera does not end what it films into. The main view goes back to the player - and to what it was on, a
        // vehicle or a remote unit, in the view it had.
        if (!isNull _camera) then {
            if ((_scene getOrDefault ["main", []]) isEqualTo []) then {
                _camera cameraEffect ["Terminate", "Back", INSPECT_3D_TARGET];
            } else {
                _camera cameraEffect ["Terminate", "Back"];
            };

            camDestroy _camera;
        };

        if (_scene getOrDefault ["hidSelf", false]) then {
            player hideObject false;
        };

        (_scene getOrDefault ["before", []]) params [["_on", objNull], ["_view", ""]];

        if (!isNull _on && {_view isNotEqualTo ""} && {cameraOn isNotEqualTo _on || {cameraView isNotEqualTo _view}}) then {
            _on switchCamera _view;
        };

        {
            if (!isNull _x) then {
                deleteVehicle _x;
            };
        } forEach (_scene getOrDefault ["objects", []]);

        GVAR(scene3D) = createHashMap;
        GVAR(inspect3DTurn) = [];
        GVAR(inspect3DPan) = [];
    };
    case "turn": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_across", 0, [0]], ["_down", 0, [0]]];

        // The item follows the mouse: dragged to the right, its front turns to the right.
        _scene set ["dir", (_scene get "dir") + _across * INSPECT_3D_TURN_ACROSS];
        _scene set ["pitch", (((_scene get "pitch") + _down * INSPECT_3D_TURN_DOWN) max -80) min 80];

        call _fnc_camera;
    };
    case "zoom": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_turn", 0, [0]]];

        if (_turn == 0) exitWith {};

        // By how far the wheel turned: several notches in one frame come as one turn of that many.
        private _distance = (_scene get "distance") / (1.15 ^ ((_turn max -6) min 6));

        _scene set ["distance", ((_distance max (_scene get "near")) min (_scene get "far"))];

        call _fnc_camera;
    };
    case "pan": {
        if (count _scene == 0) exitWith {};

        _arguments params [["_across", 0, [0]], ["_down", 0, [0]]];

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
    case "follow": {
        if (_scene getOrDefault ["close", false]) then {
            call _fnc_near;
        };
    };
    case "reset": {
        if (count _scene == 0) exitWith {};

        _scene set ["target", +(_scene get "origin")];
        _scene set ["dir", [45, INSPECT_3D_NEAR_DIR] select (_scene getOrDefault ["close", false])];
        _scene set ["pitch", 15];
        _scene set ["distance", _scene get "start"];

        call _fnc_camera;
    };
};
