params ["_destination", "_type", "_side", ["_arguments", []]];

/*  Handles the creation of any AI Action
*   Params
*     _destination : MARKER or POS; the marker or position the AI should take AI on
*     _type : STRING; (not case sensitive) one of "ATTACK", "PATROL", "REINFORCE", "CONVOY", "AIRSTRIKE" more to add
*     _side : SIDE; the side of the AI forces to send
*     _arguments : ARRAY; any further argument needed for the operation
*        -here should be some manual for each _type, but it is currently unfinished
*   Returns:
*     Nothing
*/

if(!serverInitDone) then
{
  diag_log "CreateAIAction: Waiting for server init to be completed!";
  waitUntil {sleep 1; serverInitDone};
};

if(isNil "_destination") exitWith {diag_log "CreateAIAction: No destination given for AI Action"};
_acceptedTypes = ["attack", "patrol", "reinforce", "convoy", "airstrike"];
if(isNil "_type" || {!((toLower _type) in _acceptedTypes)}) exitWith {diag_log "CreateAIAction: Type is not in the accepted types"};
if(isNil "_side" || {!(_side == Occupants || _side == Invaders)}) exitWith {diag_log "CreateAIAction: Can only create AI for Inv and Occ"};

_convoyID = round (random 1000);
_IDinUse = server getVariable [format ["Con%1", _convoyID], false];
sleep 0.1;
while {_IDinUse} do
{
  _convoyID = round (random 1000);
  _IDinUse = server getVariable [format ["Con%1", _convoyID], false];
};
server setVariable [format ["Con%1", _convoyID], true, true];

_convoyID spawn
{
  sleep (30 * 60);
  server setVariable [format ["Con%1", _this], nil, true];
};

_type = toLower _type;
_isMarker = _destination isEqualType "";
_targetString = if(_isMarker) then {_destination} else {str _destination};
diag_log format ["CreateAIAction[%1]: Started creation of %2 action to %3", _convoyID, _type, _targetString];

_destinationPos = if(_isMarker) then {getMarkerPos _destination} else {_destination};
_originPos = [];
_origin = "";
_units = [];
_vehicleCount = 0;
_cargoCount = 0;
private _abort = false;

if(_type == "reinforce") then
{
  _arguments params ["_canReinf"];
  _possibleBases = _canReinf select {[_x, _destination] call A3A_fnc_shouldReinforce};
  if((count _possibleBases) != 0) then
  {

	_selectedBase = [_possibleBases, _destination] call BIS_fnc_nearestPosition;
	//Found base to reinforce, selecting units now
	_units = [_selectedBase, _destination] call A3A_fnc_selectReinfUnits;

	if(_units isEqualTo []) then
	{
	  diag_log format ["CreateAIAction[%1]: No units given for reinforcements!", _convoyID];
	  _abort = true;
	}
	else
	{
	  _origin = _selectedBase;
	  _originPos = getMarkerPos _origin;

	  _countUnits = [_units, false] call A3A_fnc_countGarrison;

	  _vehicleCount = _vehicleCount + (_countUnits select 0);
	  _cargoCount = _cargoCount + (_countUnits select 1) + (_countUnits select 2);

	  //For debug is direct placement
	  //diag_log format ["Reinforce %1 from %2", _target, _selectedBase];
	  //[_units, "Reinf units"] call A3A_fnc_logArray;
	  //[_target, _units] call A3A_fnc_addGarrison;
	};
  }
  else
  {
	diag_log format ["CreateAIAction[%1]: Reinforcement aborted as no base is available!", _convoyID];
	_abort = true;
  };
};
if(_type == "attack") then
{

};
if(_type == "convoy") then
{
  //Heavy will call in more and better vehicles
  _isHeavy = if (random 10 < tierWar) then {true} else {false};
  //Easy will call in only FIA (police) vehicles (We really have to rename this)
  _isEasy = if (!(_isHeavy) && {_side == Occupants && {random 10 >= tierWar}}) then {true} else {false};
  _sideCheck = sidesX getVariable [_destination, sideUnknown];
  if(_sideCheck == _side) then
  {
	_origin = [_destination] call A3A_fnc_findBasesForConvoy;
	_originPos = getMarkerPos _origin;
	if(!_abort && !(_origin isEqualTo "")) then
	{
	  _typeConvoy = [];
	  if ((_destination in airportsX) or (_destination in outposts)) then
	  {
		_typeConvoy = ["Ammunition","Armor"];
		/* Reinforcement convoys will be standard not a special mission
		if (_destination in outposts) then
		{
		  //That doesn't make sense, or am I wrong? Can someone double check this logic?
		  if (((count (garrison getVariable [_destination, []]))/2) >= [_destinationX] call A3A_fnc_garrisonSize) then
		  {
			_typeConvoy pushBack "Reinforcements";
		  };
		};
		*/
	  }
	  else
	  {
		if (_destination in citiesX) then
		{
		  _typeConvoy = ["Supplies"];
		}
		else
		{
			if ((_destinationX in resourcesX) or (_destinationX in factories)) then
		  {
			_typeConvoy = ["Money"];
		  }
		  else
		  {
			_typeConvoy = ["Prisoners"];
		  };
		  //Same here, not sure about it
			if (((count (garrison getVariable [_destinationX, []]))/2) >= [_destinationX] call A3A_fnc_garrisonSize) then
		  {
			_typeConvoy pushBack "Reinforcements"
		  };
		};
		};
	  _selectedType = selectRandom _typeConvoy;

	  private ["_timeLimit", "_dateLimitNum", "_displayTime", "_nameDest", "_nameOrigin" ,"_timeToFinish", "_dateFinal"];
	  //The time the convoy will wait before starting
	  _timeLimit = if (_isHeavy) then {0} else {round random 10};// timeX for the convoy to come out, we should put a random round 15

	  _timeToFinish = 120;
	  _dateTemp = date;
	  _dateFinal = [_dateTemp select 0, _dateTemp select 1, _dateTemp select 2, _dateTemp select 3, (_dateTemp select 4) + _timeToFinish];
	  _dateLimit = [_dateTemp select 0, _dateTemp select 1, _dateTemp select 2, _dateTemp select 3, (_dateTemp select 4) + _timeLimit];
	  _dateLimitNum = dateToNumber _dateLimit;
	  _dateLimit = numberToDate [_dateTemp select 0, _dateLimitNum];//converts datenumber back to date array so that time formats correctly when put through the function
	  _displayTime = [_dateLimit] call A3A_fnc_dateToTimeString;//Converts the time portion of the date array to a string for clarity in hints

	  _nameDest = [_destination] call A3A_fnc_localizar;
	  _nameOrigin = [_origin] call A3A_fnc_localizar;
	  [_origin, 30] call A3A_fnc_addTimeForIdle;

	  private ["_text", "_taskState", "_taskTitle", "_taskIcon", "_taskState1", "_typeVehEsc", "_typeVehObj", "_typeVehLead"];

	  _text = "";
	  _taskState = "CREATED";
	  _taskTitle = "";
	  _taskIcon = "";
	  _taskState1 = "CREATED";

	  _typeVehLead = "";
	  _typeVehEsc = "";
	  _typeVehObj = "";

	  switch (_selectedType) do
	  {
		case "Ammunition":
		{
			_text = format ["A convoy from %1 is about to depart at %2. It will provide ammunition to %3. Try to intercept it. Steal or destroy that truck before it reaches it's destination.",_nameOrigin,_displayTime,_nameDest];
			_taskTitle = "Ammo Convoy";
			_taskIcon = "rearm";
			_typeVehObj = if (_side == Occupants) then {vehNATOAmmoTruck} else {vehCSATAmmoTruck};
		};
		case "Armor":
		{
			_text = format ["A convoy from %1 is about to depart at %2. It will reinforce %3 with armored vehicles. Try to intercept it. Steal or destroy that thing before it reaches it's destination.",_nameOrigin,_displayTime,_nameDest];
			_taskTitle = "Armored Convoy";
			_taskIcon = "Destroy";
			_typeVehObj = if (_side == Occupants) then {vehNATOAA} else {vehCSATAA};
		};
		case "Prisoners":
		{
			_text = format ["A group os POW's is being transported from %1 to %3, and it's about to depart at %2. Try to intercept it. Kill or capture the truck driver to make them join you and bring them to HQ. Alive if possible.",_nameOrigin,_displayTime,_nameDest];
			_taskTitle = "Prisoner Convoy";
			_taskIcon = "run";
			_typeVehObj = if (_side == Occupants) then {selectRandom vehNATOTrucks} else {selectRandom vehCSATTrucks};
		};
		case "Reinforcements":
		{
			_text = format ["Reinforcements are being sent from %1 to %3 in a convoy, and it's about to depart at %2. Try to intercept and kill all the troops and vehicle objective.",_nameOrigin,_displayTime,_nameDest];
			_taskTitle = "Reinforcements Convoy";
			_taskIcon = "run";
			_typeVehObj = if (_side == Occupants) then {selectRandom vehNATOTrucks} else {selectRandom vehCSATTrucks};
		};
		case "Money":
		{
			_text = format ["A truck plenty of money is being moved from %1 to %3, and it's about to depart at %2. Steal that truck and bring it to HQ. Those funds will be very welcome.",_nameOrigin,_displayTime,_nameDest];
			_taskTitle = "Money Convoy";
			_taskIcon = "move";
			_typeVehObj = "C_Van_01_box_F";
		};
		case "Supplies":
		{
			_text = format ["A truck with medical supplies destination %3 it's about to depart at %2 from %1. Steal that truck bring it to %3 and let people in there know it is %4 who's giving those supplies.",_nameOrigin,_displayTime,_nameDest,nameTeamPlayer];
			_taskTitle = "Supply Convoy";
			_taskIcon = "heal";
			_typeVehObj = "C_Van_01_box_F";
		};
		default
		{
		  diag_log format ["CreateAIAction[%1]: Aborting convoy, selected type not found, type was %2", _convoyID, _selectedType];
		  _abort = true;
		};
	  };
	  if(!_abort) then
	  {
		//Deactivated, cause you can't win this mission currently
		[[teamPlayer,civilian],"CONVOY",[_text,_taskTitle,_destination], _destinationPos,false,0,true,_taskIcon,true] call BIS_fnc_taskCreate;
		[[_side],"CONVOY1",[format ["A convoy from %1 to %3, it's about to depart at %2. Protect it from any possible attack.",_nameOrigin,_displayTime,_nameDest],"Protect Convoy",_destination],_destinationPos,false,0,true,"run",true] call BIS_fnc_taskCreate;
		missionsX pushBack ["CONVOY","CREATED"]; publicVariable "missionsX";

		sleep (_timeLimit * 60);
		_crewUnits = if(_side == Occupants) then {NATOCrew} else {CSATCrew};

		//Creating convoy lead vehicle
		_typeVehLead = if (_side == Occupants) then {if (!_isEasy) then {selectRandom vehNATOLightArmed} else {vehPoliceCar}} else {selectRandom vehCSATLightArmed};
		_crew = [_typeVehLead, _crewUnits] call A3A_fnc_getVehicleCrew;
		_units pushBack [_typeVehLead, _crew, []];
		_vehicleCount = _vehicleCount + 1;
		_cargoCount = _cargoCount + (count _crew);
		//Convoy lead created

		//Prepared vehicle pool
		private _count = 1;
		if (_isHeavy) then
		{
		  _count = 3;
		}
		else
		{
		  if ([_destination] call A3A_fnc_isFrontline) then
		  {
			_count = (round random 2) + 1;
		  };
		};

		_vehPool = if (_side == Occupants) then
		{
		  if (!_isEasy) then
		  {
			vehNATOAttack
		  }
		  else
		  {
			[vehFIAArmedCar,vehFIATruck,vehFIACar]
		  };
		}
		else
		{
		  vehCSATAttack;
		};

		//Delete MBT from array if aggro is not high enough
		if (!_isEasy) then
		{
			_rnd = random 100;
			if (_side == Occupants) then
			{
				if (_rnd > aggressionOccupants) then
				{
					_vehPool = _vehPool - [vehNATOTank];
				};
			}
			else
			{
				if (_rnd > aggressionInvaders) then
				{
					_vehPool = _vehPool - [vehCSATTank];
				};
			};
			if (count _vehPool == 0) then {if (_side == Occupants) then {_vehPool = vehNATOTrucks} else {_vehPool = vehCSATTrucks}};
		};
		//Vehicle pool prepared

		//Select escort vehicles and their groups
		for "_i" from 1 to _count do
		{
		  _veh = [_vehPool, _side] call A3A_fnc_selectAndCreateVehicle;
		  _vehPool = _veh select 1;
		  _units pushBack (_veh select 0);
		  _vehicleCount = _vehicleCount + 1;
		  _cargoCount = _cargoCount + count ((_veh select 0) select 1) + count ((_veh select 0) select 2);
		};
		//Escorts and groups added

		//Add objective vehicle and cargo
		_typeGroup = [];
		if(_selectedType == "Reinforcements") then
		{
		  _typeGroup = [_typeVehObj,_side] call A3A_fnc_cargoSeats;
		};
		if(_selectedType == "Prisoners") then
		{
		  for "_i" from 1 to (1 + round (random 11)) do
		  {
			_typeGroup pushBack SDKUnarmed;
		  };
		};
		_crew = [_typeVehObj, _crewUnits] call A3A_fnc_getVehicleCrew;
		_units pushBack [_typeVehObj, _crew, _typeGroup];
		_vehicleCount = _vehicleCount + 1;
		_cargoCount = _cargoCount + (count _typeGroup) + (count _crew);
		//Objective and its cargo added

		//Last escort vehicle
		_veh = [_vehPool, _side] call A3A_fnc_selectAndCreateVehicle;
		_vehPool = _veh select 1;
		_units pushBack (_veh select 0);
		_vehicleCount = _vehicleCount + 1;
		_cargoCount = _cargoCount + count ((_veh select 0) select 1) + count ((_veh select 0) select 2);
		//Last escrot vehicle added
	  };
	}
	else
	{
	  diag_log format ["CreateAIAction[%1]: Aborting convoy, as no base is available to send a convoy", _convoyID];
	  _abort = true;
	};
  }
  else
  {
	diag_log format ["CreateAIAction[%1]: Side of convoy does not match side of destination, aborting!", _convoyID];
	_abort = true;
  };
};

if(_abort) exitWith
{
  server setVariable [format ["Con%1", _convoyID], nil, true];
  false
};

_target = if(_destination isEqualType "") then {_destination} else {str _destination};
diag_log format ["CreateAIAction[%1]: Created AI action to %2 from %3 to %4 with %5 vehicles and %6 units", _convoyID, _type, _origin, _targetString, _vehicleCount , _cargoCount];

[_convoyID, _units, _originPos, _destinationPos, [_origin, if(_isMarker) then {_destination} else {""}], _type, _side] spawn A3A_fnc_createConvoy;
true;
