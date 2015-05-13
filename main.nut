/* -*- Mode: C++; tab-width: 4 -*- */
/**
 *  This file is part of the AI library cEngineLib
 *  Copyright (C) 2013  krinn@chez.com
 *
 *  cEngineLib is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or any later version.
 *
 *  cEngineLib is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this AI Library. If not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
**/

/** @class cEngineLib
 *  @brief A library with helpers for engine and vehicle handling.
 */
class  cEngineLib extends AIEngine
{
	static	VT_RAIL = AIVehicle.VT_RAIL;
	static	VT_ROAD = AIVehicle.VT_ROAD;
	static	VT_WATER = AIVehicle.VT_WATER;
	static	VT_AIR = AIVehicle.VT_AIR;
	static	VT_RAIL_LOCO = AIVehicle.VT_AIR + 1;
	static	VT_RAIL_WAGON = AIVehicle.VT_AIR + 2;


	static	_cel_ebase = {};									/** our base where engines are store */
	static	_cel_blacklist = AIList();							/** the blacklist engine */
	static	_cel_RT = AIList();									/**< item = the railtype, value = maximum speed doable */
	static	_cel_config = [false,"", null];						/**< hold configuration options and error message, you have functions to alter that. */
	static	_cel_cache = [null, null, null, null, null, null];	/**< we cache enginelist result here */

	engine_id		= null;	/**< id of the engine */
	cargo_capacity	= null;	/**< capacity per cargo item=cargoID, value=capacity when refit */
	cargo_length	= null;	/**< that's the length of a vehicle depending on its current cargo setting */
	cargo_pull		= null; /**< only for locos, cargobits it is able to pull. */
	is_known		= null;	/**< 0: never seen that engine, 1: basic tests made 2: loco tests made */
	usuability		= null;	/**< compatibility list of wagons & locos, item=the other engineID value=cargobits 1 compatible, 0 incompatible with that cargo */


	constructor()
		{
		engine_id		= null;
		cargo_capacity	= AIList();
		cargo_length	= AIList();
		cargo_pull		= 0;
		is_known		= 0;
		usuability		= AIList();
		}

	  // ********************** //
	 // PUBLIC FUNCTIONS - API //
	// ********************** //

	/**
	 * That function will let the library learn engines by creating vehicles and testing them (and sell them), so this function use @VehicleWagonCompatibilityTest
     * Because this function use money @SetMoneyCallBack, you may prefer handle the learning yourself using @VehicleUpdateEngineProperties... But this function really automates everything for you.
     * The learning is done at the given depot and it will create all engines it could with the money you have (and sell them fast to get your money back), keep in mind, that a rail depot is limited by its railtype, so you can't build (and learn) a maglev engine in a non maglev depot (look at engine == -2 for that). Because this function do all the job, the accuracy of all other functions of the lib will goes upto 100%
     * Unlike VehicleUpdateEngineProperties, this function also check compatibility of locos and wagons, making "bypass" usage 100% accurate.
	 * @param depotID a valid depot of any type (an airport is a depot)
	 * @param engineID	if a valid engineID it will test that engine only (but also other known engines for new wagons), giving 100% accuracy result for this engine.
	 *					if -1 it will test all engines from that depot. This increase accuracy to 100% on all engines of that depot type ; except VT_RAIL that need more.
	 */
	function LearnEngineFromDepot(depotID, engineID);

	/**
	 * That function will let the library learn engines from existing vehicles
     * This function use an existing vehicle to discover properties of engines in it. It is similar and actually do exactly the same as @VehicleUpdateEngineProperties on all vehicles type except rails as this function will also fill the compatibility of engine while the other cannot. So it use what was previously create to learn from it. If it find a depot it will called @LearnEngineFromDepot with the engineID taken from that vehicle.
     * Because it could be use with more than one vehicle, but also more than one vehicle type, it can learn from all vehicles in one go. Making it a good helper when your AI is loading a game and the lib can learn from what was create previously.
	 * @param vehicleID if it's a valid vehicleID it will learn only from that vehicle
	 * @param all_type if vehicleID is invalid only, all vehicles from the AIVehicle.VehicleType type will be check. With AIVehicle.VT_INVALID all vehicles of any type.
	 */
	function LearnEngineFromVehicle(vehicleID, all_type);

	/**
	 * That's the library key function, this update properties of engine by looking at the vehicle. This get enough information to get 100% accuracy (but only for this engine) on any vehicle type except rail, that need another step see @VehicleWagonCompatibilityTest
     * This function should be called after a vehicle creation, so the base is filled with its values,
	 * @param veh_id a valid vehicle_id that we will inspect to get informations about its engine
	 */
	function VehicleUpdateEngineProperties(veh_id);

	/**
	 * This function returns the best engine to use (or couple engine loco+wagon) using the filter you wish. If you don't provide a filter it will use its own internal one, that is basic, but functional and should gives not bad result.
	 * The accuracy of the result depend on the limits you put yourself in the query, but also if the vehicle has been create and test by the lib.
	 * If you gives it a real depot, it will run @LearnEngineFromDepot (limit to the engine it think is the best) and loop to find if it's still the best one once it get test, so even it limit @LearnEngineFromDepot to one engine only, it can feed it one by one until it get a stable result.
	 * As this function may use your money, make sure the AI have enough money to buy stuff. See @SetMoneyCallBack
	 * @param object
	 * Here's the different options :
	 * - object.depot : if valid, this put a restriction to rail/road type. It will test the result prior to returning it (and use your money so). If depot is invalid or -1 get theorical results only ; accuracy depend on what engines the lib has learned.
	 * - object.engine_id : Not use except for VT_RAIL query.
	 *			- if it's a wagon engine: restrict to find a locomotive that can pull this wagon.
	 *          - if it's a locomotive: restrict to find a wagon that could be use with that locomotive.
	 *          - if set to -1: allow finding best locomotive & wagon couple.
	 * - object.engine_type : if depot == -1 this must be set as the AIVehicle.VehicleType of vehicle you want the query to be done.
	 * - object.bypass : only use with VT_RAIL. true or false. Set it true to bypass ai_special_flag (see @CanPullCargo).
	 * - object.cargo_id : This could restrict the search for this cargo, -1 to not use cargo restriction
	 * - object.engine_roadtype : This add a special restriction to the search, -1 to add none
	 *			- for VT_ROAD: it could of AIRoad.ROADTYPE_ROAD or AIRoad.ROADTYPE_TRAM
	 *			- for VT_RAIL: it is a railtrack restriction. It is not use when object.depot is valid, as it will be the one of the depot use.
	 *			- for VT_AIR: it could be AIAirport.PT_HELICOPTER, AIAirport.PT_BIG_PLANE or AIAirport.PT_SMALL_PLANE to restrict search on this kind of plane only.
	 *          - for VT_WATER: it's not use.
	 * @param filter A function that will be called to apply your own filter and heuristic on the engine list. If null a private function will be used.
	 *               The function must be : function myfilter(AIList, object)
     *               For VT_RAIL the filter will be called with two different list, 1 for locomotive, and 2nd for the wagons. So be sure to check if AIEngine.IsWagon(object.engine_id) or any engine in the list you get, to see if your filter is working on a loco or a wagon.
	 * @return An array with the best engines : [0]= -1 not found, [0]=engine_id water/air/road, rail : [0]=loco_id [1]=wagon_id [2] railtype
	 */
	function GetBestEngine(object, filter);

	/**
	 * Change an ailist to filter out engine (so watchout what ailist you gives, its content will be change)
     * Default filters are : remove blacklist engine, remove unbuildable, remove incompatible engine, other filters are optionals.
	 * @param engine_list an ailist of engine id
	 * @param cargo_id if -1 don't filter, if set, filter engines that cannot be refit to use that cargo (or pull other engines using that cargo)
	 * @param road_type : if -1 don't filter, if set, filter engines that are limit (by the roadtype, railtrack type or airport type), see @GetBestEngine object.engine_roadtype for posssible values.
	 * @param engine_id : if -1 don't filter, if it's a wagon filter out locos that cannot pull it, if it's a loco filter out wagons that loco cannot pull
	 * @param bypass : alter the cargo & train filter decision : see @CanPullCargo bypass value for more
	 */
	function EngineFilter(engine_list, cargo_id, road_type, engine_id, bypass);

	/**
	 * Create the vehicle at depot, upto you to add orders... It will also refit the vehicle to the given cargo.
	 * As this function use your money, make sure the AI have enough money to buy stuff. See @SetMoneyCallBack
	 * This function use @LearnEngineFromDepot limit to the vehicle you are creating, so it allow the lib to learn from each creation you do.
	 * @param depot a depot to use to create the vehicle
	 * @param engine_id the engine to create the vehicle
	 * @param cargo_id if set to -1 you get just the vehicle, otherwise the engine will be refit to handle the cargo (if possible)
	 * @return vehileID of the new vehicle or -1 on error. No error if you ask to refit a vehicle that cannot be refit to that cargo ; but if the vehicle could be refit and it cannot do it, it will return -1 and sell it.
	 */
	function VehicleCreate(depot, engine_id, cargo_id = -1);

	/**
	 * Get the length of an engine when refit to handle cargo_id type. Accuracy depend on @VehicleUpdateEngineProperties
	 * @param engine_id the engine id to query
	 * @param cargo_id the length of the engine when refit to that cargo, if -1 the length of the engine with its default cargo
	 * @return length of engine or 0 on error (note that VT_AIR will always be 0 length)
	 */
	function GetLength(engine_id, cargo_id = -1);

	/**
	 * Get the capacity of an engine for that cargo type. Accuracy depend on @VehicleUpdateEngineProperties
	 * @param engine_id The engine to get the capacity of
	 * @param cargo_id If -1, it's the current refit cargo, else the cargo id to get the capacity for.
	 * @return the capacity, 0 if the cargo is not support or on error
	 */
	function GetCapacity(engine_id, cargo_id = -1);

	/**
	 * Get the total weight of a vehicle : only for rail vehicle. The function takes freight_trains setting and if the cargo is freight to calc the weight. See: http://wiki.openttd.org/Freight_trains
	 * @param vehicle_id The vehicle id of the vehicle to calc its total weight
	 * @param vehicle_id An array with [loco engine, number of locos, wagon engine, number of wagons], so you could get what a non existing vehicle weight will be after creation. Set "number" to 0 to not pass a loco or wagon engine but array must be of size 4.
	 * @param empty true to get the total weight when empty, false to get the total weight when full (and this include filling loco with cargo if loco handle some)
	 * @return the total of loco + all wagons weight of the vehicle, -1 on error
	 */
	function VehicleGetWeight(vehicle_id, empty = true);

	/**
	 * Get the total max tractive effort a vehicle handle (summing all engines values), only for rail and road vehicle
	 * @param vehicle_id The vehicle id of a rail or road vehicle
	 * @return the total tractive effort in KN, -1 on error, 0 if not a road or rail vehicle
	 */
	function VehicleGetMaxTractiveEffort(vehicle_id);

	/**
	 * Get the total power of a vehicle (summing all engines values), only for rail and road vehicle
	 * @param vehicle_id The vehicle id
	 * @param KW Per default the function return power in HP (like the AI API), if set to true, you will get the power in KW and the return value will be a float number.
	 * @return the total power of the vehicle in HP or KW, -1 on error, 0 if not a road or rail vehicle
	 */
	function VehicleGetMaxPower(vehicle_id, KW = false);

	/**
	 * Get the railtype the vehicle is running on (if you run a vehicle on different railtype, the answer will depend on which ones it was running when checked)
	 * @param vehicle_id The vehicle id to get the RailType in use
	 * @return the RailType in use, AIRail.RAILTYPE_INVALID on error
	 */
	function VehicleGetRailTypeUse(vehicle_id);

	/**
	 * Return the maximum speed the vehicle can do with its engine, railtype and wagons in use. However it doesn't check if the engine has enough power to actually reach that limit. It takes the setting "wagon_speed_limits" (see http://wiki.openttd.org/Wagon_speed_limits) and the railtype limit.
	 * @param vehicle_id The vehicle id to get its maximum speed. If the vehicle is not of AIVehicle.VT_RAIL it return the result of AIEngine.GetMaxSpeed
	 * @return The maximum speed reachable by this vehicle. -1 on error.
	 */
	function VehicleGetMaxSpeed(vehicle_id);

	/**
	 * Check if an engine is a locomotive
	 * @param engine_id the engine to check
	 * @return True if it's a locomotive, false if not or invalid...
	 */
	function IsLocomotive(engine_id);

	/**
	 * Check if a train use multi locomotive or is multihead if the API support the function
	 * @param vehicle_id the vehicle to check
	 * @return True if it have more than 1 locomotive or 1 multihead, false for any others reason...
	 */
	function VehicleIsMultiEngine(vehicle_id);

	/**
	 * Get the number of locomotive a vehicle have: note that two heads engine will be count as two locomotives!
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return 0 if no locomotive/not a train, or the number of locomotive in the vehicle
	 */
	function VehicleGetNumberOfLocomotive(vehicle_id);

	/**
	 * Look at the given vehicle, get its first loco engine and return true if you lack enough power (for original acceleration model) or tractive effort (for realistic model) to run that vehicle at low speed on hills (at ~15% of its maxspeed)
	 * It handle the game setting "train_slope_steepness" (http://wiki.openttd.org/Train_slope_steepness)
	 * It handle the "train_accelaration_model", increase x2 the aim speed when original model is use. (http://wiki.openttd.org/Realistic_acceleration)
	 * Even its accuracy isn't that bad, don't take its "true" answer as-is but keep some limit, To simplify the example, if you need 1000hp to pull 5 wagons and use a loco with 100hp, it would then return true until you use 10 locos, not really something usable.
	 * @param vehicle_id The vehicle id of a rail vehicle
	 * @param aim_speed The calc are base on a train ability to aim a certain mimimum speed when climbing with its load, per default (0) the aim_speed will be 15% of maximum speed of the train engine (and a non-alterable minimum of 15spd). You can pass your own custom aim_speed to use.
	 * @return true if you should add more engine to that vehicle, -1 on error
	 */
	function VehicleLackPower(vehicle_id, aim_speed = 0);

	/**
	 * Get the number of wagons a vehicle have (excluding loco engine)
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return 0 if not a train or without wagon, or the number of wagons in the vehicle
	 */
	function VehicleGetNumberOfWagons(vehicle_id);

	/**
	 * Get the position of a random wagon in the train
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return -1 if not a train or no wagon. A place (position) with a wagon in that train
	 */
	function VehicleGetRandomWagon(vehicle_id);

	/**
	 * Mark engine_one and engine_two not compatible with each other
	 * This could only be use with trains. Use in @VehicleWagonCompatibilityTest
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */
	function IncompatibleEngine(engine_one, engine_two);

	/**
	 * Mark engine_one and engine_two compatible with each other
	 * This could only be use with trains. Use in @VehicleWagonCompatibilityTest
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */
	function CompatibleEngine(engine_one, engine_two);

	/**
	 * Check if engine1 is usable with engine2. For trains/wagons only. It is inside the default filter for trains, but your custom filter better use it too.
	 * @param engine engine id of the first engine
	 * @param compare_engine engine id of the second engine
	 * @return true if you can use them, if we never check their compatibilities, it will return true
	 */
	function AreEngineCompatible(engine, compare_engine);

	/**
	 * Test compatibilty of a wagon engine with the vehicle. For rails vehicle only. This autofill compatibilty state of both engines.
	 * @param vehicleID a valid vehicle, stopped in a depot, with a locomotive in it
	 * @param wagonID  the engine wagon type to test.
	 * @return true if you can, but false doesn't mean you cannot! Use AreEngineCompatible to get the answer.
	 */
	function VehicleWagonCompatibilityTest(vehicleID, wagonID);

	/**
	 * Check if the engine can pull a wagon with the given cargo. Exactly the same as AIEngine.CanPullCargo if the bypass is set to false
	 * The ai_special_flag (nfo property 08) for newGRF is set if an engine can pull a cargo or not. But the newGRF can also allow/disallow what couple cargo/engine you are allowed to use.
     * So, if the newGRF didn't disallow cargo/engine couple, but have its ai_special_flag set to disallow that, we could ignore it and pull the cargo we wish (as long as some compatible wagons exist to carry it). That's what the bypass param is for.
     * The trick to get the answer: if the loco can use wagonX and wagonX can be refit to potatoes, then loco is able to pull potatoes...
     * In order to know if wagonX can be use with that loco you need to test that with @VehicleWagonCompatibilityTest
     * So until the loco has been test, the result is the one from AIEngine.CanPullCargo.
	 * @param engine_id The engine to check
	 * @param cargo_id The cargo to check
	 * @param bypass Set to false to respect newGRF author wishes, set it to true to allow bypassing the ai_special_flag
	 * @return true if it can pull the cargo, false if it cannot.
	 */
	function CanPullCargo(engine_id, cargo_id, bypass = false);

	/**
	 * Return if that engine is blacklist or not. The lib itself doesn't need to blacklist any engines (yet).
	 * @param engine_id The engine to get check
	 * @return True if engine is blacklist, false if not
	 */
	function IsEngineBlacklist(engine_id);

	/**
	 * Add an engine to the blacklist
	 * @param engine_id The engine to get blacklist
	 */
	function BlacklistEngine(engine_id);

	/**
	 * Check if the tile is a depot
	 * @param tile a valid tile
	 * @return true if tile is a valid depot of any type, false if not or on error.
	 */
	function IsDepotTile(tile)	{ return (cEngineLib.GetDepotType(tile) != -1); }

	/**
	 * Get the type of depot found at tile
	 * @param tile a valid tile, should be a tile with a depot
	 * @return the type of depot found at tile (AIVehicle.VT_RAIL...) or -1 on error
	 */
	function GetDepotType(tile);

	/**
	 * Answer if the current order (even not in its list) is going to depot and if it will stop there. Servicing at depot is not stopping at it.
	 * @param vehicle_id the vehicle to check
	 * @return true only if the vehicle is going to stop at a depot, false if it does not or on error.
	 */
	function VehicleIsGoingToStopInDepot(vehicle_id);

	/**
	 * Skip the current order in vehicle, it doesn't check any conditionnal orders and just jump to next order in position. If order was last, it jump to order 0
	 * @param vehicle_id the vehicle to skip current order
	 * @return the new order position, -1 on error (mostly, a vehicle with empty order, but anything: destination too far...).
	 */
	function VehicleOrderSkipCurrent(vehicle_id);

	/**
	 * Unshare and clear the order list of a vehicle
	 * @param vehicle_id the vehicle to work on
	 * @return true if order list is clear, false on error
	 */
	function VehicleOrderClear(vehicle_id);

	/**
	 * This will browse railtype and return the railtype that can reach the fastest speed or the fastest railtype a given engine could use
	 * @param engineID the engineID to get its best railtype to use with it, if -1 get the current fastest railtype
	 * @return -1 if no railtype is found
	 */
	function RailTypeGetFastestType(engineID = -1);

	/**
	 * This will browse railtype and return the railtype that can reach the fastest speed to pull a cargo
	 * Even if you can easy get the fastest railtype, it is harder to actually find one that is usable with a cargo. If you have no train able to pull it, or no wagon able to be refit to it with that railtype, the fastest railtype is finally not usable to handle this cargo.
	 * So the return answer from this function is really the fastest railtrack type with a loco and wagon that exists and that you could use with that cargo, and not simply the fastest railtrack type. It's accuracy depend on @CanPullCargo ; so range from 0% when bypass is enable and no loco has been test, to 100% if tests were made. And without enabling bypass, its accuracy depend on AIEngine.CanPullCargo that is 0% as it will never answer if the loco have a real wagon that could be refit to pull that cargo.
	 * @param cargoID the cargoID to get the railtype with a train able to pull that cargo and a compatible wagon with that loco, refitable to handle that cargo.
	 * @param bypass enable/disable it, see @CanPullCargo
	 * @return -1 if no railtype is found (it mean no train can pull that cargo or no wagon can be refit for it, or just because no railtype are there)
	 */
	function RailTypeGetFastestTypeForCargo(cargoID, bypass = false);

	/**
	 * Return the speed of the given railtype, so to get the speed of the current fastest railtype, cEngineLib.RailTypeGetSpeed(cEngineLib.RailTypeGetFastestType());
	 * @param RT The RailType to get the speed, if -1 we will return the fastest one.
	 * @return -1 if no railtype is found
	 */
	function RailTypeGetSpeed(RT = -1);

	/**
	 * This restrict a train length to met max_length, selling wagons only to met it (so a train, stopped, in a depot), the vehicle size may still not met the length if it is bigger because of its loco(s) length in it.
	 * @param vehicle_id A train with wagons you want to limit its length
	 * @param max_length The length to match : don't forget to x16 it if you aim a tile length: ie: limit to 3 tiles, max_length = 3*16
	 * @return -1 on error, else return the number of wagons removed (that could be 0)
	 */
	function VehicleRestrictLength(vehicle_id, max_length);

	/**
	 * Get the number of wagons we could add to stay below max_length. This will return inacurate results or error if the wagon or loco was never built.
	 * @param engines an array with [0] the loco engine, and [1] the wagon engine. Accept also the array return by GetBestEngine function
	 * @param max_length The length to match : don't forget to x16 it if you aim a tile length: ie: limit to 3 tiles, max_length = 3*16
	 * @param cargo_id the cargo the wagon will use (-1 for default wagon size, because wagon size can change depending on the cargo use).
	 * @return -1 on error, else return the maximum number of wagons usable within that length limit
	 */
	function GetMaxWagons(engines, max_length, cargo_id = -1);

	/**
	 * Enable or disable errors message. Those are only errors at using the API, not errors report by the NOAI API
	 * @param output True and the API will output its errors messages. False to disable this. You can still get the last error with GetAPIError
	 */
	function SetAPIErrorHandling(output);

	/**
	 * Get the last error string the API report
	 * @return A string.
	 */
	function GetAPIError();

	/**
	 * Set the API to use your money callback function, a function run by the API when it need to get money
	 * The callback function will be called with "amount" as parameter,
	 * ie: cEngineLib.SetMoneyCallBack(myAI.MoneyGiver); with <function myAI::MoneyGiver(amount) { // grant the money }
	 * @param money_func A valid function from your AI that should raise your account to to the wanted "amount" of money
	 */
	function SetMoneyCallBack(money_func);

	/**
	 * This will browse engines so they are all added to the engine database, faster next access to any engine properties.
	 * If you want use this, it should be called early in your AI, else its usage will get poorer with time. It now also use @LearnFromVehicle
	 */
	function EngineCacheInit();

	/**
	 * This will dirty the cache of eng_type, forcing next access to the cache to sent fresh infos.
	 * The cache itself has a 7 openttd days lifetime ; but in case you wish a fresh list.
	 * The lib dirty the cache also when a new engine is found in a vehicle (and not because of the event)
	 * @param eng_type The engine type to dirty, it could be AIVehicle.VT_RAIL, AIVehicle.VT_ROAD, AIVehicle.VT_WATER or AIVehicle.VT_AIR
	 */
	function DirtyEngineCache(eng_type);

	/**
	 * Return a cache AIList of engines of the type "eng_type". Faster access to the very same list and lesser this effect http://bugs.openttd.org/task/6213 as you will work on a shorter list. Note that the lists are stock lists of engines EXCEPT blacklist engines that are remove from it (but it still include non buildable engine).
	 * @param eng_type It could of AIVehicle.VT_RAIL, AIVehicle.VT_ROAD, AIVehicle.VT_WATER or AIVehicle.VT_AIR. But you can also use the special cEngineLib.VT_RAIL_LOCO to get only loco engine, or cEngineLib.VT_RAIL_WAGON to get only wagon engine. This should replace occurances of AIEngineList() in your code. To ease handling AIVehicle.VT_ have their cEngineLib.VT_ equivalent.
	 * @return an AIList of engines of the eng_type type, on error you will get an empty AIList.
	 */
	function GetEngineList(eng_type);

	/**
	 * The lib will output to the console some stats about itself, that's of course a debug feature, but it might help you.
	 */
	function DumpLibStats();

}

	function cEngineLib::LearnEngineFromDepot(depotID, engineID)
	// That's the learning part: it create all vehicles it doesn't know and look at their engine properties
	{
		local depot_type = cEngineLib.GetDepotType(depotID);
		if (depot_type == -1)	return;
		if (engineID >= 0)
			{
			if (!AIEngine.IsValidEngine(engineID))	engineID = -1;
			if (AIEngine.IsWagon(engineID))	return; // we don't need to learn from wagon engine
			}
		cEngineLib.DirtyEngineCache(depot_type); // use fresh lists
		// do easy type first
		if (depot_type != cEngineLib.VT_RAIL)
			{
			local engine_list = cEngineLib.GetEngineList(depot_type);
			if (engineID >= 0)	{ engine_list = AIList(); engine_list.AddItem(engineID, 0); }
			engine_list.Valuate(cEngineLib.EngineIsKnown);
			engine_list.KeepValue(0); // keep ones we don't know yet
			engine_list.Valuate(AIEngine.IsBuildable);
			engine_list.KeepValue(1);
			if (depot_type == cEngineLib.VT_ROAD)
				{
				local r = AIRoad.ROADTYPE_ROAD;
				if (AIRoad.HasRoadType(depotID, AIRoad.ROADTYPE_TRAM))	r = AIRoad.ROADTYPE_TRAM;
				engine_list.Valuate(AIEngine.GetRoadType);
				engine_list.KeepValue(r);
				}
			if (engine_list.IsEmpty())	{ return; }
			foreach (engine_id, _ in engine_list)
				{
				local money = AIEngine.GetPrice(engine_id);
				cEngineLib.GetMoney(money);
				local vehicle = AIVehicle.BuildVehicle(depotID, engine_id);
				if (!AIVehicle.IsValidVehicle(vehicle))	continue; // may lack money for this one...
				cEngineLib.VehicleUpdateEngineProperties(vehicle);
				AIVehicle.SellVehicle(vehicle);
				}
			return;
			}
		// now the rail part
		if (!cEngineLib.GetMoney(AICompany.GetLoanInterval()))	return; // no test need if we have no money at all
		local depot_rt = AIRail.GetRailType(depotID);
		local loco_list = cEngineLib.GetEngineList(cEngineLib.VT_RAIL_LOCO);
		local wagon_list = cEngineLib.GetEngineList(cEngineLib.VT_RAIL_WAGON);
		// Keep tracking loco we knows + the one user ask (to find new wagons for the loco we knows already)
		if (engineID >= 0)	{ loco_list.Valuate(cEngineLib.EngineIsKnown); loco_list.KeepValue(1); loco_list.AddItem(engineID, 0); }
		loco_list.Valuate(AIEngine.IsBuildable);
		loco_list.KeepValue(1);
		wagon_list.Valuate(AIEngine.IsBuildable);
		wagon_list.KeepValue(1);
		local loco_test = AIList();
		local wagon_test = AIList();
		loco_test.AddList(loco_list);
		loco_test.Valuate(AIEngine.HasPowerOnRail, depot_rt);
		loco_test.KeepValue(1);
		// look for new locos
		foreach (n_loco, _ in loco_test)
			{
			local create_loco = false;
			local loc_obj = cEngineLib.Load(n_loco);
			if (loc_obj == null)	continue;
			wagon_test.AddList(wagon_list);
			wagon_test.Valuate(AIEngine.CanRunOnRail, depot_rt);
			wagon_test.KeepValue(1);
			if (loc_obj.is_known != 2)	create_loco = true;
								else	wagon_test.RemoveList(loc_obj.usuability);
			loc_obj = null;
			if (!wagon_test.IsEmpty())	create_loco = true;
			if (create_loco)
					{
					print("Learning & Testing "+AIEngine.GetName(n_loco)+" with wagons: "+wagon_test.Count());
					if (!cEngineLib.GetMoney(AIEngine.GetPrice(n_loco)))	continue;
					local vehicle_loco = AIVehicle.BuildVehicle(depotID, n_loco);
					if (!AIVehicle.IsValidVehicle(vehicle_loco))	continue;
					cEngineLib.VehicleUpdateEngineProperties(vehicle_loco);
					foreach (wagon_id, _ in wagon_test)	cEngineLib.VehicleWagonCompatibilityTest(vehicle_loco, wagon_id);
					AIVehicle.SellVehicle(vehicle_loco);
					}
			}
	}

	function cEngineLib::LearnEngineFromVehicle(vehicleID, all_type)
	{
		local v_type = all_type;
		local v_list = AIList();
		if (AIVehicle.IsValidVehicle(vehicleID))	{ v_list.AddItem(vehicleID, 0); v_type = AIVehicle.GetVehicleType(vehicleID); }
											else	v_list = AIVehicleList();
		v_list.Valuate(AIVehicle.GetVehicleType);
		if (v_type != AIVehicle.VT_INVALID)	v_list.KeepValue(v_type);
		foreach (veh, veh_type in v_list)
			{
			cEngineLib.VehicleUpdateEngineProperties(veh);
			if (veh_type == cEngineLib.VT_RAIL)
				{
				local wagon_engine = AIList();
				local loco_engine = AIList();
				for (local i = 0; i < AIVehicle.GetNumWagons(veh); i++)
						{ // scan it to find wagon and loco in it
						local engine_part = AIVehicle.GetWagonEngineType(veh, i);
						if (AIEngine.IsWagon(engine_part))	{ wagon_engine.AddItem(engine_part, 0); continue; }
													else	loco_engine.AddItem(engine_part, 0);
						}
				foreach (loco, _ in loco_engine)
						{
						if (AIVehicle.IsStoppedInDepot(veh)) // got lucky!
									cEngineLib.LearnEngineFromDepot(AIVehicle.GetLocation(veh), loco);
							else	{
									local e = cEngineLib.Load(loco);
									if (e == null)	continue;
									foreach (cart, _ in wagon_engine)
										{
										local c = cEngineLib.Load(cart);
										if (c == null)	continue;
										e.usuability.AddItem(cart, 1);
										e.cargo_pull = (e.cargo_pull | c.cargo_pull);
										}
									e.is_known = 2;
									}
						}
				}
			}
	}

	function cEngineLib::VehicleUpdateEngineProperties(veh_id)
	{
		if (!AIVehicle.IsValidVehicle(veh_id))	return;
		if (AIVehicle.GetState(veh_id) != AIVehicle.VS_IN_DEPOT)	return;
		local new_engine = AIVehicle.GetEngineType(veh_id);
		local engObj = cEngineLib.Load(new_engine);
		if (engObj == null || engObj.is_known != 0)	return;
		local vtype = AIVehicle.GetVehicleType(veh_id);
		if (vtype == AIVehicle.VT_RAIL && AIVehicle.GetNumWagons(veh_id) > 1) return;
		local crgList = AICargoList();
		foreach (cargoID, _ in crgList)
			{
			local testing = AIVehicle.GetRefitCapacity(veh_id, cargoID);
			if (testing < 0)	testing = 0;
			engObj.cargo_capacity.SetValue(cargoID, testing);
			if (testing > 0)
					{
					local test_mode = AITestMode();
					local refitted = AIVehicle.RefitVehicle(veh_id, cargoID);
					if (!refitted)	return; // we will retry later
					engObj.cargo_length.SetValue(cargoID, AIVehicle.GetLength(veh_id));
					test_mode = null;
					}
			}
		engObj.is_known = 1;
	}

	function cEngineLib::GetBestEngine(object, filter)
	{
		local isobject = object instanceof cEngineLib.Infos;
		local error = []; error.push(-1);
		if (!isobject)	{ cEngineLib.ErrorReport("GetBestEngine: object must be a cEngineLib.Infos instance"); return error; }
		cEngineLib.CheckEngineObject(object);
		if (object.cargo_id == -1)	{ cEngineLib.ErrorReport_INVALIDCARGO(object.cargo_id); return error; }
		if (object.depot == -1 && object.engine_type == -1)	{ cEngineLib.ErrorReport("GetBestEngine: object.engine_type must be set when the depot doesn't exist"); return error; }
		local all_engineList = cEngineLib.GetEngineList(object.engine_type);
		local filter_callback = cEngineLib.Filter_EngineGeneric;
		local filter_callback_params = [];
		if (object.engine_type == AIVehicle.VT_RAIL)	filter_callback = cEngineLib.Filter_EngineTrain;
		filter_callback_params.push(all_engineList);
		filter_callback_params.push(object);
		if (filter != null)
					{
					if (typeof(filter) != "function")	{ cEngineLib.ErrorReport("GetBestEngine: filter must be a function"); return error; }
					filter_callback = filter;
					}
		local result = [];
		// prepare trains work
		local oTrain, oWagon, train_list, wagon_list, filter_callback_train, filter_callback_wagon;
		if (object.engine_type == AIVehicle.VT_RAIL)
			{
			if (cEngineLib._cel_RT.IsEmpty())	{ cEngineLib.ErrorReport_NORAILTRACK(); return error; }
			oTrain = cEngineLib.Infos();
			oTrain.engine_id = object.engine_id;
			oTrain.engine_type = object.engine_type;
			oTrain.engine_roadtype = object.engine_roadtype;
			oTrain.depot = object.depot;
			oTrain.cargo_id = object.cargo_id;
			oTrain.bypass = object.bypass;
			oWagon = cEngineLib.Infos();
			oWagon.engine_id = object.engine_id;
			oWagon.engine_type = object.engine_type;
			oWagon.engine_roadtype = object.engine_roadtype;
			oWagon.depot = object.depot;
			oWagon.cargo_id = object.cargo_id;
			oWagon.bypass = object.bypass;
			train_list = cEngineLib.GetEngineList(cEngineLib.VT_RAIL_LOCO);
			wagon_list = cEngineLib.GetEngineList(cEngineLib.VT_RAIL_WAGON);
			filter_callback_train = [];
			filter_callback_wagon = [];
			filter_callback_train.push(train_list);
			filter_callback_train.push(oTrain);
			filter_callback_wagon.push(wagon_list);
			filter_callback_wagon.push(oWagon);
			}
		local confirm = false;

		// before answering we learn new engines properties
//		if (object.depot != -1)	cEngine.LearnEngineFromDepot(object.depot);
   			/*print("depot : "+object.depot);
			print("engine: "+object.engine_id);
			print("type  : "+object.engine_type);
            print("roadtype : "+object.engine_roadtype);
			print("cargo : "+object.cargo_id);
			print("bypass: "+object.bypass);*/

		if (object.engine_type != AIVehicle.VT_RAIL)
				{
				local save_engine_list = AIList();
				save_engine_list.AddList(all_engineList); // save the list (this one is store in the callback and use by it)
				local search_engine = -1;
				do	{
					search_engine = cEngineLib.GetCallbackResult(filter_callback, filter_callback_params);
					if (search_engine == -1 || cEngineLib.EngineIsKnown(search_engine) || object.depot == -1)	confirm = true;
					if (!confirm)
						{
						cEngineLib.LearnEngineFromDepot(object.depot, search_engine); // learn it
						all_engineList.AddList(save_engine_list);
						local taketwo = cEngineLib.GetCallbackResult(filter_callback, filter_callback_params);
						if (taketwo == -1 || taketwo == search_engine)	{ confirm = true; search_engine = taketwo; }
						if (!confirm)	all_engineList.AddList(save_engine_list); // prepare next call
						}
					} while (!confirm)
				if (search_engine != -1)
						{
						result.push(search_engine);
						return result;
						}
				else	{
						local r_type = "VT_ROAD";
						if (object.engine_type == AIVehicle.VT_WATER)	r_type = "VT_WATER3";
						if (object.engine_type == AIVehicle.VT_AIR)	r_type = "VT_AIR";
						local r_cargo = "";
						if (object.cargo == -1)	r_cargo = "any";
										else	r_cargo = "#"+object.cargo+" "+AICargo.GetCargoLabel(object.cargo);
						if (cargo == -1)
						cEngineLib.ErrorReport("GetBestEngine: Can't find an engine of type " + r_type + " to use with cargo " + r_cargo);
						return error;
						}
				result.push(search_engine);
				return result;
				}

		local save_train_list = AIList(); // each call to the callback will alter it
		local save_wagon_list = AIList();
		save_train_list.AddList(train_list);
		save_wagon_list.AddList(wagon_list);
		local errmsg = " using railtrack: ";
		if (object.engine_roadtype == -1)	errmsg += "any";
									else	errmsg += AIRail.GetName(object.engine_roadtype)+"("+object.engine_roadtype+")";
		errmsg += " for cargo: ";
		if (object.cargo_id == -1)	errmsg += "any";
							else	errmsg += AICargo.GetCargoLabel(object.cargo_id)+"("+object.cargo_id+")";

		if (object.engine_id != -1)
				{
				local back = null;
				confirm = false;
				if (object.depot != -1)	cEngineLib.LearnEngineFromDepot(object.depot, object.engine_id);
				if (AIEngine.IsWagon(object.engine_id))
						{ // find a train to pull that wagon
						do	{
							train_list.AddList(save_train_list);
							oTrain.engine_id = object.engine_id;
							// find it
							back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
							// If we knows it already, or we have no depot to test, or because we find no answer, we have nothing more to do
							if (object.depot != -1 || back == -1 || cEngineLib.EngineIsKnown(back))	confirm = true;
							if (!confirm)
								{
								// make it learn the new loco
								cEngineLib.LearnEngineFromDepot(object.depot, back);
								// restore the list that has just been change by the callback call
								train_list.AddList(save_train_list);
								// redo the same call to see if the answer is the same (answer could change because of the learning)
								local taketwo = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
								// if second try don't find answer, or find the same answer we stop.
								if (taketwo == back || taketwo == -1)	{
																		confirm = true;
																		// because after the test, the first engine found might not be valid anymore, so the good answer is 2nd
																		back = taketwo;
																		}
								// if second try find the same, we stop
								if (!confirm && taketwo == back)	confirm = true;
								}
							} while (!confirm)
						if (back != -1)		{
											result.push(back);
											result.push(object.engine_id);
											// before returning the result, if user didn't gave us a tracktype limit, let's give him back the one that would be the best
											if (oTrain.engine_roadtype == -1)
												{ // but it might have gave us a restrict on cargo
												if (oTrain.cargo_id == -1)	oTrain.engine_roadtype = cEngineLib.RailTypeGetFastestType(oTrain.engine_id);
																	else	oTrain.engine_roadtype = cEngineLib.RailTypeGetFastestTypeForCargo(oTrain.cargo_id, oTrain.bypass);
												}
											result.push(oTrain.engine_roadtype);
											return result;
											}
									else	{
											cEngineLib.ErrorReport("GetBestEngine: No train able to pull that wagon : "+cEngineLib.EngineToName(object.engine_id) + errmsg);
											return error;
											}
						}
				else	{ // find a wagon for that train
						oWagon.engine_id = object.engine_id;
						back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
						if (back != -1)	{
										result.push(object.engine_id);
										result.push(back);
										if (oWagon.engine_roadtype == -1)
												{
												if (oWagon.cargo_id == -1)	oWagon.engine_roadtype = cEngineLib.RailTypeGetFastestType(object.engine_id);
																	else	oWagon.engine_roadtype = cEngineLib.RailTypeGetFastestTypeForCargo(object.cargo_id, object.bypass);
												}
										result.push(oWagon.engine_roadtype);
										return result;
										}
								else	{
										cEngineLib.ErrorReport("GetBestEngine: No wagon that we could use with that train : "+cEngineLib.EngineToName(object.engine_id) + errmsg);
										return error;
										}
						}
					}
			// no engine was set: find the loco and wagon, and maybe the railtype too
			local railtype_list = AIList();
			local search_loco = -1;
			local search_wagon = -1;
			if (object.engine_roadtype == -1)	{
												railtype_list.AddList(cEngineLib._cel_RT);
												railtype_list.Sort(AIList.SORT_BY_VALUE, false);
												}
										else	railtype_list.AddItem(object.engine_roadtype, 0);
			foreach (RT, _ in railtype_list) // they are sort by first = fastest, last = slowest
				{
				confirm = false;
				do	{
					oTrain.engine_roadtype = RT;
					train_list.AddList(save_train_list); // else list of trains may be too short as a call lower the list
					search_loco = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
					print("found loco = "+cEngineLib.EngineToName(search_loco)+" for "+AIRail.GetName(RT));
					if (oTrain.depot == -1 || search_loco == -1)	confirm = true;
						if (!confirm)
							{
							cEngineLib.LearnEngineFromDepot(oTrain.depot, search_loco); // let it test our solve
							train_list.AddList(save_train_list); // restore the list
							local taketwo = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train); // search again
							print("taketwo: "+taketwo+" "+cEngineLib.EngineToName(taketwo));
							if (taketwo == -1 || taketwo == search_loco)	{ confirm = true; search_loco = taketwo; }
							}
					} while (!confirm)
				if (search_loco != -1) // found the best train using that railtype
					{
					oWagon.engine_roadtype = RT;
					oWagon.engine_id = search_loco;
					wagon_list.AddList(save_wagon_list);
					search_wagon = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
					print("found wagon: "+cEngineLib.EngineToName(search_wagon)+" cargo: "+oWagon.cargo_id);
					if (search_wagon != 1) // found a good wagon to use with it
						{
						result.push(search_loco);
						result.push(search_wagon);
						result.push(RT);
						return result;
						}
					}
				} // foreach
/*			print("depot : "+object.depot);
			print("engine: "+object.engine_id);
			print("type  : "+object.engine_type);
            print("roadtype : "+object.engine_roadtype);
			print("cargo : "+object.cargo_id);
			print("bypass: "+object.bypass);
			local cargo = "#"+object.cargo_id;
			if (AICargo.IsValidCargo(object.cargo_id))	cargo+=":"+AICargo.GetCargoLabel(object.cargo_id);
			local rtinfo = "any railtrack";
			if (object.engine_roadtype != -1)	rtinfo = AIRail.GetName(object.engine_roadtype);*/
			cEngineLib.ErrorReport("GetBestEngine: Coudn't find a matching train and wagon"+errmsg);
			return error;
		}

	function cEngineLib::EngineFilter(engine_list, cargo_id, road_type, engine_id, bypass)
	// Change an AIList of engines to filter out ones that cannot match engine_id, or run on road_type road/rail or that aren't buildable
	{
		if (engine_list instanceof AIList && !engine_list.IsEmpty())
				{
				engine_list.Valuate(AIEngine.IsBuildable);
				engine_list.KeepValue(1);
				if (engine_list.IsEmpty())	return; // a dumb list without valid engine
				local engine_type = AIEngine.GetVehicleType(engine_list.Begin());
				if (engine_id != -1 && (!AIEngine.IsValidEngine(engine_id) || engine_type != AIVehicle.VT_RAIL))	engine_id = -1;
				engine_list.Valuate(cEngineLib.IsEngineBlacklist);
				engine_list.KeepValue(0);
				if (road_type != -1)
					{ // apply filter if we need a special road type
					if (engine_type == cEngineLib.VT_RAIL)
							{
							// Until prove false, HasPowerOnRail do a better job than CanRunOnRail : no diff with wagon if it can run on a rail, it has power on it
							// While some loco may run on rail but with no power
							engine_list.Valuate(AIEngine.HasPowerOnRail, road_type);
							engine_list.KeepValue(1);
							}
					if (engine_type == cEngineLib.VT_ROAD)
							{
							engine_list.Valuate(AIEngine.GetRoadType);
							engine_list.KeepValue(road_type);
							}
					if (engine_type == cEngineLib.VT_AIR)
							{
							engine_list.Valuate(AIEngine.GetPlaneType);
							engine_list.KeepValue(road_type);
							}
					}
				if (engine_id != -1)
					{ // apply a filter base on the engine
					engine_list.Valuate(cEngineLib.AreEngineCompatible, engine_id);
					engine_list.KeepValue(1);
					engine_list.Valuate(AIEngine.IsWagon);
					engine_list.KeepValue(AIEngine.IsWagon(engine_id) ? 0 : 1); // kick wagon or loco
					}
				if (cargo_id != -1)
					{ // apply a filter per cargo type
					if (engine_type == AIVehicle.VT_RAIL)
								{ // filter train or wagon base on cargo
								if (!AIEngine.IsWagon(engine_list.Begin()))	{ engine_list.Valuate(cEngineLib.CanPullCargo, cargo_id, bypass); }
																	else	{ engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id); }
								engine_list.KeepValue(1);
								}
					if (engine_type != AIVehicle.VT_RAIL)	{ engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id); engine_list.KeepValue(1); }
					}
				}
	}

	function cEngineLib::VehicleCreate(depot, engine_id, cargo_id = -1)
	{
		if (!AIEngine.IsValidEngine(engine_id))	{ cEngineLib.ErrorReport_INVALIDVEHICLE(engine_id); return -1; }
		if (!cEngineLib.IsDepotTile(depot))	{ cEngineLib.ErrorReport("VehicleCreate: Invalid depot : "+depot); return -1; }
		cEngineLib.LearnEngineFromDepot(depot, engine_id);
		cEngineLib.GetMoney(AIEngine.GetPrice(engine_id));
		local vehID = AIVehicle.BuildVehicle(depot, engine_id);
		if (!AIVehicle.IsValidVehicle(vehID))	return -1;
		if (cargo_id == -1)	return vehID;
		if (AIEngine.CanRefitCargo(engine_id, cargo_id) && !AIVehicle.RefitVehicle(vehID, cargo_id))	{ AIVehicle.SellVehicle(vehID); return -1; }
		return vehID;
	}

	function cEngineLib::GetLength(engine_id, cargo_id = -1)
	{
        if (cargo_id != -1 && !AICargo.IsValidCargo(cargo_id))	{ cEngine.ErrorReport_INVALIDCARGO(cargo_id); return 0; }
		local eng = cEngineLib.Load(engine_id);
		if (eng == null)	return 0;
		if (cargo_id == -1)	cargo_id = AIEngine.GetCargoType(engine_id);
		return eng.cargo_length.GetValue(cargo_id);
	}

	function cEngineLib::GetCapacity(engine_id, cargo_id = -1)
	{
		local engObj = cEngineLib.Load(engine_id);
		if (engObj == null)	return 0;
		if (cargo_id == -1)	cargo_id = AIEngine.GetCargoType(engine_id);
					else	if (!AICargo.IsValidCargo(cargo_id))	return 0;
		return engObj.cargo_capacity.GetValue(cargo_id);
	}

	function cEngineLib::VehicleGetWeight(vehicle_id, empty = true)
     {
		local my_vehicle = [];
		if (typeof vehicle_id == "array")
				{
				if (vehicle_id.len() != 4)	{ return -1; }
                local loc = vehicle_id[0];
                local locnum = vehicle_id[1];
                local wag = vehicle_id[2];
                local wagnum = vehicle_id[3];
                for (local j = 0; j < locnum; j++)	{
													if (AIEngine.GetVehicleType(loc) != AIVehicle.VT_RAIL)	return -1;
													my_vehicle.push(loc);
													}
                for (local j = 0; j < wagnum; j++)	{
													if (AIEngine.GetVehicleType(wag) != AIVehicle.VT_RAIL)	return -1;
													my_vehicle.push(wag);
													}
				}
		else	{
				if (!AIVehicle.IsValidVehicle(vehicle_id))	{ return -1; }
				if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	{ return -1; }
				for (local i = 0; i < AIVehicle.GetNumWagons(vehicle_id); i++)
					{
					local engine = AIVehicle.GetWagonEngineType(vehicle_id, i);
					my_vehicle.push(engine);
					}
				}
		local total_weight = 0;
        local mulfactor = 1;
        if (AIGameSettings.IsValid("vehicle.freight_trains"))	{ mulfactor = AIGameSettings.GetValue("vehicle.freight_trains"); }
        local cargos = AIList();
        foreach (engine in my_vehicle)
			{
			local weight = AIEngine.GetWeight(engine);
			local cargotype = AIEngine.GetCargoType(engine);
			total_weight += weight;
			if (!empty)	{
						local cap_cargo = cEngineLib.GetCapacity(engine, cargotype);
						if (cargotype != null)
							if (AICargo.IsFreight(cargotype))	{ total_weight += cEngineLib.GetCapacity(engine, cargotype) * mulfactor; }
														else	{ total_weight += 2; } // my tests shown a full passenger wagon takes 2t more than an empty wagon
						}
			}
		return total_weight;
	}

	function cEngineLib::VehicleGetMaxTractiveEffort(vehicle_id)
     {
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ cEngineLib.ErrorReport_INVALIDVEHICLE(vehicle_id); return -1; }
		local total_tract = 0;
        local numpart = AIVehicle.GetNumWagons(vehicle_id);
		for (local i = 0; i < numpart; i++)
				{
				local engine = AIVehicle.GetWagonEngineType(vehicle_id, i);
				if (AIEngine.GetVehicleType(vehicle_id) == AIVehicle.VT_ROAD || cEngineLib.IsLocomotive(engine))	{ total_tract += AIEngine.GetMaxTractiveEffort(engine); }
				// don't check IsLocomotive first as engine might be invalid if it's a ROAD vehicle
				}
		return total_tract;
	}

	function cEngineLib::VehicleGetMaxPower(vehicle_id, KW = false)
     {
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ cEngineLib.ErrorReport_INVALIDVEHICLE(vehicle_id); return -1; }
		local total_power = 0;
        local numpart = AIVehicle.GetNumWagons(vehicle_id);
		for (local i = 0; i < numpart; i++)
				{
				local engine = AIVehicle.GetWagonEngineType(vehicle_id, i);
				if (AIEngine.GetVehicleType(vehicle_id) == AIVehicle.VT_ROAD || cEngineLib.IsLocomotive(engine))	{ total_power += AIEngine.GetPower(engine); }
				// don't check IsLocomotive first as engine might be invalid if it's a ROAD vehicle
				}
		if (KW)	{ total_power *= 0.73549875; }
		return total_power;
	}

	function cEngineLib::VehicleGetRailTypeUse(vehicle_id)
	{
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ return AIRail.RAILTYPE_INVALID; }
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	{ return AIRail.RAILTYPE_INVALID; }
		return AIRail.GetRailType(AIVehicle.GetLocation(vehicle_id));
	}

	function cEngineLib::VehicleGetMaxSpeed(vehicle_id)
	 {
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ cEngineLib.ErrorReport_INVALIDVEHICLE(vehicle_id); return -1; }
		local browse = AIVehicle.GetVehicleType(vehicle_id);
		if (browse != AIVehicle.VT_RAIL)	{ return AIEngine.GetMaxSpeed(AIVehicle.GetEngineType(vehicle_id)); }
		browse = AIVehicle.GetNumWagons(vehicle_id);
		local big_speed = 9999999999;
		local max_loco_speed = 0;
		local max_wagon_speed = big_speed;
		local max_speed = -1;
		local rt = cEngineLib.VehicleGetRailTypeUse(vehicle_id);
		local rt_speed = cEngineLib.RailTypeGetSpeed(rt);
		if (rt_speed == -1)	{ return AIEngine.GetMaxSpeed(AIVehicle.GetEngineType(vehicle_id)); } // if no railtype is found
		for (local i = 0; i < browse; i++)
			{
			local eng = AIVehicle.GetWagonEngineType(i);
			local spd = AIEngine.GetMaxSpeed(eng);
			if (AIEngine.IsWagon(eng))
					{
					local wagon_limit =	(AIGameSettings.IsValid("wagon_speed_limits") && AIGameSettings.GetValue("wagon_speed_limits") == 1);
					if (!wagon_limit)	{ spd = big_speed; } // no limit to wagons speed
					if (spd == 0)	{ spd = big_speed; } // if we get 0, it's unlimit
					if (max_wagon_speed > spd)  max_wagon_speed = spd;
					}
			else	{
					if (spd > max_loco_speed && AIEngine.HasPowerOnRail(rt))	max_loco_speed = spd;
					}
			}
		max_speed = max_loco_speed;
		if (max_speed > max_wagon_speed)	max_speed = max_wagon_speed;
		if (max_speed > rt_speed)	max_speed = rt_speed;
		return max_speed;
	 }

	function cEngineLib::IsLocomotive(engine_id)
	{
		if (!AIEngine.IsValidEngine(engine_id))	{ cEngineLib.ErrorReport_INVALIDVEHICLE(engine_id); return -1; }
		return (AIEngine.GetVehicleType(engine_id) == AIVehicle.VT_RAIL && !AIEngine.IsWagon(engine_id));
	}

	function cEngineLib::VehicleIsMultiEngine(vehicle_id)
    {
		local e = AIVehicle.GetEngineType(vehicle_id);
    	if (("IsMultiheaded" in AIEngine) && AIEngine.IsMultiheaded(e))	{ return true; } // handle new API function
	    return (cEngineLib.VehicleGetNumberOfLocomotive(vehicle_id) > 1);
    }

	function cEngineLib::VehicleGetNumberOfLocomotive(vehicle_id)
	{
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return 0;
		local numwagon = cEngineLib.VehicleGetNumberOfWagons(vehicle_id);
		local totalpart = AIVehicle.GetNumWagons(vehicle_id);
		return (totalpart - numwagon);
	}

	function cEngineLib::VehicleLackPower(vehicle_id, aim_speed = 0)
	{
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	{ return 0; }
        local weight = cEngineLib.VehicleGetWeight(vehicle_id, false);
        if (aim_speed == 0)	{aim_speed = AIEngine.GetMaxSpeed(AIVehicle.GetEngineType(vehicle_id)) * 0.15; } // we aim at least to get 15% of its max speed
        if (aim_speed < 15)	{ aim_speed = 15; } // but a minimum aim is 15 speed (for really weak engine), below 15spd, engine really have hard time climbing
        local steepness = 1;
        local new_accel = false;
        if (AIGameSettings.IsValid("vehicle.train_slope_steepness"))	{ steepness = AIGameSettings.GetValue("vehicle.train_slope_steepness"); }
		if (AIGameSettings.IsValid("vehicle.train_acceleration_model"))	{ new_accel = (AIGameSettings.GetValue("vehicle.train_acceleration_model") == 1); }
		if (!new_accel)	{ aim_speed *= 2; }
        local aim_te = ((35 * weight) + (steepness * weight * 100)) / 1000; // TE need (in KN)
        local aim_power = (aim_te * (0.277777777778 * aim_speed)); // power need (in kw)
        local veh_power = cEngineLib.VehicleGetMaxPower(vehicle_id, true); // total power we got
		local veh_te = cEngineLib.VehicleGetMaxTractiveEffort(vehicle_id);
		local advise = false;
		if (!new_accel && aim_power > veh_power)	{ advise = true; }
		if (new_accel && aim_te > veh_te)	{ advise = true; }
		return	advise;
	}

	function cEngineLib::VehicleGetNumberOfWagons(vehicle_id)
	{
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return 0;
		local numwagon = 0;
		local numpart = AIVehicle.GetNumWagons(vehicle_id);
		for (local i = 0; i < numpart; i++)	if (AIEngine.IsWagon(AIVehicle.GetWagonEngineType(vehicle_id, i)))	numwagon++;
		return numwagon;
	}

	function cEngineLib::VehicleGetRandomWagon(vehicle_id)
	{
		if (!AIVehicle.IsValidVehicle(vehicle_id) || AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	{ cEngine.ErrorReport_INVALIDVEHICLE(vehicle_id); return -1; }
		local size = AIVehicle.GetNumWagons(vehicle_id);
		for (local i = 0; i < size; i++)
				if (AIEngine.IsWagon(AIVehicle.GetWagonEngineType(vehicle_id, i)))	return i;
		return -1;
	}

	function cEngineLib::IncompatibleEngine(engine_one, engine_two)
	{
		if (AIEngine.GetVehicleType(engine_one) != AIVehicle.VT_RAIL)	return;
		if (AIEngine.GetVehicleType(engine_two) != AIVehicle.VT_RAIL)	return;
		cEngineLib.SetUsuability(engine_one, engine_two, -1);
	}

	function cEngineLib::CompatibleEngine(engine_one, engine_two)
	{
		if (AIEngine.GetVehicleType(engine_one) != AIVehicle.VT_RAIL)	return;
		if (AIEngine.GetVehicleType(engine_two) != AIVehicle.VT_RAIL)	return;
		cEngineLib.SetUsuability(engine_one, engine_two, 1);
	}

	function cEngineLib::AreEngineCompatible(engine, compare_engine)
	{
		local eng = cEngineLib.Load(compare_engine);
		if (eng == null)	return false;
		if (!eng.usuability.HasItem(engine))	return true;
		return (eng.usuability.GetValue(engine) == 1);
	}

	function cEngineLib::VehicleWagonCompatibilityTest(vehicleID, wagonID)
	// return true if we test it, return false if we cannot manage to do the test (lack money...)
	{
		if (!AIVehicle.IsValidVehicle(vehicleID) || AIVehicle.GetVehicleType(vehicleID) != AIVehicle.VT_RAIL)	{ cEngineLib.ErrorReport("VehicleWagonCompatibilityTest: VehivehicleID must be a valid rail vehicle"); return false; }
		if (!AIEngine.IsBuildable(wagonID) || AIEngine.GetVehicleType(wagonID) != AIVehicle.VT_RAIL)	{ cEngineLib.ErrorReport("VehicleWagonCompatibilityTest: wagonID must be a valid buildable wagon engine"); return false; }
		if (AIVehicle.GetState(vehicleID) != AIVehicle.VS_IN_DEPOT)	{ cEngineLib.ErrorReport("VehicleWagonCompatibilityTest: Vehicle must be a vehicle stopped at a depot"); return false; }
		local depot = AIVehicle.GetLocation(vehicleID);
		local wagon = null;
		local goodresult = true;
		local locotype = AIVehicle.GetEngineType(vehicleID);
		cEngineLib.GetMoney(AIEngine.GetPrice(wagonID));
		wagon = AIVehicle.BuildVehicle(depot, wagonID);
		cEngineLib.VehicleUpdateEngineProperties(wagon);
		if (!AIVehicle.IsValidVehicle(wagon))
								{
								local error = AIError.GetLastError();
								local errorcat = AIError.GetErrorCategory();
								if (error == AIError.ERR_UNKNOWN)
										{ // 2cc produce that error on failure with a wagon, well, no other reason given
										cEngineLib.IncompatibleEngine(locotype, wagonID);
										}
								else	goodresult = false;
								}
						else	{
								local attach_try = AITestMode();
								local atest = AIVehicle.MoveWagon(wagon, 0, vehicleID, AIVehicle.GetNumWagons(vehicleID) -1);
								attach_try = null;
								if (!atest)
										{
										if (AIError.GetLastError() == AIVehicle.ERR_VEHICLE_TOO_LONG)	goodresult = false;
																								else	cEngineLib.IncompatibleEngine(locotype, wagonID);
										}
								else	cEngineLib.CompatibleEngine(locotype, wagonID);
								AIVehicle.SellVehicle(wagon);
								}
	return goodresult;
	}

	function cEngineLib::CanPullCargo(engine_id, cargo_id, bypass = false)
	{
		if (!bypass)	return ::AIEngine.CanPullCargo(engine_id, cargo_id);
		if (!cEngineLib.EngineIsKnown(engine_id))	return ::AIEngine.CanPullCargo(engine_id, cargo_id);
		if (!AICargo.IsValidCargo(cargo_id))	return false;
		if (!cEngineLib.IsLocomotive(engine_id))	return false;
		local loco = cEngine.Load(engine_id);
		if (loco == null)	return AIEngine.CanPullCargo(engine_id, cargo_id);
		return ((loco.cargo_pull & (1 << cargo_id)) != 0);
	}

	function cEngineLib::IsEngineBlacklist(engine_id)
	{
		return (cEngineLib._cel_blacklist.HasItem(engine_id));
	}

	function cEngineLib::BlacklistEngine(engine_id)
	{
		if (cEngineLib.IsEngineBlacklist(engine_id))	return;
		cEngineLib._cel_blacklist.AddItem(engine_id, 0);
	}

	function cEngineLib::GetDepotType(depot)
	{
		if (!AIMap.IsValidTile(depot))	return -1;
		if (AIRoad.IsRoadDepotTile(depot))	return AIVehicle.VT_ROAD;
		if (AIAirport.IsHangarTile(depot))	return AIVehicle.VT_AIR;
		if (AIRail.IsRailDepotTile(depot))	return AIVehicle.VT_RAIL;
		if (AIMarine.IsWaterDepotTile(depot))	return AIVehicle.VT_WATER;
		return -1;
	}

    function cEngineLib::VehicleIsGoingToStopInDepot(vehicle_id)
    {
		if (!AIVehicle.IsValidVehicle(vehicle_id))	return false;
		local flags = AIOrder.GetOrderFlags(vehicle_id, AIOrder.ORDER_CURRENT);
        if ((flags & AIOrder.OF_GOTO_NEAREST_DEPOT) != 0)	return true;
        if ((flags & AIOrder.OF_STOP_IN_DEPOT) != 0)	return true;
		return false;
    }

	function cEngineLib::VehicleOrderSkipCurrent(vehicle_id)
	{
	local total = AIOrder.GetOrderCount(vehicle_id);
	if (total == 0)	return -1;
	local current = AIOrder.ResolveOrderPosition(vehicle_id, AIOrder.ORDER_CURRENT);
	if (current + 1 == total)	current = 0;
						else    current++;
	if (AIOrder.SkipToOrder(vehicle_id, current))	return current;
	return -1;
	}

	function cEngineLib::VehicleOrderClear(vehicle_id)
	{
		AIOrder.UnshareOrders(vehicle_id);
		for (local i = 0; i < AIOrder.GetOrderCount(vehicle_id); i++)	AIOrder.RemoveOrder(vehicle_id, i);
		return (AIOrder.GetOrderCount(vehicle_id) == 0);
	}

	function cEngineLib::RailTypeGetFastestType(engineID = -1)
	{
		if (cEngineLib._cel_RT.IsEmpty())	{ cEngine.ErrorReport_NORAILTRACK(); return -1; }
		cEngineLib._cel_RT.Sort(AIList.SORT_BY_VALUE, false);
		if (engineID == -1)	return cEngineLib._cel_RT.Begin();
		local train = cEngineLib.IsLocomotive(engineID);
		local top_rt = -1;
		local best_rt = -1;
		foreach (rt, spd in cEngineLib._cel_RT)
			{
			local res = -1;
			if (train)	res = AIEngine.HasPowerOnRail(engineID, rt);
				else	res = AIEngine.CanRunOnRail(engineID, rt);
			if (res && top_rt < spd)	{ top_rt = spd; best_rt = rt; }
			}
		return best_rt;
	}

	function cEngineLib::RailTypeGetFastestTypeForCargo(cargoID, bypass = false)
	// It's actually easy to get the fastest railtype for a cargo, as we just ask GetBestEngine for it
	{
		if (!AICargo.IsValidCargo(cargoID))	{ cEngine.ErrorReport_INVALIDCARGO(cargoID); return -1; }
		if (cEngineLib._cel_RT.IsEmpty())	{ cEngine.ErrorReport_NORAILTRACK(); return -1; }
		local rt_object = cEngineLib.Infos();
		rt_object.depot = -1;
		rt_object.engine_id = -1;
		rt_object.engine_type = AIVehicle.VT_RAIL;
		rt_object.cargo_id = cargoID;
		rt_object.bypass = bypass;
		local bestspeed = -1;
		local bestRT = -1;
		foreach (rt, speed in cEngineLib._cel_RT)
			{
			rt_object.engine_roadtype = rt;
			local res = cEngineLib.GetBestEngine(rt_object, cEngineLib.Filter_EngineTrain);
			if (res[0] == -1)	continue;
            if (speed > bestspeed)	{ bestspeed = speed; bestRT = rt; }
			}
		return bestRT;
	}

	function cEngineLib::RailTypeGetSpeed(RT = -1)
	{
		if (cEngineLib._cel_RT.IsEmpty())	{ cEngine.ErrorReport_NORAILTRACK(); return -1; }
		if (RT == -1)	{
						cEngineLib._cel_RT.Sort(AIList.SORT_BY_VALUE, false);
						RT = cEngineLib._cel_RT.Begin();
						}
		return cEngineLib._cel_RT.GetValue(RT);
	}

	function cEngineLib::VehicleRestrictLength(vehicle_id, max_length)
	{
		if (max_length <= 1)	return -1;
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return -1;
		if (AIVehicle.GetState(vehicle_id) != AIVehicle.VS_IN_DEPOT)	return -1;
		if (cEngineLib.VehicleGetRandomWagon(vehicle_id) == -1)	return -1;
	    local removed = 0;
	    while (AIVehicle.GetLength(vehicle_id) > max_length)
				{
				local wagondelete = cEngineLib.VehicleGetRandomWagon(vehicle_id);
    	        if (wagondelete == -1)  break;
				if (!AIVehicle.SellWagon(vehicle_id, wagondelete))
						{
						cEngineLib.ErrorReport("Cannot delete that wagon : "+wagondelete);
						break;
						}
				else	removed++;
				}
    	return removed;
	}

	function cEngineLib::GetMaxWagons(engines, max_length, cargo_id = -1)
	{
		if (typeof(engines) != "array" || engines.len() < 2)	{ cEngineLib.ErrorReport("GetMaxWagons: engines parameter must be an array"); return -1; }
		if (AIEngine.GetVehicleType(engines[0]) != AIVehicle.VT_RAIL || AIEngine.GetVehicleType(engines[1]) != AIVehicle.VT_RAIL)
			{
			cEngineLib.ErrorReport("GetMaxWagons: Both engines must be of rail engines");
			return -1;
			}
		local t_len = cEngineLib.GetLength(engines[0], cargo_id);
		local w_len = cEngineLib.GetLength(engines[1], cargo_id);
		if (t_len == 0 || w_len == 0)	return -1;
		max_length -= t_len;
		if (max_length < 1 || w_len == 0)	return -1; // shouldn't happen, but prevent div 0 on w_len
		max_length = max_length / w_len;
		return max_length;
	}

	function cEngineLib::SetAPIErrorHandling(output)
	{
		if (typeof(output) != "bool")	return;
		cEngineLib._cel_config[0] = output;
	}

	function cEngineLib::GetAPIError()
	{
		return cEngineLib._cel_config[1];
	}

	function cEngineLib::SetMoneyCallBack(money_func)
	{
		if (typeof(money_func) != "function")	return false;
		cEngineLib._cel_config[2] = money_func;
		return true;
	}

	function cEngineLib::EngineCacheInit()
	{
		local cache = [AIVehicle.VT_ROAD, AIVehicle.VT_AIR, AIVehicle.VT_RAIL, AIVehicle.VT_WATER];
		foreach (item in cache)
			{
			local engList = cEngineLib.GetEngineList(item);
			foreach (engID, _ in engList)	local dum = cEngineLib.Load(engID);
			}
	}

	function cEngineLib::DirtyEngineCache(eng_type)
	{
	if (eng_type < cEngineLib.VT_RAIL || eng_type > cEngineLib.VT_RAIL_WAGON)	{ return; }
	if (eng_type == cEngineLib.VT_RAIL || eng_type == cEngineLib.VT_RAIL_LOCO || eng_type == cEngineLib.VT_RAIL_WAGON)
								{ // the 3 lists are links
								cEngineLib._cel_cache[cEngineLib.VT_RAIL] = null;
								cEngineLib._cel_cache[cEngineLib.VT_RAIL_WAGON] = null;
								cEngineLib._cel_cache[cEngineLib.VT_RAIL_LOCO] = null;
								}
						else	{ cEngineLib._cel_cache[eng_type] = null; }
	}

	function cEngineLib::GetEngineList(eng_type)
	{
	if (eng_type < cEngineLib.VT_RAIL || eng_type > cEngineLib.VT_RAIL_WAGON)	{ return AIList(); }
	local special = AIList();
	special.AddItem(cEngineLib.VT_RAIL, 0);
	special.AddItem(cEngineLib.VT_RAIL_WAGON, 0);
	special.AddItem(cEngineLib.VT_RAIL_LOCO,0);
	local elist = cEngineLib._cel_cache[eng_type];
    local safelist = cEngineLib._cel_cache[eng_type]; // We don't want return our list pointer so anyone can alter its content while playing with it
	if (elist != null)
		{
		local now = AIDate.GetCurrentDate();
		local old = elist.GetValue(elist.Begin());
		if (special.HasItem(eng_type))	{ old = cEngineLib._cel_cache[cEngineLib.VT_RAIL].GetValue(cEngineLib._cel_cache[cEngineLib.VT_RAIL].Begin()); }
		if (now - old > 7*74)	{ cEngineLib.DirtyEngineCache(eng_type); elist = null; }
					else		{ elist = AIList(); elist.AddList(safelist); return elist; }
		}
	if (elist == null)
		{
		local vquery = eng_type;
		local railhandling = special.HasItem(eng_type);
		if (railhandling)	{ vquery = cEngineLib.VT_RAIL; }
		safelist = AIEngineList(vquery);
		safelist.Valuate(cEngineLib.IsEngineBlacklist);
		safelist.RemoveValue(1);
		if (railhandling)
			{
            local wlist = AIList();
            local llist = AIList();
            wlist.AddList(safelist);
            llist.AddList(safelist);
            wlist.Valuate(AIEngine.IsWagon);
            wlist.KeepValue(1);
            llist.RemoveList(wlist);
            cEngineLib._cel_cache[cEngineLib.VT_RAIL_WAGON] = wlist;
            cEngineLib._cel_cache[cEngineLib.VT_RAIL_LOCO] = llist;
			}
		safelist.SetValue(safelist.Begin(), AIDate.GetCurrentDate());
		cEngineLib._cel_cache[vquery] = safelist;
		}
	elist = cEngineLib._cel_cache[eng_type]; // renew it, it has change
	return elist;
	}

	function cEngineLib::DumpLibStats()
	{
		AILog.Info("cEngineLib Last error: "+cEngineLib.GetAPIError());
		AILog.Info("Base size: "+cEngineLib._cel_ebase.len());
		AILog.Info("Blacklist size : "+cEngineLib._cel_blacklist.Count());
		AILog.Info("RailTrack size : "+cEngineLib._cel_RT.Count());
		foreach (rt, spd in cEngineLib._cel_RT)	AILog.Info("- RailType: #"+rt+" "+AIRail.GetName(rt)+" max speed: "+AIRail.GetMaxSpeed(rt)+" max usable speed: "+spd);
		local veh_list = cEngineLib.GetEngineList(AIVehicle.VT_AIR);
		local v_count = veh_list.Count();
		veh_list.Valuate(cEngineLib.EngineIsKnown);
		veh_list.KeepValue(1);
		AILog.Info("AIR engine: "+v_count+" known: "+veh_list.Count());
		foreach (eng, _ in veh_list)	cEngineLib.Engine_Stats(eng);
		AIController.Break("next");

		veh_list = cEngineLib.GetEngineList(AIVehicle.VT_WATER);
		v_count = veh_list.Count();
		veh_list.Valuate(cEngineLib.EngineIsKnown);
		veh_list.KeepValue(1);
		AILog.Info("WATER engine: "+v_count+" known: "+veh_list.Count());
		foreach (eng, _ in veh_list)	cEngineLib.Engine_Stats(eng);
		AIController.Break("next");

		veh_list = cEngineLib.GetEngineList(AIVehicle.VT_ROAD);
		v_count = veh_list.Count();
		veh_list.Valuate(cEngineLib.EngineIsKnown);
		veh_list.KeepValue(1);
		AILog.Info("ROAD engine: "+v_count+" known: "+veh_list.Count());
		foreach (eng, _ in veh_list)	cEngineLib.Engine_Stats(eng);
		AIController.Break("next");

		veh_list = cEngineLib.GetEngineList(cEngineLib.VT_RAIL_LOCO);
		v_count = veh_list.Count();
		veh_list.Valuate(cEngineLib.EngineIsKnown);
		veh_list.KeepValue(1);
		AILog.Info("LOCO engine: "+v_count+" known: "+veh_list.Count());
		foreach (eng, _ in veh_list)	cEngineLib.Engine_Stats(eng);
		AIController.Break("next");

		veh_list = cEngineLib.GetEngineList(cEngineLib.VT_RAIL_WAGON);
		v_count = veh_list.Count();
		veh_list.Valuate(cEngineLib.EngineIsKnown);
		veh_list.KeepValue(1);
		AILog.Info("WAGON engine: "+v_count+" known: "+veh_list.Count());
		foreach (eng, _ in veh_list)	cEngineLib.Engine_Stats(eng);
		AIController.Break("end");
	}

	   // ****************** //
	  // PRIVATE FUNCTIONS  //
	 // ****************** //

	function cEngineLib::Engine_Stats(engine_id)
	{
		local z = cEngineLib.Load(engine_id);
		if (z == null)	AILog.Info("engine #"+engine_id+" invalid");
		local crg = AICargoList();
		local r = cEngineLib.EngineToName(engine_id)+" ";
		local isloco = false;
		if (AIEngine.GetVehicleType(engine_id) == AIVehicle.VT_RAIL)
			{
			if (AIEngine.IsWagon(engine_id))	r += "test locos:";
										else	{ isloco = true; r += "test wagon:"; }
			r += z.usuability.Count()+" ";
			}

		foreach (cargo, _ in crg)	if (z.cargo_capacity.GetValue(cargo) != 0)	r += AICargo.GetCargoLabel(cargo)+"(#"+cargo+")/len:"+z.cargo_length.GetValue(cargo)+"/cap:"+z.cargo_capacity.GetValue(cargo)+" ";
		AILog.Info(r);
		if (isloco)
			{
			r = "        CanPullCargo (bypass=false): ";
			foreach (cargo, _ in crg)	if (cEngineLib.CanPullCargo(engine_id, cargo, false))	r += AICargo.GetCargoLabel(cargo)+"(#"+cargo+") ";
			AILog.Info(r);
			r = "        CanPullCargo (bypass=true): ";
			foreach (cargo, _ in crg)	if (cEngineLib.CanPullCargo(engine_id, cargo, true))	r += AICargo.GetCargoLabel(cargo)+"(#"+cargo+") ";
			AILog.Info(r);
			}
	}

	function cEngineLib::ErrorReport(error)
	// if allowed print the error. Also set last error string
	{
		cEngineLib._cel_config[1] = "cEngineLib: " + error + " NOAI error: "+AIError.GetLastErrorString();
		if (cEngineLib._cel_config[0])	AILog.Error(cEngineLib._cel_config[1]);
	}

	function cEngineLib::ErrorReport_NORAILTRACK()
	{
		cEngineLib.ErrorReport("No railtrack type is currently usable.");
	}

	function cEngineLib::ErrorReport_INVALIDVEHICLE(id)
	{
		cEngineLib.ErrorReport("Invalid vehicleID or engineID : #"+id);
	}

	function cEngineLib::ErrorReport_INVALIDCARGO(id)
	{
		cEngineLib.ErrorReport("Invalid cargoID : #"+id);
	}

	function cEngineLib::SetUsuability(engine_one, engine_two, flags)
	// set the usuability flags of two engines
	{
		if (engine_one == null || engine_two == null)	return;
		if (AIEngine.GetVehicleType(engine_one) != AIVehicle.VT_RAIL)	return;
		if (AIEngine.GetVehicleType(engine_two) != AIVehicle.VT_RAIL)	return;
		local eng1 = cEngineLib.Load(engine_one);
		if (eng1 == null)	return;
		local eng2 = cEngineLib.Load(engine_two);
		if (eng2 == null)	return;
		eng1.is_known = 2;
		eng2.is_known = 2;
		if (!eng1.usuability.HasItem(engine_two))	eng1.usuability.AddItem(engine_two, 0);
		if (!eng2.usuability.HasItem(engine_one))	eng2.usuability.AddItem(engine_one, 0);
		eng1.usuability.SetValue(engine_two, flags);
		eng2.usuability.SetValue(engine_one, flags);
		if (flags != 1) return;
		local loco = eng1;
		local wagon = eng2;
		if (AIEngine.IsWagon(eng1.engine_id))	{ loco = eng2; wagon = eng1; }
		loco.cargo_pull = (loco.cargo_pull | wagon.cargo_pull);

	}

	function cEngineLib::IsCoupleTested(engine_one, engine_two)
	// return true if engine1 has been test with engine2
	{
		local eng = cEngineLib.Load(engine_one);
		if (eng == null)	return false;
		return eng.usuability.HasItem(engine_two);
	}

	function cEngineLib::SetRailTypeSpeed(engineID)
	// We set the maximum speed a train can reach on that railtype
	{
		local rlist = AIRailTypeList();
		rlist.Valuate(AIRail.GetMaxSpeed);
		local engine_speed = AIEngine.GetMaxSpeed(engineID);
		foreach (rt, rt_speed in rlist)
			{
			if (!cEngineLib._cel_RT.HasItem(rt))	cEngineLib._cel_RT.AddItem(rt, 0);
			if (AIEngine.HasPowerOnRail(engineID, rt))
					{
					local rtop = rt_speed; // don't alter the ailist while looping it
					if (rtop == 0 || rtop > engine_speed)	rtop = engine_speed;
					if (cEngineLib._cel_RT.GetValue(rt) < rtop)	{ cEngineLib._cel_RT.SetValue(rt, rtop); }
					}
			}
	}

	function cEngineLib::Load(e_id)
	{
		local cobj = cEngineLib();
		cobj.engine_id = e_id;
		if (e_id in cEngineLib._cel_ebase)	 return cEngineLib._cel_ebase[e_id];
		if (!cobj.Save())	{ return null; }
		return cobj;
	}

	function cEngineLib::Save()
	{
		if (this.engine_id == null)	return false;
		if (!AIEngine.IsValidEngine(this.engine_id))	return false;
		if (this.engine_id in cEngineLib._cel_ebase)	return true;
		local crglist = AICargoList();
		local cargobits = 0;
		foreach (crg, dummy in crglist)
			{
			this.cargo_length.AddItem(crg, 8); // default to 8, a classic length
			if (AIEngine.CanRefitCargo(this.engine_id, crg))	{ cargobits += (1 << crg); this.cargo_capacity.AddItem(crg,255); }
														else	this.cargo_capacity.AddItem(crg,0);
			// 255 so it will appears to be a bigger carrier vs an already test engine
			// These two properties set as-is will force the AI to think a non-test engine appears better
			}
		if (AIEngine.IsWagon(this.engine_id))	this.cargo_pull = cargobits; // not use, but it ease loco in @SetUsuability
		local crgtype = AIEngine.GetCargoType(this.engine_id);
		this.cargo_capacity.AddItem(crgtype, 255); // if it use that cargo, but is not refitable, it will miss to track it
		this.cargo_capacity.SetValue(crgtype, AIEngine.GetCapacity(this.engine_id));
		cEngineLib._cel_ebase[this.engine_id] <- this;
		if (AIEngine.GetVehicleType(this.engine_id) == AIVehicle.VT_RAIL && !AIEngine.IsWagon(this.engine_id))	cEngineLib.SetRailTypeSpeed(this.engine_id);
		cEngineLib.DirtyEngineCache(AIEngine.GetVehicleType(this.engine_id));
		return true;
	}

	function cEngineLib::EngineIsKnown(engine_id)
	// return true if engine is already test
	{
		local obj = cEngineLib.Load(engine_id);
		if (obj == null)	return false;
		if (obj.is_known == 0)	return false;
		if (AIEngine.GetVehicleType(obj.engine_id) != cEngineLib.VT_RAIL)	return true;
		if (obj.is_known == 2)	return true;
		return false;
	}

	function cEngineLib::GetKnownLevel(engine_id)
	// it return the is_iknown value
	{
		local obj = cEngineLib.Load(engine_id);
		if (obj == null)	return 2;
		return obj.is_known;
	}

	function cEngineLib::Filter_EngineTrain(engine_list, object)
	{
		if (engine_list.IsEmpty())	return;
		cEngineLib.EngineFilter(engine_list, object.cargo_id, object.engine_roadtype, object.engine_id, object.bypass);
		if (engine_list.IsEmpty())	return;
		if (AIEngine.IsWagon(engine_list.Begin()))	engine_list.Valuate(cEngineLib.GetCapacity, object.cargo_id);
											else	engine_list.Valuate(AIEngine.GetMaxSpeed);
		engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	}

	function cEngineLib::Filter_EngineGeneric(engine_list, object)
	{
		cEngineLib.EngineFilter(engine_list, object.cargo_id, object.engine_roadtype, object.engine_id, false);
		engine_list.Valuate(AIEngine.GetMaxSpeed);
		engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	}

	function cEngineLib::GetCallbackResult(callback, callback_param)
	// return the best engine as return by the callback
	{
		callback(callback_param[0], callback_param[1]);
		local back = callback_param[0];
		if (back.IsEmpty())	return -1;
		return back.Begin();
	}

	function cEngineLib::EngineToName(engID)
	// return the engine name with its id next to it.
	{
		local name = "#"+engID+" - ";
		if (AIEngine.IsValidEngine(engID))	name += AIEngine.GetName(engID);
									else	name += "invalid engine";
		return name;
	}

	function cEngineLib::CheckEngineObject(eo)
	// we autofill values we could grab for the object
	{
		if (eo.engine_id != -1 && !AIEngine.IsValidEngine(eo.engine_id))	eo.engine_id = -1;
		if (!AICargo.IsValidCargo(eo.cargo_id))	eo.cargo_id = -1;
		if (eo.depot != -1)
			{
			eo.engine_type = cEngineLib.GetDepotType(eo.depot);
			if (eo.engine_type != -1)
					{
					if (eo.engine_type == AIVehicle.VT_ROAD)	eo.engine_roadtype = AIRoad.HasRoadType(eo.depot, AIRoad.ROADTYPE_ROAD) ? AIRoad.ROADTYPE_ROAD : AIRoad.ROADTYPE_TRAM;
					if (eo.engine_type == AIVehicle.VT_RAIL)	eo.engine_roadtype = AIRail.GetRailType(eo.depot);
					}
			else	eo.depot = -1; // invalidate the depot
			}
		if (eo.engine_type != AIVehicle.VT_RAIL)	eo.engine_id = -1; // only rail could let us search with a specific engine_id, other will always use -1
		if (eo.engine_roadtype != -1 && eo.engine_type == AIVehicle.VT_AIR && eo.engine_roadtype != AIAirport.PT_HELICOPTER && eo.engine_roadtype != AIAirport.PT_SMALL_PLANE && eo.engine_roadtype != AIAirport.PT_BIG_PLANE)	eo.engine_roadtype = -1;
	}

	function cEngineLib::GetMoney(amount)
	// this is the internal function that will call the user callback function to get more money
	{
		if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) >= amount)	return true;
        local callback = cEngineLib._cel_config[2];
        if (callback == null)	return false;
        callback(amount);
        return (AICompany.GetBankBalance(AICompany.COMPANY_SELF) >= amount);
	}




/** @brief The class to create object that could be use by cEngineLib.GetBestEngine()
 *  ie: local myobject = cEngineLib.Infos(); myobject.engine_id = 34; local result = cEngineLib.GetBestEngine(myobject);
 */
class	cEngineLib.Infos
{
	engine_id 		= null;	/**< The engine_id to use, -1 to guess the engine */
	engine_type 	= null;	/**< The engine_type to use */
	engine_roadtype = null;	/**< The roadtype to use */
	depot			= null;	/**< The depot to use, keep it to -1 to get non real results */
	cargo_id		= null;	/**< The cargoID to use, -1 to get default cargo */
	bypass			= null;	/**< See cEngineLib.CanPullCargo() for its usage */

	constructor()
		{
		this.engine_id = -1;
		this.engine_type = -1;
		this.engine_roadtype = -1;
		this.depot = -1;
		this.cargo_id = -1;
		this.bypass = false;
		}
}
