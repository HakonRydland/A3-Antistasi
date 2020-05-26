params ["_side", "_timerIndex", "_supportType", "_supportPos", "_precision", "_revealCall"];

/*  Creates an support type that attacks areas

    Execution on: Server

    Scope: Internal

    Parameters:
        _side: SIDE: The side of the support unit
        _timerIndex: NUMBER: The number of the timer for the support
        _supportType: STRING : The type of support to send
        _supportPos: POSITION : The position which will be attack
        _precision: NUMBER : How precise the target info is
*/

private _fileName = "createArealSupport";

//Selecting the first available name of support type
private _supportIndex = 0;
private _supportName = format ["%1%2", _supportType, _supportIndex];
while {(server getVariable [format ["%1_targets", _supportName], -1]) isEqualType []} do
{
    _supportIndex = _supportIndex + 1;
    _supportName = format ["%1%2", _supportType, _supportIndex];
};

[
    3,
    format ["New support name will be %1", _supportName],
    _fileName
] call A3A_fnc_log;

private _supportMarker = "";
switch (_supportType) do
{
    case ("QRF"):
    {
        _supportMarker = [_side, _supportPos, _supportName] call A3A_fnc_SUP_QRF;
    };
    case ("AIRSTRIKE"):
    {
        _supportMarker = [_side, _timerIndex, _supportPos, _supportName] call A3A_fnc_SUP_airstrike;
    };
    case ("MORTAR"):
    {
        _supportMarker = [_side, _timerIndex, _supportPos, _supportName] call A3A_fnc_SUP_mortar;
    };
};

if(_supportMarker != "") then
{
    server setVariable [format ["%1_targets", _supportName], [[[_supportPos, _precision], _revealCall]], true];
    if (_side == Occupants) then
    {
        occupantsSupports pushBack [_supportType, _supportMarker, _supportName];
    };
    if(_side == Invaders) then
    {
        invadersSupports pushBack [_supportType, _supportMarker, _supportName];
    };
    [_revealCall + (random 0.4) - 0.2, _side, toLower _supportType, _supportPos] spawn A3A_fnc_showInterceptedSetupCall;
};
