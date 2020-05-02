/*
	Initialises a vehicle for use in Antistasi.
	Handles last-resort despawning and various damage/smoke/kill/capture logic

	Params:
	1. Object: Vehicle object
	2. Side: Initial side ownership for vehicle. Will change if rebel enters the vehicle.
	3. Bool (default false): If true, don't send to the despawner unless captured.

	Will set and modify the "sideOwner" variable on the vehicle.
*/

params ["_veh", "_side", ["_noDespawn"]];

if (isNil "_veh") exitWith {};
if ((_veh isKindOf "FlagCarrier") or (_veh isKindOf "Building") or (_veh isKindOf "ReammoBox_F")) exitWith {};
//if (_veh isKindOf "ReammoBox_F") exitWith {[_veh] call A3A_fnc_NATOcrate};

_veh setVariable ["sideOwner", _side, true];

private _typeX = typeOf _veh;

if ((_typeX in vehNormal) or (_typeX in vehAttack) or (_typeX in vehBoats)) then
{
	_veh call A3A_fnc_addActionBreachVehicle;

	if !(_typeX in vehAttack) then
	{
		if (_veh isKindOf "Car") then
			{
			_veh addEventHandler ["HandleDamage",{if (((_this select 1) find "wheel" != -1) and ((_this select 4=="") or (side (_this select 3) != teamPlayer)) and (!isPlayer driver (_this select 0))) then {0} else {(_this select 2)}}];
			if ({"SmokeLauncher" in (_veh weaponsTurret _x)} count (allTurrets _veh) > 0) then
				{
				_veh setVariable ["within",true];
				_veh addEventHandler ["GetOut", {private ["_veh"]; _veh = _this select 0; if (side (_this select 2) != teamPlayer) then {if (_veh getVariable "within") then {_veh setVariable ["within",false]; [_veh] call A3A_fnc_smokeCoverAuto}}}];
				_veh addEventHandler ["GetIn", {private ["_veh"]; _veh = _this select 0; if (side (_this select 2) != teamPlayer) then {_veh setVariable ["within",true]}}];
				};
			};
		};
	}
	else
		{
		if (_typeX in vehAPCs) then
			{
			_veh addEventHandler ["HandleDamage",{private ["_veh"]; _veh = _this select 0; if (!canFire _veh) then {[_veh] call A3A_fnc_smokeCoverAuto; _veh removeEventHandler ["HandleDamage",_thisEventHandler]};if (((_this select 1) find "wheel" != -1) and (_this select 4=="") and (!isPlayer driver (_veh))) then {0;} else {(_this select 2);}}];
			_veh setVariable ["within",true];
			_veh addEventHandler ["GetOut", {private ["_veh"];  _veh = _this select 0; if (side (_this select 2) != teamPlayer) then {if (_veh getVariable "within") then {_veh setVariable ["within",false];[_veh] call A3A_fnc_smokeCoverAuto}}}];
			_veh addEventHandler ["GetIn", {private ["_veh"];_veh = _this select 0; if (side (_this select 2) != teamPlayer) then {_veh setVariable ["within",true]}}];
			}
		else
			{
			if (_typeX in vehTanks) then
				{
				_veh addEventHandler ["HandleDamage",{private ["_veh"]; _veh = _this select 0; if (!canFire _veh) then {[_veh] call A3A_fnc_smokeCoverAuto;  _veh removeEventHandler ["HandleDamage",_thisEventHandler]}}];
				}
			else
				{
				_veh addEventHandler ["HandleDamage",{if (((_this select 1) find "wheel" != -1) and ((_this select 4=="") or (side (_this select 3) != teamPlayer)) and (!isPlayer driver (_this select 0))) then {0} else {(_this select 2)}}];
				};
			};
		};
	}
else
	{
	if (_typeX in vehPlanes) then
		{
		_veh addEventHandler ["GetIn",
			{
			_positionX = _this select 1;
			if (_positionX == "driver") then
				{
				_unit = _this select 2;
				if ((!isPlayer _unit) and (_unit getVariable ["spawner",false]) and (side group _unit == teamPlayer)) then
					{
					moveOut _unit;
					["General", "Only Humans can pilot an air vehicle"] call A3A_fnc_customHint;
					};
				};
			}];
		if (_veh isKindOf "Helicopter") then
			{
			if (_typeX in vehTransportAir) then
				{
				_veh setVariable ["within",true];
				_veh addEventHandler ["GetOut", {private ["_veh"];_veh = _this select 0; if ((isTouchingGround _veh) and (isEngineOn _veh)) then {if (side (_this select 2) != teamPlayer) then {if (_veh getVariable "within") then {_veh setVariable ["within",false]; [_veh] call A3A_fnc_smokeCoverAuto}}}}];
				_veh addEventHandler ["GetIn", {private ["_veh"];_veh = _this select 0; if (side (_this select 2) != teamPlayer) then {_veh setVariable ["within",true]}}];
				};
			};
		}
	else
		{
		if (_veh isKindOf "StaticWeapon") then
			{
			_veh setCenterOfMass [(getCenterOfMass _veh) vectorAdd [0, 0, -1], 0];
			if ((not (_veh in staticsToSave)) and (side gunner _veh != teamPlayer)) then
				{
				if (activeGREF and ((_typeX == staticATteamPlayer) or (_typeX == staticAAteamPlayer))) then {[_veh,"moveS"] remoteExec ["A3A_fnc_flagaction",[teamPlayer,civilian],_veh]} else {[_veh,"steal"] remoteExec ["A3A_fnc_flagaction",[teamPlayer,civilian],_veh]};
				};
			if (_typeX == SDKMortar) then
				{
				if (!isNull gunner _veh) then
					{
					[_veh,"steal"] remoteExec ["A3A_fnc_flagaction",[teamPlayer,civilian],_veh];
					};
				_veh addEventHandler ["Fired",
					{
					_mortarX = _this select 0;
					_dataX = _mortarX getVariable ["detection",[position _mortarX,0]];
					_positionX = position _mortarX;
					_chance = _dataX select 1;
					if ((_positionX distance (_dataX select 0)) < 300) then
						{
						_chance = _chance + 2;
						}
					else
						{
						_chance = 0;
						};
					if (random 100 < _chance) then
						{
						{if ((side _x == Occupants) or (side _x == Invaders)) then {_x reveal [_mortarX,4]}} forEach allUnits;
						if (_mortarX distance posHQ < 300) then
							{
							if (!(["DEF_HQ"] call BIS_fnc_taskExists)) then
								{
								_LeaderX = leader (gunner _mortarX);
								if (!isPlayer _LeaderX) then
									{
									[[],"A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler",2];
									}
								else
									{
									if ([_LeaderX] call A3A_fnc_isMember) then {[[],"A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler",2]};
									};
								};
							}
						else
							{
							_bases = airportsX select {(getMarkerPos _x distance _mortarX < distanceForAirAttack) and ([_x,true] call A3A_fnc_airportCanAttack) and (sidesX getVariable [_x,sideUnknown] != teamPlayer)};
							if (count _bases > 0) then
								{
								_base = [_bases,_positionX] call BIS_fnc_nearestPosition;
								_sideX = sidesX getVariable [_base,sideUnknown];
								[[getPosASL _mortarX,_sideX,"Normal",false],"A3A_fnc_patrolCA"] remoteExec ["A3A_fnc_scheduler",2];
								};
							};
						};
					_mortarX setVariable ["detection",[_positionX,_chance]];
					}];
				};
			};
		};
	};

[_veh] spawn A3A_fnc_cleanserVeh;


// EH behaviour:
// GetIn/GetOut/Dammaged: Runs where installed, regardless of locality 
// Local: Runs where installed if target was local before or after the transition
// HandleDamage/Killed: Runs where installed, only if target is local
// MPKilled: Runs everywhere, regardless of locality

if (_side != teamPlayer) then {

	// Vehicle stealing handler
	_veh addEventHandler ["GetIn", {

		params ["_veh", "_role", "_unit"];

		if (side group _unit != teamPlayer) exitWith {};		// only rebels can flip vehicles atm
		private _side = _veh getVariable ["ownerSide", teamPlayer];
		if (_side == teamPlayer) exitWith {};

		[_veh, teamPlayer, true] call A3A_fnc_vehKilledOrCaptured;

		_veh setVariable ["ownerSide", teamPlayer, true];
		[_veh] spawn A3A_fnc_VEHdespawner;

		_veh removeEventHandler ["GetIn", _thisEventHandler];
	}];
};

// Because Killed and MPKilled are both retarded, we use Dammaged

_veh addEventHandler ["Dammaged", {
	params ["_veh", "_selection", "_damage"];
	if (_damage >= 1 && _selection == "") then {
		[_veh, side group (_this select 5), false] call A3A_fnc_vehKilledOrCaptured;
		[_veh] spawn A3A_fnc_postmortem;
		_veh removeEventHandler ["Dammaged", _thisEventHandler];
	};
}];


/*
if (isNil "A3A_vehicleEH_addHandlers") then 
{	
	A3A_vehicleEH_Killed = {
		params ["_veh", "_killer", "_instigator"];
		[_veh, side group _instigator, false] call A3A_fnc_vehKilledOrCaptured;
		[_veh] spawn A3A_fnc_postmortem;
	};
	
	A3A_vehicleEH_Local = {
		params ["_veh", "_isLocal"];
		[_veh] remoteExec ["A3A_vehicleEH_addHandlers", _veh];
		_veh removeEventHandler ["Killed", _veh getVariable "killedEHindex"];
		_veh removeEventHandler ["Local", _thisEventHandler];
	};

	A3A_vehicleEH_addHandlers = {
		params ["_veh"];
		_veh addEventHandler ["Local", A3A_vehicleEH_Local];
		_idx = _veh addEventHandler ["Killed", A3A_vehicleEH_Killed];
		_veh setVariable ["killedEHIndex", _idx];
	};
};
_veh call A3A_vehicleEH_addHandlers;
*/


/*
_veh addMPEventHandler ["MPKilled", {
	
	if (!isServer) exitWith {};			// MPKilled runs everywhere for some reason
	params ["_veh", "_killer", "_instigator"];
	[_veh, side group _instigator, false] call A3A_fnc_vehKilledOrCaptured;
	[_veh] spawn A3A_fnc_postmortem;
}];
*/

if (not(_veh in staticsToSave)) then
	{
	if (((count crew _veh) > 0) and (not (_typeX in vehAA)) and (not (_typeX in vehMRLS) and !(_veh isKindOf "StaticWeapon"))) then
		{
		[_veh] spawn A3A_fnc_VEHdespawner
		};
	if (_veh distance getMarkerPos respawnTeamPlayer <= 50) then
		{
		clearMagazineCargoGlobal _veh;
		clearWeaponCargoGlobal _veh;
		clearItemCargoGlobal _veh;
		clearBackpackCargoGlobal _veh;
		};
	};
