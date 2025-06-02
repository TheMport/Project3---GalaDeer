-- Import modules
local GrabberClass = require("grabber")
local cardData = require("cardData")
local gameRules = require("gameRules")

-- Game state variables
local gameState = "loading" -- all game states
local player1Deck = {}
local player2Deck = {} -- AI player
local player1Hand = {}
local player2Hand = {}
local player1Mana = 10 -- Changed starting mana to 10
local player2Mana = 10 -- Changed starting mana to 10
local maxMana = 20 -- Increased max mana
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
        winner = nil -- nil, 1, 2, or "tie"
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
    playerFirst = 1 -- which player's cards reveal first
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

-- Handle window resize
function love.resize(w, h)
    -- Update any necessary UI elements based on new window size
    print("Window resized to: " .. w .. "x" .. h)
end

function initializeGame()
    print("Initializing location-based card game...")
    
    -- Reset game state with new mana values
    player1Mana = 10
    player2Mana = 10
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
        
        if gamePhase == "staging" then
            -- Handle AI staging during player's turn
            if currentPlayer == 2 and not aiIsThinking then
                aiIsThinking = true
                aiTurnTimer = aiTurnDelay
                print("AI is deciding on card placements...")
            elseif currentPlayer == 2 and aiIsThinking then
                aiTurnTimer = aiTurnTimer - dt
                if aiTurnTimer <= 0 then
                    aiStageCards()
                    aiIsThinking = false
                    currentPlayer = 1 -- Return to player for final submissions
                end
            end
        elseif gamePhase == "reveal" then
            handleRevealPhase(dt)
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
        revealPhase.timer = 0
        
        if revealPhase.currentLocation <= #locations then
            local location = locations[revealPhase.currentLocation]
            print("Revealing cards at " .. location.name)
            
            -- Calculate power for this location
            location.player1Power = gameRules.calculateLocationPower(location.player1Cards)
            location.player2Power = gameRules.calculateLocationPower(location.player2Cards)
            
            -- Determine winner and update scores properly
            if location.player1Power > location.player2Power then
                location.winner = 1
                local points = location.player1Power - location.player2Power
                player1Points = player1Points + points
                print("Player 1 wins " .. location.name .. " (+" .. points .. " points)")
            elseif location.player2Power > location.player1Power then
                location.winner = 2
                local points = location.player2Power - location.player1Power
                player2Points = player2Points + points
                print("Player 2 wins " .. location.name .. " (+" .. points .. " points)")
            else
                location.winner = "tie"
                print(location.name .. " is a tie!")
            end
            
            revealPhase.currentLocation = revealPhase.currentLocation + 1
        else
            -- All locations revealed, end reveal phase
            endRevealPhase()
        end
    end
end

function endRevealPhase()
    revealPhase.isRevealing = false
    revealPhase.currentLocation = 1
    gamePhase = "staging"
    
    print("\n=== Turn " .. currentTurn .. " Results ===")
    print("Player 1 Total Points: " .. player1Points)
    print("Player 2 Total Points: " .. player2Points)
    
    -- Start next turn
    startNextTurn()
end

function startNextTurn()
    currentTurn = currentTurn + 1
    currentPlayer = 1
    bothPlayersReady = false
    
    -- Increase mana by 2 each turn
    player1Mana = math.min(player1Mana + 2, maxMana)
    player2Mana = math.min(player2Mana + 2, maxMana)
    
    -- Draw cards
    gameRules.drawCardsForTurn(player1Deck, player1Hand, "Player 1")
    gameRules.drawCardsForTurn(player2Deck, player2Hand, "Player 2")
    
    -- Enforce hand limits
    gameRules.enforceHandSizeLimit(player1Hand, "Player 1")
    gameRules.enforceHandSizeLimit(player2Hand, "Player 2")
    
    print("\n=== Turn " .. currentTurn .. " begins ===")
    print("Mana: " .. player1Mana .. " each")
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
        
        -- Power display
        love.graphics.setFont(love.graphics.newFont(14))
        local powerText = "P1: " .. location.player1Power .. " | P2: " .. location.player2Power
        if location.winner == 1 then
            love.graphics.setColor(0.2, 1, 0.2)
        elseif location.winner == 2 then
            love.graphics.setColor(1, 0.2, 0.2)
        else
            love.graphics.setColor(1, 1, 0.8)
        end
        love.graphics.printf(powerText, x, y + 25, locationWidth, "center")
        
        -- Enemy area background
        love.graphics.setColor(0.4, 0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", x + 5, y + 45, locationWidth - 10, 125)
        love.graphics.setColor(0.6, 0.3, 0.3)
        love.graphics.rectangle("line", x + 5, y + 45, locationWidth - 10, 125)
        
        -- Draw enemy cards (top)
        drawLocationCards(location.player2Cards, x + 15, y + 50, true)
        
        -- Draw divider
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.line(x + 10, y + 180, x + locationWidth - 10, y + 180)
        
        -- Player area background - this is the drop zone (FIXED COORDINATES)
        love.graphics.setColor(0.2, 0.4, 0.2, 0.3)
        love.graphics.rectangle("fill", x + 5, y + 185, locationWidth - 10, 110)
        love.graphics.setColor(0.3, 0.6, 0.3)
        love.graphics.rectangle("line", x + 5, y + 185, locationWidth - 10, 110)
        
        -- Player area label
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("Your Cards (" .. #location.player1Cards .. "/4)", x + 10, y + 190, locationWidth - 20, "left")
        
        -- Draw player cards (bottom) - positioned within the green area
        drawLocationCards(location.player1Cards, x + 15, y + 205, false)
    end
end

function drawLocationCards(cards, startX, startY, isEnemy)
    local cardSpacing = 85 -- Reduced spacing to fit better
    
    -- First draw all empty slots
    for i = 1, 4 do
        local x = startX + (i - 1) * cardSpacing
        local y = startY
        
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
        
        -- Add slot number
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("Slot " .. tostring(i), x + 2, y + cardHeight/2 - 5, cardWidth - 4, "center")
    end
    
    -- Then draw cards on top of slots
    for i, card in ipairs(cards) do
        local x = startX + (i - 1) * cardSpacing
        local y = startY
        
        if isEnemy then
            -- For reveal phase or after, show actual cards
            if gamePhase == "reveal" or revealPhase.isRevealing then
                -- Draw actual enemy card
                drawCard(card, x, y)
            else
                -- Draw card back for enemy during staging
                love.graphics.setColor(0.6, 0.3, 0.3)
                love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
                love.graphics.setColor(0.3, 0.1, 0.1)
                love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
                
                -- Draw card back pattern
                love.graphics.setColor(0.4, 0.2, 0.2)
                love.graphics.setFont(love.graphics.newFont(12))
                love.graphics.printf("CARD", x + 2, y + cardHeight/2 - 6, cardWidth - 4, "center")
            end
        else
            -- Draw player card normally - make sure it's visible
            love.graphics.setColor(1, 1, 1) -- Reset color to white
            drawCard(card, x, y)
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
        
        -- Draw card back pattern
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
        
        if stagedCard.card.isDragging then
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
    
    -- Card background with more visible colors
    love.graphics.setColor(0.9, 0.9, 1) -- Light blue-white background
    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
    love.graphics.setColor(0.1, 0.1, 0.2) -- Dark border
    love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
    
    -- Card image
    local cardImage = cardData.getCardImage(card.id)
    if cardImage then
        love.graphics.setColor(1, 1, 1)
        local scale = math.min(cardWidth / cardImage:getWidth(), (cardHeight - 30) / cardImage:getHeight())
        local imgX = x + (cardWidth - cardImage:getWidth() * scale) / 2
        local imgY = y + 5
        love.graphics.draw(cardImage, imgX, imgY, 0, scale, scale)
    else
        -- If no image, draw a placeholder
        love.graphics.setColor(0.7, 0.7, 0.9)
        love.graphics.rectangle("fill", x + 5, y + 5, cardWidth - 10, cardHeight - 35)
        love.graphics.setColor(0.3, 0.3, 0.5)
        love.graphics.rectangle("line", x + 5, y + 5, cardWidth - 10, cardHeight - 35)
    end
    
    -- Card info with better contrast
    love.graphics.setColor(0, 0, 0) -- Black text
    love.graphics.setFont(love.graphics.newFont(9))
    -- Card name
    love.graphics.printf(card.name or "Unknown", x + 2, y + cardHeight - 25, cardWidth - 4, "center")
    -- Mana cost and power
    love.graphics.printf("M:" .. (card.manaCost or 0) .. " P:" .. (card.power or 0), x + 2, y + cardHeight - 12, cardWidth - 4, "center")
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
    love.graphics.printf("Drag cards to locations (4 max per location). ENTER: Submit plays | SPACE: End turn | R: Restart", 0, screenHeight - 20, screenWidth, "center")
end

function drawManaDisplay()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Player Mana UI (bottom right)
    local playerUIWidth = 220
    local playerUIHeight = 90
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
    
    -- FORCE UPDATE THE DISPLAY VALUES
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.printf("Mana: " .. tostring(player1Mana), playerUIX + 10, playerUIY + 30, playerUIWidth - 20, "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.printf("Points: " .. tostring(player1Points), playerUIX + 10, playerUIY + 65, playerUIWidth - 20, "center")
    

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
    
    -- FORCE UPDATE THE DISPLAY VALUES
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("Mana: " .. tostring(player2Mana), aiUIX + 10, aiUIY + 30, playerUIWidth - 20, "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(1, 0.8, 0.8)
    love.graphics.printf("Points: " .. tostring(player2Points), aiUIX + 10, aiUIY + 65, playerUIWidth - 20, "center")
    
    -- DEBUGGER Print current values to console when they change
    if love.timer.getTime() % 1 < 0.1 then -- Print every second
        print("DEBUG - Current values: P1 Mana=" .. player1Mana .. ", P1 Points=" .. player1Points .. ", P2 Mana=" .. player2Mana .. ", P2 Points=" .. player2Points)
    end
    
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

-- Mouse handling
function love.mousepressed(x, y, button)
    if button == 1 and gameState == "playing" and gamePhase == "staging" and currentPlayer == 1 then
        local screenHeight = love.graphics.getHeight()
        local dynamicHandY = screenHeight - 140
        grabber:onMousePressed(x, y, player1Hand, stagedCards, cardWidth, cardHeight, dynamicHandY)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and gameState == "playing" and gamePhase == "staging" and currentPlayer == 1 then
        local screenHeight = love.graphics.getHeight()
        local dynamicHandY = screenHeight - 140
        -- Check if dropping on a location first with FIXED coordinates
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
    end
end

function submitPlayerCards()
    if #stagedCards == 0 then
        print("No cards staged to submit!")
        return
    end
    
    -- Check mana cost PROPERLY
    local totalCost = grabber:calculateStagedManaCost(stagedCards)
    
    if totalCost > player1Mana then
        print("Not enough mana! Need " .. totalCost .. ", have " .. player1Mana)
        return
    end
    
    print("BEFORE submission - Player1 Mana: " .. player1Mana .. ", Total Cost: " .. totalCost)
    
    -- Play cards to locations
    for _, stagedCard in ipairs(stagedCards) do
        local location = locations[stagedCard.locationIndex]
        -- Make sure the card has all necessary properties
        local cardToPlay = {
            id = stagedCard.card.id,
            name = stagedCard.card.name,
            type = stagedCard.card.type,
            description = stagedCard.card.description,
            imagePath = stagedCard.card.imagePath,
            manaCost = stagedCard.card.manaCost,
            power = stagedCard.card.power or 0
        }
        table.insert(location.player1Cards, cardToPlay)
        print("Played " .. stagedCard.card.name .. " to " .. location.name .. " (Power: " .. cardToPlay.power .. ", Cost: " .. cardToPlay.manaCost .. ")")
    end
    
    player1Mana = player1Mana - totalCost
    print("AFTER submission - Player1 Mana: " .. player1Mana .. " (deducted " .. totalCost .. ")")
    
    -- Clear staged cards
    stagedCards = {} -- Clear the entire array
    
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
            -- Find a location with space
            local availableLocations = {}
            for i, location in ipairs(locations) do
                if #location.player2Cards < 4 then
                    table.insert(availableLocations, i)
                end
            end
            
            if #availableLocations > 0 then
                local targetLocation = availableLocations[love.math.random(1, #availableLocations)]
                local location = locations[targetLocation]
                
                -- Play the card and PROPERLY DEDUCT AI MANA
                table.remove(player2Hand, randomCardIndex)
                table.insert(location.player2Cards, card)
                print("BEFORE AI mana deduction: " .. player2Mana .. ", Card cost: " .. card.manaCost)
                player2Mana = player2Mana - card.manaCost
                print("AFTER AI mana deduction: " .. player2Mana)
                
                print("AI played " .. card.name .. " to " .. location.name .. " (Power: " .. card.power .. ", Cost: " .. card.manaCost .. ", Remaining mana: " .. player2Mana .. ")")
            else
                break -- No locations available
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
    
    love.graphics.printf("Press R to play again", 0, screenHeight / 2 + 60, screenWidth, "center")
    love.graphics.printf("Press ESC to quit", 0, screenHeight / 2 + 100, screenWidth, "center")
end