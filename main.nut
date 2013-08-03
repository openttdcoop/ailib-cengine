/* -*- Mode: C++; tab-width: 4 -*- */ 
/*
    This file is part of the AI library cEngineLib
    Copyright (C) 2013  krinn@chez.com

    cEngineLib is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or any later version.

    cEngineLib is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this AI Library. If not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

class cEngineLib extends AIEngine
{
	static	enginedatabase = {};
	static	EngineBL = AIList();
	static	RailType = AIList();	// item = the railtype, value = maximum speed doable
	static	APIConfig = [false,""];	// hold configuration options and error message, you have functions to alter that.

	engine_id		= null;	// id of the engine
	cargo_capacity	= null;	// capacity per cargo item=cargoID, value=capacity when refit
	cargo_price		= null;	// price to refit item=cargoID, value=refit cost
	cargo_length	= null;	// that's the length of a vehicle depending on its current cargo setting
	is_known		= null;	// -1 seen that engine, -2 tests already made
	usuability		= null;	// compatibility list of wagons & locos, item=the other engine value=state : -1 incompatible, 1 compatible
	
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

	function UpdateEngineProperties(veh_id)
	/**
	 * That's the library key function, this update properties of engines by looking at a real vehicle
     * This function should be called after a vehicle creation, so the database is fill with proper values, increasing accuracy of any other queries.
	 * Per example if you use the included CreateVehicle function, this one is added in it already.
	 * @param veh_id a valid vehicle_id that we will browse to catch information about engine
	 */

	function GetBestEngine(object, filter)
	/**
	 * This function autocreate vehicle (if need and allowed), check them, sell them and return the best vehicle (using the filter and valuator you wish). If you don't provide your own function, two defaults functions will be use, one for speed on locomotive only, and one for capacity on any other engines.
	 * As this function could use your money, you MUST make sure the AI have enough money to buy stuff. This library doesn't handle loan itself.
	 * Here's the different effects :
	 * object.depot : if valid, put a restriction to rail/road type. Really tests engines (and cost money). If -1 get theorical results only (accuracy depend on how many times the GetBestEngine has been run with a valid depot and new engine avaiability).
	 * object.engine_id : if it's a wagon engine : restrict to find a locomotive that can pull this wagon.
	 *                    if it's a locomotive : restrict to find a wagon that could be use with that locomotive.
	 *                    if set to -1 : allow finding best locomotive & wagon couple.
	 * object.engine.id : unused if not VT_RAIL
	 * object.engine_type : if depot = -1 this must be set as AIVehicle.VehicleType
	 * object.bypass : only use with VT_RAIL. true or false. Set it true to bypass ai_special_flag (see CanPullCargo).
	 * object.cargo_id : must be set with a valid cargo
	 * object.engine_roadtype : put a theorical restriction to rail/road type to use. Not used when object.depot is valid.
	 * @param filter A function that will be called to apply your own filter and heuristic on the engine list. If null a private function will be used.
	 *               The function must be : function myfilter(AIList, object)
     *               For VT_RAIL that function will be called with two different list, 1 for locomotive, and 2nd for the wagon. So be sure to check if IsWagon(object.engine_id) to see if you work for a train or a wagon.
	 * @return An array with the best engines : [0]= -1 not found, [0]=engine_id water/air/road, rail : [0]=loco_id [1]=wagon_id [2] railtype
	 */

	function EngineFilter(engine_list, cargo_id, road_type, engine_id, bypass) {}
	/**
	 * Change an ailist to filter out engine (so watchout what ailist you gives, it will get change)
     * Default filters are : remove blacklist engine, remove unbuildable, remove incompatible engine, other filters are optionals.
	 * @param engine_list an ailist of engine id
	 * @param cargo_id if -1 don't filter, if set, filter engines that cannot be refit to use that cargo (or pull other engines using that cargo)
	 * @param road_type : if -1 don't filter, if set, filter engines that cannot be use (no power or can't run on it) with that road type
	 * @param engine_id : if -1 don't filter, if it's a wagon filter train that cannot pull it, if it's a train filter wagons unusuable with it
	 * @param bypass : alter the cargo&train filter decision : see CanPullCargo bypass value for more
	 */

	function CreateVehicle(depot, engine_id, cargo_id = -1) {}
	/**
	 * Create the vehicle at depot, upto you to add orders... It's internally use, but as you may like use it too, it's public
	 * As this function use your money, you MUST make sure the AI have enough money to buy stuff. This library doesn't handle loan itself.
	 * @param depot a depot to use to create the vehicle
	 * @param engine_id the engine to create the vehicle
	 * @param cargo_id if set to -1 you get just the vehicle, otherwise the engine will be refit to handle the cargo
	 * @return vehileID of the new vehicle or -1 on error
	 */

	function GetLength(engine_id, cargo_id = -1) {}
	/**
	 * Get the length of an engine when refit to handle cargo_id type
	 * @param engine_id the engine id to query
	 * @param cargo_id the length of the engine when refit to that cargo, if -1 the length of the engine with its default cargo
	 * @return length of engine or null on error
	 */

	function GetCapacity(engine_id, cargo_id = -1) {}
	/**
	 * Get the capacity of an engine for that cargo type
	 * @param engine_id The engine to get the capacity of
	 * @param cargo_id If -1, it's the current refit cargo, else the cargo id to get the capacity for.
	 * @return the capacity, 0 if the cargo is not support or on error
	 */

	function IsLocomotive(engine_id) {}
	/**
	 * Check if an engine is a locomotive
	 * @param engine_id the engine to check
	 * @return True if it's a locomotive, false if not or invalid...
	 */

	function GetNumberOfLocomotive(vehicle_id) {}
	/**
	 * Get the number of locomotive a vehicle have
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return 0 if no locomotive/not a train, or the number of locomotive in the vehicle
	 */

	function GetNumberOfWagons(vehicle_id) {}
	/**
	 * Get the number of wagons a vehicle have
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return 0 if not a train or without wagon, or the number of wagons in the vehicle
	 */

	function GetWagonFromVehicle(vehicle_id) {}
	/**
	 * Get the position of any wagon in the train
	 * @param vehicle_id the vehicle to check, must be a rail vehicle
	 * @return -1 if not a train or no wagon. A place (position) with a wagon in the train
	 */

	function IncompatibleEngine(engine_one, engine_two) {}
	/**
	 * Mark engine_one and engine_two not compatible with each other
	 * This could only be seen with trains
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */

	function CompatibleEngine(engine_one, engine_two) {}
	/**
	 * Mark engine_one and engine_two compatible with each other
	 * This could only be seen with trains
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */

	function AreEngineCompatible(engine, compare_engine) {}
	/**
	 * Check if engine1 is usable with engine2. For trains/wagons only.
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 * @return true if you can use them, if we never check their compatibilities, it will return true
	 */

	function WagonCompatibilityTest(vehicleID, wagonID, cargoID) {}
	/**
	 * Test compatibilty of a wagon engine with the vehicle. For rails vehicle only. This autofill compatibilty state of both engines.
	 * @param vehicleID a valid vehicle, stopped in a depot, with a locomotive in it
	 * @param wagonID  the engine wagon type to test.
	 * @return true if test succeed, false if test fail for some reason.
	 */

	function GetPrice(engine_id, cargo_id = -1)	{}
	/**
	 * Get the cost of an engine, including cost to refit the engine to handle cargo_id
	 * @param engine_id The engine to get the cost
	 * @param cargo_id The cargo you will use that engine with, if -1 the price of vehicle without refit
	 * @return The cost or 0 on error
	 */

	function CanPullCargo(engine_id, cargo_id, bypass = false) {}
	/**
	 * Check if the engine can pull a wagon with the given cargo. Exactly the same as AIEngine.CanPullCargo if the bypass is set to false
	 * The ai_special_flag (nfo property 08) for newGRF set if an engine can pull a cargo or not. But the newGRF can also allow/disallow what couple cargo/engine you are allowed to use.
     * So, if the newGRF didn't disallow cargo/engine couple, but have its ai_special_flag set to disallow that, we could ignore it and pull the cargo we wish (as long as some compatible wagons exist to carry it). That's what the bypass param is for.
     * This can be use as valuator
	 * @param engine_id The engine to check
	 * @param cargo_id The cargo to check
	 * @param bypass Set to false to respect newGRF author wishes, set it to true to allow bypassing the ai_special_flag
	 * @return true or false
	 */

	function IsEngineBlacklist(engine_id)	{}
	/**
	 * Return if that engine is blacklist or not
	 * @param engine_id The engine to get check
	 * @return True if engine is blacklist, false
	 */

	function BlacklistEngine(engine_id)	{}
	/**
	 * Add an engine to the blacklist
	 * @param engine_id The engine to get blacklist
	 */

	function IsDepotTile(tile)	{}
	/**
	 * Check if the tile is a depot
	 * @param tile a valid tile
	 * @return true if tile is a valid depot of any type, false if not
	 */

	function EngineCacheInit()	{}
	/**
	 * This will browse engines so they are all added to the engine database, faster the next access to any engine properties.
	 * If you want use this, it should be called early in your AI, else its usage will get poorer while the API fill the database itself.
	 */

	function GetBestRailType(engineID = -1)	{}
	/**
	 * This will browse railtype and return the railtype that can reach the maximum speed
	 * @param engineID the engineID to get its best railtype to use with it, if -1 get the current best railtype
	 * @return -1 if no railtype is found
	 */

	function GetTrainMaximumSpeed()	{}
	/**
	 * This return the current maximum reachable speed (limit by train speed capacity and railtype speed limitpe
	 * @return The current maximum speed, -1 if no trains can be found
	 */

	function SetAPIErrorHandling(output)	{}
	/**
	 * Enable or disable errors message. Those are only errors at using the API, not errors report by the NOAI API
	 * @param output True and the API will output its errors messages. False to disable this. You can still get the last error with GetAPIError
	 */

	function GetAPIError()	{}
	/**
	 * Get the last error string the API report
	 * @return A string.
	 */

}

	function cEngineLib::UpdateEngineProperties(veh_id)
	{
		if (!AIVehicle.IsValidVehicle(veh_id))	return;
		local vtype = AIVehicle.GetVehicleType(veh_id);
		local new_engine = AIVehicle.GetEngineType(veh_id);
		if (vtype == AIVehicle.VT_RAIL && AIVehicle.GetNumWagons(veh_id) > 1) return;
		local engObj = cEngineLib.Load(new_engine);
		if (engObj == null || engObj.is_known == -2)	return;
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
		local all_engineList = AIEngineList(object.engine_type);
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
			train_list = AIEngineList(object.engine_type);
			wagon_list = AIEngineList(object.engine_type);
			filter_callback_train = [];
			filter_callback_train.extend(filter_callback_params);
			filter_callback_wagon = [];
			filter_callback_wagon.extend(filter_callback_params);
			filter_callback_train[0] = train_list;
			filter_callback_train[1] = oTrain;
			filter_callback_wagon[0] = wagon_list;
			filter_callback_wagon[1] = oWagon;
			wagon_list.Valuate(AIEngine.IsWagon);
			train_list.Valuate(AIEngine.IsWagon);
			wagon_list.KeepValue(1);
			train_list.KeepValue(0);
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
							oTrain.engine_routetype = cEngineLib.GetBestRailType(object.engine_id);
							back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
							if (back != -1)	{ result.push(back); result.push(object.engine_id); result.push(oTrain.engine_routetype); return result; }
									else	{ cEngineLib.ErrorReport("No train that can pull that wagon : #"+object.engine_id+" - "+AIEngine.GetName(object.engine_id)); return error; }
							}
					else	{ // find a wagon for that train
							oWagon.engine_id = object.engine_id;
							oWagon.engine_roadtype = cEngineLib.GetBestRailType(object.engine_id);
							back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
							if (back != -1)	{ result.push(object.engine_id); result.push(back); result.push(oWagon.engine_roadtype); return result; }
									else	{ cEngineLib.ErrorReport("No wagon that we could use with that train : #"+object.engine_id+" - "+AIEngine.GetName(object.engine_id)); return error; }
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
			foreach (RT, _ in railtype_list) // they are sort by first = best, last = poorest
				{
				oTrain.engine_roadtype = -1;
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
				if (bestEngine == -1)	{ cEngineLib.ErrorReport("Couldn't find any engine: filter too hard, lack of engine avaiable..."); return error; }
				while (!confirm)
						{
						local vehID = cEngineLib.CreateVehicle(object.depot, bestEngine, object.cargo_id);
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
							if (wagon_list.IsEmpty())	{ cEngineLib.ErrorReport("No train that can pull that wagon : #"+object.engine_id+" - "+AIEngine.GetName(object.engine_id)); return error; }
							oTrain.engine_id = object.engine_id;
							}
					else	{
							train_list.Clear();
							train_list.AddItem(object.engine_id,0);
							if (train_list.IsEmpty())	{ cEngineLib.ErrorReport("No wagon that we could use with that train : #"+object.engine_id+" - "+AIEngine.GetName(object.engine_id)); return error; }
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
			if (bestLoco == -1)	{ cEngineLib.ErrorReport("Cannot find any train engine usable"); is_error = true; } // cannot find any train engine usable
			if (!train_exist && !is_error)
						{
						loco = cEngineLib.CreateVehicle(object.depot, bestLoco, object.cargo_id);
						train_exist = AIVehicle.IsValidVehicle(loco);
						if (!train_exist)	{ cEngineLib.ErrorReport("Cannot create the train engine : #"+bestLoco+" - "+AIEngine.GetName(bestLoco)+" > "+AIError.GetLastErrorString()); is_error = true; } // cannot be built, lack money...
						}
			if (!is_error)
				{
				wagon_list.AddList(save_wagon_list);
				oWagon.engine_id = bestLoco;
				bad_wagon =false;
				bestWagon = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
				if (bestWagon == -1)
						{ // no more wagons to try, changing loco
						train_tested.AddItem(bestLoco, 0);
						train_exist = false;
						AIVehicle.SellVehicle(loco);
						}
				else	{
						if (!cEngineLib.IsCoupleTested(bestLoco, bestWagon))
								{
								is_error = !cEngineLib.WagonCompatibilityTest(loco, bestWagon, object.cargo_id);
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
							engine_list.Valuate(AIEngine.CanRunOnRail, road_type);
							engine_list.KeepValue(1);
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
								if (!AIEngine.IsWagon(engine_list.Begin()))	engine_list.Valuate(cEngineLib.CanPullCargo, cargo_id, bypass);
																	else	engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id);
								engine_list.KeepValue(1);
								}
					if (engine_type != AIVehicle.VT_RAIL)	{ engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id); engine_list.KeepValue(1); }
					}
				}
	}

	function cEngineLib::CreateVehicle(depot, engine_id, cargo_id = -1)
	{
		if (!AIEngine.IsValidEngine(engine_id))	return -1;
		if (!cEngineLib.IsDepotTile(depot))	return -1;
		local vehID = AIVehicle.BuildVehicle(depot, engine_id);
		if (!AIVehicle.IsValidVehicle(vehID))	return -1;
		cEngineLib.UpdateEngineProperties(vehID);
		if (cargo_id == -1)	return vehID;
		if (!AICargo.IsValidCargo(cargo_id) || !AIEngine.CanRefitCargo(engine_id, cargo_id))	return vehID;
		if (!AIVehicle.RefitVehicle(vehID, cargo_id))	{ AIVehicle.SellVehicle(vehID); return -1; }
		return vehID;
	}

	function cEngineLib::GetLength(engine_id, cargo_id = -1)
	{
		local eng = cEngineLib.Load(e_id);
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

	function cEngineLib::IsLocomotive(engine_id)
	{
		if (!AIEngine.IsValidEngine(engine_id))	return false;
		return (AIEngine.GetVehicleType(engine_id) == AIVehicle.VT_RAIL && !AIEngine.IsWagon(engine_id));
	}

	function cEngineLib::GetNumberOfLocomotive(vehicle_id)
	{
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return 0;
		local numwagon = cEngineLib.GetNumberOfWagons(vehicle_id);
		local totalpart = AIVehicle.GetNumWagons(vehicle_id);
		return (totalpart - numwagon);
	}

	function cEngineLib::GetNumberOfWagons(vehicle_id)
	{
		if (AIVehicle.GetVehicleType(vehicle_id) != AIVehicle.VT_RAIL)	return 0;
		local numwagon = 0;
		local numpart = AIVehicle.GetNumWagons(vehicle_id);
		for (local i = 0; i < numpart; i++)	if (AIEngine.IsWagon(AIVehicle.GetWagonEngineType(vehicle_id, i)))	numwagon++;
		return numwagon;	
	}

	function cEngineLib::GetWagonFromVehicle(vehicle_id)
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

	function cEngineLib::WagonCompatibilityTest(vehicleID, wagonID, cargoID)
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
		wagon = cEngineLib.CreateVehicle(depot, wagonID, cargoID);
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
		local engine = cEngineLib.Load(engine_id);
		local wagonlist = AIEngineList(AIVehicle.VT_RAIL);
		wagonlist.Valuate(AIEngine.IsWagon);
		wagonlist.KeepValue(1);
		wagonlist.Valuate(cEngineLib.AreEngineCompatible, engine_id);
		wagonlist.KeepValue(1);
		wagonlist.Valuate(cEngineLib.IsEngineBlacklist);
		wagonlist.KeepValue(0);
		wagonlist.Valuate(AIEngine.CanRefitCargo, cargo_id);
		wagonlist.KeepValue(1);
		wagonlist.Valuate(AIEngine.IsBuildable);
		wagonlist.KeepValue(1);
		wagonlist.Valuate(AIEngine.CanRunOnRail, AIEngine.GetRailType(engine_id));
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

	function cEngineLib::IsDepotTile(tile)
	{
		if (!AIMap.IsValidTile(tile))	return false;
		return (AIRoad.IsRoadDepotTile(tile) || AIAirport.IsHangarTile(tile) || AIRail.IsRailDepotTile(tile) || AIMarine.IsWaterDepotTile(tile));
	}

	function cEngineLib::EngineCacheInit()
		{
		local cache = [AIVehicle.VT_ROAD, AIVehicle.VT_AIR, AIVehicle.VT_RAIL, AIVehicle.VT_WATER];
		foreach (item in cache)
			{
			local engList = AIEngineList(item);
			foreach (engID, _ in engList)	local dum = cEngineLib.Load(engID);
			}
		}

	function cEngineLib::GetBestRailType(engineID = -1)
	{
		if (cEngineLib.RailType.IsEmpty())	return -1;
		cEngineLib.RailType.Sort(AIList.SORT_BY_VALUE, true);
		if (engineID == -1)	return cEngineLib.RailType.Begin();
		local train = cEngine.IsLocomotive(engineID);
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

	function cEngineLib::GetTrainMaximumSpeed()
	{
		if (cEngineLib.RailType.IsEmpty())	return -1;
		cEngineLib.RailType.Sort(AIList.SORT_BY_VALUE, true);
		return cEngineLib.RailType.GetValue(cEngineLib.RailType.Begin());
	}

	function SetAPIErrorHandling(output)
	{
		if (typeof(output) != "bool")	return;
		cEngineLib.APIConfig[0] = output;
	}

	function GetAPIError()
	{
		return cEngineLib.APIConfig[1];
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
		if (AIEngine.GetVehicleType(engine_one) != AIVehicle.VT_RAIL)	return;
		if (AIEngine.GetVehicleType(engine_two) != AIVehicle.VT_RAIL)	return;
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
					if (rt_speed == 0)	rt_speed = engine_speed;
								else	if (rt_speed > engine_speed)	rt_speed = engine_speed;
					if (cEngineLib.RailType.GetValue(rt) < rt_speed)	{ cEngineLib.RailType.SetValue(rt, rt_speed); }
					}
			}
	}

	function cEngineLib::Load(e_id)
	{
		local cobj = cEngineLib();
		cobj.engine_id = e_id;
		if (e_id in cEngineLib.enginedatabase)	 return cEngineLib.enginedatabase[e_id];
		if (!cobj.Save())	return null;
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
			// 2 reasons: make the engine appears cheaper vs an already test one & allow us to know if we met it already (see UpdateEngineProperties)
			if (AIEngine.CanRefitCargo(this.engine_id, crg))	this.cargo_capacity.AddItem(crg,255);
														else	this.cargo_capacity.AddItem(crg,0);
			// 255 so it will appears to be a bigger carrier vs an already test engine
			// These two properties set as-is will force the AI to think a non-test engine appears better
			}
		local crgtype = AIEngine.GetCargoType(this.engine_id);
		this.cargo_capacity.SetValue(crgtype, AIEngine.GetCapacity(this.engine_id));
		cEngineLib.enginedatabase[this.engine_id] <- this;
		if (AIEngine.GetVehicleType(this.engine_id) == AIVehicle.VT_RAIL && !AIEngine.IsWagon(this.engine_id))	cEngineLib.SetRailTypeSpeed(this.engine_id);
		return true;
	}

	function cEngineLib::GetDepotType(depot)
	// -1 if invalid, else the type of depot
	{
		if (!AIMap.IsValidTile(depot))	return -1;
		if (AIRoad.IsRoadDepotTile(depot))	return AIVehicle.VT_ROAD;
		if (AIAirport.IsHangarTile(depot))	return AIVehicle.VT_AIR;
		if (AIRail.IsRailDepotTile(depot))	return AIVehicle.VT_RAIL;
		if (AIMarine.IsWaterDepotTile(depot))	return AIVehicle.VT_WATER;
		return -1;
	}

	function cEngineLib::EngineIsKnown(engine_id)
	// return true if engine is already test
	{
		local obj = cEngine.Load(engine_id);
		if (obj == null)	return false;
		if (obj.is_known == -2)	return true;
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
		if (eo.engine_id != -1)	eo.engine_type = AIVehicle.VT_RAIL; // no need to test
		if (eo.engine_type != AIVehicle.VT_RAIL)	eo.engine_id = -1;
	}



class	cEngineLib.Infos
{
	engine_id 		= null;
	engine_type 	= null;
	engine_roadtype = null;
	depot			= null;
	cargo_id		= null;
	bypass			= null;

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
