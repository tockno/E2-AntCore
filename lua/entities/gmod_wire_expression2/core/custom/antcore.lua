//author: Antagonist --I stole half of it, I'm making it for myself smd
E2Lib.RegisterExtension("AntCore", false, "Misc useful functionality.")

--[[
	version: 13/08/2018

	RECENT CHANGES (not specifically unique to this version):
	
	optimised findClosestCentered
	fixed propCanCreate
	
	E:setCollisionGroup(S)
	E:getCollisionGroup()
	E:removeCollisionGroup()
	E:getPhysScale/E:getModelScale return prop resizer (advanced collision resizer addon) values if they exist
	
	improved how processors work, removed useProcessor
	
	fixed runOnEntRemove running even when the chip is being deleted
	
	bugs/errors:
	R:clean or findSetResults(R) + findClosest has a util nil error (utils.lua)
]]

-- to reduce local var count (max 200 in a script)
-- any would-be locals are instead added to AntCore
local AntCore = {}

AntCore.turretShoot_enabled = CreateConVar("antcore_turretShoot_enabled","1",FCVAR_ARCHIVE)
AntCore.turretShoot_persecond = CreateConVar("antcore_turretShoot_persecond","10",FCVAR_ARCHIVE)
AntCore.turretShoot_damage_max = CreateConVar("antcore_turretShoot_damage_max","110000000",FCVAR_ARCHIVE)
AntCore.turretShoot_spread_max = CreateConVar("antcore_turretShoot_spread_max","2",FCVAR_ARCHIVE)
AntCore.turretShoot_count_max = CreateConVar("antcore_turretShoot_count_max","20",FCVAR_ARCHIVE)
AntCore.boom_enabled = CreateConVar("antcore_boom_enabled","1",FCVAR_ARCHIVE)
AntCore.boom_delay = CreateConVar("antcore_boom_delay","100",FCVAR_ARCHIVE)
AntCore.boom_damage_max = CreateConVar("antcore_boom_damage_max","10000",FCVAR_ARCHIVE)
AntCore.boom_radius_max = CreateConVar("antcore_boom_radius_max","50000",FCVAR_ARCHIVE)
AntCore.hintPlayer_enabled = CreateConVar("antcore_hintPlayer_enabled","1",FCVAR_ARCHIVE)
AntCore.hintPlayer_persecond = CreateConVar("antcore_hintPlayer_persecond","5",FCVAR_ARCHIVE)
AntCore.hintPlayer_persist_max = CreateConVar("antcore_hintPlayer_persist_max","7",FCVAR_ARCHIVE)
AntCore.hintPlayer_persecond_self = CreateConVar("antcore_hintPlayer_persecond_self","20",FCVAR_ARCHIVE)
AntCore.hintPlayer_persist_max_self = CreateConVar("antcore_hintPlayer_persist_max_self","60",FCVAR_ARCHIVE)
AntCore.printPlayer_persecond = CreateConVar("antcore_printPlayer_persecond",10,FCVAR_ARCHIVE)
AntCore.weapons_enabled = CreateConVar("antcore_weapons_enabled","2",FCVAR_ARCHIVE)
AntCore.weapons_remove_any = CreateConVar("antcore_weapons_remove_any","1",FCVAR_ARCHIVE)
AntCore.wirespawn_enabled = CreateConVar("antcore_wirespawn_enabled","1",FCVAR_ARCHIVE)
AntCore.entities_spawn_persecond = CreateConVar("antcore_entities_spawn_persecond","16",FCVAR_ARCHIVE)
AntCore.entities_spawn_e2chip = CreateConVar("antcore_entities_spawn_e2chip","0",FCVAR_ARCHIVE)
AntCore.bolt_persecond = CreateConVar("antcore_bolt_persecond","8",FCVAR_ARCHIVE)
AntCore.bolt_max = CreateConVar("antcore_bolt_max","32",FCVAR_ARCHIVE)
AntCore.combine_persecond = CreateConVar("antcore_combine_persecond","1",FCVAR_ARCHIVE)
AntCore.dropweapon_persecond = CreateConVar("antcore_dropweapon_persecond","5",FCVAR_ARCHIVE)
AntCore.processor_max = CreateConVar("antcore_processor_max","8",FCVAR_ARCHIVE)

-- notes: 0.005 is roughly smallest physgunnable for normal sized props
-- and 10 is roughly the point before the server lags
AntCore.physscale_min = CreateConVar("antcore_physscale_min","0.005",FCVAR_ARCHIVE)
AntCore.physscale_max = CreateConVar("antcore_physscale_max","10",FCVAR_ARCHIVE)
--local AntCore.physscale_types = {[""]}

-- boxical can have a much larger physical scale because it's much simpler physics
AntCore.physscale_boxmin = CreateConVar("antcore_physscale_boxmin","0.001",FCVAR_ARCHIVE)
AntCore.physscale_boxmax = CreateConVar("antcore_physscale_boxmax","50",FCVAR_ARCHIVE)



AntCore.boomEffects = {"explosion","helicoptermegabomb","bloodimpact","glassimpact","striderblood","airboatgunimpact","cball_explode","manhacksparks","antliongib","stunstickimpact"}
AntCore.boomEffectsSize = 0 --this gets counted
AntCore.turretTracers = {"tracer", "ar2tracer", "helicoptertracer", "airboatgunheavytracer","lasertracer","tooltracer"}
AntCore.turretTracersSize = 0 --also counted
AntCore.WeaponGiveWhiteList = {"weapon_pistol","weapon_crowbar","weapon_stunstick","weapon_physcannon","weapon_shotgun","weapon_ar2","weapon_crossbow","wt_backfiregun","ragdollroper","laserpointer","remotecontroller","none","gmod_camera","weapon_fists"}
AntCore.WeaponControlWhiteList = {"weapon_pistol","weapon_crowbar","weapon_stunstick","weapon_physcannon","weapon_shotgun","weapon_ar2","weapon_crossbow","wt_backfiregun","ragdollroper","laserpointer","remotecontroller","none","gmod_camera","weapon_fists","weapon_rpg","weapon_smg1","weapon_slam","weapon_bugbait","weapon_physgun","gmod_tool","weapon_medkit","weapon_frag","parachuter","wt_writingpad"}
AntCore.AmmoWhiteList = {"pistol","357","ar2","xbowbolt","buckshot"}

AntCore.delays = {} --the last time things occured
AntCore.occurs = {} --things that have happened this second
AntCore.nextTime = CurTime()+1

-- Ent spawn/remove clk
AntCore.entSpawnAlert = {}
AntCore.typeSpawnAlert = {}
AntCore.runByEntSpawn = 0
AntCore.runByEntSpawnType = ""
AntCore.lastSpawnedEnt = nil

AntCore.entRemoveAlert = {} -- indexed by either chip (run on all)
AntCore.typeRemoveAlert = {}
AntCore.entRemoveAlertByEnt = {} -- indexed by entity for runOnEntRemove(R)
AntCore.entRemoveAlertArrays = {} -- for undoing runOnEntRemove(R)
AntCore.runByEntRemove = 0
AntCore.runByEntRemoveType = ""
AntCore.runByRemovedEnt = nil

AntCore.bolts = {} -- how many AntCore.bolts a chip has spawned

-- Custom att/infl
AntCore.customAttackers = {}
AntCore.customInflictors = {}

-- max propSpawn per second with propSpawnAsync
AntCore.propSpawnTimes = {} -- modified propSpawn allow solid times (indexed by player)
-- this can be really high due to how async spawning works
AntCore.propspawn_async_maxpersec = CreateConVar("antcore_propspawn_async_maxpersec","60",FCVAR_ARCHIVE)
AntCore.propspawn_async_enabled = CreateConVar("antcore_propspawn_async_enabled","1",FCVAR_ARCHIVE)

function AntCore.copy(t)
  local u = {}
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

function AntCore.setup()
	print("AntCore loading")
	--make effects indexed by value as well
	for key,value in pairs(AntCore.copy(AntCore.boomEffects)) do
		AntCore.boomEffects[value] = key
		AntCore.boomEffectsSize = AntCore.boomEffectsSize+1
	end
	for key,value in pairs(AntCore.copy(AntCore.turretTracers)) do
		AntCore.turretTracers[value] = key
		AntCore.turretTracersSize = AntCore.turretTracersSize+1
	end
	for key,value in pairs(AntCore.copy(AntCore.WeaponGiveWhiteList)) do
		AntCore.WeaponGiveWhiteList[value] = key
	end
	for key,value in pairs(AntCore.copy(AntCore.WeaponControlWhiteList)) do
		AntCore.WeaponControlWhiteList[value] = key
	end
	for key,value in pairs(AntCore.copy(AntCore.AmmoWhiteList)) do
		AntCore.AmmoWhiteList[value] = key
	end
end
AntCore.setup()

function AntCore.OccurReset()
	if CurTime() >= AntCore.nextTime then
		AntCore.occurs = {}
		AntCore.nextTime = CurTime()+1
	end
end
hook.Add("Think","AntCoreAntCore.OccurReset",AntCore.OccurReset)

function AntCore.getDelay(id,delayname)
	if AntCore.delays[id] == nil then AntCore.delays[id] = {} end
	if AntCore.delays[id][delayname] == nil then AntCore.delays[id][delayname] = SysTime() return false end
	
	return SysTime() < AntCore.delays[id][delayname]
end

--sets the delay last time to now
function AntCore.setDelay(id, delayname, length) --length in ms
	AntCore.delays[id][delayname] = SysTime() + length/1000
end

--gets whether an event can occur this second
function AntCore.getCanOccur(id, eventname, maxamt)
	if AntCore.occurs[id] == nil then AntCore.occurs[id] = {} end
	if AntCore.occurs[id][eventname] == nil then AntCore.occurs[id][eventname] = 0 end
	
	return AntCore.occurs[id][eventname] < maxamt
end

function AntCore.setOccur(id, eventname)
	AntCore.occurs[id][eventname] = AntCore.occurs[id][eventname] + 1
end

--an improvement on Divran's boom function, effects are whitelisted
function AntCore.boomCustom(self,effect,pos,damage,radius)
	local Pos = Vector(pos[1],pos[2],pos[3])
	if not util.IsInWorld(Pos) then return end
	effect = string.lower(effect)
	if AntCore.boomEffects[effect] == nil then effect = AntCore.boomEffects[1] end
	if AntCore.getDelay(self.entity,"AntCore.boomCustom") then return end
	
	AntCore.setDelay(self.entity,"AntCore.boomCustom",AntCore.boom_delay:GetFloat())
	
	util.BlastDamage(self.entity, self.player, Pos, math.Clamp(radius,1,50000), math.Clamp(damage,1,10000))
	local effectdata = EffectData()
	effectdata:SetOrigin(Pos)
	util.Effect(effect, effectdata, true, true)
end

--returns the current boomdelay for auto adjusting
__e2setcost(2)
e2function number boomDelay()
	return AntCore.boom_delay:GetFloat()
end

__e2setcost(5)
e2function void boomCustom(string effect, vector pos, number damage, number radius)
	AntCore.boomCustom(self,effect,pos,damage,radius)
end

--overload boom with number tracer
e2function void boomCustom(number effect, vector pos, number damage, number radius)
	effect = math.Max(effect%(AntCore.boomEffectsSize+1),1)
	AntCore.boomCustom(self,AntCore.boomEffects[effect],pos,damage,radius)
end

--a predefined custom boom
--E2Helper.Descriptions["boom2"] = "A silent normal nice looking explosion"
e2function void boom2(vector pos, number damage, number radius)
	AntCore.boomCustom(self,"helicoptermegabomb",pos,damage,radius)
end

--modified hint(s,t), allows hinting to another player, also allows longer persisting (only on yourself by default)
--note: the occurance limit is per the receiver, meaning your own limit is (amount of players * limit)
__e2setcost(5)
e2function void entity:hintPlayer(string text,number persist)
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end	
	if this == self.player then
		if not AntCore.getCanOccur(this,"hintPlayer",AntCore.hintPlayer_persecond_self:GetFloat()) then return end
		
		AntCore.setOccur(this,"hintPlayer")
		WireLib.AddNotify(this, text, NOTIFY_GENERIC, math.Clamp(persist,0.7,AntCore.hintPlayer_persist_max_self:GetFloat()))
	else
		if not AntCore.getCanOccur(this,"hintPlayer",AntCore.hintPlayer_persecond:GetFloat()) then return end
		
		--text = self.player:GetName() .. ": " .. text:sub(1,50)
		text = text:sub(1,70) --truncate to max length
		AntCore.setOccur(this,"hintPlayer")
		this:PrintMessage(HUD_PRINTCONSOLE, "Player '"..self.player:GetName().."' is sending you a hint.")
		WireLib.AddNotify(this, text, NOTIFY_GENERIC, math.Clamp(persist,0.7,AntCore.hintPlayer_persist_max:GetFloat()))
	end
end

e2function void entity:printPlayer(string text)
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end	
	if not AntCore.getCanOccur(this,"printPlayer",AntCore.printPlayer_persecond:GetFloat()) then return end
	
	AntCore.setOccur(this,"printPlayer")
	
	this:PrintMessage(HUD_PRINTCONSOLE, "Player '"..self.player:GetName().."' is printing to your chat.")
	this:ChatPrint(text)
end

--returns whether the player is in e2
--[[__e2setcost(1)
e2function number entity:plyInE2()
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end
	return busyplayers[this] ~= nil
end]]

-- returns if any player is aiming at the entity
__e2setcost(50)
e2function number entity:aimedAt()
	if not IsValid(this) then return end
	for k,ply in pairs(player.GetAll()) do
		if this == ply:GetEyeTraceNoCursor().Entity then return 1 end
	end
	return 0
end

-- array must be indexed by entity id
-- note: this won't be heavier than normal e:aimedAt() though both could
e2function number aimedAt(array entities)
	for k,ply in pairs(player.GetAll()) do
		local ent = ply:GetEyeTraceNoCursor().Entity
		if ent:IsValid() then
			if entities[ent:EntIndex()] ~= nil then return 1 end
		end
	end
	return 0
end

__e2setcost(70)
-- returns an array of players aiming at an entity
e2function array entity:aimingAt()
	if not IsValid(this) then return end
	local tmp = {}
	for k,ply in pairs(player.GetAll()) do
		if this == ply:GetEyeTraceNoCursor().Entity then
			table.insert(tmp, ply)
		end
	end
	self.prf = self.prf + #tmp/3
	return tmp
end

e2function array aimingAt(array entities)
	local tmp = {}
	for k,ply in pairs(player.GetAll()) do
		local ent = ply:GetEyeTraceNoCursor().Entity
		if ent:IsValid() then
			if entities[ent:EntIndex()] ~= nil then
				table.insert(tmp, ply)
			end
		end
	end
	self.prf = self.prf + #tmp/3
	return tmp
end

--toggles shadow on a player
__e2setcost(3)
e2function void entity:plyShadow(number enable)
	if not this:IsPlayer() then return end
	if self.player ~= this then return end
	this:DrawShadow(enable ~= 0)
end



AntCore.npcKillInputs = { ["npc_helicopter"] = "SelfDestruct", ["npc_rollermine"] = "InteractivePowerDown", ["npc_combinegunship"] = "SelfDestruct", ["npc_combinedropship"] = "Break", ["npc_turret_floor"] = "SelfDestruct", ["npc_strider"] = "Break" }

--kills any npc, come on if you think this is exploitable it's not, turrets and explosive props can do worse easily
__e2setcost(2)
e2function void entity:npcKill()
	if not IsValid(this) or !this:IsNPC() then return end
	
	-- npc needs to be killed via input
	if AntCore.npcKillInputs[this:GetClass()] then
		if this.killedByAntCore then return end -- only allow one call
		this.killedByAntCore = true
		this:SetHealth(0) -- give e2s a way to check if its dead
		if this:GetClass() == "npc_helicopter" then
			-- need a delay to prevent crash (even 500ms causes crash with helicopter)
			timer.Simple(1,function() this:Fire(AntCore.npcKillInputs[this:GetClass()]) end)
		else
			this:Fire(AntCore.npcKillInputs[this:GetClass()])
		end
		return
	end
	
	this:SetHealth(1)
	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(game.GetWorld())
	dmginfo:SetInflictor(game.GetWorld())
	dmginfo:SetDamage(this:Health())
	dmginfo:SetDamageType( DMG_DISSOLVE )
	this:TakeDamageInfo(dmginfo)
end

--modified "entity:shootTo" (https://steamcommunity.com/sharedfiles/filedetails/?id=168794775)
function AntCore.turretShoot(ent,self,direction,damage,spread,force,count,tracer)
	if not IsValid(ent) or not isOwner(self, ent) then return end
	
	if AntCore.turretShoot_enabled:GetFloat() == 0 then return end
    if not self.player:IsAdmin() and AntCore.turretShoot_enabled:GetFloat() == 2 then return end
	tracer = string.lower(tracer)
	if AntCore.turretTracers[tracer] == nil then tracer = AntCore.turretTracers[1] end
	
	if not AntCore.getCanOccur(self,"AntCore.turretShoot",AntCore.turretShoot_persecond:GetFloat()) then return end
	AntCore.setOccur(self,"AntCore.turretShoot")
	
    local bullet = {}
    bullet.Num = math.Clamp(count,1,AntCore.turretShoot_count_max:GetFloat())
    bullet.Src = ent:GetPos()
    bullet.Dir = Vector(direction[1],direction[2],direction[3]) 
    bullet.Spread = Vector(math.Clamp(spread,0,AntCore.turretShoot_spread_max:GetFloat()),math.Clamp(spread,0,AntCore.turretShoot_spread_max:GetFloat()),0)
    bullet.Tracer = 1
    bullet.TracerName = tracer
    bullet.Force = force --auto clamped
    bullet.Damage = math.Clamp(damage,-AntCore.turretShoot_damage_max:GetFloat(),AntCore.turretShoot_damage_max:GetFloat())
    bullet.Attacker = self.player
    bullet.Inflictor = ent
	
    ent:FireBullets(bullet)
end

--returns the turret delay so users can adjust e2s
__e2setcost(2)
e2function number turretShootLimit()
	return AntCore.turretShoot_persecond:GetFloat()
end

__e2setcost(20)
--E2Helper.Descriptions["AntCore.turretShoot"] = "Fire a turret bullet from an entity with direction, spread, force, damage, count, and tracer"
e2function void entity:turretShoot(vector direction,number damage,number spread, number force,number count, string tracer)
    AntCore.turretShoot(this,self,direction,damage,spread,force,count,tracer)
end

--override with numeric tracer
e2function void entity:turretShoot(vector direction,number damage,number spread, number force,number count, number tracer)
	tracer = math.Max(tracer%(AntCore.turretTracersSize+1),1)
    AntCore.turretShoot(this,self,direction,damage,spread,force,count,AntCore.turretTracers[tracer])
end

--just an override to make it simpler
e2function void entity:turretShoot(vector direction,number damage,number count, string tracer)
    AntCore.turretShoot(this,self,direction,damage,0,0,count,tracer)
end

--override with numeric tracer
e2function void entity:turretShoot(vector direction,number damage,number count, number tracer)
	tracer = math.Max(tracer%(AntCore.turretTracersSize+1),1)
    AntCore.turretShoot(this,self,direction,damage,0,0,count,AntCore.turretTracers[tracer])
end


-- both copied straight from constraintcore
function AntCore.checkEnts(self, ent1, ent2)
	if !ent1 || (!ent1:IsValid() && !ent1:IsWorld()) || !ent2 || (!ent2:IsValid() && !ent2:IsWorld()) || ent1 == ent2 then return false end
	if !isOwner(self, ent1) || !isOwner(self, ent2) then return false end
	return true
end
function AntCore.addundo(self, prop, message)
	self.player:AddCleanup( "constraints", prop )
	if self.data.constraintUndos then
		undo.Create("e2_"..message)
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish()
	end
end

__e2setcost(30)
e2function void rope(number index, entity ent1, vector lpos1, entity ent2, vector lpos2, number length, number addLength, number width, string material, number rigid)
	if !AntCore.checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(lpos1[1], lpos1[2], lpos1[3]), Vector(lpos2[1], lpos2[2], lpos2[3])
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	if material == "" then material = "cable/rope" end
	
	ent1.data.Ropes[index] = constraint.Rope(ent1,ent2,0,0, vec1, vec2, length, addLength,0,width,material,rigid ~= 0)
	AntCore.addundo(self, ent1.data.Ropes[index], "rope")
end

-- automatic length
e2function void rope(number index, entity ent1, vector lpos1, entity ent2, vector lpos2, number width, string material, number rigid)
	if !AntCore.checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(lpos1[1], lpos1[2], lpos1[3]), Vector(lpos2[1], lpos2[2], lpos2[3])
	local length = (ent1:LocalToWorld(vec1) - ent2:LocalToWorld(vec2)):Length()
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	if material == "" then material = "cable/rope" end
	
	ent1.data.Ropes[index] = constraint.Rope(ent1,ent2,0,0, vec1, vec2, length,0,0,width,material,rigid ~= 0)
	AntCore.addundo(self, ent1.data.Ropes[index], "rope")
end

e2function void elastic(index,entity ent1,vector lpos1,entity ent2,vector lpos2,string material,width,compression,constant,dampen)
	if !AntCore.checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(lpos1[1],lpos1[2],lpos1[3]), Vector(lpos2[1],lpos2[2],lpos2[3])
	if width < 0 || width > 50 then width = 1 end
	
	if IsValid(ent1.data.Ropes[index]) then
		ent1.data.Ropes[index]:Remove()
	end
	
	if material == "" then material = "cable/cable2" end
	local rdampen = dampen
	
	ent1.data.Ropes[index] = constraint.Elastic( ent1, ent2, 0, 0, vec1, vec2, constant, dampen, rdampen, material, width, compression == 0 )
	AntCore.addundo(self, ent1.data.Ropes[index], "elastic")
end


__e2setcost(5)
e2function void entity:giveWeapon(string weapname)
	if AntCore.weapons_enabled:GetFloat() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if not AntCore.WeaponGiveWhiteList[weapname] then return end
	
	this:Give(weapname)
end

-- create function once for performance
AntCore.entCreated = function(ent)
	if not IsValid(ent) then return end
	
	local enttype = ent:GetClass()
	AntCore.runByEntSpawn = 1
	AntCore.lastSpawnedEnt = ent
	for e,_ in pairs(AntCore.entSpawnAlert) do
		if IsValid(e) then
			e:Execute()
		else
			AntCore.entSpawnAlert[e] = nil
		end
	end
	if AntCore.typeSpawnAlert[enttype] then
		for e,_ in pairs(AntCore.typeSpawnAlert[enttype]) do
			if IsValid(e) then
				e:Execute()
			else
				AntCore.typeSpawnAlert[enttype][e] = nil
			end
		end
	end
	AntCore.runByEntSpawn = 0
	--AntCore.lastSpawnedEnt = nil may aswell keep it alive
end

hook.Add("OnEntityCreated","antcore_onentitycreated", function(ent)
	-- delay for initialization, also only create small parser function
	timer.Simple(0, function() AntCore.entCreated(ent) end)
end)

hook.Remove("EntityRemoved","antcore_entityremoved")
hook.Add("EntityRemoved","antcore_entityremoved", function(ent)
	-- don't need a delay here
	if not IsValid(ent) then return end
	
	local enttype = ent:GetClass()
	AntCore.runByEntRemove = 1
	AntCore.runByRemovedEnt = ent
	
	for e,_ in pairs(AntCore.entRemoveAlert) do --runOnEnt(n) chips
		if IsValid(e) then
			-- dont execute for itself removing
			if e != ent and not e.context.data.last and not e.removing then
				e:Execute()
			end
		else
			AntCore.entRemoveAlert[e] = nil
		end
	end
	if AntCore.typeRemoveAlert[enttype] then
		for e,_ in pairs(AntCore.typeRemoveAlert[enttype]) do --runOnEntTypeSpawn(t,n) chips
			if IsValid(e) then
				-- dont execute for itself removing
				if e != ent and not e.context.data.last and not e.removing then
					e:Execute()
				end
			else
				AntCore.typeRemoveAlert[enttype][e] = nil
			end
		end
	end
	if AntCore.entRemoveAlertByEnt[ent] then
		for e,_ in pairs(AntCore.entRemoveAlertByEnt[ent]) do --runOn..(R) chips
			if IsValid(e) then
				-- dont execute for itself removing
				if e != ent and not e.context.data.last and not e.removing then
					e:Execute()
				end
			end
			AntCore.entRemoveAlertByEnt[ent][e] = nil --the ent is being removed, clean up
		end
	end
	
	AntCore.runByEntRemove = 0
	AntCore.runByRemovedEnt = nil
	
	--if its a crossbow bolt spawned by a chip, lower the chip's count
	if enttype == "crossbow_bolt" and ent.antcoreChip then
		AntCore.bolts[ent.antcoreChip] = AntCore.bolts[ent.antcoreChip] - 1
	elseif enttype == "wire_expression2" then
		if AntCore.bolts[ent] then AntCore.bolts[ent] = nil end --clean up
	end
end)

-- by default any custom spawned bolt wont do damage, override it using this
-- also for other damage stuff
hook.Add("EntityTakeDamage", "antcore_ent_damage", function(target, dmginfo)
	local inflictor = dmginfo:GetInflictor()
	if !IsValid(inflictor) then return end -- bug in another addon
	
	--if inflictor == NULL then return end
	if inflictor:GetClass() == "crossbow_bolt" and inflictor.antcoreDmg then
		dmginfo:SetDamage(inflictor.antcoreDmg)
		dmginfo:SetAttacker(inflictor:GetOwner())
	end
	
	if IsValid(AntCore.customInflictors[inflictor]) then
		inflictor = AntCore.customInflictors[inflictor]
		dmginfo:SetInflictor(inflictor)
	end
	
	local customAtt = AntCore.customAttackers[inflictor]
	if IsValid(customAtt) and customAtt:IsVehicle() then
		if IsValid(customAtt:GetDriver()) then
			dmginfo:SetAttacker(customAtt:GetDriver())
		end
	end
end)

e2function void entity:dropWeapon(string weapname)
	if AntCore.weapons_enabled:GetFloat() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	
	if not AntCore.getCanOccur(this, "drop weapon", AntCore.dropweapon_persecond:GetFloat()) then return end
	
	weapname = string.lower(weapname)
	if AntCore.weapons_remove_any:GetInt() ~= 1 and not AntCore.WeaponControlWhiteList[weapname] then return end
	
	this:DropNamedWeapon(weapname)
	
	AntCore.setOccur(this, "drop weapon")
end

e2function void entity:removeWeapon(string weapname)
	if AntCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if AntCore.weapons_remove_any:GetInt() ~= 1 and not AntCore.WeaponControlWhiteList[weapname] then return end
	
	this:StripWeapon(weapname)
end

e2function number entity:hasWeapon(string weapname)
	if AntCore.weapons_enabled:GetInt() < 1 then return nil end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	--if this ~= self.player then return end
	weapname = string.lower(weapname)
	--if not WeaponWhiteList[weapname] then return end
	
	if this:HasWeapon(weapname) then return 1 else return 0 end
end

e2function array entity:getWeapons()
	if AntCore.weapons_enabled:GetInt() < 1 then return nil end
	if not IsValid(this) then return end
	if not this:IsPlayer() then return end
	--if this ~= self.player then return end -- disabled this
	
	return this:GetWeapons()
end

e2function void entity:giveAmmo(string ammoname, number count)
	if AntCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	ammoname = string.lower(ammoname)
	if not AntCore.AmmoWhiteList[ammoname] then return end

	this:GiveAmmo(math.Clamp(count,1,9999), ammoname, false)
end

e2function void entity:setAmmo(string ammoname, number count)
	if AntCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	ammoname = string.lower(ammoname)
	if not AntCore.AmmoWhiteList[ammoname] then return end
	
	this:SetAmmo(math.Clamp(count,0,9999), ammoname)
end

e2function void entity:selectWeaponSlot(number slot)
	if AntCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	
	local weaps = this:GetWeapons()
	if not weaps[slot] then return end

	this:SetActiveWeapon(weaps[slot])
end

local function getWeapon(player, weap)
	for k,v in pairs(player:GetWeapons()) do
		if string.lower(v:GetClass()) == weap then
			return v
		end
	end
end

__e2setcost(30) --because these all use iteration
e2function entity entity:getWeapon(string weapname)
	if AntCore.weapons_enabled:GetInt() < 1 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	--if not WeaponWhiteList[weapname] then return end

	return getWeapon(this, weapname)
end

e2function void entity:selectWeapon(string weapname)
	if AntCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if AntCore.weapons_remove_any:GetInt() ~= 1 and not AntCore.WeaponControlWhiteList[weapname] then return end
	
	local weap = getWeapon(this, weapname) 
	if not IsValid(weap) then return end
	if not weap:IsWeapon() then return end

	this:SetActiveWeapon(weap)
end

e2function void entity:setClip1(string weapname, number count)
	if AntCore.weapons_enabled:GetInt() < 2 then return end
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	weapname = string.lower(weapname)
	if not AntCore.WeaponControlWhiteList[weapname] then return end
	
	local weap = getWeapon(this, weapname)
	if not weap:IsWeapon() then return end
	
	weap:SetClip1(math.Clamp(count,0,9999))
end

__e2setcost(2)

e2function void entity:plySetRenderFX(number effect)
	if not this or not this:IsValid() or not this:IsPlayer() then return end
	if this ~= self.player then return end
	
	this:SetKeyValue("renderfx",effect)
end

e2function void entity:plyAlpha(number alpha)
	if this ~= self.player then return end
	this:Fire( "alpha", alpha)
	-- shouldnt have to undo this
	this:SetRenderMode( RENDERMODE_TRANSALPHA )
end

__e2setcost(5)
e2function void entity:weapSetMaterial(string mat)
	if not this or not this:IsValid() then return end
	if not isOwner(self, this) then return end
	if not getOwner(self, this):HasWeapon(this:GetClass()) then return end --my only way to tell if its a weap
	if string.lower(mat) == "pp/AntCore.copy" then return end --this was in the source of entity:setMaterial
	this:SetMaterial(mat)
end

__e2setcost(2)
-- Returns the closest entity to the center of a FOV
e2function entity findClosestCentered(vector pos, vector dir)
	dir = Vector(dir[1], dir[2], dir[3]):GetNormalized()
	local closest = nil
	local maxDot = -math.huge
	self.prf = self.prf + #self.data.findlist * 10
	for _,ent in pairs(self.data.findlist) do
		if IsValid(ent) then
			local pos2 = ent:GetPos()
			local dir2 = Vector(pos2.x-pos.x, pos2.y-pos.y, pos2.z-pos.z):GetNormalized()
			local dot = dir.x*dir2.x + dir.y*dir2.y + dir.z*dir2.z
			if dot > maxDot then -- closest dot to 1 (cos 0 is 1) is closest to center angle
				maxDot = dot
				closest = ent
			end
		end
	end
	return closest
end

--modified findToArray from find.lua, with maxresults to improve chip and server performance
--note: I was going (got pretty far) to completely remake the find.lua functions to optimise server performance even more but those rely on garry's mod's built in find functions which would have their, own optimisations, and also doing all of that would make antcore unnecessarily huge
__e2setcost(2)
e2function array findToArray(number maxresults)
	local count = 0
	local tmp = {}
	for k,v in ipairs(self.data.findlist) do
		if count >= maxresults then break end
		tmp[k] = v
		count = count + 1
	end
	self.prf = self.prf + #tmp / 3
	return tmp
end

__e2setcost(10)
-- modified findExcludeEntities:
-- the default function exits the whole function when it reaches an invalid entity
-- entity, this is annoying if you keep an array because if one entity half way in
-- the array is deleted, it will basically stop working for half of the entities
e2function void findForceExcludeEntities(array arr)
	local bl_entity = self.data.find.bl_entity

	for _,ent in ipairs(arr) do
		if IsValid(ent) then
			bl_entity[ent] = true
		end
	end
	self.data.findfilter = nil -- invalidate find.lua filter
end

-- the same as the above but for Include
e2function void findForceIncludeEntities(array arr)
	local wl_entity = self.data.find.wl_entity
	
	for _,ent in ipairs(arr) do
		if IsValid(ent) then
			wl_entity[ent] = true
		end
	end
	self.data.findfilter = nil -- invalidate find.lua filter
end

__e2setcost(5)
e2function void entity:setModel(string model)
	if not IsValid(this) then return end
	if this:GetClass() != "prop_physics" and this:GetClass() != self.entity:GetClass() then return end
	if not isOwner(self, this) then return end
	if not util.IsValidModel(model) then return end
	this:SetModel(model)
	this:GetPhysicsObject():Wake()
end

function AntCore.SpawnEntity(limittype,limitname,self,class,model,pos,ang,freeze)
	if not util.IsValidModel( model ) then return nil end
	if not AntCore.getCanOccur(self.player,"spawn entity",AntCore.entities_spawn_persecond:GetInt()) then return nil end
	
	AntCore.setOccur(self.player,"spawn entity")
	
	if IsValid(self.player) and (!self.player:CheckLimit(limittype)) then
		WireLib.AddNotify(self.player, "You've hit the "..limitname.." limit", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
		return nil
	end
	
	local ent = ents.Create(class)
	ent:SetModel(model)
	ent:SetPos(Vector(pos[1],pos[2],pos[3]))
	ent:SetAngles(Angle(ang[1],ang[2],ang[3]))
	ent:SetCreator(self.player)
	ent:SetPlayer(self.player)
	
	if IsValid(self.player) then self.player:AddCount( limittype, ent ) end
	
	self.player:AddCleanup( "E2_"..class, ent )
	
	if self.data.propSpawnUndo then
		undo.Create( "[E2] "..class )
		undo.AddEntity( ent )
		undo.SetPlayer(self.player)
		undo.Finish()
	end
	
	ent:CallOnRemove( "wire_expression2_antcore_entity_remove",
		function( ent )
			self.data.spawnedProps[ ent ] = nil
		end
	)
	self.data.spawnedProps[ ent ] = self.data.propSpawnUndo
		
	ent:Spawn()
	
	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Wake()
		phys:EnableMotion( freeze == 0 )
	end
	
	return ent
end

__e2setcost(10)
e2function entity spawnEgp(string model,vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	if (EGP.ConVars.AllowScreen:GetInt() == 0) then
		self.player:ChatPrint("[EGP] The server has blocked EGP screens.")
		return NULL
	end
	
	local ent = AntCore.SpawnEntity("wire_egps","EGP",self,"gmod_wire_egp",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:Activate()
	ent:SetEGPOwner( self.player )
	return ent
end

e2function entity spawnEgpHud(vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	if (EGP.ConVars.AllowHUD:GetInt() == 0) then
		self.player:ChatPrint("[EGP] The server has blocked EGP HUDs.")
		return NULL
	end
	
	local ent = AntCore.SpawnEntity("wire_egps","EGP",self,"gmod_wire_egp_hud","models/bull/dynamicbutton.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:Activate()
	ent:SetEGPOwner( self.player )
	return ent
end

e2function entity spawnEgpEmitter(vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	if (EGP.ConVars.AllowEmitter:GetInt() == 0) then
		self.player:ChatPrint("[EGP] The server has blocked EGP emitters.")
		return NULL
	end
	
	local ent = AntCore.SpawnEntity("wire_egps","EGP",self,"gmod_wire_egp_emitter","models/bull/dynamicbutton.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:Activate()
	ent:SetEGPOwner( self.player )
	return ent
end

e2function entity spawnWireUser(string model,vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
		
	ent = AntCore.SpawnEntity("wire_users","wire user",self,"gmod_wire_user",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local range = 100
	ent:Setup(range)
	ent:Activate()
	return ent
end

e2function entity spawnWireUser(string model,vector pos,angle ang,number freeze,number range)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
		
	ent = AntCore.SpawnEntity("wire_users","wire user",self,"gmod_wire_user",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:Setup(range)
	ent:Activate()
	return ent
end

e2function entity spawnWireForcer(string model,vector pos,angle ang,number freeze)	
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	ent = AntCore.SpawnEntity("wire_forcers","wire forcer",self,"gmod_wire_forcer",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local force, length, showbeam, reaction = 50, 200, 1, 0
	
	ent:Setup(force, length, showbeam, reaction)
	ent:Activate()
	return ent
end

e2function entity spawnWireForcer(string model,vector pos,angle ang,number freeze,number force, number range, number beam, number reaction)	
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	ent = AntCore.SpawnEntity("wire_forcers","wire forcer",self,"gmod_wire_forcer",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:Setup(force, range, beam, reaction)
	ent:Activate()
	return ent
end

e2function entity spawnExpression2(string model,vector pos,angle ang)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	if not AntCore.entities_spawn_e2chip:GetBool() then return NULL end
	
	if IsValid(self.player) and (!self.player:CheckLimit("wire_expressions")) then
		WireLib.AddNotify(self.player, "You've hit the expression 2 limit", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
		return NULL
	end
	
	-- doesnt use spawnEntity
	local ent = MakeWireExpression2(self.player, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]), model)
	if not IsValid(ent) then return NULL end
	
	if IsValid(self.player) then self.player:AddCount( "wire_expressions", ent ) end
	
	self.player:AddCleanup( "wire_expression2", ent )
	
	if self.data.propSpawnUndo then
		undo.Create( "wire_expression2" )
		undo.AddEntity( ent )
		undo.SetPlayer(self.player)
		undo.Finish()
	end
	
	ent:CallOnRemove( "wire_expression2_antcore_e2_remove",
		function( ent )
			self.data.spawnedProps[ ent ] = nil
		end
	)
	self.data.spawnedProps[ ent ] = self.data.propSpawnUndo
	
	return ent
end

e2function entity spawnTextEntry(string model,vector pos,angle ang,number freeze,number disableuse)	
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
		
	local ent = AntCore.SpawnEntity("wire_textentrys","text entry",self,"gmod_wire_textentry",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:SetPlayer(self.player)
	ent:Setup(freeze,disableuse)
	return ent
end

e2function entity spawnTextScreen(string model,vector pos,angle ang,number freeze)	
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_textscreens","text screen",self,"gmod_wire_textscreen",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor = "", 10, 1, 1, "Arial", Color(255,255,255), Color(0,0,0)
	ent:Setup(DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor)
	
	return ent
end

e2function entity spawnTextScreen(string model,vector pos,angle ang,number freeze,number textsize)	
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_textscreens","text screen",self,"gmod_wire_textscreen",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor = "", 15-textsize, 1, 1, "Arial", Color(255,255,255), Color(0,0,0)
	ent:Setup(DefaultText, chrPerLine, halign, valign, tfont, fgcolor, bgcolor)
	
	return ent
end

e2function entity spawnButton(string model,vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_buttons","button",self,"gmod_wire_button",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local toggle, value_off, value_on, desc, entityout = false, 0, 1, "", true
	ent:Setup(toggle, value_off, value_on, description, entityout)
	
	return ent
end

e2function entity spawnButton(string model,vector pos,angle ang,number freeze,number toggle, number on, number off)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
			
	local ent = AntCore.SpawnEntity("wire_buttons","button",self,"gmod_wire_button",model,pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local desc, entityout = "", true
	ent:Setup(toggle, off, on, description, entityout)
	
	return ent
end

e2function entity spawnPodController(vector pos,angle ang,number freeze, entity pod)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_pods","pod controller",self,"gmod_wire_pod","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	return ent
end

e2function entity spawnEyePod(vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_eyepods","eye pod",self,"gmod_wire_eyepod","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local defaultzero, rateOfChange, minx, miny, maxx, maxy = 1, 1, 0, 0, 0, 0
	ent:Setup(defaultzero, rateOfChange, minx, miny, maxx, maxy)
	
	return ent
end

e2function entity spawnEyePod(vector pos,angle ang,number freeze,number defaultzero, number cumulative, vector2 min, vector2 max)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_eyepods","eye pod",self,"gmod_wire_eyepod","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	local defaultzero, rateOfChange = true
	local rateOfChange = 0
	if cumulative == 0 then rateOfChange = 1 end
	ent:Setup(defaultzero, rateOfChange, min[1], min[2], max[1], max[2])
	
	return ent
end

e2function entity spawnCamController(vector pos,angle ang,number freeze,number parentLocal,number autoMove,number localMove,number allowZoom,number autoUnclip,number drawPlayer,number autoUnclip_IgnoreWater,number drawParent)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_cameracontrollers","cam controller",self,"gmod_wire_cameracontroller","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	ent:Setup(parentLocal,autoMove,localMove,allowZoom,autoUnclip,drawPlayer,autoUnclip_IgnoreWater,drawParent)
	return ent
end

e2function entity spawnCamController(vector pos,angle ang,number freeze)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	local ent = AntCore.SpawnEntity("wire_cameracontrollers","cam controller",self,"gmod_wire_cameracontroller","models/jaanus/wiretool/wiretool_range.mdl",pos,ang,freeze)
	if not IsValid(ent) then return NULL end
	
	-- default setup
	local parentLocal = 1
	local autoMove = 1
	local localMove = 1
	local allowZoom = 0
	local autoUnclip = 0
	local drawPlayer = 1
	local autoUnclip_IgnoreWater = 0
	local drawParent = 1
	
	ent:Setup(parentLocal,autoMove,localMove,allowZoom,autoUnclip,drawPlayer,autoUnclip_IgnoreWater,drawParent)
	return ent
end

__e2setcost(20)
e2function void entity:linkToPod(entity pod)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	if this.LinkEnt then this:LinkEnt(pod) end -- most wire ents use this
	if this.PodLink then this:PodLink(pod) end -- eye pods use this
end

__e2setcost(2)
e2function void runOnEntSpawn(number activate)
	if activate ~= 0 then
		AntCore.entSpawnAlert[self.entity] = true
	else
		AntCore.entSpawnAlert[self.entity] = nil
	end
end

e2function void runOnEntRemove(number activate)
	if activate ~= 0 then
		AntCore.entRemoveAlert[self.entity] = true
	else
		-- cleanup arrays
		if AntCore.entRemoveAlertArrays[self] then
			for ent,_ in pairs(AntCore.entRemoveAlertArrays[self]) do
				-- dont touch other chips indexed by this ent
				AntCore.entRemoveAlertByEnt[ent][self.entity] = nil
			end
			AntCore.entRemoveAlertArrays[self] = nil
		end
		AntCore.entRemoveAlert[self.entity] = nil
	end
end

e2function void runOnEntSpawn(string type, number activate)
	AntCore.typeSpawnAlert[type] = AntCore.typeSpawnAlert[type] or {}
	if activate ~= 0 then
		AntCore.typeSpawnAlert[type][self.entity] = true
	else
		AntCore.typeSpawnAlert[type][self.entity] = nil
	end
end

e2function void runOnEntRemove(string type, number activate)
	AntCore.typeRemoveAlert[type] = AntCore.typeRemoveAlert[type] or {}
	if activate ~= 0 then
		AntCore.typeRemoveAlert[type][self.entity] = true
	else
		AntCore.typeRemoveAlert[type][self.entity] = nil
		
		if AntCore.entRemoveAlertArrays[self] then --remove all the runOnEntRemove(R) entities
			for ent,_ in pairs(AntCore.entRemoveAlertArrays[self]) do
				AntCore.entRemoveAlert[ent][self.entity] = nil --removed from the main array
			end
			AntCore.entRemoveAlertArrays[self] = nil
		end
	end
end

e2function void runOnEntRemove(array entities)
	AntCore.entRemoveAlertArrays[self] = AntCore.entRemoveAlertArrays[self] or {}
	for n,ent in pairs(entities) do
		if ent:IsValid() then
			AntCore.entRemoveAlertByEnt[ent] = AntCore.entRemoveAlertByEnt[ent] or {} --ensure exist
			AntCore.entRemoveAlertByEnt[ent][self.entity] = true
			AntCore.entRemoveAlertArrays[self][ent] = true --mark here for removing with runOnEntRemove(0)
		end
	end
end

-- index (or unindex) a specific entity from the runOnRemove list
e2function void runOnEntRemove(entity ent, number activate)
	if not IsValid(ent) then return end
	
	if activate == 0 then
		if AntCore.entRemoveAlertByEnt[ent] then
			if AntCore.entRemoveAlertByEnt[ent][self.entity] then
				AntCore.entRemoveAlertByEnt[ent][self.entity] = nil
			end
		end
	else--if AntCore.entRemoveAlertByEnt[ent][self.entity] = true
		AntCore.entRemoveAlertByEnt[ent] = AntCore.entRemoveAlertByEnt[ent] or {} --ensure exist
		AntCore.entRemoveAlertByEnt[ent][self.entity] = true
	end
end

e2function number entSpawnClk()
	return AntCore.runByEntSpawn
end

e2function entity spawnedEnt()
	return AntCore.lastSpawnedEnt
end

e2function number entRemoveClk()
	return AntCore.runByEntRemove
end

e2function entity removedEnt()
	return AntCore.runByRemovedEnt
end

function AntCore.shootBolt(self, pos, vel, damage)
	if not AntCore.getCanOccur(self,"crossbow bolt",AntCore.bolt_persecond:GetInt()) then return nil end
	if not AntCore.bolts[self] then
		AntCore.bolts[self] = 0
	elseif AntCore.bolts[self] >= AntCore.bolt_max:GetInt() then return end
	
	local bolt = ents.Create("crossbow_bolt")
    if not IsValid(bolt) then return end
	AntCore.setOccur(self,"crossbow bolt")
	
	AntCore.bolts[self] = AntCore.bolts[self] + 1
	
	bolt:SetPos( Vector(pos[1],pos[2],pos[3]) )
	bolt:SetOwner(self.player)
	bolt.m_iDamage = damage
	bolt.antcoreDmg = bolt.m_iDamage
	bolt.antcoreChip = self
	bolt:Spawn()
	local Vel = Vector(vel[1],vel[2],vel[3])
	bolt:SetVelocity( Vel )
	bolt:SetAngles(Vel:Angle())
	
	return bolt
end

__e2setcost(5)
e2function entity shootBolt(vector pos, vector vel)
	return AntCore.shootBolt(self, pos, vel, 100)
end

e2function entity shootBolt(vector pos, vector vel, number damage)
	return AntCore.shootBolt(self, pos, vel, damage)
end

e2function entity shootBolt(vector pos, angle dir)
	local vel = Vector(3500, 0, 0)
	vel:Rotate(Angle(dir[1], dir[2], dir[3]))
	return AntCore.shootBolt(self, pos, vel, 100)
end

e2function entity shootBolt(vector pos, angle dir, number damage)
	local vel = Vector(3500, 0, 0)
	vel:Rotate(Angle(dir[1], dir[2], dir[3]))
	return AntCore.shootBolt(self, pos, vel, damage)
end


--incomplete, spawns a tiny indefinite-timed ball
--[[
e2function entity combineBallSpawn(vector pos, vector vel, number damage)
	if not AntCore.getCanOccur(self,"combine ball",AntCore.combine_persecond:GetInt()) then return nil end
	
	local ball = ents.Create("prop_AntCore.combine_ball")
    if not IsValid(ball) then return end
	AntCore.setOccur(self,"combine ball")

	ball:SetPos( Vector(pos[1],pos[2],pos[3]) )
	ball:SetOwner(self.Owner)
	ball.m_iDamage = damage
	ball.antcoreDmg = ball.m_iDamage
	ball:Spawn()
	--ball:SetVelocity( Vector(vel[1],vel[2],vel[3]) )
	
	local phys = ball:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(vel[1]*phys:GetMass(),vel[2]*phys:GetMass(),vel[3]*phys:GetMass()))
	
	ball:Setup(5)
	
	return ball
end]]

__e2setcost(5)
e2function entity spawnRTCam( vector pos, angle ang, number freeze)
	
	-- grouped RTcam limit with cameras here deliberately
	-- RT cams normally have no limit, this seems a bit nicer
	local cam = AntCore.SpawnEntity("cameras","RT cam",self,"gmod_rtcameraprop","models/dav0r/camera.mdl",pos,ang,freeze)
	if not IsValid(cam) then return NULL end
	
	UpdateRenderTarget(cam)
	return cam
end

--[[
	Custom attackers/inflictors
	allows entity owners to change what entity they are attacking with,
	this means that if you have a vehicle that players are using to kill other players with
	the kills will come up as what they actually are, and you wont be responsible
	note: only works with
]]

-- whenever this entity (inflictor) does damage, the attacker will be set to the driver
-- (if the driver is valid at the time)
e2function void entity:podSetAttacker(entity inflictor)
	if not IsValid(this) or not IsValid(newinflictor) then return end
	if not isOwner(self, this) or not this:IsVehicle() then return end
	if not isOwner(self, inflictor) then return end
	
	AntCore.customAttackers[inflictor] = this
end

-- whenever this entity (this) does damage, the inflictor will be set to newinflictor
e2function void entity:setInflictor(entity newinflictor)
	if not IsValid(this) or not IsValid(newinflictor) then return end
	if not isOwner(self, this) or not isOwner(self, newinflictor)  then return end
	
	AntCore.customInflictors[this] = newinflictor
end

__e2setcost(3)
e2function void entity:setVelocity(vector vel)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocity(Vector(vel[1],vel[2],vel[3]))
	end
end

__e2setcost(3)
e2function void entity:setAngVel(angle angVel)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:AddAngleVelocity(Vector(angVel[3],angVel[1],angVel[2])-phys:GetAngleVelocity())
	end
end

__e2setcost(3)
e2function void entity:addAngVel(angle angVel)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:AddAngleVelocity(Vector(angVel[3],angVel[1],angVel[2]))
	end
end

__e2setcost(2)
e2function void entity:keepUpright()
	if not IsValid(this) or not isOwner(self, this) then return end
	constraint.Keepupright(this,this:GetAngles(),0,999999) -- default context menu values
end

e2function void entity:keepUpright(angle ang)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	constraint.Keepupright(this,Angle(ang[1],ang[2],ang[3]),0,999999)
end

e2function void entity:keepUpright(angle ang, number bone, number angularLimit)
	if not IsValid(this) or not isOwner(self, this) then return end

	constraint.Keepupright(this,Angle(ang[1],ang[2],ang[3]),bone,angularLimit)
end

e2function void entity:setModelScale(number scale)
	if not IsValid(this) or not isOwner(self, this) then return end
	if this:GetClass() == "prop_ragdoll" then return end -- self explanatory	

	scale = math.Clamp(scale,-50,50)
	this.modelScale = Vector(scale,scale,scale) -- stored because e:GetModelScale errors
	this:SetModelScale(scale, 0)
end

__e2setcost(5)
e2function void entity:setModelScale(number scale, number deltaTime)
	if not IsValid(this) or not isOwner(self, this) then return end
	if this:GetClass() == "prop_ragdoll" then return end -- self explanatory	
	
	scale = math.Clamp(scale,-50,50)
	this:SetModelScale(scale, deltaTime)
end

AntCore.setPhysScale = function( ent, scale )

	ent:PhysicsInit( SOLID_VPHYSICS )

	local physobj = ent:GetPhysicsObject()

	if ( not IsValid( physobj ) ) then return false end

	local physmesh = physobj:GetMeshConvexes()

	if ( not istable( physmesh ) ) or ( #physmesh < 1 ) then return false end

	for convexkey, convex in pairs( physmesh ) do

		for poskey, postab in pairs( convex ) do

			convex[ poskey ] = postab.pos * scale

		end

	end

	ent:PhysicsInitMultiConvex( physmesh )

	ent:EnableCustomCollisions( true )

	return IsValid( ent:GetPhysicsObject() )

end

e2function void entity:setPhysScale(number scale)
	if not IsValid(this) or not isOwner(self, this) or not IsValid(this:GetPhysicsObject()) then return end
	local scale = math.Clamp(scale,AntCore.physscale_min:GetFloat(),AntCore.physscale_max:GetFloat())
	this.physScale = Vector(scale,scale,scale) -- for getter
	AntCore.setPhysScale(this, this.physScale)
end

e2function vector entity:getPhysScale()
	if not IsValid(this) then return Vector(0,0,0) end
	
	local advMods = this:GetTable()['advr'] -- advanced resizer mods
	if advMods then return Vector(advMods[1],advMods[2],advMods[3]) end
	
	return this.physScale or Vector(1,1,1)
end



__e2setcost(2)
e2function vector entity:getModelScale()
	if not IsValid(this) then return Vector(0,0,0) end
	
	local advMods = this:GetTable()['advr'] -- advanced resizer mods
	if advMods then return Vector(advMods[4],advMods[5],advMods[6]) end
	
	-- e:GetModelScale errors
	return this.modelScale and this.modelScale or Vector(1,1,1)
end

e2function angle entity:getModelAngle()
	if not IsValid(this) then return end
	if this.modelAngle then return this.modelAngle end
	return Angle(0,0,0)
end

--util.AddNetworkString("antcore_physcale");

function AntCore.SetMesh(this, oldmesh, nextmesh, mass)

	this:PhysicsInit(SOLID_VPHYSICS)
	
	if #oldmesh > 1 then
		this:PhysicsInitMultiConvex(nextmesh) -- multi (uncommon)
	else
		this:PhysicsInitConvex(nextmesh) -- normal
	end
	
	this:GetPhysicsObject():SetMass(mass)
	this:GetPhysicsObject():Wake() -- woke AF
	--this:Activate()
	--this:GetPhysicsObject():EnableMotion(false)
	--this:GetPhysicsObject():EnableMotion(true)
	this:EnableCustomCollisions(true) -- apparently problems without this
	
	-- Send it to clients
	--[[net.Start("antcore_physcale")
	net.WriteInt(this:EntIndex(),32)
	net.WriteVector(scale)
	net.Broadcast()]]
end

function AntCore.ScaleMesh(this, scale)
	
	--this:PhysicsInit(SOLID_VPHYSICS)
	
	local oldmesh = this.oldMesh or this:GetPhysicsObject():GetMeshConvexes()
	this.oldMesh = oldmesh
	this.meshScale = scale -- for e:getPhysScale
	local nextmesh = {}
	
	if #oldmesh > 1 then
		for i=1,#oldmesh do
			nextmesh[i] = {}
			for v=1,#oldmesh[i] do
				nextmesh[i][v] = oldmesh[i][v].pos*scale
			end
		end
	else
		for v=1,#oldmesh[1] do
			nextmesh[v] = oldmesh[1][v].pos*scale
		end
	end
	
	AntCore.SetMesh(this, oldmesh, nextmesh, this:GetPhysicsObject():GetMass())
end

__e2setcost(10)
e2function void entity:resetPhysics()
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	-- resets the physics based on the current model
	this:PhysicsInit(SOLID_VPHYSICS)
end

util.AddNetworkString("antcore_editmodel");

__e2setcost(10)
e2function void entity:editModel(vector scale, angle ang)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	-- just for get functions
	this.modelScale = Vector(math.Clamp(scale[1],-50,50), math.Clamp(scale[2],-50,50), math.Clamp(scale[3],-50,50))
	this.modelAngle = ang
	
	-- ISSUE:
	-- it only sends this initially
	-- players who join later wont be able to tell
	-- and it wont save in dupes
	
	net.Start("antcore_editmodel")
	net.WriteInt(this:EntIndex(),32)
	--net.WriteVector(Vector(offset[1],offset[2],offset[3]))
	net.WriteVector(this.modelScale)
	net.WriteAngle(this.modelAngle)
	net.Broadcast()
end

__e2setcost(5)
e2function void entity:setModelScale(vector scale)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	this.modelScale = Vector(math.Clamp(scale[1],-50,50), math.Clamp(scale[2],-50,50), math.Clamp(scale[3],-50,50))
	
	net.Start("antcore_editmodel")
	net.WriteInt(this:EntIndex(),32)
	--net.WriteVector(Vector(offset[1],offset[2],offset[3]))
	net.WriteVector(this.modelScale)
	net.WriteAngle(this.modelAngle or Angle(0,0,0))
	net.Broadcast()
end

__e2setcost(5)
e2function void entity:setModelAngle(angle ang)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	this.modelAngle = Angle(ang[1],ang[2],ang[3])
	
	net.Start("antcore_editmodel")
	net.WriteInt(this:EntIndex(),32)
	--net.WriteVector(Vector(offset[1],offset[2],offset[3]))
	net.WriteVector(this.modelScale or Vector(1,1,1))
	net.WriteAngle(this.modelAngle)
	net.Broadcast()
end

function AntCore.makeSpherical(ent, radius)
	-- check if the spherical tool exists and use it
	if MakeSpherical.ApplySphericalCollisionsE2 then
		local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
		MakeSpherical.ApplySphericalCollisionsE2( ent, true, radius, nil )
		timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
		return
	end
	-- otherwise do it manually
	local boxsize = ent:OBBMaxs()-ent:OBBMins()
	local minradius = math.min( boxsize.x, boxsize.y, boxsize.z ) / 2 * AntCore.physscale_boxmin:GetFloat()
	local maxradius = math.max( boxsize.x, boxsize.y, boxsize.z ) / 2 * AntCore.physscale_boxmax:GetFloat()
	radius = math.Clamp( radius, minradius, maxradius )
	ent:PhysicsInitSphere(radius, ent:GetPhysicsObject():GetMaterial())
end

__e2setcost(5)
e2function void entity:makeSpherical(number radius)
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	--local boxsize = this:OBBMaxs() - this:OBBMins()
	--local maxradius = ((boxsize[1] * boxsize[1] + boxsize[2] * boxsize[2] + boxsize[3] * boxsize[3]) ^ 0.5) * 10
	AntCore.makeSpherical(this, radius)
end

__e2setcost(5)
e2function void entity:makeSpherical()
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	local boxsize = this:OBBMaxs()-this:OBBMins()
	local radius = math.max( boxsize.x, boxsize.y, boxsize.z ) / 2
	
	AntCore.makeSpherical(this, radius)
end

e2function void entity:makeBoxical(vector min, vector max)
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	local boxradius = (this:OBBMaxs() - this:OBBMins()) / 2
	local minradius = boxradius * AntCore.physscale_boxmin:GetFloat()
	local maxradius = boxradius * AntCore.physscale_boxmax:GetFloat()
	
	local minlocal = - Vector(
		math.Clamp(-min[1], minradius[1], maxradius[1]),
		math.Clamp(-min[2], minradius[2], maxradius[2]),
		math.Clamp(-min[3], minradius[3], maxradius[3])
	)
	local maxlocal = Vector(
		math.Clamp(max[1], minradius[1], maxradius[1]),
		math.Clamp(max[2], minradius[2], maxradius[2]),
		math.Clamp(max[3], minradius[3], maxradius[3])
	)
	
	this:PhysicsInitBox(minlocal,maxlocal)
end

e2function void entity:makeBoxical()
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	this:PhysicsInitBox(this:OBBMins(),this:OBBMaxs())
end

-- materials note:
-- if you add a way to set entity materials you'll open a way around hologram.lua's banned materials

-- to interface with the advanced material tool
util.AddNetworkString("Materialize");
util.AddNetworkString("AdvMatInit");

-- this is created to imitate how advanced material works
function AntCore.scaleMaterial(ent, material, xoffset, yoffset, xscale, yscale)
	ent.MaterialData = ent.MaterialData or {} -- prevent nil errors below
	ent.MaterialData = {
		texture = material,
		ScaleX = xscale,
		ScaleY = yscale,
		OffsetX = xoffset,
		OffsetY = yoffset,
		UseNoise = ent.MaterialData.UseNoise or false,
		NoiseTexture = ent.MaterialData.NoiseTexture or "detail/noise_detail_01",
		NoiseScaleX = ent.MaterialData.NoiseScaleX or 1,
		NoiseScaleY = ent.MaterialData.NoiseScaleY or 1,
		NoiseOffsetX = ent.MaterialData.NoiseOffsetX or 0,
		NoiseOffsetY = ent.MaterialData.NoiseOffsetY or 0
	}
	
	net.Start("Materialize");
	net.WriteEntity(ent);
	net.WriteString(material);
	net.WriteTable(ent.MaterialData);
	net.Broadcast();
end

__e2setcost(3)
e2function void entity:setMaterialScale(vector scale)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	AntCore.scaleMaterial(this, this:GetMaterial(), 0, 0, scale[1], scale[2])
end

e2function void entity:setMaterialScale(vector2 scale)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	AntCore.scaleMaterial(this, this:GetMaterial(), 0, 0, scale[1], scale[2])
end

e2function void entity:setMaterialScale(vector scale, vector offset)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	AntCore.scaleMaterial(this, this:GetMaterial(), offset[1], offset[2], scale[1], scale[2])
end

e2function void entity:setMaterialScale(vector2 scale, vector2 offset)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	AntCore.scaleMaterial(this, this:GetMaterial(), offset[1], offset[2], scale[1], scale[2])
end

__e2setcost(2)
e2function entity entity:getGroundEntity()
	if not IsValid(this) then return end
	
	return this:GetGroundEntity()
end

__e2setcost(5)
-- note: this is false when the timer executes
e2function number timerRunning(string name)
	if self.data['timer'].timers[name] then return 1 else return 0 end
end

-- note: negative if the timer is paused
e2function number timerTimeLeft(string name)
	if self.data['timer'].timers[name] then
		return timer.TimeLeft("e2_" .. self.data['timer'].timerid .. "_" .. name) * 1000
	end
	return 0
end

e2function void pauseTimer(string name)
	if self.data['timer'].timers[name] then
		timer.Pause("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end
end

e2function void resumeTimer(string name)
	if self.data['timer'].timers[name] then
		return timer.UnPause("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end
end

__e2setcost(2)
e2function void entity:setBouyancy(number ratio)
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	ratio = math.Clamp(ratio, 0, 1)
	
	this.BuoyancyRatio = ratio -- buoyancy tool uses this to AntCore.copy
	
	this:GetPhysicsObject():SetBuoyancyRatio(ratio)
	this:GetPhysicsObject():Wake()
end

-- Dynamically create generic type functions
for k,v in pairs( wire_expression_types ) do
		local name = k
		local id = v[1]

		__e2setcost(3)
		-- t:GetIndex(obj)
		registerFunction( "getIndex","t:"..id,"s",function(self,args)
			local op1, op2 = args[2], args[3]
			local tab, value = op1[1](self,op1), op2[1](self,op2)
			self.prf = self.prf + #tab.s / 5 -- better cpu than counting loops, but higher ops
			for k,v in pairs(tab.s) do
				if v == value then return k end
			end
			return ""
		end)
		
		-- t:GetIndexNum(obj)
		registerFunction( "getIndexNum","t:"..id,"n",function(self,args)
			local op1, op2 = args[2], args[3]
			local tab, value = op1[1](self,op1), op2[1](self,op2)
			self.prf = self.prf + #tab.n / 5
			for k,v in pairs(tab.n) do
				if v == value then return k end
			end
			return 0
		end)
		
		-- r:GetIndex(obj)
		registerFunction( "getIndex","r:"..id,"n",function(self,args)
			local op1, op2 = args[2], args[3]
			local array, value = op1[1](self,op1), op2[1](self,op2)
			self.prf = self.prf + #array / 5
			for k,v in pairs(array) do
				if v == value then return k end
			end
			return 0
		end)
end

-- check if any e2 object is valid in e2
function AntCore.valid(value)
	if type(value) == "string" then
		return value ~= ""
	elseif type(value) == "number" then
		return value ~= 0
	end
	return IsValid(value)
end

__e2setcost(5)
e2function array array:clean()
	local tmp = {}
	tmp.size = 0
	for k,v in pairs(this) do
		if AntCore.valid(v) then
			tmp[k] = v
		end
	end
	self.prf = self.prf + #this / 5 -- better cpu than counting but higher ops
	return tmp
end

-- note, missing types lists
e2function table table:clean()
	local ret = {}
	ret.size = 0
	ret.n = {}
	ret.s = {}
	ret.ntypes = {}
	ret.stypes = {}
	
	for k,v in pairs(this.s) do
		if AntCore.valid(v) then
			ret.s[k] = v
			ret.size = ret.size + 1
			--ret.stypes[k] = typeids[k]
		end
	end
	for k,v in pairs(this.n) do
		if AntCore.valid(v) then
			ret.n[k] = v
			ret.size = ret.size + 1
			--ret.ntypes[k] = typeids[k]
		end
	end
	self.prf = self.prf + this.size * 2 / 5 -- iterates twice
	return ret
end

-- returns an array of keys sorted by the values that are in the array
e2function array array:sort()
	-- note: must contain all same types
	local indexed = {}
	local vals = {}
	local prevtype = nil
    for k,v in pairs(this) do
		if prevtype and prevtype ~= type(v) then
			return {} -- types dont match
		end
		prevtype = type(v)
		
		-- index the table in reverse for getting keys after sort
		if not indexed[v] then
			indexed[v] = {}
		end
		table.insert(indexed[v], k)
		
		table.insert(vals,v)
	end
	table.sort(vals)
	
	-- uses the same vals array, just replace vals with keys
	for k,v in ipairs(vals) do
		vals[k] = table.remove(indexed[v], 1) -- replace val with table key
	end
	
	self.prf = self.prf + #this * 12 -- same multiplier as findSortByDistance
	return vals
end

-- returns an array of keys sorted by the values that are in the table
e2function array table:sort()
	local indexed = {}
	local vals = {}
	local prevtype = nil
    for k,v in pairs(this.s) do
		if prevtype and prevtype ~= type(v) then
			return {} -- types dont match
		end
		prevtype = type(v)
		
		-- index the table in reverse for getting keys after sort
		if not indexed[v] then
			indexed[v] = {}
		end
		table.insert(indexed[v], k)
		
		table.insert(vals,v)
	end
	table.sort(vals)
	
	-- uses the same vals array, just replace vals with keys
	for k,v in ipairs(vals) do
		vals[k] = table.remove(indexed[v], 1) -- replace val with table key
	end
	
	self.prf = self.prf + #this.s * 12 -- same multiplier as findSortByDistance
	return vals
end

__e2setcost(5)
e2function number entity:isPenetrating()
	if not IsValid(this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	if this:GetPhysicsObject():IsPenetrating() then return 1 else return 0 end
end

e2function void entity:setDrag(number drag)
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	this:GetPhysicsObject():SetDragCoefficient(drag)
end

e2function void entity:enableDrag(number enabled)
	if not IsValid(this) or not isOwner(self, this) then return end
	if not IsValid(this:GetPhysicsObject()) then return end
	
	this:GetPhysicsObject():EnableDrag(enabled ~= 0)
end

__e2setcost(3)
e2function void entity:podThirdPerson(number enable)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	this:SetThirdPersonMode(enable ~= 0)
end

e2function void entity:podThirdPersonDist(number distance)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	this:SetCameraDistance(distance)
end

__e2setcost(1)
e2function void entity:podGetThirdPerson() -- returns if enabled
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	if this:GetThirdPersonMode() then return 1 else return 0 end
end

__e2setcost(5)
e2function void entity:podSwapDriver(entity pod2)
	if not IsValid(this) or not IsValid(pod2) then return end
	if not isOwner(self, this) or not isOwner(self, pod2) then return end
	if not this:IsVehicle() or not pod2:IsVehicle() then return end
	
	local ply1, ply2 = this:GetDriver(), pod2:GetDriver()
	
	-- have to eject both before enter
	if IsValid(ply1) then ply1:ExitVehicle() end
	if IsValid(ply2) then ply2:ExitVehicle() end
	if IsValid(ply1) then ply1:EnterVehicle(pod2) end
	if IsValid(ply2) then ply2:EnterVehicle(this) end
end

__e2setcost(5)
e2function void entity:ejectPod(vector pos)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		ply:ExitVehicle()
		ply:SetPos(Vector(pos[1],pos[2],pos[3]))
	end
end

__e2setcost(5)
e2function void entity:ejectPod(angle ang)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		ply:ExitVehicle()
		ply:SetEyeAngles(Angle(ang[1],ang[2],ang[3]))
	end
end

__e2setcost(5)
e2function void entity:ejectPod(vector pos, angle ang)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		ply:ExitVehicle()
		ply:SetPos(Vector(pos[1],pos[2],pos[3]))
		ply:SetEyeAngles(Angle(ang[1],ang[2],ang[3]))
	end
end

__e2setcost(5)
e2function void entity:ejectPodTemp(vector pos)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		this.tempEjectedDriver = ply
		ply:ExitVehicle()
		ply:SetPos(Vector(pos[1],pos[2],pos[3]))
	end
end

__e2setcost(5)
e2function void entity:ejectPodTemp(vector pos, angle ang)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		this.tempEjectedDriver = ply
		ply:ExitVehicle()
		ply:SetPos(Vector(pos[1],pos[2],pos[3]))
		ply:SetEyeAngles(Angle(ang[1],ang[2],ang[3]))
	end
end

__e2setcost(5)
e2function void entity:ejectPodTemp(angle ang)
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		this.tempEjectedDriver = ply
		ply:ExitVehicle()
		ply:SetEyeAngles(Angle(ang[1],ang[2],ang[3]))
	end
end

__e2setcost(3)
e2function void entity:ejectPodTemp()
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this:GetDriver()
	if IsValid(ply) then
		this.tempEjectedDriver = ply
		ply:ExitVehicle()
	end
end

__e2setcost(3)
e2function void entity:returnDriver()
	if not IsValid(this) or not isOwner(self, this) or not this:IsVehicle() then return end
	
	local ply = this.tempEjectedDriver
	if IsValid(ply) and ply:IsPlayer() then
		ply:EnterVehicle(this)
		this.tempEjectedDriver = nil -- dont allow again unless temp ejected again
	end
end

__e2setcost(15)
e2function number string:count(string subStr)
	local _, count = string.gsub(this, "%"..subStr, "")
	return count
end

__e2setcost(3)
e2function number string:startsWith(string subStr)
	if string.sub(this,1,string.len(subStr)) == subStr then return 1 else return 0 end
end

e2function number string:endsWith(string subStr)
	if string.sub(this,-string.len(subStr)) == subStr then return 1 else return 0 end
end

__e2setcost(2)
e2function number frameTime()
	return FrameTime()
end

__e2setcost(15)
e2function array pings()
	local tmp = {}
	for _,plr in ipairs(player.GetAll()) do
		table.insert(tmp, plr:Ping())
	end
	self.prf = self.prf + #tmp / 10
	return tmp
end

__e2setcost(3)
e2function number entity:isSolid()
	if not IsValid(this) then return end
	
	if this:IsSolid() then return 1 else return 0 end
end

e2function number entity:getSolid()
	if not IsValid(this) then return end
	
	return this:GetSolid()
end

util.AddNetworkString("antcore_clipboard_text");

e2function void entity:setClipboardText(string text)
	if not IsValid(this) then return end
	if this ~= self.player then return end
	
	net.Start("antcore_clipboard_text")
	net.WriteString(text)
	net.Send(this)
end

-- Holograms
util.AddNetworkString("wire_holograms_set_visible");

-- modified hologram.lua CheckIndex
function AntCore.HoloEntity(self, index)
	index = index - index % 1
	return self.data.holos[index]
end

-- this is how hologram.lua's holoVisible system works
-- every holo that has its visibility changed is queued
AntCore.vis_queue = {}
registerCallback("postexecute", function(self)
	-- flush the hologram vis queue
	-- imported/modified from hologram.lua
	
	if not next(AntCore.vis_queue) then return end
	
	for ply,tbl in pairs( AntCore.vis_queue ) do
		if IsValid( ply ) and #tbl > 0 then
			net.Start("wire_holograms_set_visible")
				for _,Holo,visible in ipairs_map(tbl, unpack) do
					net.WriteUInt(Holo:EntIndex(), 16) -- holo entity here
					net.WriteBit(visible)
				end
				net.WriteUInt(0, 16)
			net.Send(ply)
		end
	end
	
	AntCore.vis_queue = {}
end)

__e2setcost(25)
e2function void holoVisible(array indexes, array players, number visible)
	local Holo = nil
	visible = visible ~= 0
	
	-- remove invalid players before nested loop
	-- means players are only validated once
	for k,ply in pairs(players) do
		if not IsValid( ply ) or not ply:IsPlayer() then
			table.remove(players,k)
		end
	end
	
	for _,index in pairs(indexes) do
		if type(index) == "number" then -- verify e2er input
			Holo = AntCore.HoloEntity(self, index)
			if Holo and IsValid(Holo.ent) then -- we know we own this one
				-- imported/modified hologram.lua set_visible
				if not Holo.visible then Holo.visible = {} end
				for _,ply in pairs( players ) do
					if Holo.visible[ply] ~= visible then
						Holo.visible[ply] = visible
						AntCore.vis_queue[ply] = AntCore.vis_queue[ply] or {}
						table.insert( AntCore.vis_queue[ply], { Holo.ent, visible } )
					end
				end
			end
		end
	end
	self.prf = self.prf + #indexes / 2
end

e2function void holoVisibleEnts(array holos, array players, number visible)
	visible = visible ~= 0
	
	-- remove invalid players before nested loop
	for k,ply in pairs(players) do
		if not IsValid( ply ) or not ply:IsPlayer() then
			table.remove(players,k)
		end
	end
	
	for _,Holo in pairs(holos) do
		if Holo:GetClass() == "gmod_wire_hologram" and isOwner(self, Holo) then
			-- imported/modified hologram.lua set_visible
			if not Holo.visible then Holo.visible = {} end
			for _,ply in pairs( players ) do
				if Holo.visible[ply] ~= visible then
					Holo.visible[ply] = visible
					AntCore.vis_queue[ply] = AntCore.vis_queue[ply] or {}
					
					table.insert( AntCore.vis_queue[ply], { Holo, visible } ) -- holo entity
				end
			end
		end
	end
	self.prf = self.prf + #holos / 2
end

__e2setcost(35)
e2function void entity:noCollide(array entities)
	if not IsValid(this) or not isOwner(self, this) then return end
	
	self.prf = self.prf + #entities / 3
	for k,ent in pairs(entities) do
		if type(ent) == "Entity" and isOwner(self, ent) then
			constraint.NoCollide(this, ent, 0, 0)
		end
	end
end

__e2setcost(15)
e2function void entity:gravityHull(vector dir, number con, number prot, number grav)
	if not IsValid(this) or not isOwner(self, this) then return end
	if not GravHull then return end -- requires gravity hull addon to be installed
	
	--if constr == 0 then constr = 1 else constr = 0 end
	GravHull.RegisterHull(this,prot,grav)
	GravHull.UpdateHull(this,con,Vector(dir[1],dir[2],dir[3]))
	
	-- no constraint entity
end

__e2setcost(15)
e2function void entity:removeHull()
	if not IsValid(this) or not isOwner(self, this) then return end
	if not GravHull then return end -- requires gravity hull addon to be installed
	
	--if constr == 0 then constr = 1 else constr = 0 end
	GravHull.UnHull(this)
	--GravHull.UpdateHull(this)	
end


AntCore.e2_softquota = GetConVar("wire_expression2_unlimited"):GetBool() and 1000000 or GetConVar("wire_expression2_quotasoft"):GetInt()
AntCore.e2_hardquota = GetConVar("wire_expression2_unlimited"):GetBool() and 1000000 or GetConVar("wire_expression2_quotahard"):GetInt()
AntCore.e2_tickquota = GetConVar("wire_expression2_unlimited"):GetBool() and 100000 or GetConVar("wire_expression2_quotatick"):GetInt()

registerCallback("preexecute", function(self)
	if self.data.processorCount and self.data.processorCount >= 1 then -- this e2 has extra quota
		-- arbitrary equation which seems to work
		self.prf = self.prf - e2_tickquota/5.3*self.data.processorCount + 1
	end
end)

registerCallback("postexecute", function(self)
	if self.data.processorCount and self.data.processorCount >= 1 then -- this e2 has extra quota
		-- keep the ops from going negative
		self.prfbench = math.max(0, self.prfbench)
		self.prf = math.max(0, self.prf)
	end
end)

registerCallback('construct', function(self) -- e2 starting
	if self.entity.masterChip then
		-- someone has uploaded code into a slave processor, disconnect it
		local master = self.entity.masterChip
		master.data.extraProcessors[self] = nil
		master.data.processorCount = math.max(0,master.data.processorCount - 1)
				
		self.entity.masterChip = nil
	end
end)

__e2setcost(10)
e2function entity spawnProcessor(vector pos, angle ang)
	if not AntCore.wirespawn_enabled:GetBool() then return NULL end
	
	if IsValid(self.player) and (!self.player:CheckLimit("wire_expressions")) then
		WireLib.AddNotify(self.player, "You've hit the expression 2 limit", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
		return nil
	end
	
	-- processor quota used for this chip
	if self.data.processorCount and self.data.processorCount >= AntCore.processor_max:GetInt() then
		return nil
	end
	
	-- doesnt use spawnEntity
	--local model = self.entity:GetModel() or "models/beer/wiremod/gate_e2.mdl"
	local model = "models/beer/wiremod/gate_e2.mdl"
	local ent = MakeWireExpression2(self.player, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]), model)
	if not IsValid(ent) then return NULL end
	
	--WireLib.Expression2Upload(self.player, ent, ". . . . . . ")
	local code = "@name processor\n#if you modify this, it will disconnect from the master"
	ent:Setup(code, {}, nil, nil, "antcore_spawnprocessor")
	--ent:SetColor(Color(255, 255, 255, 255)) -- get rid of the default e2 red
	ent.masterChip = self
	
	if IsValid(self.player) then self.player:AddCount("wire_expressions", ent) end
	
	self.player:AddCleanup("wire_expression2", ent)
	
	--[[if self.data.propSpawnUndo then
		undo.Create( "wire_expression2" )
		undo.AddEntity( ent )
		undo.SetPlayer(self.player)
		undo.Finish()
	end]]
	
	self.data.spawnedProps[ent] = false -- always undo with master
	
	self.data.extraProcessors = self.data.extraProcessors or {}
	self.data.extraProcessors[ent] = true
	self.data.processorCount = (self.data.processorCount or 0) + 1
	
	ent:CallOnRemove( "wire_expression2_antcore_e2_remove",
		function(ent)
			self.data.spawnedProps[ent] = nil
			self.data.extraProcessors[ent] = nil
			self.data.processorCount = math.max(0,self.data.processorCount - 1)
		end
	)
	
	return ent
end

__e2setcost(1)
e2function number entity:processorCount()
	if !IsValid(this) or !this.context or !this.context.data then return 0 end
	return this.context.data.processorCount or 0
end

e2function number processorCount()
	return self.data.processorCount or 0
end

__e2setcost(1)
e2function number entity:ctpEnabled() -- customisable third person addon
	if !IsValid(this) or !this:IsPlayer() then return end
	return this:GetInfoNum("ctp_enabled", 0)
end

-- this is for propSpawnASync(n)
timer.Simple(0, function() -- timer is required to override PropCore functions
if PropCore then -- extend some propcore functions if propcore is installed
	
	if PropCore.ValidAction then
	AntCore.defaultValidAction = PropCore.ValidAction
	function PropCore.ValidAction(self, entity, cmd)
	
		if self.data.propSpawnASync and cmd == "spawn" then -- the chip has propSpawnASync enabled
			return AntCore.getCanOccur(self.player, "propspawn_async", AntCore.propspawn_async_maxpersec:GetInt()) and AntCore.defaultValidAction(self, entity, cmd)
		end
		if IsValid(entity) and entity.allowSolidTime and cmd == "solid" then
			return CurTime() >= entity.allowSolidTime and AntCore.defaultValidAction(self, entity, cmd)
		end
		
		return AntCore.defaultValidAction(self, entity, cmd)
	end
	end
	
	if PropCore.ValidSpawn then
	AntCore.defaultValidSpawn = PropCore.ValidSpawn
	PropCore.ValidSpawn = function() return true end -- disabled so propcore doesnt use internally
	
	-- forcibly override propcore's propCanCreate function
	__e2setcost(2)
	registerFunction( "propCanCreate","","n",function(self,args)
		if self.data.propSpawnASync then
			if AntCore.getCanOccur(self.player,"propspawn_async",AntCore.propspawn_async_maxpersec:GetInt()) then return 1 end
		end
		if AntCore.defaultValidSpawn() then return 1 end
		return 0
	end)
	end
	
	if PropCore.PhysManipulate then
	AntCore.defaultPhysManipulate = PropCore.PhysManipulate
	function PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)		
		if this.allowSolidTime and notsolid != nil then -- entity was spawned with async
			if this.allowSolidTime <= CurTime() then -- entity is still waiting for allow solid
				this.asyncSolid = notsolid ~= 0
				return
			end
		end
		AntCore.defaultPhysManipulate(this, pos, rot, freeze, gravity, notsolid)
	end
	end
	
	if PropCore.CreateProp then
	-- modified PropCore.CreateProp, allows infinite props (under max limit) per second
	-- any that are spawned past the limit are non-solid until they could be spawned
	AntCore.defaultCreateProp = PropCore.CreateProp
	function PropCore.CreateProp(self,model,pos,angles,freeze,isVehicle)
		
		if !self.data.propSpawnASync and !AntCore.defaultValidSpawn() then -- async disabled chip
			return nil
		elseif !AntCore.getCanOccur(self.player,"propspawn_async",AntCore.propspawn_async_maxpersec:GetInt()) then
			return nil
		end
				
		local prop = AntCore.defaultCreateProp(self,model,pos,angles,freeze,isVehicle)
		if !IsValid(prop) then return nil end
		AntCore.setOccur(self.player, "propspawn_async") -- count the spawn occurance in both forms (async and non-async)
		
		if self.data.propSpawnASync then
			-- perform the not-solid-ing
			if AntCore.propSpawnTimes[self.player] and AntCore.propSpawnTimes[self.player] > CurTime() then -- they have spawned recently
				prop:SetSolid(SOLID_NONE)
				prop.allowSolidTime = AntCore.propSpawnTimes[self.player] -- mark when it can be made solid
				prop.asyncSolid = true -- allows them to change it before the time is up
				
				-- round the time DOWN to the nearest second (groups solid events together, as they would have been without async)
				local dt = math.floor(AntCore.propSpawnTimes[self.player] - CurTime())				
				timer.Simple(dt, function()
					if prop.asyncSolid then prop:SetSolid(SOLID_VPHYSICS) end -- automatically make it whatever they set it to
				end)
				prop:CallOnRemove("antcore_asyncprop_remove", function()
					if CurTime() < prop.allowSolidTime then -- prop removed before it could be solid, refund the player their time
						AntCore.propSpawnTimes[self.player] = AntCore.propSpawnTimes[self.player] - 1/GetConVar("sbox_E2_maxPropsPerSecond"):GetInt()
					end
				end)
			else -- they havent spawned recently (or ever)
				AntCore.propSpawnTimes[self.player] = CurTime()
			end
			-- add onto the "solid" time
			AntCore.propSpawnTimes[self.player] = AntCore.propSpawnTimes[self.player] + 1/GetConVar("sbox_E2_maxPropsPerSecond"):GetInt()
		end

		return prop
	end
	
	end
end
end)

__e2setcost(1)
e2function void propSpawnASync(number enable)
	if enable then self.data.propSpawnASync = true else self.data.propSpawnASync = nil end
end

__e2setcost(2)
e2function number change(number value)
	local chg = self.data.changed

	if chg[args] then
		local chval = value - chg[args]
		chg[args] = value
		return chval
	end

	chg[args] = value
	return value
end

__e2setcost(2)
e2function vector change(vector value)
	local chg = self.data.changed

	local prev = chg[args]
	if prev then
		local chval = {value[1] - prev[1], value[2] - prev[2], value[3] - prev[3]}
		chg[args] = value
		return chval
	end

	chg[args] = value
	return value
end

__e2setcost(2)
e2function number change(angle value)
	local chg = self.data.changed

	local prev = chg[args]
	if prev then
		local chval = {value[1] - prev[1], value[2] - prev[2], value[3] - prev[3]}
		chg[args] = value
		return chval
	end
	
	chg[args] = value
	return value
end

__e2setcost(5)
e2function void findSetResults(array entities)
	self.data.findlist = entities
end

__e2setcost(3)
e2function void findAddEntity(entity ent)
	self.data.findlist[#self.data.findlist+1] = ent
end

__e2setcost(1)
e2function number findGetCount()
	return #self.data.findlist
end

-- theres a possibility for error but it should be ok
AntCore.numConnected = player.GetCount()
AntCore.nameConnected = ""
hook.Add("PlayerConnect", "antcore_connect", function(name, ip)
	AntCore.numConnected = AntCore.numConnected + 1
	AntCore.nameConnected = name
	if !timer.Exists("antcore_resetconn") then timer.Create("antcore_resetconn", 1000, 1, function() AntCore.numConnected = player.GetCount() end) end -- fix (a bit) numConnected getting out of sync
end)
hook.Add("PlayerDisconnected", "antcore_disconnect", function(ply)
	AntCore.numConnected = math.max(player.GetCount(), AntCore.numConnected - 1)
end)

__e2setcost(1)
e2function number numConnected()
	return AntCore.numConnected
end

e2function string connectingName()
	return AntCore.nameConnected
end

function AntCore.perf(self)
	if self.prf >= self.data.autoPerfLimit then return false end
	if self.prf + self.prfcount >= self.data.autoPerfHardLimit then return false end
	return self.prf < self.data.autoPerfSoftLimit
end

function AntCore.autoPerfExecute(self)
	if AntCore.perf(self.context) then
		self.defaultExecute(self)
	end
end

__e2setcost(5)
e2function void autoPerf(number enable)
	if enable == 0 then
		if self.entity.autoPerf then
			self.entity.autoPerf = nil -- store on entity so it persists through reset
			self.entity.Execute = self.entity.defaultExecute
			self.entity.defaultExecute = nil -- small cleanup
		end
	elseif !self.entity.autoPerf then
		self.entity.autoPerf = true
		self.entity.defaultExecute = self.entity.Execute
		self.entity.Execute = AntCore.autoPerfExecute -- override the e2's execute
		self.data.autoPerfLimit = e2_tickquota*0.95-200 -- values are from perf()'s logic
		self.data.autoPerfHardLimit = e2_hardquota
		self.data.autoPerfSoftLimit = e2_softquota*2
	end
end

e2function void autoPerf(number enable, number n)
	if enable == 0 then
		if self.entity.autoPerf then
			self.entity.autoPerf = nil
			self.entity.Execute = self.entity.defaultExecute
			self.entity.defaultExecute = nil
		end
	elseif !self.entity.autoPerf then
		n = math.Clamp(n, 0, 100)
		self.entity.autoPerf = true
		self.entity.defaultExecute = self.entity.Execute
		self.entity.Execute = AntCore.autoPerfExecute -- override the e2's execute
		self.data.autoPerfLimit = e2_tickquota*0.95-200*n/100
		self.data.autoPerfHardLimit = e2_hardquota*n/100
		self.data.autoPerfSoftLimit = e2_softquota*2*n/100
	end
end

registerCallback("construct", function(self)
	-- disable autoperf if its enabled, it means the chip was reset
	if self.entity.autoPerf then
		self.entity.autoPerf = nil
		self.entity.Execute = self.entity.defaultExecute
		self.entity.defaultExecute = nil
	end
end)

__e2setcost(1)
e2function void entity:setCollisionGroup(string group)
	if not IsValid(this) or not isOwner(self, this) or not IsValid(this:GetPhysicsObject()) then return end
	this.ColGroup = group
	this:CollisionRulesChanged()
end

e2function void entity:removeCollisionGroup()
	if not IsValid(this) or not isOwner(self, this) or not IsValid(this:GetPhysicsObject()) then return end
	this.ColGroup = nil
	this:CollisionRulesChanged()
end

-- empty string is no group
e2function string entity:getCollisionGroup()
	return IsValid(this) and this.ColGroup or ""
end

-- compute collision group collisions
hook.Add("ShouldCollide", "antcore_shouldcollide", function(ent1, ent2)
	-- only intervene physics if there's a valid collision group and the two are not equal
	-- otherwise DON'T do anything here
	if ent1:IsWorld() or ent2:IsWorld() then return end -- ignore world
	if (ent1.ColGroup and ent1.ColGroup != "" or ent2.ColGroup and ent2.ColGroup != "") and ent1.ColGroup != ent2.ColGroup then
		return false
	end
end)