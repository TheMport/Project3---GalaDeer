-- Import modules
local GrabberClass = require("grabber")
local cardData = require("cardData")
local gameRules = require("gameRules")
local discardPile = require("discardPile")

-- Game state variables
local gameState = "loading" -- all game states
local player1Deck = {}
local player2Deck = {} -- AI player
local player1Hand = {}
local player2Hand = {}
local maxMana = 10 -- Max mana is 10
local currentTurn = 1 -- Track turns
local currentPlayer = 1 -- 1 for player, 2 for AI

local grabber = nil
local player1Points = 0
local player2Points = 0

-- Location system - 3 locations with 4 slots each per player
local locations = {
    {
        name = "Forest Glade", 
        player1Cards = {}, -- max 4 cards
        player2Cards = {}, -- max 4 cards
        player1Power = 0,
        player2Power = 0,
        winner = nil -- nil, 1, 2, or "tie
    },
    {
        name = "Ancient Temple", 
        player1Cards = {}, 
        player2Cards = {}, 
        player1Power = 0,
        player2Power = 0,
        winner = nil
    },
    {
        name = "Crystal Cavern", 
        player1Cards = {}, 
        player2Cards = {}, 
        player1Power = 0,
        player2Power = 0,
        winner = nil
    }
}

local stagedCards = {} -- Cards staged for play this turn with location info
local gamePhase = "staging" -- "staging", "reveal", "scoring"
local revealPhase = {
    isRevealing = false,
    timer = 0,
    delay = 1.0,
    currentLocation = 1,
    playerFirst = 1 
}

-- AI turn timer
local aiTurnTimer = 0
local aiTurnDelay = 1.5
local aiIsThinking = false
local bothPlayersReady = false

-- Card image details
local cardWidth = 80
local cardHeight = 120
local handY = 580
local enemyHandY = 30

-- Location display
local locationY = 180
local locationHeight = 300
local locationWidth = 400

function love.load()
    -- game title and window settings (adjustable)
    love.window.setMode(1280, 720, {
        resizable = true,
        minwidth = 1024,
        minheight = 600
    })
    love.window.setTitle("3CG - Project 3 - Fantasy Card Game")

    -- added grabber 
    grabber = GrabberClass:new()
    
    -- RNG
    love.math.setRandomSeed(os.time())
    
    -- pre load
    gameState = "loading"
    cardData.loadImages()
    
    initializeGame()
    gameState = "playing"
end

-- window resize
function love.resize(w, h)

    print("Window resized to: " .. w .. "x" .. h)
end

function initializeGame()
    print("Initializing location-based card game...")
    
    -- Reset game state with correct starting mana
    player1Mana = 6
    player2Mana = 6
    currentTurn = 1
    currentPlayer = 1
    aiIsThinking = false
    aiTurnTimer = 0
    bothPlayersReady = false
    gamePhase = "staging"
    
    -- Clear all cards and points
    stagedCards = {}
    player1Points = 0
    player2Points = 0
    
    -- Initialize discard pile system
    discardPile.initialize()
    
    -- Reset locations
    for i, location in ipairs(locations) do
        location.player1Cards = {}
        location.player2Cards = {}
        location.player1Power = 0
        location.player2Power = 0
        location.winner = nil
    end
    
    -- Reset reveal phase
    revealPhase.isRevealing = false
    revealPhase.timer = 0
    revealPhase.currentLocation = 1
    revealPhase.playerFirst = 1
    
    -- Deck creation (20 cards, max 2 copies of a card allowed)
    player1Deck = gameRules.createValidDeck(cardData)
    player2Deck = gameRules.createValidDeck(cardData)
    
    -- Deal starting hands
    player1Hand, player2Hand = gameRules.dealStartingHands(player1Deck, player2Deck)
    
    -- Draw initial cards for turn 1
    gameRules.drawCardsForTurn(player1Deck, player1Hand, "Player 1")
    gameRules.drawCardsForTurn(player2Deck, player2Hand, "Player 2")
    
    print("Game initialized:")
    print("- Player 1: " .. #player1Hand .. " cards in hand")
    print("- Player 2: " .. #player2Hand .. " cards in hand")
    print("- 3 locations available for play")
    print("- Starting mana: " .. player1Mana)
    print("- Discard pile system ready")
end

function love.update(dt)
    if gameState == "playing" then
        grabber:update(dt)
        
        -- Check game end
        local gameEnded, winner, reason = gameRules.checkGameEnd(player1Deck, player1Hand, player2Deck, player2Hand, player1Points, player2Points)
        if gameEnded then
            print("Game Over! " .. winner .. " wins! Reason: " .. reason)
            gameState = "gameOver"
            return
        end
        
        -- Update location powers continuously
        updateLocationPowers()
        
        if gamePhase == "staging" then
            -- Handle AI staging during players turn
            if currentPlayer == 2 and not aiIsThinking then
                aiIsThinking = true
                aiTurnTimer = aiTurnDelay
                print("AI is deciding on card placements...")
            elseif currentPlayer == 2 and aiIsThinking then
                aiTurnTimer = aiTurnTimer - dt
                if aiTurnTimer <= 0 then
                    aiStageCards()
                    aiIsThinking = false
                    currentPlayer = 1 
                end
            end
        elseif gamePhase == "reveal" then
            handleRevealPhase(dt)
        end
    end
end

-- location powers with proper validation
function updateLocationPowers()
    for i, location in ipairs(locations) do

        local p1Power = 0
        for _, card in ipairs(location.player1Cards) do
            local cardPower = card.power or 0
            p1Power = p1Power + cardPower

            if cardPower == 0 and card.id then
                local originalCard = cardData.getCard(card.id)
                if originalCard and originalCard.power then
                    print("WARNING: Card " .. card.name .. " missing power, should be " .. originalCard.power)
                    card.power = originalCard.power
                    p1Power = p1Power + originalCard.power
                end
            end
        end
        location.player1Power = p1Power
        
        -- Player 2 power with validation
        local p2Power = 0
        for _, card in ipairs(location.player2Cards) do
            local cardPower = card.power or 0
            p2Power = p2Power + cardPower

            if cardPower == 0 and card.id then
                local originalCard = cardData.getCard(card.id)
                if originalCard and originalCard.power then
                    print("WARNING: Card " .. card.name .. " missing power, should be " .. originalCard.power)
                    card.power = originalCard.power
                    p2Power = p2Power + originalCard.power
                end
            end
        end
        location.player2Power = p2Power
        if p1Power > 0 or p2Power > 0 then
            print("DEBUG: Location " .. location.name .. " - P1 cards: " .. #location.player1Cards .. " (power: " .. p1Power .. "), P2 cards: " .. #location.player2Cards .. " (power: " .. p2Power .. ")")
        end
    end
end

function handleRevealPhase(dt)
    if not revealPhase.isRevealing then
        return
    end
    
    revealPhase.timer = revealPhase.timer + dt
    
    if revealPhase.timer >= revealPhase.delay then
        -- Move to next reveal step
        revealPhase.timer = 2
        
        if revealPhase.currentLocation <= #locations then
            local location = locations[revealPhase.currentLocation]
            print("Revealing cards at " .. location.name)
            

            calculateAndAwardLocationPoints(location)
            
            revealPhase.currentLocation = revealPhase.currentLocation + 1
        else
            -- All locations revealed, end reveal phase
            endRevealPhase()
        end
    end
end

-- calculate and award points based on power difference
function calculateAndAwardLocationPoints(location)

    location.player1Power = calculateLocationPowerCorrectly(location.player1Cards)
    location.player2Power = calculateLocationPowerCorrectly(location.player2Cards)
    
    print("=== SCORING " .. location.name .. " ===")
    print("Player 1 Power: " .. location.player1Power .. " (from " .. #location.player1Cards .. " cards)")
    print("Player 2 Power: " .. location.player2Power .. " (from " .. #location.player2Cards .. " cards)")
    
    -- List all cards at this location for debugging
    print("P1 Cards at " .. location.name .. ":")
    for i, card in ipairs(location.player1Cards) do
        print("  " .. i .. ": " .. (card.name or "Unknown") .. " (Power: " .. (card.power or 0) .. ")")
    end
    print("P2 Cards at " .. location.name .. ":")
    for i, card in ipairs(location.player2Cards) do
        print("  " .. i .. ": " .. (card.name or "Unknown") .. " (Power: " .. (card.power or 0) .. ")")
    end
    
    if location.player1Power > location.player2Power then
        local pointsAwarded = location.player1Power - location.player2Power
        location.winner = 1
        player1Points = player1Points + pointsAwarded
        
        print("✓ Player 1 WINS " .. location.name .. "!")
        print("✓ Points awarded to Player 1: " .. pointsAwarded)
        print("✓ Player 1 total points: " .. player1Points)
        
    elseif location.player2Power > location.player1Power then
        local pointsAwarded = location.player2Power - location.player1Power
        location.winner = 2
        player2Points = player2Points + pointsAwarded
        
        print("✓ Player 2 (AI) WINS " .. location.name .. "!")
        print("✓ Points awarded to Player 2: " .. pointsAwarded)
        print("✓ Player 2 total points: " .. player2Points)
        
    else
        location.winner = "tie"
        print("⚪ " .. location.name .. " is a TIE!")
        print("⚪ No points awarded (both players have " .. location.player1Power .. " power)")
    end
    
    print("=== Current Score: P1=" .. player1Points .. " | P2=" .. player2Points .. " ===\n")
end

-- Calculate location power correctly with proper validation
function calculateLocationPowerCorrectly(cards)
    local totalPower = 0
    for _, card in ipairs(cards) do
        if card and card.power then
            totalPower = totalPower + card.power
        elseif card and card.id then

            local originalCard = cardData.getCard(card.id)
            if originalCard and originalCard.power then
                totalPower = totalPower + originalCard.power
                card.power = originalCard.power 
            end
        end
    end
    return totalPower
end

function endRevealPhase()
    revealPhase.isRevealing = false
    revealPhase.currentLocation = 1
    gamePhase = "staging"
    
    print("\n=== Turn " .. currentTurn .. " FINAL Results ===")
    print("Player 1 Total Points: " .. player1Points)
    print("Player 2 Total Points: " .. player2Points)
    
    -- Show detailed location results
    print("\nLocation Winners:")
    for i, location in ipairs(locations) do
        if location.winner == 1 then
            print("  " .. location.name .. ": Player 1 (" .. location.player1Power .. " vs " .. location.player2Power .. ")")
        elseif location.winner == 2 then
            print("  " .. location.name .. ": Player 2 (" .. location.player2Power .. " vs " .. location.player1Power .. ")")
        else
            print("  " .. location.name .. ": TIE (" .. location.player1Power .. " vs " .. location.player2Power .. ")")
        end
    end
    
    -- Move all played cards to discard pile
    discardPile.moveLocationCardsToDiscard(locations, currentTurn)
    

    if currentTurn % 3 == 0 then
        discardPile.printDiscardPileInfo(1)
        discardPile.printDiscardPileInfo(2)
    end
    

    startNextTurn()
end

function startNextTurn()
    currentTurn = currentTurn + 1
    currentPlayer = 1
    bothPlayersReady = false
    
    -- Increase mana by 2 each turn, capped at 10
    player1Mana = math.min(player1Mana + 2, maxMana)
    player2Mana = math.min(player2Mana + 2, maxMana)
    
    print("Turn " .. currentTurn .. " - Player mana increased to: " .. player1Mana .. "/" .. maxMana)
    
    -- Draw cards
    gameRules.drawCardsForTurn(player1Deck, player1Hand, "Player 1")
    gameRules.drawCardsForTurn(player2Deck, player2Hand, "Player 2")
    
    -- hand limits
    gameRules.enforceHandSizeLimit(player1Hand, "Player 1")
    gameRules.enforceHandSizeLimit(player2Hand, "Player 2")
    
    print("\n=== Turn " .. currentTurn .. " begins ===")
    print("Current mana: Player 1=" .. player1Mana .. ", Player 2=" .. player2Mana)
end

function love.draw()
    love.graphics.setBackgroundColor(0.1, 0.2, 0.1) -- Dark green background
    love.graphics.setColor(1, 1, 1)
    
    if gameState == "loading" then
        drawLoadingScreen()
    elseif gameState == "playing" then
        drawGameScreen()
    elseif gameState == "gameOver" then
        drawGameOverScreen()
    end
end

function drawLoadingScreen()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Loading Fantasy Card Game...", 0, screenHeight / 2 - 12, screenWidth, "center")
end

function drawGameScreen()
    drawLocations()
    drawPlayerHand()
    drawEnemyHand()
    drawStagedCards()
    drawGameInfo()
    drawManaDisplay()
    
    -- Draw drop zone hints
    if grabber:isHolding() then
        drawDropZoneHints()
    end
end

function drawLocations()
    for i, location in ipairs(locations) do
        local x = 50 + (i - 1) * 420
        local y = locationY
        
        -- Location background
        love.graphics.setColor(0.3, 0.4, 0.3)
        love.graphics.rectangle("fill", x, y, locationWidth, locationHeight)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", x, y, locationWidth, locationHeight)
        
        -- Location name
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(location.name, x, y + 5, locationWidth, "center")
        

        love.graphics.setFont(love.graphics.newFont(14))
        local powerText = "P1: " .. location.player1Power .. " | P2: " .. location.player2Power
        
        if location.winner == 1 then
            love.graphics.setColor(0.2, 1, 0.2) -- Green for Player 1 win
            local pointsWon = location.player1Power - location.player2Power
            powerText = powerText .. " (P1 +" .. pointsWon .. "pts)"
        elseif location.winner == 2 then
            love.graphics.setColor(1, 0.2, 0.2) -- Red for Player 2 win
            local pointsWon = location.player2Power - location.player1Power
            powerText = powerText .. " (P2 +" .. pointsWon .. "pts)"
        elseif location.winner == "tie" then
            love.graphics.setColor(1, 1, 0.2) -- Yellow for tie
            powerText = powerText .. " (TIE)"
        else
            love.graphics.setColor(1, 1, 0.8) -- Default white
        end
        
        love.graphics.printf(powerText, x, y + 25, locationWidth, "center")
        
        -- Enemy area background
        love.graphics.setColor(0.4, 0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", x + 5, y + 45, locationWidth - 10, 125)
        love.graphics.setColor(0.6, 0.3, 0.3)
        love.graphics.rectangle("line", x + 5, y + 45, locationWidth - 10, 125)
        
        -- Draw enemy cards (top)
        drawLocationCards(location.player2Cards, x + 15, y + 50, true)
        
        -- divider
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.line(x + 10, y + 180, x + locationWidth - 10, y + 180)
        
        -- Player area background 
        love.graphics.setColor(0.2, 0.4, 0.2, 0.3)
        love.graphics.rectangle("fill", x + 5, y + 185, locationWidth - 10, 110)
        love.graphics.setColor(0.3, 0.6, 0.3)
        love.graphics.rectangle("line", x + 5, y + 185, locationWidth - 10, 110)
        

        -- Draw player cards (bottom) - positioned within the green area
        drawLocationCards(location.player1Cards, x + 15, y + 183, false)
    end
end


function drawLocationCards(cards, startX, startY, isEnemy)
    local cardSpacing = 85 
    local maxSlots = 4

    for slot = 1, maxSlots do
        local x = startX + (slot - 1) * cardSpacing
        local y = startY

        -- Draw slot background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight)

        -- Add slot number label
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("Slot " .. slot, x + 2, y + cardHeight/2 - 5, cardWidth - 4, "center")


        local card = cards[slot]
        if card then
            love.graphics.setColor(1, 1, 1)
            if isEnemy then
                if gamePhase == "reveal" or revealPhase.isRevealing then
                    -- Draw revealed enemy card at exact slot position
                    drawCard(card, x, y)
                else
                    -- Enemy card back at exact slot position
                    love.graphics.setColor(0.6, 0.3, 0.3)
                    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
                    love.graphics.setColor(0.3, 0.1, 0.1)
                    love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
                    love.graphics.setColor(0.4, 0.2, 0.2)
                    love.graphics.setFont(love.graphics.newFont(10))
                    love.graphics.printf("CARD", x + 2, y + cardHeight/2 - 5, cardWidth - 4, "center")
                end
            else

                drawCard(card, x, y)
            end
        end
    end
end

function drawDropZoneHints()
    local screenHeight = love.graphics.getHeight()
    local handY = screenHeight - 140 -- Match the updated hand position
    
    local heldCard = grabber:getHeldCard()
    if not heldCard then return end
    
    -- Highlight valid drop zones for each location 
    for i, location in ipairs(locations) do
        if #location.player1Cards < 4 then -- Can only place if not full
            local x = 50 + (i - 1) * 420
            local y = locationY + 185 -- Match the actual player area position
            
            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.rectangle("fill", x + 5, y, locationWidth - 10, 110)
            love.graphics.setColor(0, 1, 0, 0.8)
            love.graphics.rectangle("line", x + 5, y, locationWidth - 10, 110)
            
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("DROP HERE", x, y + 45, locationWidth, "center")
        end
    end
    
    -- Hand return zone
    love.graphics.setColor(0, 0, 1, 0.3)
    love.graphics.rectangle("fill", 50, handY - 20, love.graphics.getWidth() - 100, 140)
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("line", 50, handY - 20, love.graphics.getWidth() - 100, 140)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("RETURN TO HAND", 0, handY + 40, love.graphics.getWidth(), "center")
end

function drawPlayerHand()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local handY = screenHeight - 140 -- Adjust hand position based on screen height
    
    love.graphics.setColor(1, 1, 1)
    local startX = 100
    local spacing = 90
    
    for i, card in ipairs(player1Hand) do
        local x, y
        
        if card.isDragging and card.dragX and card.dragY then
            x = card.dragX
            y = card.dragY
        else
            x = startX + (i - 1) * spacing
            y = handY
        end
        
        drawCard(card, x, y)
    end
end

function drawEnemyHand()
    love.graphics.setColor(1, 1, 1)
    local startX = 100
    local spacing = 90
    
    for i, card in ipairs(player2Hand) do
        local x = startX + (i - 1) * spacing
        local y = enemyHandY
        
        -- Draw card back
        love.graphics.setColor(0.6, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
        love.graphics.setColor(0.3, 0.1, 0.1)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
        
        love.graphics.setColor(0.4, 0.2, 0.2)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("CARD", x + 2, y + cardHeight/2 - 5, cardWidth - 4, "center")
    end
end


function drawStagedCards()
    if #stagedCards == 0 then return end
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(love.graphics.newFont(14))
    
    -- Calculate total staged mana cost
    local totalStagedCost = 0
    for _, stagedCard in ipairs(stagedCards) do
        totalStagedCost = totalStagedCost + (stagedCard.card.manaCost or 0)
    end
    
    love.graphics.printf("Staged: " .. #stagedCards .. " cards (Cost: " .. totalStagedCost .. ")", 50, 520, 400, "left")
    
    local startX = 50
    local spacing = 90
    
    for i, stagedCard in ipairs(stagedCards) do
        local x = startX + (i - 1) * spacing
        local y = 530
        

        if stagedCard.card.isDragging and stagedCard.card.dragX and stagedCard.card.dragY then
            x = stagedCard.card.dragX
            y = stagedCard.card.dragY
        end
        
        love.graphics.setColor(0.9, 0.9, 1)
        drawCard(stagedCard.card, x, y)
        
        -- Show target location
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(love.graphics.newFont(10))
        local locationName = locations[stagedCard.locationIndex].name
        love.graphics.printf("→ " .. locationName, x, y - 15, cardWidth, "center")
    end
end


function drawCard(card, x, y)
    -- Ensure we have a valid card
    if not card then return end

    local drawX = x
    local drawY = y

    if card.isDragging and card.dragX and card.dragY and grabber:isHolding() and grabber:getHeldCard() == card then
        drawX = card.dragX
        drawY = card.dragY
        print("DEBUG: Using drag coordinates for " .. (card.name or "Unknown") .. " at (" .. drawX .. ", " .. drawY .. ")")
    else
        -- Use the provided slot coordinates (this is what was broken)
        print("DEBUG: Using slot coordinates for " .. (card.name or "Unknown") .. " at (" .. drawX .. ", " .. drawY .. ")")
    end
    
    -- Card background
    love.graphics.setColor(0.9, 0.9, 1) -- Light blue-white background
    love.graphics.rectangle("fill", drawX, drawY, cardWidth, cardHeight)
    love.graphics.setColor(0.1, 0.1, 0.2) -- Dark border
    love.graphics.rectangle("line", drawX, drawY, cardWidth, cardHeight)
    
    -- Card image
    local cardImage = cardData.getCardImage(card.id)
    if cardImage then
        love.graphics.setColor(1, 1, 1)
        local scale = math.min(cardWidth / cardImage:getWidth(), (cardHeight - 30) / cardImage:getHeight())
        local imgX = drawX + (cardWidth - cardImage:getWidth() * scale) / 2
        local imgY = drawY + 5
        love.graphics.draw(cardImage, imgX, imgY, 0, scale, scale)
    else
        -- fail case
        love.graphics.setColor(0.7, 0.7, 0.9)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, cardWidth - 10, cardHeight - 35)
        love.graphics.setColor(0.3, 0.3, 0.5)
        love.graphics.rectangle("line", drawX + 5, drawY + 5, cardWidth - 10, cardHeight - 35)
    end
    
    -- Card info 
    love.graphics.setColor(0, 0, 0) -- Black text
    love.graphics.setFont(love.graphics.newFont(9))
    -- Card name
    love.graphics.printf(card.name or "Unknown", drawX + 2, drawY + cardHeight - 25, cardWidth - 4, "center")
    -- Mana cost and power
    love.graphics.printf("M:" .. (card.manaCost or 0) .. " P:" .. (card.power or 0), drawX + 2, drawY + cardHeight - 12, cardWidth - 4, "center")
end

function drawGameInfo()
    local screenWidth = love.graphics.getWidth()
    
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Location Card Game - Turn " .. currentTurn, 0, 5, screenWidth, "center")
    
    -- Game phase and status
    local statusText = gamePhase
    if gamePhase == "staging" then
        if currentPlayer == 1 then
            statusText = "Your Turn - Stage Cards"
        else
            statusText = aiIsThinking and "AI Thinking..." or "AI Turn"
        end
    elseif gamePhase == "reveal" then
        statusText = "Revealing Cards..."
    end
    
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.printf(statusText, 0, 25, screenWidth, "center")
    
    -- Instructions (bottom of screen)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.8, 0.8, 0.8)
    local screenHeight = love.graphics.getHeight()
    love.graphics.printf("Drag cards to locations (4 max per location). ENTER: Submit plays | SPACE: End turn | R: Restart | D: Discard info", 0, screenHeight - 20, screenWidth, "center")
end

function drawManaDisplay()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate actual available mana
    local stagedCost = 0
    for _, stagedCard in ipairs(stagedCards) do
        stagedCost = stagedCost + (stagedCard.card.manaCost or 0)
    end
    local availableMana = player1Mana - stagedCost
    
    -- Player Mana UI (bottom right)
    local playerUIWidth = 220
    local playerUIHeight = 120
    local playerUIX = screenWidth - playerUIWidth - 20
    local playerUIY = screenHeight - playerUIHeight - 20
    
    -- Player mana background
    love.graphics.setColor(0.1, 0.3, 0.6, 0.9)
    love.graphics.rectangle("fill", playerUIX, playerUIY, playerUIWidth, playerUIHeight)
    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle("line", playerUIX, playerUIY, playerUIWidth, playerUIHeight)
    
    -- Player mana text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("PLAYER", playerUIX + 10, playerUIY + 5, playerUIWidth - 20, "center")
    
    -- Show staged cost
    love.graphics.setFont(love.graphics.newFont(20))
    if stagedCost > 0 then
        love.graphics.setColor(availableMana >= 0 and 0.3 or 1, availableMana >= 0 and 0.8 or 0.3, 0.3)
        love.graphics.printf("Mana: " .. availableMana .. "/" .. player1Mana, playerUIX + 10, playerUIY + 25, playerUIWidth - 20, "center")
    else
        love.graphics.setColor(0.3, 0.8, 1)
        love.graphics.printf("Mana: " .. player1Mana, playerUIX + 10, playerUIY + 25, playerUIWidth - 20, "center")
    end
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.printf("Points: " .. tostring(player1Points), playerUIX + 10, playerUIY + 50, playerUIWidth - 20, "center")
    
    -- Discard pile info
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.7, 0.9, 1)
    local discardCount = discardPile.getDiscardCount(1)
    love.graphics.printf("Discard: " .. discardCount .. " cards", playerUIX + 10, playerUIY + 75, playerUIWidth - 20, "center")
    
    local totalPowerPlayed = discardPile.getTotalPowerPlayed(1)
    love.graphics.printf("Power played: " .. totalPowerPlayed, playerUIX + 10, playerUIY + 90, playerUIWidth - 20, "center")
    
    -- AI UI
    local aiUIX = screenWidth - playerUIWidth - 20
    local aiUIY = 20
    
    -- AI mana background
    love.graphics.setColor(0.6, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", aiUIX, aiUIY, playerUIWidth, playerUIHeight)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.rectangle("line", aiUIX, aiUIY, playerUIWidth, playerUIHeight)
    
    -- AI mana text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("AI OPPONENT", aiUIX + 10, aiUIY + 5, playerUIWidth - 20, "center")
    
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("Mana: " .. tostring(player2Mana), aiUIX + 10, aiUIY + 25, playerUIWidth - 20, "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(1, 0.8, 0.8)
    love.graphics.printf("Points: " .. tostring(player2Points), aiUIX + 10, aiUIY + 50, playerUIWidth - 20, "center")
    
    -- AI Discard pile info
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 0.7, 0.7)
    local aiDiscardCount = discardPile.getDiscardCount(2)
    love.graphics.printf("Discard: " .. aiDiscardCount .. " cards", aiUIX + 10, aiUIY + 75, playerUIWidth - 20, "center")
    
    local aiTotalPowerPlayed = discardPile.getTotalPowerPlayed(2)
    love.graphics.printf("Power played: " .. aiTotalPowerPlayed, aiUIX + 10, aiUIY + 90, playerUIWidth - 20, "center")
    
    -- Mana cost indicator when dragging (center right)
    if grabber:isHolding() then
        local heldCard = grabber:getHeldCard()
        if heldCard then
            local currentStagedCost = grabber:calculateStagedManaCost(stagedCards)
            local totalCostAfterPlay = currentStagedCost + heldCard.manaCost
            
            -- Cost preview box (center right)
            local costUIWidth = 200
            local costUIHeight = 80
            local costUIX = screenWidth - costUIWidth - 20
            local costUIY = screenHeight / 2 - costUIHeight / 2
            
            love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
            love.graphics.rectangle("fill", costUIX, costUIY, costUIWidth, costUIHeight)
            love.graphics.setColor(totalCostAfterPlay > player1Mana and 1 or 0.8, totalCostAfterPlay > player1Mana and 0.2 or 0.8, 0.2)
            love.graphics.rectangle("line", costUIX, costUIY, costUIWidth, costUIHeight)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.printf("Cost Preview:", costUIX + 10, costUIY + 10, costUIWidth - 20, "center")
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.setColor(totalCostAfterPlay > player1Mana and 1 or 0.3, totalCostAfterPlay > player1Mana and 0.3 or 1, 0.3)
            love.graphics.printf(totalCostAfterPlay .. " / " .. player1Mana, costUIX + 10, costUIY + 35, costUIWidth - 20, "center")
            
            -- Show if over budget
            if totalCostAfterPlay > player1Mana then
                love.graphics.setColor(1, 0.2, 0.2)
                love.graphics.setFont(love.graphics.newFont(12))
                love.graphics.printf("OVER BUDGET!", costUIX + 10, costUIY + 55, costUIWidth - 20, "center")
            end
        end
    end
    
    -- Turn indicator
    local turnUIWidth = 180
    local turnUIHeight = 40
    local turnUIX = screenWidth - turnUIWidth - 20
    local turnUIY = aiUIY + playerUIHeight + 10
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", turnUIX, turnUIY, turnUIWidth, turnUIHeight)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", turnUIX, turnUIY, turnUIWidth, turnUIHeight)
    
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Turn " .. currentTurn, turnUIX + 10, turnUIY + 10, turnUIWidth - 20, "center")
end


function love.mousepressed(x, y, button)
    if button == 1 and gameState == "playing" and gamePhase == "staging" and currentPlayer == 1 then
        local screenHeight = love.graphics.getHeight()
        local dynamicHandY = screenHeight - 140
        grabber:onMousePressed(x, y, player1Hand, stagedCards, cardWidth, cardHeight, dynamicHandY)
    end
end

-- Checking if dropping on a location first
function love.mousereleased(x, y, button)
    if button == 1 and gameState == "playing" and gamePhase == "staging" and currentPlayer == 1 then
        local screenHeight = love.graphics.getHeight()
        local dynamicHandY = screenHeight - 140
        local locationDropped = checkLocationDrop(x, y)
        grabber:onMouseReleased(x, y, player1Hand, stagedCards, cardWidth, cardHeight, dynamicHandY, currentPlayer, player1Mana, locations, locationDropped)
    end
end

function checkLocationDrop(x, y)
    local playerAreaY = locationY + 185 
    local playerAreaHeight = 110
    
    for i, location in ipairs(locations) do
        local locationX = 50 + (i - 1) * 420
        
        if x >= locationX + 5 and x <= locationX + locationWidth - 5 and
           y >= playerAreaY and y <= playerAreaY + playerAreaHeight then
            return i
        end
    end
    
    return nil
end

-- Key handling
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        initializeGame()
    elseif key == "return" or key == "enter" then
        if gamePhase == "staging" and currentPlayer == 1 then
            submitPlayerCards()
        end
    elseif key == "space" then
        if gamePhase == "staging" and currentPlayer == 1 then
            -- Skip to AI turn
            currentPlayer = 2
        end
    elseif key == "d" then
        -- Debug: Print discard pile info for both players (BROKEN)
        print("\n=== DEBUG: Discard Pile Information ===")
        discardPile.printDiscardPileInfo(1)
        discardPile.printDiscardPileInfo(2)
        

        print("\n=== DEBUG: Current Location Status ===")
        for i, location in ipairs(locations) do
            print("Location " .. i .. " (" .. location.name .. "):")
            print("  P1 Cards: " .. #location.player1Cards .. ", Power: " .. location.player1Power)
            print("  P2 Cards: " .. #location.player2Cards .. ", Power: " .. location.player2Power)
            if #location.player1Cards > 0 then
                print("  P1 Card Details:")
                for j, card in ipairs(location.player1Cards) do
                    print("    " .. j .. ": " .. (card.name or "Unknown") .. " (Power: " .. (card.power or 0) .. ", ID: " .. (card.id or "None") .. ")")
                end
            end
            if #location.player2Cards > 0 then
                print("  P2 Card Details:")
                for j, card in ipairs(location.player2Cards) do
                    print("    " .. j .. ": " .. (card.name or "Unknown") .. " (Power: " .. (card.power or 0) .. ", ID: " .. (card.id or "None") .. ")")
                end
            end
        end
    end
end

function submitPlayerCards()
    if #stagedCards == 0 then
        print("No cards staged to submit!")
        return
    end
    
    -- Check mana cost
    local totalCost = 0
    for _, stagedCard in ipairs(stagedCards) do
        totalCost = totalCost + (stagedCard.card.manaCost or 0)
    end
    
    if totalCost > player1Mana then
        print("Not enough mana! Need " .. totalCost .. ", have " .. player1Mana)
        return
    end
    
    print("BEFORE submission - Player1 Mana: " .. player1Mana .. ", Total Cost: " .. totalCost)
    

    for _, stagedCard in ipairs(stagedCards) do
        local location = locations[stagedCard.locationIndex]
        

        local originalCard = cardData.getCard(stagedCard.card.id)
        if not originalCard then
            print("ERROR: Could not find original card data for ID " .. tostring(stagedCard.card.id))
            return
        end
        
        -- card in play
        local cardToPlay = {
            id = originalCard.id,
            name = originalCard.name,
            type = originalCard.type,
            description = originalCard.description,
            imagePath = originalCard.imagePath,
            manaCost = originalCard.manaCost,
            power = originalCard.power or 0

        }
        

        for i = #player1Hand, 1, -1 do
            if player1Hand[i].id == stagedCard.card.id then
                table.remove(player1Hand, i)
                break
            end
        end
        

        table.insert(location.player1Cards, cardToPlay)
        
        print("✓ SUCCESSFULLY played " .. cardToPlay.name .. " to " .. location.name .. " slot " .. #location.player1Cards .. " (Power: " .. cardToPlay.power .. ", Cost: " .. cardToPlay.manaCost .. ")")
        print("DEBUG: Card has dragX=" .. tostring(cardToPlay.dragX) .. ", dragY=" .. tostring(cardToPlay.dragY) .. ", isDragging=" .. tostring(cardToPlay.isDragging))
        

        local newPower = calculateLocationPowerCorrectly(location.player1Cards)
        location.player1Power = newPower
        print("✓ Location " .. location.name .. " new P1 power: " .. newPower)
    end
    
    -- sub mana
    player1Mana = player1Mana - totalCost
    print("AFTER submission - Player1 Mana: " .. player1Mana .. " (deducted " .. totalCost .. ")")
    
    stagedCards = {}
    
    currentPlayer = 2
    print("Cards submitted! AI's turn...")
end

function aiStageCards()
    print("AI staging cards...")
    print("AI starting mana: " .. player2Mana)
    
    local attempts = 0
    local maxAttempts = #player2Hand
    
    while attempts < maxAttempts and #player2Hand > 0 and player2Mana > 0 do
        local randomCardIndex = love.math.random(1, #player2Hand)
        local card = player2Hand[randomCardIndex]
        
        if card.manaCost <= player2Mana then
            local availableLocations = {}
            for i, location in ipairs(locations) do
                if #location.player2Cards < 4 then
                    table.insert(availableLocations, i)
                end
            end
            
            if #availableLocations > 0 then
                local targetLocation = availableLocations[love.math.random(1, #availableLocations)]
                local location = locations[targetLocation]
                
                table.remove(player2Hand, randomCardIndex)
                
                local originalCard = cardData.getCard(card.id)
                if not originalCard then
                    print("ERROR: Could not find original card data for AI card ID " .. tostring(card.id))
                    break
                end
                
                local cardToPlay = {
                    id = originalCard.id,
                    name = originalCard.name,
                    type = originalCard.type,
                    description = originalCard.description,
                    imagePath = originalCard.imagePath,
                    manaCost = originalCard.manaCost,
                    power = originalCard.power or 0
                }
                

                table.insert(location.player2Cards, cardToPlay)
                
                -- Deduct mana
                player2Mana = player2Mana - cardToPlay.manaCost
                
                print("✓ AI played " .. cardToPlay.name .. " to " .. location.name .. " slot " .. #location.player2Cards .. " (Power: " .. cardToPlay.power .. ", Cost: " .. cardToPlay.manaCost .. ", Remaining mana: " .. player2Mana .. ")")
                print("DEBUG: AI card has dragX=" .. tostring(cardToPlay.dragX) .. ", dragY=" .. tostring(cardToPlay.dragY) .. ", isDragging=" .. tostring(cardToPlay.isDragging))
                

                local newPower = calculateLocationPowerCorrectly(location.player2Cards)
                location.player2Power = newPower
                print("✓ Location " .. location.name .. " new P2 power: " .. newPower)
            else
                break 
            end
        end
        
        attempts = attempts + 1
    end
    
    print("AI finished staging. Final mana: " .. player2Mana)
    startRevealPhase()
end

function startRevealPhase()
    gamePhase = "reveal"
    revealPhase.isRevealing = true
    revealPhase.timer = 0
    revealPhase.currentLocation = 1
    
    -- who reveals first 
    revealPhase.playerFirst = love.math.random(1, 2)
    
    print("Starting reveal phase...")
end

function drawGameOverScreen()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("GAME OVER", 0, screenHeight / 2 - 100, screenWidth, "center")
    
    love.graphics.setFont(love.graphics.newFont(24))
    local winner = player1Points > player2Points and "Player 1" or "Player 2"
    love.graphics.printf(winner .. " Wins!", 0, screenHeight / 2 - 40, screenWidth, "center")
    love.graphics.printf("Final Score: P1: " .. player1Points .. " | P2: " .. player2Points, 0, screenHeight / 2, screenWidth, "center")
    
    -- Display final discard pile statistics
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(0.8, 0.8, 1)
    local p1DiscardCount = discardPile.getDiscardCount(1)
    local p2DiscardCount = discardPile.getDiscardCount(2)
    local p1TotalPower = discardPile.getTotalPowerPlayed(1)
    local p2TotalPower = discardPile.getTotalPowerPlayed(2)
    
    love.graphics.printf("Cards Played - P1: " .. p1DiscardCount .. " | P2: " .. p2DiscardCount, 0, screenHeight / 2 + 30, screenWidth, "center")
    love.graphics.printf("Total Power Played - P1: " .. p1TotalPower .. " | P2: " .. p2TotalPower, 0, screenHeight / 2 + 50, screenWidth, "center")
    
    -- Show detailed final scoring breakdown
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.7, 1, 0.7)
    love.graphics.printf("FINAL LOCATION RESULTS:", 0, screenHeight / 2 + 80, screenWidth, "center")
    
    local yOffset = 100
    for i, location in ipairs(locations) do
        local resultText = location.name .. ": "
        if location.winner == 1 then
            local points = location.player1Power - location.player2Power
            resultText = resultText .. "P1 wins (" .. location.player1Power .. " vs " .. location.player2Power .. ") +" .. points .. "pts"
            love.graphics.setColor(0.2, 1, 0.2)
        elseif location.winner == 2 then
            local points = location.player2Power - location.player1Power
            resultText = resultText .. "P2 wins (" .. location.player2Power .. " vs " .. location.player1Power .. ") +" .. points .. "pts"
            love.graphics.setColor(1, 0.2, 0.2)
        else
            resultText = resultText .. "TIE (" .. location.player1Power .. " vs " .. location.player2Power .. ")"
            love.graphics.setColor(1, 1, 0.2)
        end
        love.graphics.printf(resultText, 0, screenHeight / 2 + yOffset, screenWidth, "center")
        yOffset = yOffset + 20
    end
    
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Press R to play again", 0, screenHeight / 2 + yOffset + 20, screenWidth, "center")
    love.graphics.printf("Press ESC to quit", 0, screenHeight / 2 + yOffset + 50, screenWidth, "center")
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.8, 0.8, 0.8)
end