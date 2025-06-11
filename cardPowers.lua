local cardPowers = {}

-- Card power definitions with their special abilities
cardPowers.definitions = {
    [1] = { -- Fireball
        name = "Fireball",
        type = "vanilla",
        description = "No special ability"
    },
    [2] = { -- Trenchcoat Mushrooms
        name = "Trenchcoat Mushrooms",
        type = "vanilla",
        description = "No special ability"
    },
    [3] = { -- Monk
        name = "Monk",
        type = "vanilla",
        description = "No special ability"
    },
    [4] = { -- Market
        name = "Market Hustler",
        type = "vanilla",
        description = "No special ability"
    },
    [5] = { -- Steal
        name = "Steal",
        type = "on_reveal",
        description = "When Revealed: Lower the power of each card in your opponent's hand by -1",
        effect = function(gameState, playerId, locationIndex)
            local opponentId = playerId == 1 and 2 or 1
            local opponentHand = opponentId == 1 and gameState.player1Hand or gameState.player2Hand
            local cardsAffected = 0
            
            for _, card in ipairs(opponentHand) do
                if card.power and card.power > 0 then
                    card.power = card.power - 1
                    cardsAffected = cardsAffected + 1
                end
            end
            
            print("Steal effect: Reduced power of " .. cardsAffected .. " cards in opponent's hand by 1")
            return true
        end
    },
    [6] = { -- King
        name = "King",
        type = "on_reveal",
        description = "When Revealed: Gain +2 power for each enemy card here",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local enemyCards = playerId == 1 and location.player2Cards or location.player1Cards
            local powerGain = #enemyCards * 2
            
            if cardRef and powerGain > 0 then
                cardRef.power = (cardRef.power or 0) + powerGain
                print("King effect: Gained +" .. powerGain .. " power (now " .. cardRef.power .. ")")
            end
            
            return true
        end
    },
    [7] = { -- Stink Trap
        name = "Stink Trap",
        type = "ongoing",
        description = "When ANY other card is played here, lower that card's power by -1",
        effect = function(gameState, playerId, locationIndex, triggerCard)
            -- This is handled in the main game when cards are played
            if triggerCard and triggerCard.power and triggerCard.power > 0 then
                triggerCard.power = triggerCard.power - 1
                print("Stink Trap effect: Reduced " .. (triggerCard.name or "Unknown") .. "'s power by 1")
                return true
            end
            return false
        end
    },
    [8] = { -- Lightning Wizard
        name = "Lightning Wizard",
        type = "on_reveal",
        description = "When Revealed: Discard your other cards here, gain +2 power for each discarded",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local playerCards = playerId == 1 and location.player1Cards or location.player2Cards
            local cardsToDiscard = {}
            
            -- Find other cards to discard (excluding the Lightning Wizard itself)
            for i, card in ipairs(playerCards) do
                if card ~= cardRef then
                    table.insert(cardsToDiscard, i)
                end
            end
            
            local powerGain = #cardsToDiscard * 2
            
            -- Remove cards from back to front to avoid index issues
            for i = #cardsToDiscard, 1, -1 do
                local cardIndex = cardsToDiscard[i]
                local discardedCard = table.remove(playerCards, cardIndex)
                print("Lightning Wizard discarded: " .. (discardedCard.name or "Unknown"))
            end
            
            if cardRef and powerGain > 0 then
                cardRef.power = (cardRef.power or 0) + powerGain
                print("Lightning Wizard effect: Gained +" .. powerGain .. " power (now " .. cardRef.power .. ")")
            end
            
            return true
        end
    },
    [9] = { -- Hypnosis
        name = "Hypnosis",
        type = "on_reveal",
        description = "When Revealed: Move away an enemy card here with the lowest power",
        effect = function(gameState, playerId, locationIndex)
            local location = gameState.locations[locationIndex]
            local enemyCards = playerId == 1 and location.player2Cards or location.player1Cards
            local enemyHand = playerId == 1 and gameState.player2Hand or gameState.player1Hand
            
            if #enemyCards > 0 then
                -- Find card with lowest power
                local lowestPower = math.huge
                local lowestIndex = 1
                
                for i, card in ipairs(enemyCards) do
                    local cardPower = card.power or 0
                    if cardPower < lowestPower then
                        lowestPower = cardPower
                        lowestIndex = i
                    end
                end
                
                -- Move the card back to hand
                local movedCard = table.remove(enemyCards, lowestIndex)
                table.insert(enemyHand, movedCard)
                
                print("Hypnosis effect: Moved " .. (movedCard.name or "Unknown") .. " back to opponent's hand")
                return true
            end
            
            return false
        end
    },
    [10] = { -- Beehive
        name = "Beehive",
        type = "on_reveal",
        description = "When Revealed: Gain +5 power if there is exactly one enemy card here",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local enemyCards = playerId == 1 and location.player2Cards or location.player1Cards
            
            if #enemyCards == 1 and cardRef then
                cardRef.power = (cardRef.power or 0) + 5
                print("Beehive effect: Gained +5 power (now " .. cardRef.power .. ")")
                return true
            end
            
            return false
        end
    },
    [11] = { -- Pollination
        name = "Pollination",
        type = "on_reveal",
        description = "When Revealed: Give cards in your hand +1 power",
        effect = function(gameState, playerId, locationIndex)
            local playerHand = playerId == 1 and gameState.player1Hand or gameState.player2Hand
            local cardsAffected = 0
            
            for _, card in ipairs(playerHand) do
                card.power = (card.power or 0) + 1
                cardsAffected = cardsAffected + 1
            end
            
            print("Pollination effect: Gave +" .. cardsAffected .. " cards in hand +1 power")
            return true
        end
    },
    [12] = { -- Mimic
        name = "Mimic",
        type = "on_play",
        description = "Add a copy to your hand after this card is played",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local playerHand = playerId == 1 and gameState.player1Hand or gameState.player2Hand
            local cardData = require("cardData")
            
            if cardRef then
                -- Create a copy of the mimic card
                local originalCard = cardData.getCard(cardRef.id)
                if originalCard then
                    local mimicCopy = {
                        id = originalCard.id,
                        name = originalCard.name,
                        type = originalCard.type,
                        description = originalCard.description,
                        imagePath = originalCard.imagePath,
                        manaCost = originalCard.manaCost,
                        power = originalCard.power or 0
                    }
                    
                    table.insert(playerHand, mimicCopy)
                    print("Mimic effect: Added a copy of Mimic to hand")
                    return true
                end
            end
            
            return false
        end
    },
    [13] = { -- Sea Monster
        name = "Sea Monster",
        type = "vanilla",
        description = "No special ability"
    },
    [14] = { -- Coin
        name = "Coin",
        type = "on_reveal",
        description = "When Revealed: Gain +2 mana next turn",
        effect = function(gameState, playerId, locationIndex)
            -- Set a flag for next turn mana bonus
            if playerId == 1 then
                gameState.player1ManaBonus = (gameState.player1ManaBonus or 0) + 2
            else
                gameState.player2ManaBonus = (gameState.player2ManaBonus or 0) + 2
            end
            
            print("Coin effect: Player " .. playerId .. " will gain +2 mana next turn")
            return true
        end
    },
    [15] = { -- Cult
        name = "Cult",
        type = "on_reveal",
        description = "When Revealed: Both players draw a card",
        effect = function(gameState, playerId, locationIndex)
            local gameRules = require("gameRules")
            
            -- Draw a card for both players
            local p1Drawn = gameRules.drawCardsForTurn(gameState.player1Deck, gameState.player1Hand, "Player 1")
            local p2Drawn = gameRules.drawCardsForTurn(gameState.player2Deck, gameState.player2Hand, "Player 2")
            
            print("Cult effect: Both players drew a card")
            return true
        end
    },

    [16] = { -- Bell Tower
        name = "Bell Tower",
        type = "on_reveal",
        description = "When Revealed: Gain +2 power for each card in your discard pile",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local discardPile = require("discardPile")
            local discardCount = discardPile.getDiscardCount(playerId)
            local powerGain = discardCount * 2
            
            if cardRef and powerGain > 0 then
                cardRef.power = (cardRef.power or 0) + powerGain
                print("Bell Tower effect: Gained +" .. powerGain .. " power from " .. discardCount .. " discarded cards (now " .. cardRef.power .. ")")
            end
            
            return true
        end
    },
    [17] = { -- Rebirth
        name = "Rebirth",
        type = "on_reveal",
        description = "When Revealed: Gain +2 power for each of your other cards here",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local playerCards = playerId == 1 and location.player1Cards or location.player2Cards
            local otherCardCount = #playerCards - 1 -- Exclude this card itself
            local powerGain = otherCardCount * 2
            
            if cardRef and powerGain > 0 then
                cardRef.power = (cardRef.power or 0) + powerGain
                print("Rebirth effect: Gained +" .. powerGain .. " power from " .. otherCardCount .. " ally cards (now " .. cardRef.power .. ")")
            end
            
            return true
        end
    },
    [18] = { -- Water Dragon
        name = "Water Dragon",
        type = "on_reveal",
        description = "When Revealed: Moves to another location",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local currentLocation = gameState.locations[locationIndex]
            local playerCards = playerId == 1 and currentLocation.player1Cards or currentLocation.player2Cards
            
            -- Find available locations that arent full
            local availableLocations = {}
            for i, location in ipairs(gameState.locations) do
                if i ~= locationIndex then
                    local targetCards = playerId == 1 and location.player1Cards or location.player2Cards
                    if #targetCards < 4 then
                        table.insert(availableLocations, i)
                    end
                end
            end
            
            if #availableLocations > 0 then
                -- Remove from current location
                for i, card in ipairs(playerCards) do
                    if card == cardRef then
                        table.remove(playerCards, i)
                        break
                    end
                end
                
                -- Move to random available location
                local targetLocationIndex = availableLocations[love.math.random(1, #availableLocations)]
                local targetLocation = gameState.locations[targetLocationIndex]
                local targetCards = playerId == 1 and targetLocation.player1Cards or targetLocation.player2Cards
                
                table.insert(targetCards, cardRef)
                
                print("Water Dragon effect: Moved from " .. currentLocation.name .. " to " .. targetLocation.name)
                return true
            end
            
            return false
        end
    },
    [19] = { -- Ocean Treasure
        name = "Ocean Treasure",
        type = "on_reveal",
        description = "When Revealed: Add a copy with +1 power to your hand",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local playerHand = playerId == 1 and gameState.player1Hand or gameState.player2Hand
            local cardData = require("cardData")
            
            if cardRef then
                local originalCard = cardData.getCard(cardRef.id)
                if originalCard then
                    local treasureCopy = {
                        id = originalCard.id,
                        name = originalCard.name,
                        type = originalCard.type,
                        description = originalCard.description,
                        imagePath = originalCard.imagePath,
                        manaCost = originalCard.manaCost,
                        power = (originalCard.power or 0) + 1 -- +1 power bonus
                    }
                    
                    table.insert(playerHand, treasureCopy)
                    print("Ocean Treasure effect: Added copy with +" .. treasureCopy.power .. " power to hand")
                    return true
                end
            end
            
            return false
        end
    },
    [20] = { -- Fire Element
        name = "Fire Element",
        type = "end_of_turn",
        description = "End of Turn: Loses 1 power if not winning this location",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local playerPower = playerId == 1 and location.player1Power or location.player2Power
            local enemyPower = playerId == 1 and location.player2Power or location.player1Power
            
            if playerPower <= enemyPower and cardRef and cardRef.power > 0 then
                cardRef.power = cardRef.power - 1
                print("Fire Element effect: Lost 1 power for not winning location (now " .. cardRef.power .. ")")
                return true
            end
            
            return false
        end
    },
    [21] = { -- Lightning Element
        name = "Lightning Element",
        type = "on_reveal",
        description = "When Revealed: Set ALL cards here to 3 power",
        effect = function(gameState, playerId, locationIndex)
            local location = gameState.locations[locationIndex]
            local cardsAffected = 0
            
            -- Set all player 1 cards to 3 power
            for _, card in ipairs(location.player1Cards) do
                card.power = 3
                cardsAffected = cardsAffected + 1
            end
            
            -- Set all player 2 cards to 3 power
            for _, card in ipairs(location.player2Cards) do
                card.power = 3
                cardsAffected = cardsAffected + 1
            end
            
            print("Lightning Element effect: Set " .. cardsAffected .. " cards to 3 power")
            return true
        end
    },
    [22] = { -- Air Element
        name = "Air Element",
        type = "on_reveal",
        description = "When Revealed: Lower the power of each enemy card here by 1",
        effect = function(gameState, playerId, locationIndex)
            local location = gameState.locations[locationIndex]
            local enemyCards = playerId == 1 and location.player2Cards or location.player1Cards
            local cardsAffected = 0
            
            for _, card in ipairs(enemyCards) do
                if card.power and card.power > 0 then
                    card.power = card.power - 1
                    cardsAffected = cardsAffected + 1
                end
            end
            
            print("Air Element effect: Reduced power of " .. cardsAffected .. " enemy cards by 1")
            return true
        end
    },
    [23] = { -- Water Element
        name = "Water Element",
        type = "ongoing",
        description = "Gain +1 power when you play another card here",
        effect = function(gameState, playerId, locationIndex, cardRef, triggerCard)
            -- This effect is triggered when a new card is played at the same location
            if cardRef and triggerCard and cardRef ~= triggerCard then
                cardRef.power = (cardRef.power or 0) + 1
                print("Water Element effect: Gained +1 power from ally card (now " .. cardRef.power .. ")")
                return true
            end
            return false
        end
    },
    [24] = { -- Dark Element
        name = "Dark Element",
        type = "on_reveal",
        description = "When Revealed: Lower the cost of 2 cards in your hand by 1",
        effect = function(gameState, playerId, locationIndex)
            local playerHand = playerId == 1 and gameState.player1Hand or gameState.player2Hand
            local cardsAffected = 0
            local maxCards = 2
            
            for _, card in ipairs(playerHand) do
                if cardsAffected < maxCards and card.manaCost and card.manaCost > 0 then
                    card.manaCost = card.manaCost - 1
                    cardsAffected = cardsAffected + 1
                    print("Dark Element: Reduced " .. (card.name or "Unknown") .. "'s cost by 1")
                end
            end
            
            print("Dark Element effect: Reduced cost of " .. cardsAffected .. " cards in hand")
            return true
        end
    },
    [25] = { -- Earth Element
        name = "Earth Element",
        type = "on_reveal",
        description = "When Revealed: Discard the lowest power card in your hand",
        effect = function(gameState, playerId, locationIndex)
            local playerHand = playerId == 1 and gameState.player1Hand or gameState.player2Hand
            
            if #playerHand > 0 then
                -- Find lowest power card
                local lowestPower = math.huge
                local lowestIndex = 1
                
                for i, card in ipairs(playerHand) do
                    local cardPower = card.power or 0
                    if cardPower < lowestPower then
                        lowestPower = cardPower
                        lowestIndex = i
                    end
                end
                
                local discardedCard = table.remove(playerHand, lowestIndex)
                print("Earth Element effect: Discarded " .. (discardedCard.name or "Unknown") .. " from hand")
                return true
            end
            
            return false
        end
    },
    [26] = { -- Blood Ring
        name = "Blood Ring",
        type = "on_reveal",
        description = "When Revealed: Draw a card from your opponent's deck",
        effect = function(gameState, playerId, locationIndex)
            local playerHand = playerId == 1 and gameState.player1Hand or gameState.player2Hand
            local opponentDeck = playerId == 1 and gameState.player2Deck or gameState.player1Deck
            
            if #opponentDeck > 0 then
                local stolenCard = table.remove(opponentDeck, 1) -- Take top card
                table.insert(playerHand, stolenCard)
                print("Blood Ring effect: Drew " .. (stolenCard.name or "Unknown") .. " from opponent's deck")
                return true
            end
            
            return false
        end
    },
    [27] = { -- Book
        name = "Book",
        type = "on_reveal",
        description = "When Revealed: If no ally cards are here, lower this card's power by 5",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local playerCards = playerId == 1 and location.player1Cards or location.player2Cards
            local allyCount = #playerCards - 1 -- Exclude this card itself
            
            if allyCount == 0 and cardRef then
                cardRef.power = math.max(0, (cardRef.power or 0) - 5)
                print("Book effect: Reduced power by 5 for being alone (now " .. cardRef.power .. ")")
                return true
            end
            
            return false
        end
    },
    [28] = { -- Roll Dice
        name = "Roll Dice",
        type = "end_of_turn",
        description = "End of Turn: Gains +1 power, but is discarded when its power is greater than 7",
        effect = function(gameState, playerId, locationIndex, cardRef)
            if cardRef then
                cardRef.power = (cardRef.power or 0) + 1
                print("Roll Dice effect: Gained +1 power (now " .. cardRef.power .. ")")
                
                if cardRef.power > 7 then
                    -- Find and remove this card from the location
                    local location = gameState.locations[locationIndex]
                    local playerCards = playerId == 1 and location.player1Cards or location.player2Cards
                    
                    for i, card in ipairs(playerCards) do
                        if card == cardRef then
                            table.remove(playerCards, i)
                            print("Roll Dice effect: Discarded for exceeding 7 power")
                            break
                        end
                    end
                end
                
                return true
            end
            
            return false
        end
    },
    [29] = { -- Block
        name = "Block",
        type = "end_of_turn",
        description = "End of Turn: Give your cards at each other location +1 power if they have unique powers",
        effect = function(gameState, playerId, locationIndex)
            local cardsBuffed = 0
            
            -- Check all other locations
            for i, location in ipairs(gameState.locations) do
                if i ~= locationIndex then
                    local playerCards = playerId == 1 and location.player1Cards or location.player2Cards
                    local uniquePowers = {}
                    
                    -- Collect unique powers at this location
                    for _, card in ipairs(playerCards) do
                        if cardPowers.hasSpecialAbility(card.id) then
                            local powerDef = cardPowers.getPowerDefinition(card.id)
                            if powerDef and powerDef.description then
                                uniquePowers[powerDef.description] = true
                            end
                        end
                    end
                    
                    -- If there are unique powers buff all cards
                    local uniqueCount = 0
                    for _ in pairs(uniquePowers) do
                        uniqueCount = uniqueCount + 1
                    end
                    
                    if uniqueCount > 0 then
                        for _, card in ipairs(playerCards) do
                            card.power = (card.power or 0) + 1
                            cardsBuffed = cardsBuffed + 1
                        end
                    end
                end
            end
            
            print("Block effect: Gave +1 power to " .. cardsBuffed .. " cards at other locations")
            return true
        end
    },
    [30] = { -- Wizard
        name = "Wizard",
        type = "on_reveal",
        description = "When Revealed: Discards your other cards here, add their power to this card",
        effect = function(gameState, playerId, locationIndex, cardRef)
            local location = gameState.locations[locationIndex]
            local playerCards = playerId == 1 and location.player1Cards or location.player2Cards
            local cardsToDiscard = {}
            local totalPowerGain = 0
            
            -- Find other cards to discard (excluding the Wizard itself)
            for i, card in ipairs(playerCards) do
                if card ~= cardRef then
                    table.insert(cardsToDiscard, {index = i, power = card.power or 0, name = card.name})
                    totalPowerGain = totalPowerGain + (card.power or 0)
                end
            end
            
            -- Remove cards from back to front to avoid index issues
            for i = #cardsToDiscard, 1, -1 do
                local cardInfo = cardsToDiscard[i]
                table.remove(playerCards, cardInfo.index)
                print("Wizard discarded: " .. (cardInfo.name or "Unknown") .. " (+" .. cardInfo.power .. " power)")
            end
            
            if cardRef and totalPowerGain > 0 then
                cardRef.power = (cardRef.power or 0) + totalPowerGain
                print("Wizard effect: Absorbed +" .. totalPowerGain .. " power (now " .. cardRef.power .. ")")
            end
            
            return true
        end
    }
}

-- Get card power definition by ID
function cardPowers.getPowerDefinition(cardId)
    return cardPowers.definitions[cardId]
end

-- Check if card has special ability
function cardPowers.hasSpecialAbility(cardId)
    local def = cardPowers.getPowerDefinition(cardId)
    return def and def.type ~= "vanilla"
end

-- Trigger card power based on timing
function cardPowers.triggerPower(cardId, timing, gameState, playerId, locationIndex, cardRef, triggerCard)
    local def = cardPowers.getPowerDefinition(cardId)
    
    if not def or def.type == "vanilla" then
        return false
    end
    
    if def.type == timing and def.effect then
        return def.effect(gameState, playerId, locationIndex, cardRef, triggerCard)
    end
    
    return false
end

-- Get card info
function cardPowers.getCardDescription(cardId)
    local def = cardPowers.getPowerDefinition(cardId)
    return def and def.description or "No special ability"
end

-- Handle ongoing effects when new cards are played
function cardPowers.handleOngoingEffects(gameState, locationIndex, newCard, playerId)
    local location = gameState.locations[locationIndex]
    local allCards = {}
    
    -- Collect all cards at this location
    for _, card in ipairs(location.player1Cards) do
        table.insert(allCards, {card = card, playerId = 1})
    end
    for _, card in ipairs(location.player2Cards) do
        table.insert(allCards, {card = card, playerId = 2})
    end
    
    -- Check for ongoing effects that trigger when new cards arrive
    for _, cardData in ipairs(allCards) do
        if cardData.card ~= newCard then -- Don't trigger on self
            local def = cardPowers.getPowerDefinition(cardData.card.id)
            if def and def.type == "ongoing" and def.effect then
                def.effect(gameState, cardData.playerId, locationIndex, cardData.card, newCard)
            end
        end
    end
end

-- Handle Stink Trap effect specifically
function cardPowers.handleStinkTrapEffect(gameState, locationIndex, newCard)
    local location = gameState.locations[locationIndex]
    local allCards = {}
    
    -- Collect all cards at this location
    for _, card in ipairs(location.player1Cards) do
        table.insert(allCards, card)
    end
    for _, card in ipairs(location.player2Cards) do
        table.insert(allCards, card)
    end
    
    -- Check for Stink Trap cards
    for _, card in ipairs(allCards) do
        if card.id == 7 and card ~= newCard then -- Stink Trap ID is 7
            cardPowers.triggerPower(7, "ongoing", gameState, nil, locationIndex, nil, newCard)
        end
    end
    
    -- Check for Water Element cards (id 23) - gain power when ally cards are played
    for _, card in ipairs(allCards) do
        if card.id == 23 and card ~= newCard then -- Water Element ID is 23
            -- Check if newCard is an ally (same player)
            local cardLocation = nil
            local newCardLocation = nil
            
            -- Find which player owns each card
            for _, playerCard in ipairs(location.player1Cards) do
                if playerCard == card then cardLocation = 1 end
                if playerCard == newCard then newCardLocation = 1 end
            end
            for _, playerCard in ipairs(location.player2Cards) do
                if playerCard == card then cardLocation = 2 end
                if playerCard == newCard then newCardLocation = 2 end
            end
            
            -- If theyre on the same team trigger Water Element
            if cardLocation == newCardLocation then
                cardPowers.triggerPower(23, "ongoing", gameState, cardLocation, locationIndex, card, newCard)
            end
        end
    end
end

-- Handle end of turn effects
function cardPowers.handleEndOfTurnEffects(gameState)
    for locationIndex, location in ipairs(gameState.locations) do
        -- Handle Player 1 cards
        for i = #location.player1Cards, 1, -1 do -- Reverse order in case cards are removed
            local card = location.player1Cards[i]
            cardPowers.triggerPower(card.id, "end_of_turn", gameState, 1, locationIndex, card)
        end
        
        -- Handle Player 2 cards
        for i = #location.player2Cards, 1, -1 do -- Reverse order in case cards are removed
            local card = location.player2Cards[i]
            cardPowers.triggerPower(card.id, "end_of_turn", gameState, 2, locationIndex, card)
        end
    end
end

return cardPowers