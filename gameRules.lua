local gameRules = {}

-- constants 
gameRules.DECK_SIZE = 20
gameRules.MAX_COPIES_PER_CARD = 2
gameRules.STARTING_HAND_SIZE = 2
gameRules.MAX_HAND_SIZE = 6
gameRules.CARDS_DRAWN_PER_TURN = 1
gameRules.MAX_CARDS_PER_LOCATION = 4
gameRules.WINNING_POINTS = 20 -- Points needed to win the game

-- create a valid deck 
function gameRules.createValidDeck(cardData)
    local deck = {}
    local availableCards = {}
    
    -- pool of available cards (2 dupes max)
    for i, card in ipairs(cardData.definitions) do
        for copy = 1, gameRules.MAX_COPIES_PER_CARD do
            table.insert(availableCards, {
                id = card.id,
                name = card.name,
                type = card.type,
                description = card.description,
                imagePath = card.imagePath,
                manaCost = card.manaCost,
                power = card.power or 0, -- Ensure power is set
                copyNumber = copy
            })
        end
    end
    
    -- RNG selecter
    for i = 1, gameRules.DECK_SIZE do
        if #availableCards > 0 then
            local randomIndex = love.math.random(1, #availableCards)
            local selectedCard = availableCards[randomIndex]
            table.insert(deck, selectedCard)
            table.remove(availableCards, randomIndex)
        else
            print("Warning: Not enough unique cards to fill deck completely")
            break
        end
    end
    
    -- Shuffle 
    gameRules.shuffleDeck(deck)
    
    print("Created valid deck with " .. #deck .. " cards")
    return deck
end

-- shuffle function
function gameRules.shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- deal cards 
function gameRules.dealStartingHands(player1Deck, player2Deck)
    local player1Hand = {}
    local player2Hand = {}
    
    for i = 1, gameRules.STARTING_HAND_SIZE do
        -- Player 1 
        if #player1Deck > 0 then
            table.insert(player1Hand, table.remove(player1Deck, 1))
        end
        
        -- Player 2 (AI)
        if #player2Deck > 0 then
            table.insert(player2Hand, table.remove(player2Deck, 1))
        end
    end
    
    print("Dealt starting hands: Player 1 = " .. #player1Hand .. " cards, Player 2 = " .. #player2Hand .. " cards")
    return player1Hand, player2Hand
end

-- draw cards for turn
function gameRules.drawCardsForTurn(deck, hand, playerName)
    local cardsDrawn = 0
    
    for i = 1, gameRules.CARDS_DRAWN_PER_TURN do
        if #deck > 0 and #hand < gameRules.MAX_HAND_SIZE then
            table.insert(hand, table.remove(deck, 1))
            cardsDrawn = cardsDrawn + 1
        elseif #hand >= gameRules.MAX_HAND_SIZE then
            print(playerName .. " hand is full! Cannot draw more cards.")
            break
        elseif #deck == 0 then
            print(playerName .. " deck is empty! Cannot draw more cards.")
            break
        end
    end
    
    if cardsDrawn > 0 then
        print(playerName .. " drew " .. cardsDrawn .. " card(s). Hand size: " .. #hand)
    end
    
    return cardsDrawn
end

-- card placement checker for locations
function gameRules.canPlayCardToLocation(hand, cardIndex, currentMana, card, location)
    -- Check if card index is valid
    if cardIndex < 1 or cardIndex > #hand then
        return false, "Invalid card selection"
    end
    
    -- Check mana cost 
    if card and card.manaCost > currentMana then
        return false, "Not enough mana"
    end
    
    -- Check if location has space
    if #location.player1Cards >= gameRules.MAX_CARDS_PER_LOCATION then
        return false, "Location is full (max " .. gameRules.MAX_CARDS_PER_LOCATION .. " cards)"
    end
    
    return true, "Card can be played to location"
end

-- Calculate total power at a location
function gameRules.calculateLocationPower(cards)
    local totalPower = 0
    for _, card in ipairs(cards) do
        totalPower = totalPower + (card.power or 0)
    end
    return totalPower
end

-- Check if a player can place more cards at any location
function gameRules.canPlaceMoreCards(locations, playerNumber)
    for _, location in ipairs(locations) do
        local playerCards = playerNumber == 1 and location.player1Cards or location.player2Cards
        if #playerCards < gameRules.MAX_CARDS_PER_LOCATION then
            return true
        end
    end
    return false
end

-- Get available locations for a player
function gameRules.getAvailableLocations(locations, playerNumber)
    local available = {}
    for i, location in ipairs(locations) do
        local playerCards = playerNumber == 1 and location.player1Cards or location.player2Cards
        if #playerCards < gameRules.MAX_CARDS_PER_LOCATION then
            table.insert(available, i)
        end
    end
    return available
end

-- Calculate total mana cost of a set of cards
function gameRules.calculateTotalManaCost(cards)
    local totalCost = 0
    for _, card in ipairs(cards) do
        totalCost = totalCost + (card.manaCost or 0)
    end
    return totalCost
end

-- deck validation
function gameRules.validateDeck(deck)
    local cardCounts = {}
    local isValid = true
    local errors = {}
    
    if #deck ~= gameRules.DECK_SIZE then
        isValid = false
        table.insert(errors, "Deck must contain exactly " .. gameRules.DECK_SIZE .. " cards (currently has " .. #deck .. ")")
    end
    
    for i, card in ipairs(deck) do
        local cardId = card.id
        cardCounts[cardId] = (cardCounts[cardId] or 0) + 1
    end
    
    for cardId, count in pairs(cardCounts) do
        if count > gameRules.MAX_COPIES_PER_CARD then
            isValid = false
            table.insert(errors, "Card ID " .. cardId .. " appears " .. count .. " times (max allowed: " .. gameRules.MAX_COPIES_PER_CARD .. ")")
        end
    end
    
    return isValid, errors
end

-- win or lose checker - updated for location-based game
function gameRules.checkGameEnd(player1Deck, player1Hand, player2Deck, player2Hand, player1Points, player2Points)
    local gameEnded = false
    local winner = nil
    local reason = ""
    
    -- Check if a player reached winning points
    if player1Points >= gameRules.WINNING_POINTS then
        gameEnded = true
        winner = "Player 1"
        reason = "Reached " .. gameRules.WINNING_POINTS .. " points"
    elseif player2Points >= gameRules.WINNING_POINTS then
        gameEnded = true
        winner = "Player 2"
        reason = "Reached " .. gameRules.WINNING_POINTS .. " points"
    -- Check if a player cannot draw cards and has no cards in hand
    elseif #player1Deck == 0 and #player1Hand == 0 then
        gameEnded = true
        winner = player2Points > player1Points and "Player 2" or (player1Points > player2Points and "Player 1" or "Tie")
        reason = "Player 1 ran out of cards"
    elseif #player2Deck == 0 and #player2Hand == 0 then
        gameEnded = true
        winner = player1Points > player2Points and "Player 1" or (player2Points > player1Points and "Player 2" or "Tie")
        reason = "Player 2 ran out of cards"
    end
    
    return gameEnded, winner, reason
end

-- location scoring - determine winner of each location and award points
function gameRules.scoreLocations(locations)
    local player1TotalPoints = 0
    local player2TotalPoints = 0
    
    for i, location in ipairs(locations) do
        local p1Power = gameRules.calculateLocationPower(location.player1Cards)
        local p2Power = gameRules.calculateLocationPower(location.player2Cards)
        
        location.player1Power = p1Power
        location.player2Power = p2Power
        
        if p1Power > p2Power then
            location.winner = 1
            local points = p1Power - p2Power
            player1TotalPoints = player1TotalPoints + points
            print("Player 1 wins " .. location.name .. " (+" .. points .. " points)")
        elseif p2Power > p1Power then
            location.winner = 2
            local points = p2Power - p1Power
            player2TotalPoints = player2TotalPoints + points
            print("Player 2 wins " .. location.name .. " (+" .. points .. " points)")
        else
            location.winner = "tie"
            print(location.name .. " is a tie!")
        end
    end
    
    return player1TotalPoints, player2TotalPoints
end

-- deck stat checker
function gameRules.getDeckStats(deck)
    local stats = {
        totalCards = #deck,
        cardTypes = {},
        uniqueCards = {},
        manaCurve = {},
        powerCurve = {}
    }
    
    for i, card in ipairs(deck) do
        -- Count card types
        stats.cardTypes[card.type] = (stats.cardTypes[card.type] or 0) + 1
        
        -- Count unique cards
        stats.uniqueCards[card.id] = (stats.uniqueCards[card.id] or 0) + 1
        
        -- Count mana costs
        local manaCost = card.manaCost or 0
        stats.manaCurve[manaCost] = (stats.manaCurve[manaCost] or 0) + 1
        
        -- Count power levels
        local power = card.power or 0
        stats.powerCurve[power] = (stats.powerCurve[power] or 0) + 1
    end
    
    return stats
end

-- print deck composition (debugger)
function gameRules.printDeckComposition(deck, deckName)
    print("\n=== " .. deckName .. " Composition ===")
    print("Total cards: " .. #deck)
    
    local cardCounts = {}
    local totalPower = 0
    local totalManaCost = 0
    
    for i, card in ipairs(deck) do
        local key = card.name
        cardCounts[key] = (cardCounts[key] or 0) + 1
        totalPower = totalPower + (card.power or 0)
        totalManaCost = totalManaCost + (card.manaCost or 0)
    end
    
    for cardName, count in pairs(cardCounts) do
        print(cardName .. ": " .. count .. " copies")
    end
    
    print("Average Mana Cost: " .. string.format("%.1f", totalManaCost / #deck))
    print("Average Power: " .. string.format("%.1f", totalPower / #deck))
    print("========================\n")
end

-- hand size limiter
function gameRules.enforceHandSizeLimit(hand, playerName)
    local cardsDiscarded = 0
    
    while #hand > gameRules.MAX_HAND_SIZE do
        -- removes the oldest card when limit is exceeded
        local discardedCard = table.remove(hand, 1)
        cardsDiscarded = cardsDiscarded + 1
        print(playerName .. " discarded " .. discardedCard.name .. " (hand size limit exceeded)")
    end
    
    return cardsDiscarded
end

-- AI helper functions
function gameRules.evaluateLocationForAI(location, aiCards, opponentCards)
    local aiPower = gameRules.calculateLocationPower(aiCards)
    local opponentPower = gameRules.calculateLocationPower(opponentCards)
    

    local score = aiPower - opponentPower
    
    if #aiCards < gameRules.MAX_CARDS_PER_LOCATION then
        score = score + 1
    end
    
    return score
end

function gameRules.getBestLocationForAI(locations, card)
    local bestLocation = 1
    local bestScore = -999
    
    for i, location in ipairs(locations) do
        if #location.player2Cards < gameRules.MAX_CARDS_PER_LOCATION then
            local score = gameRules.evaluateLocationForAI(location, location.player2Cards, location.player1Cards)
            
            score = score + (card.power or 0)
            
            if score > bestScore then
                bestScore = score
                bestLocation = i
            end
        end
    end
    
    return bestLocation
end

return gameRules