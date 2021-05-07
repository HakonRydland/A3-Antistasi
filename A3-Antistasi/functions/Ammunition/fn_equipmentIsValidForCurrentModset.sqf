params ["_configClass", "_categories"];

private _itemMod = (_configClass call A3A_fnc_getModOfConfigClass);
private _itemIsVanilla = [_itemMod] call A3A_fnc_isModNameVanilla;

//Mod is disabled, remove item.
if (_itemMod in disabledMods) exitWith { true };

//We remove anything without a picture, because it's a surprisingly good indicator if whether something
//is actually a valid item or not.
//Despite all the filtering, we still get a few RHS guns, etc that are for APCs, but are still classed the item type as normal weapons.
//This is a pretty hard filter that removes anything that shouldn't be in there - I'm hoping it isn't prone to false positives!
if (getText (_configClass >> "picture") == "") exitWith { true };

//Remove vanilla items if no vanilla sides (IFA handled seperately)
if (_itemIsVanilla && {A3A_hasRHS}) exitWith {
	switch (_categories select 0) do {
		case "Item": {
			switch (_categories select 1) do {
				case "AccessoryMuzzle";
				case "AccessoryPointer";
				case "AccessorySights";
				case "AccessoryBipod";
				case "NVGoggles": { true };
			};
		};
		case "Weapon": { true };
		case "Equipment": {
			switch (_categories select 1) do {
				case "Headgear": {
					if (getNumber (_configClass >> "ItemInfo" >> "HitpointsProtectionInfo" >> "Head" >> "armor") > 0) then { true };
				};
				case "Vest": {
					if (getNumber (_configClass >> "ItemInfo" >> "HitpointsProtectionInfo" >> "Chest" >> "armor") > 5) then { true };
				};
			};
		};
	};
};

//IFA is stricter, remove all modern day stuff unless necessary (some ACE items)
//Avoid listing all of the mods here.

//we should find a Solution that is not bound to Foldernames
private _acemods = ["@ace", "@ACE - No medical [Updated]", "@Automated Ace No Medical", "@ACENomedical"];

private _TFARmods = ["@task_force_radio", "@taskforceradio", "@Task Force Arrowhead Radio (BETA!!!)", "@TaskForceArrowheadRadioBETA"];

if (A3A_hasIFA && {(_itemIsVanilla || _itemMod in _acemods || _itemMod in _TFARmods)}) exitWith {
	switch (_categories select 0) do {
		case "Item": {
			switch (_categories select 1) do {
				case "AccessoryMuzzle";
				case "AccessoryPointer";
				case "AccessorySights";
				case "AccessoryBipod";
				case "Binocular";
				case "Compass";
				case "GPS";
				case "LaserDesignator";
				case "MineDetector";
				case "NVGoggles";
				case "Radio";
				case "UAVTerminal";
				case "Unknown";
				case "Watch": { true };
			};
		};
		case "Weapon";
		case "Equipment";
		case "Magazine";
		case "Mine": { true };
	};

};
if (A3A_hasVN && {(_itemIsVanilla || _itemMod in _acemods || _itemMod in _TFARmods)}) exitWith {
	switch (_categories select 0) do {
		case "Item": {
			switch (_categories select 1) do {
				case "AccessoryMuzzle";
				case "AccessoryPointer";
				case "AccessorySights";
				case "AccessoryBipod";
				case "Binocular";
				case "Compass";
				case "GPS";
				case "LaserDesignator";
				case "MineDetector";
				case "NVGoggles";
				case "Radio";
				case "UAVTerminal";
				case "Compasses";
				case "Unknown";
				case "Watch": { true };
			};
		};
		case "Weapon";
		case "Equipment";
		case "Magazine";
		case "Mine": { true };
	};
};

//no other CDLC content when using VN
//if (A3A_hasVN && {_itemMod isNotEqualTo "VN"} && {_itemMod in (allCDLC apply {_x#1})}) exitWith {true}; //for some reason remove all items, wtf!!!
false
