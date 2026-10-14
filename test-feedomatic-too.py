"""Execute Lua syntax and aggregation tests using the installed DFHack Lua DLL."""
import ctypes
from pathlib import Path

lua = ctypes.CDLL(r'E:\SteamLibrary\steamapps\common\DFHack\hack\lua53.dll')
for name, symbol in {
    'luaL_newstate':'?luaL_newstate@@YAPEAUlua_State@@XZ',
    'luaL_openlibs':'?luaL_openlibs@@YAXPEAUlua_State@@@Z',
    'luaL_loadstring':'?luaL_loadstring@@YAHPEAUlua_State@@PEBD@Z',
    'lua_pcallk':'?lua_pcallk@@YAHPEAUlua_State@@HHH_JP6AH0H1@Z@Z',
    'lua_tolstring':'?lua_tolstring@@YAPEBDPEAUlua_State@@HPEA_K@Z',
    'lua_close':'?lua_close@@YAXPEAUlua_State@@@Z',
}.items():
    setattr(lua, name, getattr(lua, symbol))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
script = "\nlocal F={}\nassert(loadfile('HunterTools/Foods.lua'))('test',F)\nassert(loadfile('HunterTools/FoodList.lua'))('test',F)\nlocal n=0; for id,e in pairs(F.foodCatalog) do assert(type(id)=='number' and type(e.name)=='string'); n=n+1 end\nassert(n==322)\nassert(loadfile('HunterTools/Core.lua'))('GFW_FeedOMatic',F)\nassert(loadfile('HunterTools/HunterTools.lua'))\nF.LoadSettings()\nF.db.enabled=false; F.db.x=127; F.LoadSettings()\nassert(F.db.enabled==false and F.db.x==127,'preferences survive loading')\nF.db.enabled=true\nlocal slots={{itemID=1,stackCount=8},{itemID=2,stackCount=3},{itemID=3,stackCount=2,isLocked=true},{itemID=4,stackCount=1}}\nNUM_TOTAL_EQUIPPED_BAG_SLOTS=0\nC_Container={GetContainerNumSlots=function() return #slots end,GetContainerItemInfo=function(b,s) return slots[s] end}\nC_Item={GetItemInfo=function(id) return 'food'..id,'link',1,id==1 and 10 or 20 end}\nC_PetInfo={CanPetEatItem=function(id) return id~=4 end}\nassert(F.FindFood().id==2 and F.foodCount==11)\nF.db.foodOrder='low'\nassert(F.FindFood().id==1,'low order selects lower item level')\nF.LoadSettings(); assert(F.db.foodOrder=='low','order persists')\nassert(F.PreferFood({level=10,count=2},{level=10,count=8}),'smaller stack breaks ties')\nF.db.foodOrder='high'\nslots[1].stackCount=1\nassert(F.FindFood().id==2,'level priority is deterministic')\nInCombatLockdown=function() return true end\nassert(F.GetState()=='hidden','combat checked before querying restricted pet APIs')\nF.button={SetAttribute=function() error('protected write in combat') end}\nF.Refresh(true)\nInCombatLockdown=function() return false end\nF.mode='hidden'; F.reason='Pet is happy'\nassert(F.TooltipStatus()=='Your pet is happy; feeding is not needed.')\nF.mode='nofood'\nassert(F.TooltipStatus()=='No allowed, suitable unlocked food in your bags.')\nF.reason='Pet is happy'; F.food={name='Test fish'}\nassert(F.FoodPreview()=='Next food: Test fish')\nassert(F.FoodAllowed(1))\nF.db.whitelist[2]=true; assert(not F.FoodAllowed(1) and F.FoodAllowed(2))\nF.db.blacklist[2]=true; assert(not F.FoodAllowed(2))\nF.db.whitelist={}; F.db.blacklist={}\nlocal scans=0\nF.GetState=function() return 'hidden','Pet is happy' end\nF.FindFood=function() scans=scans+1; F.bagsDirty=false end\nF.button={SetAttribute=function(_,key,value) assert(value==nil,'happy pet must stay disarmed') end}\nF.Render=function(mode) assert(mode=='hidden') end\nF.bagsDirty=true; F.Refresh(); F.Refresh()\nassert(scans==1,'scan dirty bags once while happy')\nlocal sounds,now=0,100\nGetTime=function() return now end\nPlaySoundFile=function() sounds=sounds+1 end\nF.CheckHungerSound('hungry','Content'); F.CheckHungerSound('hungry','Content')\nassert(sounds==1,'one alert per hunger episode')\nF.CheckHungerSound('hidden','Pet is happy')\nnow=120; F.CheckHungerSound('hungry','Content'); assert(sounds==1)\nnow=161; F.CheckHungerSound('hungry','Content'); assert(sounds==2)\nF.db.enabled=false; F.hungerAlerted=false\nnow=230; F.CheckHungerSound('hungry','Content'); assert(sounds==2)\nF.IsPublic=function() return true end\nInCombatLockdown=function() return false end\nUnitExists=function() return true end\nC_PetInfo.CanPetEatItem=function(id) return id==1 end\nassert(F.CatalogEdibility(1,true)=='Can eat')\nassert(F.CatalogEdibility(2,true)=='Cannot eat')\nassert(F.CatalogEdibility(1,false)=='Loading')\nUnitExists=function() return false end\nassert(F.CatalogEdibility(1,true)=='No pet')\nInCombatLockdown=function() return true end\nassert(F.CatalogEdibility(1,true)=='Unknown')\nprint('PASS: Lua syntax, food eligibility, locked items, stack totals, ranking, combat guard')\n"
script += "\nassert(loadfile('test-feedomatic-features.lua'))(F)\n"
script += "\nassert(loadfile('test-feedomatic-reminders.lua'))(F)\n"
script += "\nassert(loadfile('test-feedomatic-quests.lua'))()\n"
script += "\nassert(loadfile('test-feedomatic-ammo.lua'))()\n"
script += "\nassert(loadfile('test-instance-check.lua'))()\n"
script += "\nassert(loadfile('test-config-menu.lua'))()\n"
script += "\nassert(loadfile('test-range.lua'))()\n"
script += "\nassert(loadfile('test-special-food.lua'))()\n"
script += "\nassert(loadfile('test-pet-database.lua'))()\n"
script += "\nassert(loadfile('test-known-pet-abilities.lua'))()\n"
try:
    result = lua.luaL_loadstring(state, ("local M={}; assert(loadfile('HunterTools/Core.lua'))('test',M)\nFeedomaticTooDB={enabled=false,x=123,petFoodLists={pet={blacklist={[117]=true},whitelist={}}},ammo={enabled=true,selected={[8067]=true}},range={x=44,y=55,enabled=false}}\nHunterToolsDB=nil; M.LoadSettings()\nassert(M.db~=FeedomaticTooDB and M.db.x==123 and M.db.petFoodLists.pet.blacklist[117] and M.db.ammo.selected[8067] and M.db.range.x==44)\nM.db.petFoodLists.pet.blacklist[117]=nil; assert(FeedomaticTooDB.petFoodLists.pet.blacklist[117])\nM.db.x=777; M.LoadSettings(); assert(M.db.x==777)\nHunterToolsDB=nil; FeedomaticTooDB=nil\nprint('PASS: legacy settings migration, independent nested tables and no repeat overwrite')" + script).encode())
    if result == 0:
        result = lua.lua_pcallk(state, 0, 0, 0, 0, None)
    if result:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)
