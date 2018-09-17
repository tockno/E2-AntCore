# E2-AntCore
Extension for Garry's Mod / Wiremod / Expression2

This repo just exists to save people effort/time decompiling the addon file to check the contents. Also the documentation doesn't fit in steam workshop.


# Documentation

This extension exists to remove limitations on E2 without allowing it to be abused.

# Recent Changes

**some recent changes (not only the latest changes):**
* E:setCollisionGroup(S) - entities with a collision group will only collide with other entities with the same group, does not apply constraints or get saved in duplicator
* E:getCollisionGroup()
* E:removeCollisionGroup()
* E:getPhysScale/E:getModelScale return prop resizer (advanced collision resizer addon) values if they exist
* improved how processors work, removed useProcessor
* fixed runOnEntRemove running even when the chip is being deleted
* cleaned up code a bit


# Abuse Prevention / Optimisation
Generally all of the functions that are risky for all players to have access to, have some kind of limitation or abuse prevention. All of these have console commands to be invidually disabled or configured. Also, many of the functions offer server/chip performance improvements over base E2 functions. An example is E:setVelocity, the function is much simpler, uses much less server CPU and therefore requires much less E2 OPS to use.


# Console Commands
Server sided console variables for settings.

| Command  | Description | Default |
| ------------- | ------------- | ------------- |
| "antcore_turretShoot_enabled" | Enables/disables turretShoot | 1 |
| "antcore_turretShoot_persecond" | Changes the maximum times per second turretShoot can be used. | 10 |
| "antcore_turretShoot_damage_max" | Changes the maximum damage turretShoot can do. | 110000000 |
| "antcore_turretShoot_spread_max" | Changes the maximum spread turretShoot can have. | 2 |
| "antcore_turretShoot_count_max" | Changes the maximum bullet count turretShoot can have. | 20 |
| "antcore_boom_enabled" | Enables/disables boom functions. | 1 |
| "antcore_boom_delay" | Changes the boom cooldown. | 100 |
| "antcore_boom_damage_max" | Changes the maximum amount of damage that boom functions can do. | 10000 |
| "antcore_boom_radius_max" | Changes the maximum radius that a boom function can have. | 50000 |
| "antcore_hintPlayer_enabled" | Enables/disables hintPlayer. | 1 |
| "antcore_hintPlayer_persecond" | Changes the maximum times hintPlayer can be used per second. | 5 |
| "antcore_hintPlayer_persist_max" | Changes the maximum time a hint can persist on another player. | 7 |
| "antcore_hintPlayer_persecond_self" | Changes the maximum times hintPlayer can be used per second on yourself. | 20 |
| "antcore_hintPlayer_persist_max_self" | Changes the maximum time a hint can persist on yourself. | 60 |
| "antcore_printPlayer_persecond" | Changes the max amount of times printPlayer can be used per second. | 10)
| "antcore_weapons_enabled" |  | 2 |
| "antcore_weapons_remove_any" |  | 1 |
| "antcore_wirespawn_enabled" |  | 1 |
| "antcore_entities_spawn_persecond" |  | 16 |
| "antcore_entities_spawn_e2chip" |  | 0 |
| "antcore_bolt_persecond" |  | 8 |
| "antcore_bolt_max" |  | 32 |
| "antcore_combine_persecond" |  | 1 |
| "antcore_dropweapon_persecond" |  | 5 |
| "antcore_processor_max" | The maximum amount of processors that a single E2 can spawn. | 8 |
| "antcore_propspawn_async_enabled" | Enables/disables propSpawnASync | 1 |
| "antcore_propspawn_async_maxpersec" | The maximum props that can be spawned per second by a chip with propSpawnASync enabled. | 60 |
| "antcore_propspawn_perplayer" | Override's prop core's propSpawn cooldown, makes it per player instead of global/shared. | 1 |


# Functions

# General
| Function  | Description |
| ------------- | ------------- |
| E:aimedAt() | Returns whether or not an entity is being aimed at by a player. |
| aimedAt(entities) | Returns whether any of the entities are being aimed at by a player. Entities must be indexed by E:id(), example: R[Ent:id(),entity] = Ent. This unusual method allows massive arrays to be used without lagging the server. |
| E:aimingAt() | Returns an array of players aiming at an entity. |
| aimingAt(entities) | Returns an array of players aiming at any of the entities. Must have the same indexing convention as aimedAt(R). |
| E:WeapSetMaterial(mat) | Sets a weapon's material. |
| E:setModel(model) | -- |
| E:setModelScale(scale)<br>E:setModelScale(scale,time) | Sets an entity's model's visual scale (number). It also has a time parameter (in seconds) to linearly animate the scale change. This works on holograms and is ideal for scaling animation (linear), if the scale is a single number. |
| E:editModel(scale,angle) | Adjusts a model relative to an entity's physical entity. |
| E:setModelScale(scale) | Same as the above but only for the scale. |
| E:setModelAngle(angle) | Same as the above for the angle. |
| E:getModelScale() | Returns a vector of the custom scale (works with the single number scale). Also returns the visual scale that was set by Prop resizer. (https://steamcommunity.com/sharedfiles/filedetails/?id=217376234) |
| E:getModelAngle() | Returns the modified angle of an entity. |
| findClosestCentered(pos,dir) | Finds the center prop based on a view angle, runs exactly the same as findClosest(pos) but for a direction. |
| runOnEntSpawn(enable) | Makes the chip execute when an entity is created. |
| runOnEntSpawn(type,enable) | Makes the chip execute when a specific entity type is created. |
| runOnEntRemove(enable) | runOnEntRemove(type,enable) |
| runOnEntRemove(ent,enable) | Makes the chip execute if a specific entity is removed. |
| runOnEntRemove(entities,enable) | Same as above for multiple entities. |
| frameTime() | Returns the time in seconds it took to render the last frame (server sided) ideal for approximating server lag. |
| pings() | Returns an array of players pings. This can easily be done manually but this is so chips can do things like pings():min() without having to worry about an ops spike due to iteration. |
| or(obj1, obj2)<br>or(obj1, obj2, obj3) | Functions the same way as lua's '''or'''. It returns the first of the input objects (left to right) that are valid. It can easily be done in base E2, but this makes code easier to read in some cases. |
| E:setCollisionGroup(S) E:getCollisionGroup() E:removeCollisionGroup() | Gets/sets the collision group of an entity. Entities with collision groups will only collide with other entities with the same group. |

# Base E2 Extension
These functions are sort-of an extension to already existing E2 functions.

| Function | Description |
| ------------- | ------------- |
| findToArray(maxresults) | Exactly the same as '''findToArray()''', but limits the maximum results. This will decrease server usage and also the e2's usage. Note: Technically it won't linearly decrease usage on the server. Meaning if there's 1000 entities and you limit it to find 100, it won't use 10x less resources (due to how '''find.lua''' works) but it will use significantly less than the normal findToArray(). |
| findForceExcludeEntities(R) | Modified '''findExcludeEntities(R)''', but doesn't break half way through the array if there is an invalid entity. Instead just ignores this entity and continues. The reason this is useful is if you have an array in your code that is storing manually filtered entities over time, if any of the entities in the array are deleted, any entity contained after that won't be filtered. Note: using R = R:clean() (newer update of AntCore) and using the default E2 function may be more efficient in the long run if the entities are frequently deleted. |
| findForceIncludeEntities(R) | Same for the above but for '''findIncludeEntities(R)'''. |
| timerRunning(name) | Returns if a timer is running. |
| timerTimeLeft(name) | Returns how long (in milliseconds) a timer has left. Negative time if the timer is paused. |
| pauseTimer(name) | Pauses a timer. |
| resumeTimer(name) | Resumes a timer. |
| R:getIndex(obj) | Finds the first occurrence of an object in an array and returns the index. |
| T:getIndexNum(obj) | Same as the above but for table. |
| T:getIndex(obj) | Same as the above but the string index. |
| R:clean() | Returns the array with all invalid objects removed. An example use of this would be if an array contains props, it will remove any props that have been deleted |
T:clean() | Same for the above but for tables. |
| R:sort() | Returns an array of this array's keys sorted by the array's values. Must contain all the same type values. |
| T:sort() | Returns an array of string keys sorted by the table's values. Must contain all the same type values. |
| S:count(subStr) | Returns how many instances of subStr are in S. Better performance than the default method of Count = S:length()-S:replace(subStr,""):length().<br>***Note: mistakes may occur if subStr contains a [https://en.wikipedia.org/wiki/Regular_expression regular expression] pattern, but this isn't likely to happen.*** |
| S:startsWith(subStr) | Returns if the start of the string is equal to subStr. |
| S:endsWith(subStr) | * |
| holoVisible(indexes,players,visible), holoVisibleEnts(holos,players,visible) | An improvement over base E2's holoVisible(index,players,visible). It has proper implementation of '''hologram.lua'''<nowiki/>'s queue system and also has slight nested loop optimisation. Note: the index option is unable to work for global holograms (negative indexes). |
| propSpawnASync(n) | Allows you to spawn more props per second, but they can't become solid until they would've been able to be spawned. Requires PropCore to be installed and enabled. By default, allows a max of 60 (non-solid) props to be spawned per second, any more than this can cause problems. Conforms to PropCore's settings for max solid per second. |
| change(n/a/v) | Works like a combination between $Val and changed(Val). Returns the change in a value since the last execution, but works without it being a persisted variable. |
| findGetCount() | Returns the amount of entities found. |
| findSetResults(R) | Forcibly sets the find results to an array, so that sort functions can be used. |
| findAddEntity(E) | Forcibly includes an entity in find results. |

# Players
| Function  | Description |
| ------------- | ------------- |
| E:plyRenderFX(effect) | Sets a player's render FX (number). |
| E:plyShadow(enable) | Toggles a player's shadow. |
| E:hintPlayer(S) | Hints a message to a player, limited to a default hint time and a maximum length of 100 characters on other players, also tells the player who the message was from. Allows longer persisting than normal hint on the chip's owner. |
| E:printPlayer(S) | Prints a message so a player's chat. The only abuse prevention is that it prints who sent the message to the receiver's console as proof of abuse. |
| E:plyAlpha(alpha) | Sets a player's alpha. |
| E:setClipboardText(S) | Sets a player's computer's clipboard text. |
| numConnected() | Returns the number of connected clients. |
| connectingName() | Returns the name of the most recent connected player/client. |

# Offensive
| Function  | Description |
| ------------- | ------------- |
| boomCustom(effect,pos,damage,radius) | A modified version of Divran's boom function. Allows a custom (whitelisted) effect instead of the default explosion. |
| boom2(pos,damage,radius) | A simpler version of boomCustom that uses a silent explosion effect. |
| boomDelay() | Returns the cooldown delay between allowed boom functions in ms. Default 100. |
| E:npcKill() | Kills any killable NPC, bypassing prop protection. This function exists is because damage applying functions can be abused, but NPCs can also be abused. |
| E:turretShoot(directionV,damage,spread,force,count,tracer) | Emulates a turret entity firing. |
| turretShootLimit() | Returns the maximum times per second turretShoot() can be used. |
| shootBolt(pos,vel,damage) | Shoots a crossbow bolt from a position, limited to 8 per sec and max 32 at a time. |

Currently whitelists can't be modified (apart from modifying the lua manually) but I might add it if I can be bothered.
Boom effects whitelist: "explosion", "helicoptermegabomb", "bloodimpact", "glassimpact", "striderblood", "airboatgunimpact", "cball_explode", "manhacksparks", "antliongib", "stunstickimpact"

Turret tracer whitelist: "tracer", "ar2tracer", "helicoptertracer", "airboatgunheavytracer", "lasertracer", "tooltracer"


# Weapons
| Function  | Description |
| ------------- | ------------- |
| E:giveWeapon(weapname) | Gives the entity the weapon, can only be used on self. The weapon must be whitelisted. |
| E:dropWeapon(weapname) | Drops the weapon, can be picked up by other players. Can only be used on self. |
| E:removeWeapon(weapname) | The same as dropWeapon except the weapon cannot be picked up (it is deleted). |
| E:hasWeapon(weapname) | Returns whether the player has a weapon by its name. Can be used on any player. |
| E:getWeapons() | Returns an array of all of the player's weapon entities, can only be used on self. |
| E:giveAmmo(ammoname,count) | Gives the player ammo specified by ammo type. The ammo type must be whitelisted. |
| E:setAmmo(ammoname,count) | Sets the player ammo specified by ammo type. The ammo type must be whitelisted. |
| E:selectWeaponSlot(slotnumber) | Selects the player's active slot by number. Can only be used on self. |
| E:selectWeapon(weapname) | Selects the weapon by it's name of the player has it. Can only be used on self. |
| E:getWeapon(weapname) | Returns the player's weapon by name as an entity. Can only be used on self. |
| E:setClip1(ammotype,count) | Sets the amount of ammo in the player's clip 1 (the clip that comes up on the player's HUD). Ammo type must be whitelisted and can only be used on self. |

Ammo whitelist: "pistol", "357", "ar2", "xbowbolt", "buckshot"
Weapon give whitelist: "weapon_pistol", "weapon_crowbar", "weapon_stunstick", "weapon_physcannon", "weapon_shotgun", "weapon_ar2", "weapon_crossbow", "wt_backfiregun", "ragdollroper", "laserpointer", "remotecontroller", "none", "gmod_camera", "weapon_fists"

Weapon control whitelist: "weapon_pistol", "weapon_crowbar","weapon_stunstick", "weapon_physcannon","weapon_shotgun","weapon_ar2", "weapon_crossbow", "wt_backfiregun", "ragdollroper", "laserpointer", "remotecontroller", "none", "gmod_camera", "weapon_fists", "weapon_rpg", "weapon_smg1", "weapon_slam", "weapon_bugbait","weapon_physgun", "gmod_tool", "weapon_medkit","weapon_frag", "parachuter", "wt_writingpad"

# Vehicles
Being able to control your own vehicles hugely improves the capability of E2 as it allows you to temporarily manipulate or control another player while they are in your vehicle.

| Function  | Description |
| ------------- | ------------- |
| E:podSetAttacker(inflictor) | Allows you to set a vehicle's weapon (inflictor), whenever this weapon does damage, the attacker will be set to the pod's driver (if there is one). |
| E:setInflictor(newinflictor) | Allows you to divert an inflictor to be a different entity, ie if you are using some entity E1 in E1:turretShoot, you can make a different entity come up as the inflictor, if you redirect it to a pod's weapon (E:podSetAttacker) then it the attacker will also redirect. |
| E:podThirdPerson(enabled) | Enables or disables a vehicle's third person mode. Remembers the setting even when there's no driver. |
| E:podThirdPersonDist(distance) | Sets the third person camera distance of a vehicle. Can be longer than the default scrolling distance. **Note: The camera automatically clips inside the map if you set it to a very large number.** |
| E:podGetThirdPerson() | Returns whether the vehicle is in third person mode. |
| E:podSwapDriver(pod2) | Swaps the drivers of two of your vehicles, works if one is empty. |
| E:ejectPod(position) | Exactly the same as default E:ejectPod() but it ejects the driver to a specific world position.
| E:ejectPodTemp()<br>E:ejectPodTemp(position) | Temporarily ejects a player from a vehicle, they can then be returned to it with E:returnDriver() |
| E:returnDriver() | Returns the player to the vehicle after E:ejectPodTemp() was used on it. |

# Physics
| Function  | Description |
| ------------- | ------------- |
| rope(constraintindex,ent1,offset1,ent2,offset2,rigid) | Ropes an entity to another entity, can be rigid. |
| elastic(constraintindex,ent1,offset2,ent2,offset2,width,<br>compression,constant,damping) | Elastics an entity to another entity, allows width, compression, spring constant and spring damping. |
| E:setVelocity(vel) | Sets an entity's velocity. Basically the same as E:applyForce((-E:vel()+vel) * E:mass()) but more optimised. Note: directly setting a prop's velocity gives a massive performance boost over applyForce. A chip running on tick using setVelocity uses about 34 ops and 60 μs of cpu time whereas the same chip using applyForce takes about 98 ops and 175 μs. |
| E:setAngVel(ang) | Sets an entity's angular velocity. |
| E:addAngVel(ang) | Adds angular velocity onto an entity's. Unlike E:applyAngForce it's immune to moment forces (the model's box size). |
| E:keepUpright()<br>E:keepUpright(ang,bone,angularLimit) | Creates a keep upright constraint. |
| E:getGroundEntity() | Returns the entity that an entity is standing on. |
| E:setPhysScale(N) | Uses a built in Garry's Mod physics scaling system. The system is limited to a number rather than a vector. Clamped between 0.005 and 10 by default to prevent crashes. |
| E:getPhysScale() | Returns the physics scale. In vector form for possible compatibility. Using the above will make this return the same value as a vector. Also returns the physical scale that was set by Prop resizer. (https://steamcommunity.com/sharedfiles/filedetails/?id=217376234) |
| E:resetPhysics() | Sets the entity's physics to be whatever model it currently has. |
| E:makeSpherical(radius,material)<br>E:makeSpherical() | Makes an entity's physics spherical. |
| E:makeBoxical(min,max)<br>E:makeBoxical() | Makes an entity's physics box-like using an input min and max '''local''' position vectors. Note: this is a very useful function for scaling a prop's physics because the vertices are simple regardless of the prop's. This also has its own min and maximum scale independent of E:setPhysScale's min and max (smaller and larger) due to this. |
| E:setBuoyancy(ratio) | Sets an entity's buoyancy ratio (0..1) |
| E:setDrag(drag) | Sets an entity's drag. Note: some entities seem to have their own drag override (ie ww2bomb.mdl) |
| E:enableDrag(enabled) | Enables or disables an entity's drag. |
| E:isPenetrating() | Returns whether an entity is penetrating any other entity. |
| E:isSolid() | Returns whether an entity is solid. |
| E:getSolid() | Returns the solid type of the entity. See http://wiki.garrysmod.com/page/Enums/SOLID for more info. |
| E:noCollide(entities) | No-collides the entity with multiple other entities. |

# Wire spawning
This section exists as a big convenience. A lot of the time a feature is required that can be done by using a wire part, but then a simple E2 becomes a contraption which requires advanced duplicator to save/reproduce. This just removes that inconvenience.
**Note: A few of these exist in other addons, but here they are compatible with propSpawnUndo(0) in vanilla E2, and sbox spawn limits**

| Function  | Description |
| ------------- | ------------- |
| spawnEgp(model,pos,ang) | Spawns an EGP screen |
| spawnEgpHud(pos,ang) | spawnEgpEmitter(pos,ang) |
| spawnWireUser(model,range,pos,ang) | Spawns a wire user. |
| spawnExpression2(model,pos,ang) | Spawns an E2 chip, this function is disabled by default, but requires *remoteuploader* to be enabled to put any code into the chip anyway which is also disabled by default. |
| spawnTextEntry(model,pos,ang,freeze,disableuse) | * |
| spawnTextScreen(model,pos,ang,freeze) | * |
| spawnButton(model,pos,ang,freeze)<br>spawnButton(model,pos,ang,freeze,on,off) | Spawns a wire button entity. If "on" and "off" are omitted, they will be 1 and 0 by default. |
| spawnWireForcer(model,pos,ang,frozen)<br>spawnWireForcer(model,pos,ang,frozen,range,beam,reaction) | Spawns a wire forcer. |
| spawnEyePod(pos,ang,frozen)<br>spawnEyePod(pos,ang,frozen,defaultzero,cumulative,min,max) | Spawns a wire eyepod. |

# Addon Integration
Some functions that allow the use of other existing Garry's Mod addons. If the addons aren't installed/enabled on the server then the functions will just do nothing.

| Function  | Description |
| ------------- | ------------- |
| E:gravityHull(direction, constraints, protrusion, gravity) | Adds a gravity hull to the entity (localized physics |
| E:removeHull() | Removes a gravity hull. |
| E:ctpEnabled() | Returns whether the player is using CTP (custom third person) |

# Special
| Function  | Description |
| ------------- | ------------- |
| E = spawnProcessor(...) | Spawns a slave E2 entity that can't be used on its own. It sacrifices its tick quota to increase the quota of the master E2 that spawned it. If any code is uploaded into a slave it will be disconnected from the master. The slave processors get a portion of the OPS for cosmetic purposes, but their value isn't accurate. opcounter() and maxquota() work with processors. |
| processorCount() | Returns the amount of active processors that this chip has. |

# Experimental
These features are not entirely practical or useful, but may be improved or removed in the future.

| Function  | Description |
| ------------- | ------------- |
| autoPerf(enable) autoPerf(enable,n) | Makes this chip immune to hitting its quota by an event (timer or runOn<Event>(1) style function). It can't prevent tick quota caused by a loop, tick quota occurs in one execution inside the code. |
