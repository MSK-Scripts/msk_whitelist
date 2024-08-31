# All Events and Exports
You can find everyting you need at the documentation!

## Clientside Exports

**Check if someone is whitelisted or not**
* Parameter:
playerId - number - The ServerId of the player - OPTIONAL

* Returns:
isWhitelisted - boolean - whether the player is new or not

```lua
-- Self
isWhitelisted = exports.msk_whitelist:isPlayerNew()

-- Other Player
isWhitelisted = exports.msk_whitelist:isPlayerNew(playerId)
```

## Serverside Export

**Check if someone is whitelisted or not**
* Parameter:
playerId - number - The ServerId of the player - OPTIONAL

* Returns:
isWhitelisted - boolean - whether the player is new or not

```lua
-- Self
isWhitelisted = exports.msk_whitelist:isPlayerNew()

-- Other Player
isWhitelisted = exports.msk_whitelist:isPlayerNew(playerId)
```

**Whitelist someone**
* Parameter:
playerId - number - The ServerId of the player who whitelisted someone - OPTIONAL
targetData - table - PlayerData of the player who was whitelisted

```lua
exports.msk_whitelist:whitelistPlayer(playerId, targetData)

-- If Server whitelisted the player
exports.msk_whitelist:whitelistPlayer(nil, targetData)

-- targetData
{source = targetId}
{identifier = targetIdentifier}

-- Examples
exports.msk_whitelist:whitelistPlayer(playerId, {source = 1}) 
exports.msk_whitelist:whitelistPlayer(playerId, {identifier = 'char1:83556bdis9d7sj3'})
```