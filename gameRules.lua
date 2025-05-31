

local gameRules = {}

-- constants 
gameRules.DECK_SIZE = 20
gameRules.MAX_COPIES_PER_CARD = 2
gameRules.STARTING_HAND_SIZE = 3
gameRules.MAX_HAND_SIZE = 7
gameRules.CARDS_DRAWN_PER_TURN = 1

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
                copyNumber = copy -- Track which copy this is
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

    -- card placement checker
function gameRules.canPlayCard(hand, cardIndex, currentMana, card)
    -- Check if card index is valid
    if cardIndex < 1 or cardIndex > #hand then
        return false, "Invalid card selection"
    end
    
    -- Check mana cost 
    if card and card.manaCost > currentMana then
        return false, "Not enough mana"
    end
    
    return true, "Card can be played"
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

-- win or lose checker
function gameRules.checkGameEnd(player1Deck, player1Hand, player2Deck, player2Hand)
    local gameEnded = false
    local winner = nil
    local reason = ""
    
    -- Check if a player cannot draw cards and has no cards in hand
    if #player1Deck == 0 and #player1Hand == 0 then
        gameEnded = true
        winner = "Player 2"
        reason = "Player 1 ran out of cards"
    elseif #player2Deck == 0 and #player2Hand == 0 then
        gameEnded = true
        winner = "Player 1"
        reason = "Player 2 ran out of cards"
    end
    
    return gameEnded, winner, reason
end

-- deck stat checker
function gameRules.getDeckStats(deck)
    local stats = {
        totalCards = #deck,
        cardTypes = {},
        uniqueCards = {},
        manaCurve = {}
    }
    
    for i, card in ipairs(deck) do
        -- Count card types
        stats.cardTypes[card.type] = (stats.cardTypes[card.type] or 0) + 1
        
        -- Count unique cards
        stats.uniqueCards[card.id] = (stats.uniqueCards[card.id] or 0) + 1
        
        -- Count mana costs
        local manaCost = card.manaCost or 0
        stats.manaCurve[manaCost] = (stats.manaCurve[manaCost] or 0) + 1
    end
    
    return stats
end

-- print deck composition (debugger)
function gameRules.printDeckComposition(deck, deckName)
    print("\n=== " .. deckName .. " Composition ===")
    print("Total cards: " .. #deck)
    
    local cardCounts = {}
    for i, card in ipairs(deck) do
        local key = card.name
        cardCounts[key] = (cardCounts[key] or 0) + 1
    end
    
    for cardName, count in pairs(cardCounts) do
        print(cardName .. ": " .. count .. " copies")
    end
    print("========================\n")
end

-- hand size limiter
function gameRules.enforceHandSizeLimit(hand, playerName)
    local cardsDiscarded = 0
    
    while #hand > gameRules.MAX_HAND_SIZE do
        -- removes the oldest card when limit of 7 is exceeded
        local discardedCard = table.remove(hand, 1)
        cardsDiscarded = cardsDiscarded + 1
        print(playerName .. " discarded " .. discardedCard.name .. " (hand size limit exceeded)")
    end
    
    return cardsDiscarded
end



return gameRules