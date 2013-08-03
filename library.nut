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

class cEngineLib extends AILibrary
{
    function GetAuthor()      { return "krinn@chez.com"; }
    function GetName()        { return "cEngineLib"; }
    function GetShortName()   { return "CENG"; }
    function GetDescription() { return "A library providing tools to handle engines"; }
    function GetVersion()     { return 3; }
    function GetAPIVersion()  { return "1.2"; }
    function GetDate()        { return "2013-07-23"; }
    function CreateInstance() { return "cEngineLib"; }
	function GetURL()			{ return "http://www.tt-forums.net/viewtopic.php?f=65&t=67122"; }
    function GetCategory()    { return "Library"; }
}

RegisterLibrary(cEngineLib());
