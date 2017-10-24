# E2-AntCore
Extension for Wiremod Expression2

This repo just exists to save people effort/time decompiling the addon file to check the contents. Also a good host for documentation. The contents of the repo may not be up to date with the workshop depending on if I get lazy.


# Documentation

This extension exists to remove limitations on E2 without allowing it to be abused.

# Recent Changes

**some recent changes (not only the latest changes):**
* Changed RT cam spawn limit to be same as normal cameras, normally RT cams have no limit but i think this is nicer
* Fixed inflictor nil error in damage event (problem in other addons causes errors here)
* Disabled scale (phys and cosmetic model) on ragdolls
* Added gravity hull support (requires gravity hull addon)
* Added veh:ejectPodTemp(..) and ply:returnToPod()
* Added e:ctpEnabled()

# Abuse Prevention / Optimisation
Generally all of the functions that are risky for all players to have access to, have some kind of limitation or abuse prevention. All of these have console commands to be invidually disabled or configured. Also, many of the functions offer server/chip performance improvements over base E2 functions. An example is E:setVelocity, the function is much simpler, uses much less server CPU and therefore requires much less E2 OPS to use.

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
| E:getModelScale() | Returns a vector of the custom scale (works with the single number scale). |
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
| 



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
| R:sort() | Returns an array of this array's keys sorted by the array's values. Must contain all the same type values. | T:sort()
| Returns an array of string keys sorted by the table's values. Must contain all the same type values. |
| S:count(subStr) | Returns how many instances of subStr are in S. Better performance than the default method of Count = S:length()-S:replace(subStr,""):length().<br>***Note: mistakes may occur if subStr contains a [https://en.wikipedia.org/wiki/Regular_expression regular expression] pattern, but this isn't likely to happen.*** |
| S:startsWith(subStr) | Returns if the start of the string is equal to subStr. |
| S:endsWith(subStr) | * |
| holoVisible(indexes,players,visible), holoVisibleEnts(holos,players,visible) | An improvement over base E2's holoVisible(index,players,visible). It has proper implementation of '''hologram.lua'''<nowiki/>'s queue system and also has slight nested loop optimisation. Note: the index option is unable to work for global holograms (negative indexes). |



# Players
| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Offensive
| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Weapons
| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Vehicles
| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Physics
| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Wire spawning
This section exists as a big convenience. A lot of the time a feature is required that can be done by using a wire part, but then a simple E2 becomes a contraption which requires advanced duplicator to save/reproduce. This just removes that inconvenience.
**Note: A few of these exist in other addons, but here they are compatible with propSpawnUndo(0) in vanilla E2**

| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Addon Integration
Some functions that allow the use of other existing Garry's Mod addons.

| Function  | Description |
| ------------- | ------------- |
| --  | --  |

# Experimental
These features are not entirely practical or useful, but may be improved or removed in the future.

| Function  | Description |
| ------------- | ------------- |
| --  | --  |
