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
    }
}

-- vanilla properties place holders for cards 16-30 (will add more later)
for i = 16, 30 do
    if not cardPowers.definitions[i] then
        cardPowers.definitions[i] = {
            name = "Card " .. i,
            type = "vanilla",
            description = "No special ability"
        }
    end
end

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

-- Handle
function cardPowers.handleOngoingEffects(gameState, locationIndex, newCard, playerId)
    local location = gameState.locations[locationIndex]
    local allCards = {}
    
    -- all cards at this location
    for _, card in ipairs(location.player1Cards) do
        table.insert(allCards, {card = card, playerId = 1})
    end
    for _, card in ipairs(location.player2Cards) do
        table.insert(allCards, {card = card, playerId = 2})
    end
    
    -- Check for ongoing effects that trigger when new cards arrive
    for _, cardData in ipairs(allCards) do
        if cardData.card ~= newCard then -- dont trigger on self
            local def = cardPowers.getPowerDefinition(cardData.card.id)
            if def and def.type == "ongoing" and def.effect then
                def.effect(gameState, cardData.playerId, locationIndex, newCard)
            end
        end
    end
end

-- Stink Trap specifically
function cardPowers.handleStinkTrapEffect(gameState, locationIndex, newCard)
    local location = gameState.locations[locationIndex]
    local allCards = {}
    
    -- all cards at this location
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
end

return cardPowers