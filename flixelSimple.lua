

groups = DAME.GetGroups()
groupCount = as3.tolua(groups.length) -1

DAME.SetFloatPrecision(3)

tab1 = "\t"
tab2 = "\t\t"
tab3 = "\t\t\t"

exportOnlyCSV = as3.tolua(VALUE_ExportOnlyCSV)
flixelPackage = as3.tolua(VALUE_FlixelPackage)
baseClassName = as3.tolua(VALUE_BaseClass)
as3Dir = as3.tolua(VALUE_AS3Dir)
tileMapClass = as3.tolua(VALUE_TileMapClass);
mainLayer = as3.tolua(VALUE_MainLayer)
levelName = as3.tolua(VALUE_LevelName)
GamePackage = as3.tolua(VALUE_GamePackage)
csvDir = as3.tolua(VALUE_CSVDir)
importsText = as3.tolua(VALUE_Imports)

-- This is the file for the map base class
baseFileText = "";

-- Output tilemap data
-- slow to call as3.tolua many times.

function exportMapCSV( mapLayer, layerFileName )
	-- get the raw mapdata. To change format, modify the strings passed in (rowPrefix,rowSuffix,columnPrefix,columnSeparator,columnSuffix)
	mapText = as3.tolua(DAME.ConvertMapToText(mapLayer,"","\n","",",",""))
	--print("output to "..as3.tolua(VALUE_CSVDir).."/"..layerFileName)
	DAME.WriteFile(csvDir.."/"..layerFileName, mapText );
end

-- This is the file for the map level class.
fileText = "//Code generated with DAME. http://www.dambots.com\n\n"
fileText = fileText.."package "..GamePackage..";\n"

fileText = fileText.."//Import general Flixel classes\n"
fileText = fileText.."import org.flixel.FlxObject;\n"
fileText = fileText.."import org.flixel.FlxGroup;\n"
fileText = fileText.."import org.flixel.FlxG;\n"
fileText = fileText.."import org.flixel.FlxTilemap;\n"
fileText = fileText.."import org.flixel.FlxSprite;\n"

if # importsText > 0 then
	fileText = fileText.."// Custom imports:\n"..importsText.."\n"
end
fileText = fileText.."class Level_"..levelName.." extends "..baseClassName.."\n"
fileText = fileText.."{\n"
fileText = fileText..tab1.."// Embedded media...\n"

maps = {}
spriteLayers = {}

masterLayerAddText = ""
stageAddText = tab2.."if ( addToStage )\n"
stageAddText = stageAddText..tab2.."{\n"

for groupIndex = 0,groupCount do
	group = groups[groupIndex]
	groupName = as3.tolua(group.name)
	groupName = string.gsub(groupName, " ", "_")
	
	
	layerCount = as3.tolua(group.children.length) - 1
	
	
	
	-- Go through each layer and store some tables for the different layer types.
	for layerIndex = 0,layerCount do
		layer = group.children[layerIndex]
		isMap = as3.tolua(layer.map)~=nil
		layerSimpleName = as3.tolua(layer.name)
		layerSimpleName = string.gsub(layerSimpleName, " ", "_")
		layerName = groupName..layerSimpleName
		if isMap == true then
			mapFileName = "mapCSV_"..groupName.."_"..layerSimpleName..".csv"
			-- Generate the map file.
			exportMapCSV( layer, mapFileName )
			if layerSimpleName == mainLayer then mainLayer = layerName end
			
			-- This needs to be done here so it maintains the layer visibility ordering.
			if exportOnlyCSV == false then
				table.insert(maps,{layer,layerName})
				-- For maps just generate the Embeds needed at the top of the class.
				fileText = fileText..tab1.."[Embed(source=\""..as3.tolua(DAME.GetRelativePath(as3Dir, csvDir.."/"..mapFileName)).."\", mimeType=\"application/octet-stream\")] public var CSV_"..layerName..":Class;\n"
				fileText = fileText..tab1.."[Embed(source=\""..as3.tolua(DAME.GetRelativePath(as3Dir, layer.imageFile)).."\")] public var Img_"..layerName..":Class;\n"
				masterLayerAddText = masterLayerAddText..tab2.."masterLayer.add(layer"..layerName..");\n"
			end
	
		elseif as3.tolua(layer.IsSpriteLayer()) == true then
			if exportOnlyCSV == false then
				table.insert( spriteLayers,{groupName,layer,layerName})
				masterLayerAddText = masterLayerAddText..tab2.."masterLayer.add("..layerName.."Group);\n"
				stageAddText = stageAddText..tab3.."addSpritesForLayer"..layerName.."(onAddSpritesCallback);\n"
			end
		end
	end
end


	
if exportOnlyCSV == false then
	stageAddText = stageAddText..tab3.."FlxG.state.add(masterLayer);\n"
	stageAddText = stageAddText..tab2.."}\n\n"
	
	baseFileText = "//Code generated with DAME. http://www.dambots.com\n\n"
	baseFileText = baseFileText.."package "..GamePackage..";\n"
	baseFileText = baseFileText.."import "..flixelPackage..".*;\n"
	baseFileText = baseFileText.."class "..baseClassName.."\n"
	baseFileText = baseFileText.."{\n"

	fileText = fileText.."\n"
	fileText = fileText..tab1.."//Tilemaps\n"
	for i,v in ipairs(maps) do
		fileText = fileText..tab1.."public var layer"..maps[i][2]..":"..tileMapClass..";\n"
	end
	fileText = fileText.."\n"
	
	fileText = fileText..tab1.."//Sprites\n"
	for i,v in ipairs(spriteLayers) do
		fileText = fileText..tab1.."public var "..spriteLayers[i][3].."Group:FlxGroup = new FlxGroup();\n"
	end
	fileText = fileText.."\n"
	
	fileText = fileText.."\n"
	fileText = fileText..tab1.."public function Level_"..levelName.."(addToStage:Boolean = true, onAddSpritesCallback:Function = null)\n"
	fileText = fileText..tab1.."{\n"
	fileText = fileText..tab2.."// Generate maps.\n"
	
	minx = 9999999
	miny = 9999999
	maxx = -9999999
	maxy = -9999999
	-- Create the tilemaps.
	for i,v in ipairs(maps) do
		layerName = maps[i][2]
		layer = maps[i][1]
		
		fileText = fileText..tab2.."layer"..layerName.." = new "..tileMapClass..";\n"
		fileText = fileText..tab2.."layer"..layerName..".loadMap( new CSV_"..layerName..", Img_"..layerName..", "..as3.tolua(layer.map.tileWidth)..","..as3.tolua(layer.map.tileHeight)..", FlxTilemap.OFF, 0, "..as3.tolua(layer.map.drawIndex)..", "..as3.tolua(layer.map.collideIndex).." );\n"
		
		x = as3.tolua(layer.map.x)
		y = as3.tolua(layer.map.y)
		width = as3.tolua(layer.map.width)
		height = as3.tolua(layer.map.height)
		if x < minx then minx = x end
		if y < miny then miny = y end
		if x + width > maxx then maxx = x + width end
		if y + height > maxy then maxy = y + height end
		
		fileText = fileText..tab2.."layer"..layerName..".x = "..string.format("%.6f",x)..";\n"
		fileText = fileText..tab2.."layer"..layerName..".y = "..string.format("%.6f",y)..";\n"
		fileText = fileText..tab2.."layer"..layerName..".scrollFactor.x = "..string.format("%.6f",as3.tolua(layer.xScroll))..";\n"
		fileText = fileText..tab2.."layer"..layerName..".scrollFactor.y = "..string.format("%.6f",as3.tolua(layer.yScroll))..";\n"
	end
	
	-- Add the layers to the layer list.
	
	fileText = fileText.."\n"..tab2.."//Add layers to the master group in correct order.\n"
	fileText = fileText..masterLayerAddText.."\n\n";
		
	fileText = fileText..stageAddText
	
	fileText = fileText..tab2.."mainLayer = layer"..mainLayer..";\n\n"
	fileText = fileText..tab2.."boundsMinX = "..minx..";\n"
	fileText = fileText..tab2.."boundsMinY = "..miny..";\n"
	fileText = fileText..tab2.."boundsMaxX = "..maxx..";\n"
	fileText = fileText..tab2.."boundsMaxY = "..maxy..";\n\n"
	
	fileText = fileText..tab1.."}\n\n"	-- end constructor
	
	
	
	baseFileText = baseFileText..tab1.."public var masterLayer:FlxGroup = new FlxGroup();\n\n"
	baseFileText = baseFileText..tab1.."public var mainLayer:"..tileMapClass..";\n\n"
	baseFileText = baseFileText..tab1.."public var boundsMinX:int;\n"
	baseFileText = baseFileText..tab1.."public var boundsMinY:int;\n"
	baseFileText = baseFileText..tab1.."public var boundsMaxX:int;\n"
	baseFileText = baseFileText..tab1.."public var boundsMaxY:int;\n\n"
	baseFileText = baseFileText..tab1.."public function "..baseClassName.."() { }\n\n"
	baseFileText = baseFileText..tab1.."public function addSpriteToLayer(type:Class, group:FlxGroup, x:Number, y:Number, angle:Number, flipped:Boolean, scrollX:Number, scrollY:Number, onAddCallback:Function = null):FlxSprite\n"
	
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."var obj:FlxSprite = new type(x, y);\n"
	baseFileText = baseFileText..tab2.."obj.x += obj.offset.x;\n"
	baseFileText = baseFileText..tab2.."obj.y += obj.offset.y;\n"
	baseFileText = baseFileText..tab2.."obj.angle = angle;\n"
	
	baseFileText = baseFileText..tab2.."// Only override the facing value if the class didn't change it from the default.\n"
	baseFileText = baseFileText..tab2.."if ( obj.facing == FlxObject.RIGHT )\n"
	baseFileText = baseFileText..tab3.."obj.facing = flipped ? FlxObject.LEFT : FlxObject.RIGHT;\n"
	baseFileText = baseFileText..tab2.."obj.scrollFactor.x = scrollX;\n"
	baseFileText = baseFileText..tab2.."obj.scrollFactor.y = scrollY;\n"
	baseFileText = baseFileText..tab2.."group.add(obj);\n"
	
	baseFileText = baseFileText..tab2.."if (onAddCallback != null)\n"
	baseFileText = baseFileText..tab3.."onAddCallback(obj, group);\n"
	baseFileText = baseFileText..tab2.."return obj;\n"
	baseFileText = baseFileText..tab1.."}\n\n"

	-- create the sprites.
	
	for i,v in ipairs(spriteLayers) do
		baseFileText = baseFileText..tab1.."public function addSpritesForLayer"..spriteLayers[i][3].."(onAddCallback:Function = null):void { }\n"
		layer = spriteLayers[i][2]
		creationText = tab2.."addSpriteToLayer(%class%, "..spriteLayers[i][3].."Group , %xpos%, %ypos%, %degrees%, %flipped%, "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.xScroll)..", onAddCallback );//%name%\n" 
		
		fileText = fileText..tab1.."override public function addSpritesForLayer"..spriteLayers[i][3].."(onAddCallback:Function = null):void\n"
		fileText = fileText..tab1.."{\n"
	
		fileText = fileText..as3.tolua(DAME.CreateTextForSprites(layer,creationText,"Avatar"))
		fileText = fileText..tab1.."}\n\n"
	end
	
	fileText = fileText.."\n"

	fileText = fileText.."}\n"	-- end class
	
	baseFileText = baseFileText.."}\n"	-- end class
		
	-- Save the file!
	
	DAME.WriteFile(as3Dir.."/Level_"..levelName..".hx", fileText )
	DAME.WriteFile(as3Dir.."/"..baseClassName..".hx", baseFileText )
end




return 1
