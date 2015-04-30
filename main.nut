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

enum ENGINETYPE {
	RAIL,/**< use to get an ailist with rails engine */
	ROAD,/**< use to get an ailist with road engine */
	WATER,/**< use to get an ailist with water engine */
	AIR,/**< use to get an ailist with air engine */
	RAILWAGON,/**< use to get an ailist with only wagons engine */
	RAILLOCO/**< use to get an ailist with only locos engine */
}

/** @class cEngineLib
 *  @brief A library with helpers for engine and vehicle handling.
 */
class  cEngineLib extends AIEngine
{

	static	enginedatabase = {};
	static	EngineBL = AIList();
	static	RailType = AIList();	/**< item = the railtype, value = maximum speed doable */
	static	APIConfig = [false,""];	/**< hold configuration options and error message, you have functions to alter that. */
	static	eng_cache = [null, null, null, null, null, null]; /**< we cache enginelist result here */

	engine_id		= null;	/**< id of the engine */
	cargo_capacity	= null;	/**< capacity per cargo item=cargoID, value=capacity when refit */
	cargo_price		= null;	/**< price to refit item=cargoID, value=refit cost */
	cargo_length	= null;	/**< that's the length of a vehicle depending on its current cargo setting */
	is_known		= null;	/**< -1 never seen that engine, -2 tests were made (but any other value except -1 is ok) */
	usuability		= null;	/**< compatibility list of wagons & locos, item=the other engine value=state : -1 incompatible, 1 compatible */

	constructor()
		{
		engine_id		= null;
		cargo_capacity	= AIList();
		cargo_price		= AIList();
		cargo_length	= AIList();
		is_known		= -1;
		usuability		= AIList();
		}

	  // ********************** //
	 // PUBLIC FUNCTIONS - API //
	// ********************** //

	/**
	 * That's the library key function, this update properties of engines by looking at a real vehicle
     * This function should be called after a vehicle creation, so the database is fill with proper values, increasing accuracy of any other queries.
	 * Per example if you use the included VehicleCreate function, this one is added in it already.
	 * @param veh_id a valid vehicle_id that we will browse to catch information about engine
	 */
	function VehicleUpdateEngineProperties(veh_id) {}

	/**
	 * This function autocreate vehicle (if need and allowed), check them, sell them and return the best vehicle (using the filter and valuator you wish). If you don't provide your own function, two defaults functions will be use, one for speed on locomotive only, and one for capacity on any other engines.
	 * As this function could use your money, you MUST make sure the AI have enough money to buy stuff. This library doesn't handle loan itself.
	 * @param object
	 * Here's the different options :
	 * - object.depot : if valid, put a restriction to rail/road type. Really tests engines (and cost money). If -1 get theorical results only (accuracy depend on how many times the GetBestEngine has been run with a valid depot and new engine avaiability).
	 * - object.engine_id : if it's a wagon engine : restrict to find a locomotive that can pull this wagon.
	 *                    if it's a locomotive : restrict to find a wagon that could be use with that locomotive.
	 *                    if set to -1 : allow finding best locomotive & wagon couple.
	 * - object.engine.id : unused if not VT_RAIL
	 * - object.engine_type : if depot = -1 this must be set as AIVehicle.VehicleType
	 * - object.bypass : only use with VT_RAIL. true or false. Set it true to bypass ai_special_flag (see CanPullCargo).
	 * - object.cargo_id : must be set with a valid cargo
	 * - object.engine_roadtype : put a theorical restriction to rail/road type to use. Not used when object.depot is valid.
	 * @param filter A function that will be called to apply your own filter and heuristic on the engine list. If null a private function will be used.
	 *               The function must be : function myfilter(AIList, object)
     *               For VT_RAIL that function will be called with two different list, 1 for locomotive, and 2nd for the wagon. So be sure to check if IsWagon(object.engine_id) to see if you work for a train or a wagon.
	 * @return An array with the best engines : [0]= -1 not found, [0]=engine_id water/air/road, rail : [0]=loco_id [1]=wagon_id [2] railtype
	 */
	function GetBestEngine(object, filter);

	/**
	 * Change an ailist to filter out engine (so watchout what ailist you gives, it will get change)
     * Default filters are : remove blacklist engine, remove unbuildable, remove incompatible engine, other filters are optionals.
	 * @param engine_list an ailist of engine id
	 * @param cargo_id if -1 don't filter, if set, filter engines that cannot be refit to use that cargo (or pull other engines using that cargo)
	 * @param road_type : if -1 don't filter, if set, filter engines that cannot be use (no power or can't run on it) with that road type
	 * @param engine_id : if -1 don't filter, if it's a wagon filter train that cannot pull it, if it's a train filter wagons unusuable with it
	 * @param bypass : alter the cargo&train filter decision : see CanPullCargo bypass value for more
	 */
	function EngineFilter(engine_list, cargo_id, road_type, engine_id, bypass);

	/**
	 * Create the vehicle at depot, upto you to add orders... It's internally use, but as you may like use it too, it's public
	 * As this function use your money, you MUST make sure the AI have enough money to buy stuff. This library doesn't handle loan itself.
	 * @param depot a depot to use to create the vehicle
	 * @param engine_id the engine to create the vehicle
	 * @param cargo_id if set to -1 you get just the vehicle, otherwise the engine will be refit to handle the cargo
	 * @return vehileID of the new vehicle or -1 on error
	 */
	function VehicleCreate(depot, engine_id, cargo_id = -1);

	/**
	 * Get the length of an engine when refit to handle cargo_id type
	 * @param engine_id the engine id to query
	 * @param cargo_id the length of the engine when refit to that cargo, if -1 the length of the engine with its default cargo
	 * @return length of engine or null on error
	 */
	function GetLength(engine_id, cargo_id = -1);

	/**
	 * Get the capacity of an engine for that cargo type
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
	 * @param KW Per default the function return power in HP (like the AI API), if set to true, you will get the power in KW and the return value will be a real
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
	 * @return The maximum speed reachable by this rail vehicle. -1 on error.
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
	 * Look at the given vehicle, get its first loco engine and return true if you lack enough power (for original acceleration model) or tractive effort (for realistic model) to run that vehicle at low speed on hills (at 15% of its maxspeed)
	 * It handle the game setting "train_slope_steepness" (http://wiki.openttd.org/Train_slope_steepness)
	 * It handle the "train_accelaration_model", increase x2 the aim speed when original model is use. (http://wiki.openttd.org/Realistic_acceleration)
	 * @param vehicle_id The vehicle id of a rail vehicle
	 * @param aim_speed The calc are base on a train ability to aim a certain mimimum speed when climbing with its load, per default (0) the aim_speed will be 15% of maximum speed of the train engine (and a non-alterable minimum of 15spd). You can pass your own custom aim_speed to use.
	 * @return true if you should add more engine to that vehicle, -1 on error
	 */
	function VehicleLackPower(vehicle_id, aim_speed = 0);

	/**
	 * Get the number of wagons a vehicle have
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return 0 if not a train or without wagon, or the number of wagons in the vehicle
	 */
	function VehicleGetNumberOfWagons(vehicle_id);

	/**
	 * Get the position of a wagon in the train
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return -1 if not a train or no wagon. A place (position) with a wagon in that train
	 */
	function VehicleGetRandomWagon(vehicle_id);

	/**
	 * Mark engine_one and engine_two not compatible with each other
	 * This could only be seen with trains
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */
	function IncompatibleEngine(engine_one, engine_two);

	/**
	 * Mark engine_one and engine_two compatible with each other
	 * This could only be seen with trains
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */
	function CompatibleEngine(engine_one, engine_two);

	/**
	 * Check if engine1 is usable with engine2. For trains/wagons only.
	 * @param engine engine id of the first engine
	 * @param compare_engine engine id of the second engine
	 * @return true if you can use them, if we never check their compatibilities, it will return true
	 */
	function AreEngineCompatible(engine, compare_engine);

	/**
	 * Test compatibilty of a wagon engine with the vehicle. For rails vehicle only. This autofill compatibilty state of both engines.
	 * @param vehicleID a valid vehicle, stopped in a depot, with a locomotive in it
	 * @param wagonID  the engine wagon type to test.
	 * @return true if test succeed, false if test fail for some reason.
	 */
	function WagonCompatibilityTest(vehicleID, wagonID, cargoID);

	/**
	 * Get the cost of an engine, including cost to refit the engine to handle cargo_id
	 * @param engine_id The engine to get the cost
	 * @param cargo_id The cargo you will use that engine with, if -1 the price of vehicle without refit
	 * @return The cost or 0 on error
	 */
	function GetPrice(engine_id, cargo_id = -1);

	/**
	 * Check if the engine can pull a wagon with the given cargo. Exactly the same as AIEngine.CanPullCargo if the bypass is set to false
	 * The ai_special_flag (nfo property 08) for newGRF is set if an engine can pull a cargo or not. But the newGRF can also allow/disallow what couple cargo/engine you are allowed to use.
     * So, if the newGRF didn't disallow cargo/engine couple, but have its ai_special_flag set to disallow that, we could ignore it and pull the cargo we wish (as long as some compatible wagons exist to carry it). That's what the bypass param is for.
     * This can be use as valuator
	 * @param engine_id The engine to check
	 * @param cargo_id The cargo to check
	 * @param bypass Set to false to respect newGRF author wishes, set it to true to allow bypassing the ai_special_flag
	 * @return true or false
	 */
	function CanPullCargo(engine_id, cargo_id, bypass = false);

	/**
	 * Return if that engine is blacklist or not
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
	 * This will browse railtype and return the railtype that can reach the fastest speed or the fastest railtype a given engine could use
	 * @param engineID the engineID to get its best railtype to use with it, if -1 get the current fastest railtype
	 * @return -1 if no railtype is found
	 */
	function RailTypeGetFastestType(engineID = -1);

	/**
	 * Return the speed of the given railtype, so to get the speed of the fastest current railtype, cEngineLib.RailTypeGetSpeed(cEngineLib.RailTypeGetFastestType());
	 * @param RT The RailType to get the speed, if -1 we will return the fastest one.
	 * @return -1 if no railtype is found
	 */
	function RailTypeGetSpeed(RT = -1);

	/**
	 * This restrict a train length to met max_length, selling wagons only to met it
	 * @param vehicle_id A train with wagons you want to limit its length
	 * @param max_length The length to match : don't forget to x16 it if you aim a tile length: ie: limit to 3 tiles, max_length = 3*16
	 * @return -1 if no change were made (because unneed or errors), else return the number of wagons removed
	 */
	function VehicleRestrictLength(vehicle_id, max_length);

	/**
	 * Get the number of wagons we could add to stay below max_length. This may return inacurate results if the wagon or loco was never built.
	 * @param engines an array with [0] the loco engine, and [1] the wagon engine. Accept also the array return by GetBestEngine function
	 * @param max_length The length to match : don't forget to x16 it if you aim a tile length: ie: limit to 3 tiles, max_length = 3*16
	 * @param cardo_id the cargo the wagon will use (default cargo if set to -1).
	 * @return -1 on error, else return the maximum number of wagons usable with that length limit (don't forget to count also your loco length).
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
	 * This will browse engines so they are all added to the engine database, faster next access to any engine properties.
	 * If you want use this, it should be called early in your AI, else its usage will get poorer while the API fill the database itself.
	 */
	function EngineCacheInit();

	/**
	 * This will dirty the cache of eng_type, forcing next access to the cache to sent fresh infos. Use it when engine list has change (new engine appears...)
	 * The cache itself has a 7 openttd days lifetime ; but in case you don't wish to get a list 7 days old.
	 * @param eng_type The engine type of cache to dirty. See GetEngineList for valid values.
	 */
	function DirtyEngineCache(eng_type);

	/**
	 * Return a cached AIList of engines of the type "eng_type". Faster access to the very same list (less than 1 tick) and lesser this bug: http://bugs.openttd.org/task/6213
	 * @param eng_type It could of type ENGINETYPE (see the enum at start of the lib) or AIVehicle.VehicleType (see http://noai.openttd.org/docs/trunk/classAIVehicle.html#cd95d6af61dddf43617178576d2e90a6), when you use AIVehicle.VT_RAIL's list it will also populate ENGINETYPE.RAILWAGON & ENGINETYPE.RAILLOCO lists, which are shorten rail engines lists with only wagons for the first and only locos for the second. So if you want a rail list of engines to find only wagons in it, just set eng_type to ENGINETYPE.RAILWAGON and you will get only a list of wagons. This could replace occurances of AIEngineList() in your code.
	 * @return an AIList of engines of the eng_type type, on error you will get an empty AIList.
	 */
	function GetEngineList(eng_type);

}

	function cEngineLib::VehicleUpdateEngineProperties(veh_id)
	{
		if (!AIVehicle.IsValidVehicle(veh_id))	return;
		local vtype = AIVehicle.GetVehicleType(veh_id);
		local new_engine = AIVehicle.GetEngineType(veh_id);
		if (vtype == AIVehicle.VT_RAIL && AIVehicle.GetNumWagons(veh_id) > 1) return;
		local engObj = cEngineLib.Load(new_engine);
		if (engObj == null || cEngineLib.EngineIsKnown(new_engine))	return;
		local crgList = AICargoList();
		foreach (cargoID, _ in crgList)
			{
			local testing = AIVehicle.GetRefitCapacity(veh_id, cargoID);
			if (testing < 0)	testing = 0;
			engObj.cargo_capacity.SetValue(cargoID, testing);
			engObj.cargo_length.SetValue(cargoID, AIVehicle.GetLength(veh_id));
			if (testing > 0)
					{
					local refit_account = AIAccounting();
					local test_mode = AITestMode(); // try save poor AI money
					local refitted = AIVehicle.RefitVehicle(veh_id, cargoID);
					test_mode = null;
					if (!refitted)	continue;
					engObj.cargo_price.SetValue(cargoID, refit_account.GetCosts());
					refit_account = null;
					}
			}
		engObj.is_known = -2;
	}

	function cEngineLib::GetBestEngine(object, filter)
	{
		local isobject = object instanceof cEngineLib.Infos;
		local error = []; error.push(-1);
		if (!isobject)	{ cEngineLib.ErrorReport("object must be a cEngineLib.Infos instance"); return error; }
		cEngineLib.CheckEngineObject(object);
		if (object.cargo_id == -1)	{ cEngineLib.ErrorReport("cargo_id must be a valid cargo"); return error; }
		if (object.depot == -1 && object.engine_type == -1)	{ cEngineLib.ErrorReport("object.engine_type must be set when the depot doesn't exist"); return error; }
		local all_engineList = cEngineLib.GetEngineList(object.engine_type);
		local filter_callback = cEngineLib.Filter_EngineGeneric;
		local filter_callback_params = [];
		if (object.engine_type == AIVehicle.VT_RAIL)	filter_callback = cEngineLib.Filter_EngineTrain;
		filter_callback_params.push(all_engineList);
		filter_callback_params.push(object);
		if (filter != null)
					{
					if (typeof(filter) != "function")	{ cEngineLib.ErrorReport("filter must be a function"); return error; }
					filter_callback = filter;
					}
		local result = [];
		// prepare trains work
		local oTrain, oWagon, train_list, wagon_list, filter_callback_train, filter_callback_wagon;
		if (object.engine_type == AIVehicle.VT_RAIL)
			{
			oTrain = cEngineLib.Infos();
			oWagon = cEngineLib.Infos();
			oWagon.depot = object.depot;
			oWagon.cargo_id = object.cargo_id;
			oWagon.engine_type = AIVehicle.VT_RAIL;
			oWagon.bypass = object.bypass;
			cEngineLib.CheckEngineObject(oWagon);
			oTrain.depot = object.depot;
			oTrain.cargo_id = object.cargo_id;
			oTrain.engine_type = AIVehicle.VT_RAIL;
			oTrain.bypass = object.bypass;
			cEngineLib.CheckEngineObject(oTrain);
			train_list = cEngineLib.GetEngineList(ENGINETYPE.RAILLOCO);
			wagon_list = cEngineLib.GetEngineList(ENGINETYPE.RAILWAGON);
			filter_callback_train = [];
			filter_callback_train.extend(filter_callback_params);
			filter_callback_wagon = [];
			filter_callback_wagon.extend(filter_callback_params);
			filter_callback_train[0] = train_list;
			filter_callback_train[1] = oTrain;
			filter_callback_wagon[0] = wagon_list;
			filter_callback_wagon[1] = oWagon;
			if (cEngineLib.RailType.IsEmpty())	{ cEngineLib.ErrorReport("No railtype can be found."); return error; }
			}
		if (object.depot == -1) // theorical results
			{
			if (object.engine_type != AIVehicle.VT_RAIL)
				{
				result.push(cEngineLib.GetCallbackResult(filter_callback, filter_callback_params));
				return result;
				}
			if (object.engine_id != -1)
					{
					local back = null;
					if (AIEngine.IsWagon(object.engine_id))
							{ // find a train to pull that wagon
							oTrain.engine_id = object.engine_id;
							oTrain.engine_roadtype = cEngineLib.RailTypeGetFastestType(object.engine_id);
							back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
							if (back != -1)	{ result.push(back); result.push(object.engine_id); result.push(oTrain.engine_roadtype); return result; }
									else	{
											cEngineLib.ErrorReport("No train that can pull that wagon : "+cEngineLib.EngineToName(object.engine_id));
											return error;
											}
							}
					else	{ // find a wagon for that train
							oWagon.engine_id = object.engine_id;
							oWagon.engine_roadtype = cEngineLib.RailTypeGetFastestType(object.engine_id);
							back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
							if (back != -1)	{ result.push(object.engine_id); result.push(back); result.push(oWagon.engine_roadtype); return result; }
									else	{
											cEngineLib.ErrorReport("No wagon that we could use with that train : "+cEngineLib.EngineToName(object.engine_id));
											return error;
											}
							}
					}
			// theory, train, no engine set : find loco+wagons and maybe railtype
			local confirm = false;
			local save_train_list = AIList();
			local save_wagon_list = AIList();
			local railtype_list = AIList();
			local search_loco = -1;
			local search_wagon = -1;
			if (object.engine_roadtype == -1)	{
												railtype_list.AddList(cEngineLib.RailType);
												railtype_list.Sort(AIList.SORT_BY_VALUE, false);
												}
										else	railtype_list.AddItem(object.engine_roadtype,0);
			save_train_list.AddList(train_list);
			save_wagon_list.AddList(wagon_list);
			foreach (RT, _ in railtype_list) // they are sort by first = fastest, last = slowest
				{
				oTrain.engine_roadtype = RT;
				train_list.AddList(save_train_list); // else list of trains may be too short as a call will lower the list
				search_loco = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
				if (search_loco != -1) // found the best train using that railtype
					{
					oWagon.engine_roadtype = RT;
					oWagon.engine_id = search_loco;
					wagon_list.AddList(save_wagon_list);
					search_wagon = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
					if (search_wagon != 1) // found a good wagon to use with it
						{
						result.push(search_loco);
						result.push(search_wagon);
						result.push(RT);
						return result;
						}
					}
				} // foreach
			cEngineLib.ErrorReport("Coudn't find a matching train and wagon to use");
			return error;
			}

		// real results
		if (object.engine_type != AIVehicle.VT_RAIL)
				{ // the easy part first, non rail engines
				local bestEngine = cEngineLib.GetCallbackResult(filter_callback, filter_callback_params);
				if (cEngineLib.EngineIsKnown(bestEngine))	{ return [bestEngine]; } // Already tested no need to redo them
				local confirm = false;
				if (bestEngine == -1)	{ cEngineLib.ErrorReport("Couldn't find any engine: filter too hard, lack of engine available..."); return error; }
				while (!confirm)
						{
						local vehID = cEngineLib.VehicleCreate(object.depot, bestEngine, object.cargo_id);
						if (vehID == -1)	confirm = true;	 // maybe we run out of money, keep the current one
									else	AIVehicle.SellVehicle(vehID); // discard the test vehicle
						local another = cEngineLib.GetCallbackResult(filter_callback, filter_callback_params);
						if (another == bestEngine)		confirm = true;
												else	bestEngine = another;
						}
				object.engine_id = bestEngine;
				cEngineLib.CheckEngineObject(object);
				result.push(bestEngine);
				return result;
				}
		// the trains
		if (object.engine_id != -1)
				{ // apply a constrain, user want a fixed wagon engine or a loco
				if (AIEngine.IsWagon(object.engine_id))
							{
							wagon_list.Clear();
							wagon_list.AddItem(object.engine_id,0);
							oTrain.engine_id = object.engine_id;
							}
					else	{
							train_list.Clear();
							train_list.AddItem(object.engine_id,0);
							oWagon.engine_id = object.engine_id;
							}
				}
		local bestLoco = -1;
		local bestWagon = -1;
		local loco, wagon = null;
		local altLoco = -1;
		local altWagon = -1;
		local train_end = false;
		local train_exist = false;
		local wagon_exist = false;
		local wagon_end = false;
		local giveup = false;
		local is_error = false;
		local need_looping = false;
		local bad_wagon = false;
		local save_train_list = AIList();
		local save_wagon_list = AIList();
		local train_tested = AIList();
		save_train_list.AddList(train_list);
		save_wagon_list.AddList(wagon_list);
		while (!giveup)
			{
			train_list.AddList(save_train_list);
			train_list.RemoveList(train_tested);
			bestLoco = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
			if (bestLoco == -1)	{ // no more trains to try
								cEngineLib.ErrorReport("Cannot find any train engine usable with "+cEngineLib.EngineToName(object.engine_id));
								is_error = true;
								}
			if (train_exist && !is_error && AIVehicle.GetEngineType(loco) != bestLoco)
						{ // the current built isn't the good one selected now
						AIVehicle.SellVehicle(loco);
						train_exist = false;
						}
			if (!train_exist && !is_error)
						{
						loco = cEngineLib.VehicleCreate(object.depot, bestLoco, object.cargo_id);
						train_exist = AIVehicle.IsValidVehicle(loco);
						if (!train_exist)	{ cEngineLib.ErrorReport("Cannot create the train engine : "+cEngineLib.EngineToName(bestLoco)+" > "+AIError.GetLastErrorString()); is_error = true; } // cannot be built, lack money...
						}
			if (!is_error)
				{
				wagon_list.AddList(save_wagon_list);
				oWagon.engine_id = bestLoco;
				bad_wagon =false;
				bestWagon = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
				if (bestWagon == -1)
						{ // no more wagons to try, give up.
						cEngineLib.ErrorReport("Cannot find any wagon engine usable with "+cEngineLib.EngineToName(object.engine_id));
						is_error = true;
						}
				else	{
						if (!cEngineLib.IsCoupleTested(bestLoco, bestWagon))
								{
								is_error = !cEngineLib.VehicleWagonCompatibilityTest(loco, bestWagon, object.cargo_id);
								}
						else	{ giveup = true; } // no need to continue, we got the couple
						}
				}
			if (is_error) giveup = true;
			} // while (!giveup)
		if (train_exist)	AIVehicle.SellVehicle(loco);
		if (wagon_exist)	AIVehicle.SellVehicle(wagon);
		if (is_error)	result.push(-1);
				else	{
						result.push(bestLoco);
						result.push(bestWagon);
						result.push(object.engine_roadtype);
						}
		return result;
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
				if (road_type != -1 && (engine_type == AIVehicle.VT_RAIL || engine_type == AIVehicle.VT_ROAD))
					{ // apply filter if we need a special road type
					if (engine_type == AIVehicle.VT_RAIL)
							{
							// Until prove false, HasPowerOnRail do a better job than CanRunOnRail : no diff with wagon if it can run on a rail, it has power on it
							// While some loco may run on rail but with no power
							engine_list.Valuate(AIEngine.HasPowerOnRail, road_type);
							engine_list.KeepValue(1);
							if
							}
					else	{ // a road engine
							engine_list.Valuate(AIEngine.GetRoadType);
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
								if (AIEngine.IsWagon(engine_list.Begin()) == false)	{ engine_list.Valuate(cEngineLib.CanPullCargo, cargo_id, bypass); }
																			else	{ engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id); }
								engine_list.KeepValue(1);
								}
					if (engine_type != AIVehicle.VT_RAIL)	{ engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id); engine_list.KeepValue(1); }
					}
				}
	}

	function cEngineLib::VehicleCreate(depot, engine_id, cargo_id = -1)
	{
		if (!AIEngine.IsValidEngine(engine_id))	return -1;
		if (!cEngineLib.IsDepotTile(depot))	return -1;
		local vehID = AIVehicle.BuildVehicle(depot, engine_id);
		if (!AIVehicle.IsValidVehicle(vehID))	return -1;
		cEngineLib.VehicleUpdateEngineProperties(vehID);
		if (cargo_id == -1)	return vehID;
		if (!AICargo.IsValidCargo(cargo_id) || !AIEngine.CanRefitCargo(engine_id, cargo_id))	return vehID;
		if (!AIVehicle.RefitVehicle(vehID, cargo_id))	{ AIVehicle.SellVehicle(vehID); return -1; }
		return vehID;
	}

	function cEngineLib::GetLength(engine_id, cargo_id = -1)
	{
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
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ return -1; }
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
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ return -1; }
		local total_power = 0;
        local numpart = AIVehicle.GetNumWagons(vehicle_id);
		for (local i = 0; i < numpart; i++)
				{
				local engine = AIVehicle.GetWagonEngineType(vehicle_id, i);
				if (AIEngine.GetVehicleType(vehicle_id) == AIVehicle.VT_ROAD || cEngineLib.IsLocomotive(engine))	{ total_power += AIEngine.GetPower(engine); }
				// don't check IsLocomtive first as engine might be invalid if it's a ROAD vehicle
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
		if (!AIVehicle.IsValidVehicle(vehicle_id))	{ return -1; }
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
		if (!AIEngine.IsValidEngine(engine_id))	{ return false; }
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
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return -1;
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

	function cEngineLib::VehicleWagonCompatibilityTest(vehicleID, wagonID, cargoID)
	// return true if we test it, return false if we cannot manage to do the test (lack money...)
	{
		if (!AIVehicle.IsValidVehicle(vehicleID) || AIVehicle.GetVehicleType(vehicleID) != AIVehicle.VT_RAIL)	{ cEngineLib.ErrorReport("vehicleID must be a valid rail vehicle"); return false; }
		if (!AIEngine.IsBuildable(wagonID) || AIEngine.GetVehicleType(wagonID) != AIVehicle.VT_RAIL)	{ cEngineLib.ErrorReport("wagonID must be a valid buildable wagon engine"); return false; }
		if (!AICargo.IsValidCargo(cargoID))	{ cEngineLib.ErrorReport("carogID must be a valid cargo"); return false; }
		if (AIVehicle.GetState(vehicleID) != AIVehicle.VS_IN_DEPOT)	{ cEngineLib.ErrorReport("VehileID must be a vehicle stopped at a depot"); return false; }
		local depot = AIVehicle.GetLocation(vehicleID);
		local wagon = null;
		local goodresult = true;
		local locotype = AIVehicle.GetEngineType(vehicleID);
		wagon = cEngineLib.VehicleCreate(depot, wagonID, cargoID);
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

	function cEngineLib::GetPrice(engine_id, cargo_id = -1)
	{
		local eng = cEngineLib.Load(engine_id);
		if (eng == null)	return 0;
		if (cargo_id == -1)	return AIEngine.GetPrice(engine_id);
		if (!AICargo.IsValidCargo(cargo_id))	return AIEngine.GetPrice(engine_id);
		local refitcost = 0;
		if (eng.cargo_price.HasItem(cargo_id))	refitcost = eng.cargo_price.GetValue(cargo_id);
		return (AIEngine.GetPrice(engine_id)+refitcost);
	}

	function cEngineLib::CanPullCargo(engine_id, cargo_id, bypass = false)
	{
		if (!bypass)	return AIEngine.CanPullCargo(engine_id, cargo_id);
		if (!AICargo.IsValidCargo(cargo_id))	return false;
		if (!cEngineLib.IsLocomotive(engine_id))	return false;
		local wagonlist = cEngineLib.GetEngineList(ENGINETYPE.RAILWAGON);
		wagonlist.Valuate(AIEngine.CanRunOnRail, AIEngine.GetRailType(engine_id));
		wagonlist.KeepValue(1);
		wagonlist.Valuate(AIEngine.CanRefitCargo, cargo_id);
		wagonlist.KeepValue(1);
		wagonlist.Valuate(cEngineLib.AreEngineCompatible, engine_id);
		wagonlist.KeepValue(1);
		wagonlist.Valuate(cEngineLib.IsEngineBlacklist);
		wagonlist.KeepValue(0);
		wagonlist.Valuate(AIEngine.IsBuildable);
		wagonlist.KeepValue(1);
		return (!wagonlist.IsEmpty());
	}

	function cEngineLib::IsEngineBlacklist(engine_id)
	{
		return (cEngineLib.EngineBL.HasItem(engine_id));
	}

	function cEngineLib::BlacklistEngine(engine_id)
	{
		if (cEngineLib.IsEngineBlacklist(engine_id))	return;
		cEngineLib.EngineBL.AddItem(engine_id, 0);
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

	function cEngineLib::RailTypeGetFastestType(engineID = -1)
	{
		if (cEngineLib.RailType.IsEmpty())	return -1;
		cEngineLib.RailType.Sort(AIList.SORT_BY_VALUE, false);
		if (engineID == -1)	return cEngineLib.RailType.Begin();
		local train = cEngineLib.IsLocomotive(engineID);
		local top_rt = -1;
		local best_rt = -1;
		foreach (rt, spd in cEngineLib.RailType)
			{
			local res = -1;
			if (train)	res = AIEngine.HasPowerOnRail(engineID, rt);
				else	res = AIEngine.CanRunOnRail(engineID, rt);
			if (res && top_rt < spd)	{ top_rt = spd; best_rt = rt; }
			}
		return best_rt;
	}

	function cEngineLib::RailTypeGetSpeed(RT = -1)
	{
		if (cEngineLib.RailType.IsEmpty())	return -1;
		if (RT == -1)	{
						cEngineLib.RailType.Sort(AIList.SORT_BY_VALUE, false);
						RT = cEngineLib.RailType.Begin();
						}
		return cEngineLib.RailType.GetValue(RT);
	}

	function cEngineLib::VehicleRestrictLength(vehicle_id, max_length)
	{
		if (max_length <= 1)	return -1;
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return -1;
	    local removed = 0;
	    while (AIVehicle.GetLength(vehicle_id) > max_length)
				{
				local wagondelete = cEngineLib.VehicleGetRandomWagon(vehicle_id);
    	        if (wagondelete == -1)  return -1;
				if (!AIVehicle.SellWagon(vehicle_id, wagondelete))
						{
						cEngineLib.Error("Cannot delete that wagon : "+wagondelete);
						break;
						}
				else	{ removed++; }
				}
    	return removed;
	}

	function cEngineLib::GetMaxWagons(engines, max_length, cargo_id = -1)
	{
		if (typeof(engines) != "array" || engines.len() < 2)	{ cEngineLib.Error("engines must be an array"); return -1; }
		if (AIEngine.GetVehicleType(engines[0]) != AIVehicle.VT_RAIL || AIEngine.GetVehicleType(engines[1]) != AIVehicle.VT_RAIL)
			{
			cEngineLib.Error("Both engines must be of rail engines");
			return -1;
			}
		local t_len = cEngineLib.GetLength(engines[0], cargo_id);
		local w_len = cEngineLib.GetLength(engines[1], cargo_id);
		if (t_len == null || w_len == null)	return -1;
		max_length -= t_len;
		if (max_length < 1 || w_len == 0)	return 0; // shouldn't happen, but prevent div 0 on w_len
		max_length = max_length / w_len;
		return max_length;
	}

	function cEngineLib::SetAPIErrorHandling(output)
	{
		if (typeof(output) != "bool")	return;
		cEngineLib.APIConfig[0] = output;
	}

	function cEngineLib::GetAPIError()
	{
		return cEngineLib.APIConfig[1];
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
	if (eng_type < ENGINETYPE.RAIL || eng_type > ENGINETYPE.RAILLOCO)	{ return; }
	//local special = [ENGINETYPE.RAIL, ENGINETYPE.RAILWAGON, ENGINETYPE.RAILLOCO];
	if (eng_type == ENGINETYPE.RAIL || eng_type == ENGINETYPE.RAILLOCO || eng_type == ENGINETYPE.RAILWAGON)
								{ // the 3 are links
								cEngineLib.eng_cache[ENGINETYPE.RAIL] = null;
								cEngineLib.eng_cache[ENGINETYPE.RAILWAGON] = null;
								cEngineLib.eng_cache[ENGINETYPE.RAILLOCO] = null;
								}
						else	{ cEngineLib.eng_cache[eng_type] = null; }
	}

	function cEngineLib::GetEngineList(eng_type)
	{
	if (eng_type < ENGINETYPE.RAIL || eng_type > ENGINETYPE.RAILLOCO)	{ return AIList(); }
	local special = AIList();
	special.AddItem(ENGINETYPE.RAIL, 0);
	special.AddItem(ENGINETYPE.RAILWAGON, 0);
	special.AddItem(ENGINETYPE.RAILLOCO,0);
	local elist = cEngineLib.eng_cache[eng_type];
    local safelist = cEngineLib.eng_cache[eng_type]; // We don't want return our list pointer so anyone can alter its content while playing with it
	if (elist != null)
		{
		local now = AIDate.GetCurrentDate();
		local old = elist.GetValue(elist.Begin());
		if (special.HasItem(eng_type))	{ old = cEngineLib.eng_cache[ENGINETYPE.RAIL].GetValue(cEngineLib.eng_cache[ENGINETYPE.RAIL].Begin()); }
		if (now - old > 7*74)	{ cEngineLib.DirtyEngineCache(eng_type); elist = null; }
					else		{ elist = AIList(); elist.AddList(safelist); return elist; }
		}
	if (elist == null)
		{
		local vquery = eng_type;
		local railhandling = special.HasItem(eng_type);
		if (railhandling)	{ vquery = ENGINETYPE.RAIL; }
		safelist = AIEngineList(vquery);
		if (railhandling)
			{
            local wlist = AIList();
            local llist = AIList();
            wlist.AddList(safelist);
            llist.AddList(safelist);
            wlist.Valuate(AIEngine.IsWagon);
            wlist.KeepValue(1);
            llist.RemoveList(wlist);
            cEngineLib.eng_cache[ENGINETYPE.RAILWAGON] = wlist;
            cEngineLib.eng_cache[ENGINETYPE.RAILLOCO] = llist;
			}
		safelist.SetValue(safelist.Begin(), AIDate.GetCurrentDate());
		cEngineLib.eng_cache[vquery] = safelist;
		elist = AIList();
		elist.AddList(safelist);
		}
	return elist;
	}

	   // ****************** //
	  // PRIVATE FUNCTIONS  //
	 // ****************** //

	function cEngineLib::ErrorReport(error)
	// if allowed print the error. Also set last error string
	{
		cEngineLib.APIConfig[1] = "cEngineLib: "+error;
		if (cEngineLib.APIConfig[0])	AILog.Error(cEngineLib.APIConfig[1]);
	}

	function cEngineLib::SetUsuability(engine_one, engine_two, flags)
	// set the usuability flags off two engines
	{
		if (engine_one == null || engine_two == null)	return;
		if (AIEngine.GetVehicleType(engine_one) != AIVehicle.VT_RAIL)	return;
		if (AIEngine.GetVehicleType(engine_two) != AIVehicle.VT_RAIL)	return;
		local eng1 = cEngineLib.Load(engine_one);
		if (eng1 == null)	return;
		local eng2 = cEngineLib.Load(engine_two);
		if (eng2 == null)	return;
		if (!eng1.usuability.HasItem(engine_two))	eng1.usuability.AddItem(engine_two, 0);
		if (!eng2.usuability.HasItem(engine_one))	eng2.usuability.AddItem(engine_one, 0);
		eng1.usuability.SetValue(engine_two, flags);
		eng2.usuability.SetValue(engine_one, flags);
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
			if (!cEngineLib.RailType.HasItem(rt))	cEngineLib.RailType.AddItem(rt, 0);
			if (AIEngine.HasPowerOnRail(engineID, rt))
					{
					local rtop = rt_speed; // don't alter the ailist while looping it
					if (rtop == 0 || rtop > engine_speed)	rtop = engine_speed;
					if (cEngineLib.RailType.GetValue(rt) < rtop)	{ cEngineLib.RailType.SetValue(rt, rtop); }
					}
			}
	}

	function cEngineLib::Load(e_id)
	{
		local cobj = cEngineLib();
		cobj.engine_id = e_id;
		if (e_id in cEngineLib.enginedatabase)	 return cEngineLib.enginedatabase[e_id];
		if (!cobj.Save())	{ return null; }
		return cobj;
	}

	function cEngineLib::Save()
	{
		if (this.engine_id == null)	return false;
		if (!AIEngine.IsValidEngine(this.engine_id))	return false;
		if (this.engine_id in cEngineLib.enginedatabase)	return true;
		local crglist = AICargoList();
		foreach (crg, dummy in crglist)
			{
			this.cargo_length.AddItem(crg, 8); // default to 8, a classic length
			this.cargo_price.AddItem(crg, -1);
			// 2 reasons: make the engine appears cheaper vs an already test one & allow us to know if we met it already (see VehicleUpdateEngineProperties)
			if (AIEngine.CanRefitCargo(this.engine_id, crg))	this.cargo_capacity.AddItem(crg,255);
														else	this.cargo_capacity.AddItem(crg,0);
			// 255 so it will appears to be a bigger carrier vs an already test engine
			// These two properties set as-is will force the AI to think a non-test engine appears better
			}
		local crgtype = AIEngine.GetCargoType(this.engine_id);
		this.cargo_capacity.SetValue(crgtype, AIEngine.GetCapacity(this.engine_id));
		cEngineLib.enginedatabase[this.engine_id] <- this;
		if (AIEngine.GetVehicleType(this.engine_id) == AIVehicle.VT_RAIL && !AIEngine.IsWagon(this.engine_id))	cEngineLib.SetRailTypeSpeed(this.engine_id);
		cEngineLib.DirtyEngineCache(AIEngine.GetVehicleType(this.engine_id));
		return true;
	}

	function cEngineLib::EngineIsKnown(engine_id)
	// return true if engine is already test
	{
		local obj = cEngineLib.Load(engine_id);
		if (obj == null)	return false;
		if (obj.is_known != -1)	return true;
		return false;
	}

	function cEngineLib::Filter_EngineTrain(engine_list, object)
	{
		if (engine_list.IsEmpty())	return;
		cEngineLib.EngineFilter(engine_list, object.cargo_id, object.engine_roadtype, object.engine_id, false);
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
			else eo.depot = -1; // invalidate the depot
			}
		if (eo.engine_type != AIVehicle.VT_RAIL)	eo.engine_id = -1; // only rail could let us search with a specific engine_id, other will always use -1
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
