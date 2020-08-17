params ["_side", "_strikePlane", "_strikeGroup", "_airport", "_targetPos", "_supportName"];

private _fileName = "SUP_airstrikeRoutine";
//Sleep to simulate preparetion time
private _sleepTime = random (200 - ((tierWar - 1) * 20));
while {_sleepTime > 0} do
{
    sleep 1;
    _sleepTime = _sleepTime - 1;
    if((spawner getVariable _airport) != 2) exitWith {};
};

_strikePlane setFuel 1;
_strikePlane hideObjectGlobal false;
_strikePlane enableSimulation true;

private _targetList = server getVariable [format ["%1_targets", _supportName], []];
private _reveal = _targetList select 0 select 1;

private _textMarker = createMarker [format ["%1_text", _supportName], _targetPos];
_textMarker setMarkerShape "ICON";
_textMarker setMarkerType "mil_dot";
_textMarker setMarkerText "Airstrike";
if(_side == Occupants) then
{
    _textMarker setMarkerColor colorOccupants;
}
else
{
    _textMarker setMarkerColor colorInvaders;
};
_textMarker setMarkerAlpha 0;
[_reveal, _targetPos, _side, "Airstrike", format ["%1_coverage", _supportName], _textMarker] spawn A3A_fnc_showInterceptedSupportCall;
[_side, format ["%1_coverage", _supportName]] spawn A3A_fnc_clearTargetArea;

_strikePlane flyInHeight 150;
private _minAltASL = ATLToASL [_targetPos select 0, _targetPos select 1, 0];
_strikePlane flyInHeightASL [(_minAltASL select 2) +150, (_minAltASL select 2) +150, (_minAltASL select 2) +150];

private _airportPos = getMarkerPos _airport;
private _dir = markerDir (format ["%1_coverage", _supportName]);

//Have a preBomb position to ensure nearly perfect flight path
private _preBombPosition = _targetPos getPos [750, _dir + 180];
_preBombPosition set [2, 150];
private _startBombPosition = _targetPos getPos [100, _dir + 180];
_startBombPosition set [2, 150];
private _endBombPosition = _targetPos getPos [100, _dir];
_endBombPosition set [2, 150];

//Determine speed and bomb count on aggression
private _aggroValue = if(_side == Occupants) then {aggressionOccupants} else {aggressionInvaders};
private _flightSpeed = "LIMITED";
private _bombCount = 4;
if(_aggroValue >= 70) then
{
    _flightSpeed = "FULL";
    _bombCount = 8;
};
if(_aggroValue > 30 && _aggroValue < 70) then
{
    _flightSpeed = "NORMAL";
    _bombCount = 6;
};

//Creating bombing parameters
private _bombParams = [_strikePlane, _strikePlane getVariable "bombType", _bombCount, 200];
(driver _strikePlane) setVariable ["bombParams", _bombParams, true];

private _startingPoint = (getPos _strikePlane) getPos [750, getDir _strikePlane];
_startingPoint set [2, 100];
private _wp0 = _strikeGroup addWaypoint [_startingPoint, 0];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointSpeed "FULL";
_wp1 setWaypointBehaviour "CARELESS";

private _wp1 = _strikeGroup addWaypoint [_preBombPosition, 1];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointSpeed "FULL";
_wp1 setWaypointBehaviour "CARELESS";

private _wp2 = _strikeGroup addWaypoint [_startBombPosition, 2];
_wp2 setWaypointType "MOVE";
_wp2 setWaypointSpeed _flightSpeed;

[_startBombPosition, driver _strikePlane] spawn
{
    params ["_pos", "_pilot"];
    waitUntil {sleep 1; ((_pos distance2D _pilot) < 750) || {isNull (objectParent _pilot)}};
    if(isNull (objectParent _pilot)) exitWith {};
    waitUntil {sleep 0.1; ((_pos distance2D _pilot) < 500) || {isNull (objectParent _pilot)}};
    if(isNull (objectParent _pilot)) exitWith {};
    group _pilot setCurrentWaypoint [(group _pilot), 2];
};

[_startBombPosition, driver _strikePlane] spawn
{
    params ["_pos", "_pilot"];
    waitUntil {sleep 1; ((_pos distance2D _pilot) < 350) || {isNull (objectParent _pilot)}};
    if(isNull (objectParent _pilot)) exitWith {};
    waitUntil {sleep 0.1; ((_pos distance2D _pilot) < 250) || {isNull (objectParent _pilot)}};
    if(isNull (objectParent _pilot)) exitWith {};
    (_pilot getVariable 'bombParams') spawn A3A_fnc_airbomb;
};

private _wp3 = _strikeGroup addWaypoint [_endBombPosition, 3];
_wp3 setWaypointType "MOVE";
_wp3 setWaypointSpeed _flightSpeed;

private _wp4 = _strikeGroup addWaypoint [_airportPos, 4];
_wp4 setWaypointType "MOVE";
_wp4 setWaypointSpeed "FULL";
_wp4 setWaypointStatements ["true", "[(objectParent this) getVariable 'supportName', side (group this)] spawn A3A_fnc_endSupport; deleteVehicle (objectParent this); deleteVehicle this"];

//Give the plane some starting assist
while {((velocity _strikePlane) select 2) < 5} do
{
    private _velocity = velocityModelSpace _strikePlane;
    _velocity set [1, (_velocity select 1) * 1.025];
    _strikePlane setVelocityModelSpace _velocity;
    sleep 0.1;
};
