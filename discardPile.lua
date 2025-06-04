local discardPile = {}

-- Discard pile storage for both players
discardPile.player1Discard = {}
discardPile.player2Discard = {}

-- Statistics tracking
discardPile.stats = {
    player1TotalCardsPlayed = 0,
    player2TotalCardsPlayed = 0,
    totalTurnsCompleted = 0
}

-- Initialize/reset discard piles
function discardPile.initialize()
    discardPile.player1Discard = {}
    discardPile.player2Discard = {}
    discardPile.stats = {
        player1TotalCardsPlayed = 0,
        player2TotalCardsPlayed = 0,
        totalTurnsCompleted = 0
    }
    print("Discard piles initialized")
end

-- Add a card to a players discard pile
function discardPile.addCard(playerNumber, card, turnPlayed, location)
    local discardEntry = {
        card = {
            id = card.id,
            name = card.name,
            type = card.type,
            description = card.description,
            imagePath = card.imagePath,
            manaCost = card.manaCost,
            power = card.power or 0
        },
        turnPlayed = turnPlayed or 1,
        location = location or "Unknown",
        timestamp = os.time()
    }
    
    if playerNumber == 1 then
        table.insert(discardPile.player1Discard, discardEntry)
        discardPile.stats.player1TotalCardsPlayed = discardPile.stats.player1TotalCardsPlayed + 1
        print("Added " .. card.name .. " to Player 1's discard pile (Turn " .. (turnPlayed or 1) .. ", " .. (location or "Unknown") .. ")")
    elseif playerNumber == 2 then
        table.insert(discardPile.player2Discard, discardEntry)
        discardPile.stats.player2TotalCardsPlayed = discardPile.stats.player2TotalCardsPlayed + 1
        print("Added " .. card.name .. " to Player 2's discard pile (Turn " .. (turnPlayed or 1) .. ", " .. (location or "Unknown") .. ")")
    end
end

-- Move all cards from locations to discard pile at end of turn
function discardPile.moveLocationCardsToDiscard(locations, currentTurn)
    local totalMoved = 0
    
    for i, location in ipairs(locations) do
        -- Move Player 1 cards
        for _, card in ipairs(location.player1Cards) do
            discardPile.addCard(1, card, currentTurn, location.name)
            totalMoved = totalMoved + 1
        end
        
        -- Move Player 2 cards
        for _, card in ipairs(location.player2Cards) do
            discardPile.addCard(2, card, currentTurn, location.name)
            totalMoved = totalMoved + 1
        end
        
        -- Clear the location cards
        location.player1Cards = {}
        location.player2Cards = {}
        location.player1Power = 0
        location.player2Power = 0
        location.winner = nil
    end
    
    discardPile.stats.totalTurnsCompleted = currentTurn
    print("Moved " .. totalMoved .. " cards from locations to discard piles")
    print("Turn " .. currentTurn .. " cards discarded - P1: " .. discardPile.getDiscardCount(1) .. " total, P2: " .. discardPile.getDiscardCount(2) .. " total")
end

-- Get the number of cards in a players discard pile
function discardPile.getDiscardCount(playerNumber)
    if playerNumber == 1 then
        return #discardPile.player1Discard
    elseif playerNumber == 2 then
        return #discardPile.player2Discard
    end
    return 0
end

-- Get all cards in a players discard pile
function discardPile.getDiscardPile(playerNumber)
    if playerNumber == 1 then
        return discardPile.player1Discard
    elseif playerNumber == 2 then
        return discardPile.player2Discard
    end
    return {}
end

-- Get cards of a specific type from discard pile
function discardPile.getCardsByType(playerNumber, cardType)
    local result = {}
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        if entry.card.type == cardType then
            table.insert(result, entry)
        end
    end
    
    return result
end

-- Get cards played at a specific location
function discardPile.getCardsByLocation(playerNumber, locationName)
    local result = {}
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        if entry.location == locationName then
            table.insert(result, entry)
        end
    end
    
    return result
end

-- Get cards played on a specific turn
function discardPile.getCardsByTurn(playerNumber, turn)
    local result = {}
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        if entry.turnPlayed == turn then
            table.insert(result, entry)
        end
    end
    
    return result
end

-- Get the most recently played cards (last N cards)
function discardPile.getRecentCards(playerNumber, count)
    local result = {}
    local pile = discardPile.getDiscardPile(playerNumber)
    local startIndex = math.max(1, #pile - count + 1)
    
    for i = startIndex, #pile do
        table.insert(result, pile[i])
    end
    
    return result
end

-- Calculate total power of cards in discard pile
function discardPile.getTotalPowerPlayed(playerNumber)
    local totalPower = 0
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        totalPower = totalPower + (entry.card.power or 0)
    end
    
    return totalPower
end

-- Calculate total mana spent
function discardPile.getTotalManaSpent(playerNumber)
    local totalMana = 0
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        totalMana = totalMana + (entry.card.manaCost or 0)
    end
    
    return totalMana
end

-- about the discard pile
function discardPile.getStats(playerNumber)
    local pile = discardPile.getDiscardPile(playerNumber)
    local stats = {
        totalCards = #pile,
        totalPower = discardPile.getTotalPowerPlayed(playerNumber),
        totalManaSpent = discardPile.getTotalManaSpent(playerNumber),
        cardTypes = {},
        locations = {},
        averagePower = 0,
        averageManaCost = 0
    }
    

    for _, entry in ipairs(pile) do
        local cardType = entry.card.type
        local location = entry.location
        
        stats.cardTypes[cardType] = (stats.cardTypes[cardType] or 0) + 1
        stats.locations[location] = (stats.locations[location] or 0) + 1
    end
    

    if stats.totalCards > 0 then
        stats.averagePower = stats.totalPower / stats.totalCards
        stats.averageManaCost = stats.totalManaSpent / stats.totalCards
    end
    
    return stats
end

-- discard pile information
function discardPile.printDiscardPileInfo(playerNumber)
    local playerName = playerNumber == 1 and "Player 1" or "Player 2"
    local pile = discardPile.getDiscardPile(playerNumber)
    local stats = discardPile.getStats(playerNumber)
    
    print("\n=== " .. playerName .. " Discard Pile ===")
    print("Total cards: " .. stats.totalCards)
    print("Total power: " .. stats.totalPower)
    print("Total mana spent: " .. stats.totalManaSpent)
    print("Average power: " .. string.format("%.1f", stats.averagePower))
    print("Average mana cost: " .. string.format("%.1f", stats.averageManaCost))
    
    print("\nCard types played:")
    for cardType, count in pairs(stats.cardTypes) do
        print("  " .. cardType .. ": " .. count)
    end
    
    print("\nCards played by location:")
    for location, count in pairs(stats.locations) do
        print("  " .. location .. ": " .. count)
    end
    
    print("\nRecent cards (last 3):")
    local recentCards = discardPile.getRecentCards(playerNumber, 3)
    for i, entry in ipairs(recentCards) do
        print("  " .. entry.card.name .. " (Turn " .. entry.turnPlayed .. ", " .. entry.location .. ")")
    end
    print("=========================\n")
end

-- Check if a specific card has been played
function discardPile.hasCardBeenPlayed(playerNumber, cardId)
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        if entry.card.id == cardId then
            return true, entry
        end
    end
    
    return false, nil
end

-- Get all unique card IDs that have been played
function discardPile.getUniqueCardsPlayed(playerNumber)
    local uniqueCards = {}
    local pile = discardPile.getDiscardPile(playerNumber)
    
    for _, entry in ipairs(pile) do
        if not uniqueCards[entry.card.id] then
            uniqueCards[entry.card.id] = {
                card = entry.card,
                timesPlayed = 0,
                firstPlayedTurn = entry.turnPlayed
            }
        end
        uniqueCards[entry.card.id].timesPlayed = uniqueCards[entry.card.id].timesPlayed + 1
    end
    
    return uniqueCards
end

-- Shuffle discard pile back into deck (for future mechanics)
function discardPile.shuffleBackIntoDeck(playerNumber, deck)
    local pile = discardPile.getDiscardPile(playerNumber)
    local cardsShuffled = 0
    
    for _, entry in ipairs(pile) do
        table.insert(deck, entry.card)
        cardsShuffled = cardsShuffled + 1
    end
    
    -- Shuffle the deck
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    
    -- Clear the discard pile
    if playerNumber == 1 then
        discardPile.player1Discard = {}
    elseif playerNumber == 2 then
        discardPile.player2Discard = {}
    end
    
    print("Shuffled " .. cardsShuffled .. " cards from discard pile back into deck")
    return cardsShuffled
end

-- Export discard pile data for save/load functionality
function discardPile.exportData()
    return {
        player1Discard = discardPile.player1Discard,
        player2Discard = discardPile.player2Discard,
        stats = discardPile.stats
    }
end

-- Import discard pile data for save/load functionality
function discardPile.importData(data)
    if data then
        discardPile.player1Discard = data.player1Discard or {}
        discardPile.player2Discard = data.player2Discard or {}
        discardPile.stats = data.stats or {
            player1TotalCardsPlayed = 0,
            player2TotalCardsPlayed = 0,
            totalTurnsCompleted = 0
        }
        print("Discard pile data imported successfully")
    end
end

return discardPile