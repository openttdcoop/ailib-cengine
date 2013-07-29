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

	engine_id		= null;	// id of the engine
	cargo_capacity	= null;	// capacity per cargo item=cargoID, value=capacity when refit
	cargo_price		= null;	// price to refit item=cargoID, value=refit cost
	cargo_length	= null;	// that's the length of a vehicle depending on its current cargo setting
	is_known		= null;	// -1 seen that engine, -2 tests already made
	incompatible	= null;	// AIList of wagons imcompatible with a train engine
	
	constructor()
		{
		engine_id		= null;
		cargo_capacity	= AIList();
		cargo_price		= AIList();
		cargo_length	= AIList();
		is_known		= -1;
		incompatible	= AIList();
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
	 * @return An array with the best engines : [0]= -1 not found, [0]=engine_id water/air/road, [0]=engine_id & [1]=wagon_id for rail.
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

	function IsLocomotive(engine_id) {}
	/**
	 * Check if an engine is a locomotive
	 * @param engine_id the engine to check
	 * @return True if it's a locomotive, false if not or invalid...
	 */

	function GetCapacity(engine_id, cargo_id = -1) {}
	/**
	 * Get the capacity of an engine for that cargo type
	 * @param engine_id The engine to get the capacity of
	 * @param cargo_id If -1, it's the current refit cargo, else the cargo id to get the capacity for.
	 * @return the capacity, 0 if the cargo is not support or on error
	 */

	function IncompatibleEngine(engine_one, engine_two) {}
	/**
	 * Mark engine_one and engine_two not compatible with each other
	 * This could only be seen with trains
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 */

	function AreEngineCompatible(engine, compare_engine) {}
	/**
	 * Check if engine1 is usable with engine2. For trains/wagons only.
	 * @param engine_one engine id of the first engine
	 * @param engine_two engine id of the second engine
	 * @return true if you can use them
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
	 * This will browse road vehicles so they are all added to the engine database, faster the next time you will try to pull any road vehicle properties.
	 * If you want use this, it should be called early in your AI, else it have no usage
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

	function cEngineLib::GetLength(engine_id, cargo_id = -1)
	{
		local eng = cEngineLib.Load(e_id);
		if (eng == null)	return 0;
		if (cargo_id == -1)	cargo_id = AIEngine.GetCargoType(engine_id);
		return eng.cargo_length.GetValue(cargo_id);
	}

	function cEngineLib::IsLocomotive(engine_id)
	{
		if (!AIEngine.IsValidEngine(engine_id))	return false;
		return (AIEngine.GetVehicleType(engine_id) == AIVehicle.VT_RAIL && !AIEngine.IsWagon(engine_id));
	}

	function cEngineLib::GetCapacity(engine_id, cargo_id = -1)
	{
		local engObj = cEngineLib.Load(engine_id);
		if (engObj == null)	return 0;
		if (cargo_id == -1)	cargo_id = AIEngine.GetCargoType(engine_id);
					else	if (!AICargo.IsValidCargo(cargo_id))	return 0;
		return engObj.cargo_capacity.GetValue(cargo_id);
	}

	function cEngineLib::IncompatibleEngine(engine_one, engine_two)
	{
		local eng1 = cEngineLib.Load(engine_one);
		if (eng1 == null)	return;
		local eng2 = cEngineLib.Load(engine_two);
		if (eng2 == null)	return;
		if (AIEngine.GetVehicleType(engine_one) != AIVehicle.VT_RAIL)	return;
		if (AIEngine.GetVehicleType(engine_two) != AIVehicle.VT_RAIL)	return;
		eng1.incompatible.AddItem(engine_one, engine_two);
		eng2.incompatible.AddItem(engine_two, engine_one);
	}

	function cEngineLib::AreEngineCompatible(engine, compare_engine)
	{
		local eng = cEngineLib.Load(compare_engine);
		if (eng == null)	return false;
		return !(eng.incompatible.HasItem(engine));
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

	function cEngineLib::EngineCacheInit()
		{
		local cache = [AIVehicle.VT_ROAD, AIVehicle.VT_AIR, AIVehicle.VT_RAIL, AIVehicle.VT_WATER];
		foreach (item in cache)
			{
			local engList = AIEngineList(item);
			foreach (engID, _ in engList)	local dum = cEngineLib.Load(engID);
			}
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
					}
				if (cargo_id != -1)
					{ // apply a filter per cargo type
					if (engine_id != -1)
								{ // filter train or wagon base on cargo
								engine_list.Valuate(AIEngine.IsWagon);
								engine_list.KeepValue(AIEngine.IsWagon(engine_id) ? 0 : 1); // kick wagon or loco
								if (AIEngine.IsWagon(engine_id))	engine_list.Valuate(cEngineLib.CanPullCargo, cargo_id, bypass);
															else	engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id);
								engine_list.KeepValue(1);
								}
						else	{ engine_list.Valuate(AIEngine.CanRefitCargo, cargo_id); engine_list.KeepValue(1); }
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

	function cEngineLib::GetBestEngine(object, filter)
	{
		local isobject = object instanceof cEngineLib.Infos;
		local error = []; error.push(-1);
		if (!isobject)	{ AILog.Error("object must be a cEngineLib.Infos instance"); return error; }
		cEngineLib.CheckEngineObject(object);
		if (object.cargo_id == -1)	{ AILog.Error("cargo_id must be a valid cargo"); return error; }
		if (object.depot == -1 && object.engine_type == -1)	{ AILog.Error("object.engine_type must be set when the depot doesn't exist"); return error; }
		local all_engineList = AIEngineList(object.engine_type);
		local filter_callback = cEngineLib.Filter_EngineGeneric;
		local filter_callback_params = [];
		if (object.engine_type == AIVehicle.VT_RAIL)	filter_callback = cEngineLib.Filter_EngineTrain;
		filter_callback_params.push(all_engineList);
		filter_callback_params.push(object);
		if (filter != null)
					{
					if (typeof(filter) != "function")	{ AILog.Error("filter must be a function"); return error; }
					filter_callback = filter;
					}
		local result = [];
		if (object.depot == -1) // theorical results
			{
			if (object.engine_type != AIVehicle.VT_RAIL)
				{
				result.push(cEngineLib.GetCallbackResult(filter_callback, filter_callback_params));
				return result;
				}
			if (object.engine_id != -1)
					{
					local back = cEngineLib.GetCallbackResult(filter_callback, filter_callback_params);
					if (AIEngine.IsWagon(engine_id))	{ result.push(back); result.push(engine_id); }
												else	{ result.push(engine_id); result.push(back); }
					return result;
					}
			}

		// real results
		if (object.engine_type != AIVehicle.VT_RAIL)
			{ // the easy part first
				local bestEngine = cEngineLib.GetCallbackResult(filter_callback, filter_callback_params);
				if (cEngineLib.EngineIsKnown(bestEngine))	{ return [bestEngine]; } // Already tested no need to redo them
				local confirm = false;
				if (bestEngine == -1)	return error; // We cannot find any engine, filtered too hard or lack of engines
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
		// now trains
		local oTrain = cEngineLib.Infos();
		local oWagon = cEngineLib.Infos();
		oWagon.depot = object.depot;
		oWagon.cargo_id = object.cargo_id;
		oWagon.bypass = object.bypass;
		cEngineLib.CheckEngineObject(oWagon);
		oTrain.depot = object.depot;
		oTrain.cargo_id = object.cargo_id;
		oTrain.bypass = object.bypass;
		cEngineLib.CheckEngineObject(oTrain);
		local train_list = AIEngineList(object.engine_type);
		local wagon_list = AIEngineList(object.engine_type);
		local filter_callback_train = [];
		filter_callback_train.extend(filter_callback_params);
		local filter_callback_wagon = [];
		filter_callback_wagon.extend(filter_callback_params);
		filter_callback_train[0] = train_list;
		filter_callback_train[1] = oTrain;
		filter_callback_wagon[0] = wagon_list;
		filter_callback_wagon[1] = oWagon;
		wagon_list.Valuate(AIEngine.IsWagon);
		train_list.Valuate(AIEngine.IsWagon);
		wagon_list.KeepValue(1);
		train_list.KeepValue(0)
		if (object.engine_id != -1)
				{ // apply a constrain, user want a fixed wagon engine or a loco
				if (AIEngine.IsWagon(object.engine_id))	
							{
							wagon_list.Clear();
							wagon_list.AddItem(object.engine_id,0);
							if (wagon_list.IsEmpty())	return error;
							oTrain.engine_id = object.engine_id;
							}
					else	{
							train_list.Clear();
							train_list.AddItem(object.engine_id,0);
							if (train_list.IsEmpty())	return error;
							oWagon.engine_id = object.engine_id;
							}
				}
		local bestLoco = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
		local bestWagon = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
		local loco, wagon = null;
		local altLoco = -1;
		local altWagon = -1;
		local train_end = false;
		local train_exist = false;
		local wagon_exist = false;
		local wagon_end = false;
		while (!train_end && !wagon_end)
			{
			if (!train_exist)	loco = cEngineLib.CreateVehicle(object.depot, bestLoco, object.cargo_id);
			train_exist = AIVehicle.IsValidVehicle(loco);
			if (!wagon_exist)	wagon = cEngineLib.CreateVehicle(object.depot, bestWagon, object.cargo_id);
			wagon_exist = AIVehicle.IsValidVehicle(wagon);
			if (train_exist && wagon_exist)
				{ // let's attach them
				local attach_try = AITestMode();
				local atest = AIVehicle.MoveWagon(wagon, 0, loco, AIVehicle.GetNumWagons(loco) -1);
				attach_try = null;
				if (!atest)	cEngineLib.Incompatible(loco, wagon);
				}
			altLoco = cEngineLib.GetCallbackResult(filter_callback, filter_callback_train);
			altWagon = cEngineLib.GetCallbackResult(filter_callback, filter_callback_wagon);
			if (altLoco == bestLoco)	train_end = true;
								else	{
										if (train_exist)	AIVehicle.SellVehicle(loco);
										train_exist = false;
										bestLoco = altLoco;
										}
			if (altWagon == bestWagon)	wagon_end = true;
								else	{
										if (wagon_exist)	AIVehicle.SellVehicle(wagon);
										wagon_exist = false;
										bestWagon = altWagon;
										}
			}
		if (train_exist)	AIVehicle.SellVehicle(loco);
		if (wagon_exist)	AIVehicle.SellVehicle(wagon);
		result.push(bestLoco);
		result.push(bestWagon);
		return result;
	}

	// *********************** //
	// PRIVATE FUNCTIONS - API //
	// *********************** //

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
			// 2 reasons: make the engine appears cheap vs an already test one & allow us to know if we met it already (see UpdateEngineProperties)
			if (AIEngine.CanRefitCargo(this.engine_id, crg))	this.cargo_capacity.AddItem(crg,255);
														else	this.cargo_capacity.AddItem(crg,0);
			// 255 so it will appears to be a bigger carrier vs an already test engine
			// These two properties set as-is will force the AI to think a non-test engine appears better
			}
		local crgtype = AIEngine.GetCargoType(this.engine_id);
		this.cargo_capacity.SetValue(crgtype, AIEngine.GetCapacity(this.engine_id));
		cEngineLib.enginedatabase[this.engine_id] <- this;
print("Adding engine "+AIEngine.GetName(this.engine_id)+" to base");
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
