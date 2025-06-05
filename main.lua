-- Import modules
local GrabberClass = require("grabber")
local cardData = require("cardData")
local gameRules = require("gameRules")
local discardPile = require("discardPile")
local cardPowers = require("cardPowers")


local gameState = "loading" -- all game states
local player1Deck = {}
local player2Deck = {} -- AI player
local player1Hand = {}
local player2Hand = {}
local maxMana = 10 -- Max mana is 10
local currentTurn = 1 
local currentPlayer = 1 -- 1 for player, 2 for AI

local grabber = nil
local player1Points = 0
local player2Points = 0

-- Mana bonus system for cards like Coin
local player1ManaBonus = 0
local player2ManaBonus = 0

local screenWidth = 1280
local screenHeight = 720
local cardWidth = 80
local cardHeight = 120

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
local gamePhase = "staging" -- staging, reveal, scoring
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

-- Card hover
local hoveredCard = nil
local hoverTimer = 0
local hoverDelay = 0.5

--  layout positions
local locationY = 160
local locationHeight = 320
local locationWidth = 380
local handY = 580
local enemyHandY = 30

function love.load()

    love.window.setMode(1400, 800, {
        resizable = true,
        minwidth = 1200,
        minheight = 700
    })
    love.window.setTitle("GalaDeer")

    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
    
    -- Update layout based on new screen size
    handY = screenHeight - 140
    
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
    screenWidth = w
    screenHeight = h
    handY = screenHeight - 140
    print("Window resized to: " .. w .. "x" .. h)
end

function initializeGame()
    print("Initializing location-based card game with powers...")
    
    player1Mana = 6
    player2Mana = 6
    player1ManaBonus = 0
    player2ManaBonus = 0
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
    
    -- Reset hover system
    hoveredCard = nil
    hoverTimer = 0
    
    -- Initialize discard pile 
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
    revealPhase = {
        isRevealing = false,
        timer = 0,
        delay = 1.0,
        currentLocation = 1,
        playerFirst = 1
    }
    
    -- Deck creation (20 cards, max 2 copies of a card allowed)
    player1Deck = gameRules.createValidDeck(cardData)
    player2Deck = gameRules.createValidDeck(cardData)
    
    -- Deal starting hands
    player1Hand, player2Hand = gameRules.dealStartingHands(player1Deck, player2Deck)
    
    -- Draw initial cards for turn 1
    gameRules.drawCardsForTurn(player1Deck, player1Hand, "Player 1")
    gameRules.drawCardsForTurn(player2Deck, player2Hand, "Player 2")
    
    print("- Player 1: " .. #player1Hand .. " cards in hand")
    print("- Player 2: " .. #player2Hand .. " cards in hand")
    print("- 3 playable locatations ")
    print("- Starting mana: " .. player1Mana)
    
    gameState = "playing"
end

function love.update(dt)
    if gameState == "playing" then
        grabber:update(dt)
        
        hoverTimer = hoverTimer + dt
        
        -- Check game end
        local gameEnded, winner, reason = gameRules.checkGameEnd(player1Deck, player1Hand, player2Deck, player2Hand, player1Points, player2Points)
        if gameEnded then
            print("Game Over! " .. winner .. " wins! Reason: " .. reason)
            gameState = "gameOver"
            return
        end
        
        updateLocationPowers()
        
        if gamePhase == "staging" then
            -- AI staging during players turn
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

-- location powers with  check
function updateLocationPowers()
    for i, location in ipairs(locations) do
        local p1Power = 0
        for _, card in ipairs(location.player1Cards) do
            local cardPower = card.power or 0
            p1Power = p1Power + cardPower

            if cardPower == 0 and card.id then
                local originalCard = cardData.getCard(card.id)
                if originalCard and originalCard.power then
                    -- fail case
                    print("WARNING: Card " .. card.name .. " missing power, should be " .. originalCard.power)
                    card.power = originalCard.power
                    p1Power = p1Power + originalCard.power
                end
            end
        end
        location.player1Power = p1Power
        
        -- Player 2 power check
        local p2Power = 0
        for _, card in ipairs(location.player2Cards) do
            local cardPower = card.power or 0
            p2Power = p2Power + cardPower

            if cardPower == 0 and card.id then
                local originalCard = cardData.getCard(card.id)
                if originalCard and originalCard.power then
                    -- fail case
                    print("WARNING: Card " .. card.name .. " missing power, should be " .. originalCard.power)
                    card.power = originalCard.power
                    p2Power = p2Power + originalCard.power
                end
            end
        end
        location.player2Power = p2Power
    end
end

function handleRevealPhase(dt)
    if not revealPhase.isRevealing then
        return
    end
    
    revealPhase.timer = revealPhase.timer + dt
    
    if revealPhase.timer >= revealPhase.delay then
        -- next reveal step
        revealPhase.timer = 01
        
        if revealPhase.currentLocation <= #locations then
            local location = locations[revealPhase.currentLocation]
            print("Revealing " .. location.name)
            
            -- Trigger powers
            triggerRevealPowers(location, revealPhase.currentLocation)
            
            calculateAndAwardLocationPoints(location)
            
            revealPhase.currentLocation = revealPhase.currentLocation + 1
        else
            endRevealPhase()
        end
    end
end

-- Trigger powers for cards at location
function triggerRevealPowers(location, locationIndex)
    local gameStateData = {
        locations = locations,
        player1Hand = player1Hand,
        player2Hand = player2Hand,
        player1Deck = player1Deck,
        player2Deck = player2Deck,
        player1ManaBonus = player1ManaBonus,
        player2ManaBonus = player2ManaBonus
    }
    
    -- Trigger Player 1 cards
    for _, card in ipairs(location.player1Cards) do
        if cardPowers.hasSpecialAbility(card.id) then
            print("Triggering " .. card.name .. "'s power...")
            cardPowers.triggerPower(card.id, "on_reveal", gameStateData, 1, locationIndex, card)
        end
    end
    
    -- Then trigger Player 2 cards
    for _, card in ipairs(location.player2Cards) do
        if cardPowers.hasSpecialAbility(card.id) then
            print("Triggering " .. card.name .. "'s power...")
            cardPowers.triggerPower(card.id, "on_reveal", gameStateData, 2, locationIndex, card)
        end
    end
    
    -- Update mana bonuses
    player1ManaBonus = gameStateData.player1ManaBonus or 0
    player2ManaBonus = gameStateData.player2ManaBonus or 0
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

-- Calculate location power correctly
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
    
    -- Increase mana by 2 each turn, capped at 10, plus any bonuses
    player1Mana = math.min(player1Mana + 2 + player1ManaBonus, maxMana)
    player2Mana = math.min(player2Mana + 2 + player2ManaBonus, maxMana)
    
    if player1ManaBonus > 0 then
        print("Player 1 gained +" .. player1ManaBonus .. " bonus mana!")
    end
    if player2ManaBonus > 0 then
        print("Player 2 gained +" .. player2ManaBonus .. " bonus mana!")
    end
    
    -- Reset mana bonuses
    player1ManaBonus = 0
    player2ManaBonus = 0
    
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
    love.graphics.setBackgroundColor(0.08, 0.15, 0.08) 
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
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Loading GalaDeer...", 0, screenHeight / 2 - 12, screenWidth, "center")
end

function drawGameScreen()
    drawLocations()
    drawPlayerHand()
    drawEnemyHand()
    drawStagedCards()
    drawGameInfo()
    drawManaDisplay()
    drawCardTooltip()
    
    -- drop zone hints
    if grabber:isHolding() then
        drawDropZoneHints()
    end
end

function drawLocations()
    local totalWidth = screenWidth - 100
    local locationSpacing = totalWidth / 3

    for i, location in ipairs(locations) do
        local x = 50 + (i - 1) * locationSpacing
        local y = locationY

        -- location background
        love.graphics.setColor(0.25, 0.35, 0.25, 0.9)
        love.graphics.rectangle("fill", x, y, locationWidth, locationHeight)
        love.graphics.setColor(0.7, 0.8, 0.7)
        love.graphics.rectangle("line", x, y, locationWidth, locationHeight)

        -- Location name
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 1, 0.8)
        love.graphics.printf(location.name, x, y + 8, locationWidth, "center")

        -- Power display 
        love.graphics.setFont(love.graphics.newFont(16))
        local powerText = "P1: " .. location.player1Power .. " | P2: " .. location.player2Power

        if location.winner == 1 then
            love.graphics.setColor(0.3, 1, 0.3) 
            local pointsWon = location.player1Power - location.player2Power
            powerText = powerText .. " (P1 +" .. pointsWon .. "pts)"
        elseif location.winner == 2 then
            love.graphics.setColor(1, 0.3, 0.3) 
            local pointsWon = location.player2Power - location.player1Power
            powerText = powerText .. " (P2 +" .. pointsWon .. "pts)"
        elseif location.winner == "tie" then
            love.graphics.setColor(1, 1, 0.3) 
            powerText = powerText .. " (TIE)"
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
        end

        love.graphics.printf(powerText, x, y + 32, locationWidth, "center")

        -- Enemy area background (top)
        love.graphics.setColor(0.45, 0.25, 0.25, 0.4)
        love.graphics.rectangle("fill", x + 8, y + 55, locationWidth - 16, 130)
        love.graphics.setColor(0.7, 0.4, 0.4)
        love.graphics.rectangle("line", x + 8, y + 55, locationWidth - 16, 130)

        -- Draw enemy cards (top)
        drawLocationCards(location.player2Cards, x + 18, y + 60, true, i)

        -- divider
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(x + 15, y + 195, x + locationWidth - 15, y + 195)
        love.graphics.setLineWidth(1)

        -- Player area background (bottom)
        love.graphics.setColor(0.25, 0.45, 0.25, 0.4)
        love.graphics.rectangle("fill", x + 8, y + 200, locationWidth - 16, 115)
        love.graphics.setColor(0.4, 0.7, 0.4)
        love.graphics.rectangle("line", x + 8, y + 200, locationWidth - 16, 115)

        -- Draw player cards (bottom)
        drawLocationCards(location.player1Cards, x + 18, y + 205, false, i)
    end
end



function drawLocationCards(cards, startX, startY, isEnemy, locationIndex)
    local cardSpacing = 88
    local maxSlots = 4

    for slot = 1, maxSlots do
        local x = startX + (slot - 1) * cardSpacing
        local y = startY

        -- slot background
        love.graphics.setColor(0.15, 0.15, 0.15, 0.6)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight)

        -- slot number label
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("Slot " .. slot, x + 2, y + cardHeight/2 - 5, cardWidth - 4, "center")

        local card = cards[slot]
        if card then
            love.graphics.setColor(1, 1, 1)
            if isEnemy then
                if gamePhase == "reveal" or revealPhase.isRevealing then
                    -- reveal enemy card
                    drawCard(card, x, y, true)
                else
                    -- back of enemy card
                    love.graphics.setColor(0.6, 0.3, 0.3)
                    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
                    love.graphics.setColor(0.3, 0.1, 0.1)
                    love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
                    love.graphics.setColor(0.4, 0.2, 0.2)
                    love.graphics.setFont(love.graphics.newFont(10))
                    love.graphics.printf("CARD", x + 2, y + cardHeight/2 - 5, cardWidth - 4, "center")
                end
            else
                drawCard(card, x, y, true)
            end
        end
    end
end

function drawDropZoneHints()
    local heldCard = grabber:getHeldCard()
    if not heldCard then return end
    
    local totalWidth = screenWidth - 100
    local locationSpacing = totalWidth / 3
    
    -- Highlight valid drop zones
    for i, location in ipairs(locations) do
        if #location.player1Cards < 4 then -- Can only place if not full
            local x = 50 + (i - 1) * locationSpacing
            local y = locationY + 200
            
            love.graphics.setColor(0, 1, 0, 0.4)
            love.graphics.rectangle("fill", x + 8, y, locationWidth - 16, 115)
            love.graphics.setColor(0, 1, 0, 0.9)
            love.graphics.rectangle("line", x + 8, y, locationWidth - 16, 115)
            
            love.graphics.setFont(love.graphics.newFont(16))
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("DROP HERE", x, y + 50, locationWidth, "center")
        end
    end
    
    -- Hand return zone
    love.graphics.setColor(0, 0, 1, 0.3)
    love.graphics.rectangle("fill", 50, handY - 20, screenWidth - 100, 140)
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("line", 50, handY - 20, screenWidth - 100, 140)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("RETURN TO HAND", 0, handY + 40, screenWidth, "center")
end

function drawPlayerHand()
    love.graphics.setColor(1, 1, 1)
    local handSpacing = math.min(95, (screenWidth - 200) / math.max(#player1Hand, 1))
    local startX = (screenWidth - (handSpacing * (#player1Hand - 1) + cardWidth)) / 2
    
    for i, card in ipairs(player1Hand) do
        local x, y
        
        if card.isDragging and card.dragX and card.dragY then
            x = card.dragX
            y = card.dragY
        else
            x = startX + (i - 1) * handSpacing
            y = handY
        end
        
        drawCard(card, x, y, false)
    end
end

function drawEnemyHand()
    love.graphics.setColor(1, 1, 1)
    local handSpacing = math.min(95, (screenWidth - 200) / math.max(#player2Hand, 1))
    local startX = (screenWidth - (handSpacing * (#player2Hand - 1) + cardWidth)) / 2
    
    for i, card in ipairs(player2Hand) do
        local x = startX + (i - 1) * handSpacing
        local y = enemyHandY
        
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
    
    -- total staged mana cost
    local totalStagedCost = 0
    for _, stagedCard in ipairs(stagedCards) do
        totalStagedCost = totalStagedCost + (stagedCard.card.manaCost or 0)
    end
    
    love.graphics.printf("Staged: " .. #stagedCards .. " cards (Cost: " .. totalStagedCost .. ")", 50, 520, 400, "left")
    
    local spacing = 90
    local startX = 50
    
    for i, stagedCard in ipairs(stagedCards) do
        local x = startX + (i - 1) * spacing
        local y = 530
        
        if stagedCard.card.isDragging and stagedCard.card.dragX and stagedCard.card.dragY then
            x = stagedCard.card.dragX
            y = stagedCard.card.dragY
        end
        
        love.graphics.setColor(0.9, 0.9, 1)
        drawCard(stagedCard.card, x, y, false)
        
        -- Show target location
        love.graphics.setColor(1, 1, 0)
        love.graphics.setFont(love.graphics.newFont(10))
        local locationName = locations[stagedCard.locationIndex].name
        love.graphics.printf("→ " .. locationName, x, y - 15, cardWidth, "center")
    end
end

function drawCard(card, x, y, showPowers)
    if not card then return end

    local drawX = x
    local drawY = y
    local mouseX, mouseY = love.mouse.getPosition()
    local isHovered = mouseX >= drawX and mouseX <= drawX + cardWidth and 
                     mouseY >= drawY and mouseY <= drawY + cardHeight

    if card.isDragging and card.dragX and card.dragY and grabber:isHolding() and grabber:getHeldCard() == card then
        drawX = card.dragX
        drawY = card.dragY
    end
    
    -- hover effect
    if isHovered and not grabber:isHolding() then
        love.graphics.setColor(1, 1, 0.8) -- yellow tint on hover
        if hoverTimer >= hoverDelay then
            hoveredCard = card
        end
    else
        love.graphics.setColor(0.9, 0.9, 1)
    end
    
    love.graphics.rectangle("fill", drawX, drawY, cardWidth, cardHeight)
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("line", drawX, drawY, cardWidth, cardHeight)
    
    -- Special ability indicator
    if cardPowers.hasSpecialAbility(card.id) then
        love.graphics.setColor(1, 0.8, 0, 0.7)
        love.graphics.rectangle("fill", drawX + cardWidth - 12, drawY + 2, 10, 10)
        love.graphics.setColor(0.8, 0.6, 0)
        love.graphics.rectangle("line", drawX + cardWidth - 12, drawY + 2, 10, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(8))
        love.graphics.printf("!", drawX + cardWidth - 11, drawY + 3, 8, "center")
    end
    
    -- ffetch card image
    local cardImage = cardData.getCardImage(card.id)
    if cardImage then
        love.graphics.setColor(1, 1, 1)
        local scale = math.min(cardWidth / cardImage:getWidth(), (cardHeight - 35) / cardImage:getHeight())
        local imgX = drawX + (cardWidth - cardImage:getWidth() * scale) / 2
        local imgY = drawY + 8
        love.graphics.draw(cardImage, imgX, imgY, 0, scale, scale)
    else
        -- fail case
        love.graphics.setColor(0.7, 0.7, 0.9)
        love.graphics.rectangle("fill", drawX + 5, drawY + 8, cardWidth - 10, cardHeight - 40)
        love.graphics.setColor(0.3, 0.3, 0.5)
        love.graphics.rectangle("line", drawX + 5, drawY + 8, cardWidth - 10, cardHeight - 40)
    end
    
    -- Card info
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(8))
    love.graphics.printf(card.name or "Unknown", drawX + 2, drawY + cardHeight - 28, cardWidth - 4, "center")
    love.graphics.printf("M:" .. (card.manaCost or 0) .. " P:" .. (card.power or 0), drawX + 2, drawY + cardHeight - 15, cardWidth - 4, "center")
    
    if not isHovered then
        if hoveredCard == card then
            hoveredCard = nil
            hoverTimer = 0
        end
    end
end

function drawCardTooltip()
    if hoveredCard and hoverTimer >= hoverDelay and not grabber:isHolding() then
        local mouseX, mouseY = love.mouse.getPosition()
        local tooltipWidth = 250
        local tooltipHeight = 80
        local tooltipX = mouseX + 15
        local tooltipY = mouseY - tooltipHeight / 2
        
        if tooltipX + tooltipWidth > screenWidth then
            tooltipX = mouseX - tooltipWidth - 15
        end
        if tooltipY < 0 then
            tooltipY = 0
        elseif tooltipY + tooltipHeight > screenHeight then
            tooltipY = screenHeight - tooltipHeight
        end
        
        love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
        
        -- Card info
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(hoveredCard.name or "Unknown", tooltipX + 5, tooltipY + 5, tooltipWidth - 10, "left")
        
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf("Cost: " .. (hoveredCard.manaCost or 0) .. " | Power: " .. (hoveredCard.power or 0), 
                           tooltipX + 5, tooltipY + 22, tooltipWidth - 10, "left")
        
        -- Special ability
        local description = cardPowers.getCardDescription(hoveredCard.id)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(0.9, 0.9, 0.6)
        love.graphics.printf(description, tooltipX + 5, tooltipY + 40, tooltipWidth - 10, "left")
    end
end

function drawGameInfo()
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("GalaDeer - Turn " .. currentTurn, 0, 5, screenWidth, "center")
    
    -- Game phase and status
    local statusText = gamePhase
    if gamePhase == "staging" then
        if currentPlayer == 1 then
            statusText = "Your Turn - Stage Cards"
        else
            statusText = aiIsThinking and "AI Thinking..." or "AI Turn"
        end
    elseif gamePhase == "reveal" then
        statusText = "Revealing Cards & Triggering Powers..."
    end
    
    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(statusText, 0, 28, screenWidth, "center")
    
    -- Instructions (bottom of screen)
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf("Drag cards to locations (4 max). Hover for abilities. ENTER: Submit | SPACE: End turn | R: Restart | D: Debug", 0, screenHeight - 20, screenWidth, "center")
end

function drawManaDisplay()
    --available mana
    local stagedCost = 0
    for _, stagedCard in ipairs(stagedCards) do
        stagedCost = stagedCost + (stagedCard.card.manaCost or 0)
    end
    local availableMana = player1Mana - stagedCost
    
    -- Player Mana UI (bottom right)
    local playerUIWidth = 240
    local playerUIHeight = 130
    local playerUIX = screenWidth - playerUIWidth - 20
    local playerUIY = screenHeight - playerUIHeight - 20
    
    -- Player mana background
    love.graphics.setColor(0.15, 0.35, 0.65, 0.95)
    love.graphics.rectangle("fill", playerUIX, playerUIY, playerUIWidth, playerUIHeight)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.rectangle("line", playerUIX, playerUIY, playerUIWidth, playerUIHeight)
    
    -- Player mana text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("PLAYER", playerUIX + 10, playerUIY + 5, playerUIWidth - 20, "center")
    
    -- Show staged cost
    love.graphics.setFont(love.graphics.newFont(20))
    if stagedCost > 0 then
        love.graphics.setColor(availableMana >= 0 and 0.4 or 1, availableMana >= 0 and 1 or 0.4, 0.4)
        love.graphics.printf("Mana: " .. availableMana .. "/" .. player1Mana, playerUIX + 10, playerUIY + 25, playerUIWidth - 20, "center")
    else
        love.graphics.setColor(0.4, 1, 1)
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
    love.graphics.printf("Power played: " .. totalPowerPlayed, playerUIX + 10, playerUIY + 95, playerUIWidth - 20, "center")
    
    -- Mana bonus indicator
    if player1ManaBonus > 0 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Next turn: +" .. player1ManaBonus .. " mana", playerUIX + 10, playerUIY + 110, playerUIWidth - 20, "center")
    end
    
    -- AI UI (top right)
    local aiUIX = screenWidth - playerUIWidth - 20
    local aiUIY = 50
    
    -- AI mana background
    love.graphics.setColor(0.65, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", aiUIX, aiUIY, playerUIWidth, playerUIHeight)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("line", aiUIX, aiUIY, playerUIWidth, playerUIHeight)
    
    -- AI mana text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("AI OPPONENT", aiUIX + 10, aiUIY + 5, playerUIWidth - 20, "center")
    
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 0.4, 0.4)
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
    love.graphics.printf("Power played: " .. aiTotalPowerPlayed, aiUIX + 10, aiUIY + 95, playerUIWidth - 20, "center")
    
    -- AI Mana bonus indicator
    if player2ManaBonus > 0 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Next turn: +" .. player2ManaBonus .. " mana", aiUIX + 10, aiUIY + 110, playerUIWidth - 20, "center")
    end
    
    -- Turn indicator (center right)
    local turnUIWidth = 200
    local turnUIHeight = 50
    local turnUIX = screenWidth - turnUIWidth - 20
    local turnUIY = aiUIY + playerUIHeight + 15
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", turnUIX, turnUIY, turnUIWidth, turnUIHeight)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", turnUIX, turnUIY, turnUIWidth, turnUIHeight)
    
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("Turn " .. currentTurn, turnUIX + 10, turnUIY + 15, turnUIWidth - 20, "center")
    
    -- Cost preview when dragging
    if grabber:isHolding() then
        local heldCard = grabber:getHeldCard()
        if heldCard then
            local currentStagedCost = grabber:calculateStagedManaCost(stagedCards)
            local totalCostAfterPlay = currentStagedCost + heldCard.manaCost
            
            local costUIWidth = 220
            local costUIHeight = 90
            local costUIX = screenWidth - costUIWidth - 20
            local costUIY = screenHeight / 2 - costUIHeight / 2
            
            love.graphics.setColor(0.2, 0.2, 0.2, 0.98)
            love.graphics.rectangle("fill", costUIX, costUIY, costUIWidth, costUIHeight)
            love.graphics.setColor(totalCostAfterPlay > player1Mana and 1 or 0.8, totalCostAfterPlay > player1Mana and 0.3 or 0.8, 0.3)
            love.graphics.rectangle("line", costUIX, costUIY, costUIWidth, costUIHeight)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.printf("Cost Preview:", costUIX + 10, costUIY + 10, costUIWidth - 20, "center")
            love.graphics.setFont(love.graphics.newFont(18))
            love.graphics.setColor(totalCostAfterPlay > player1Mana and 1 or 0.4, totalCostAfterPlay > player1Mana and 0.4 or 1, 0.4)
            love.graphics.printf(totalCostAfterPlay .. " / " .. player1Mana, costUIX + 10, costUIY + 35, costUIWidth - 20, "center")
            
            -- Show if over budget
            if totalCostAfterPlay > player1Mana then
                love.graphics.setColor(1, 0.3, 0.3)
                love.graphics.setFont(love.graphics.newFont(12))
                love.graphics.printf("OVER BUDGET!", costUIX + 10, costUIY + 60, costUIWidth - 20, "center")
            else
                love.graphics.setColor(0.3, 1, 0.3)
                love.graphics.setFont(love.graphics.newFont(12))
                love.graphics.printf("Valid Play", costUIX + 10, costUIY + 60, costUIWidth - 20, "center")
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and gameState == "playing" and gamePhase == "staging" and currentPlayer == 1 then
        grabber:onMousePressed(x, y, player1Hand, stagedCards, cardWidth, cardHeight, handY)
        hoveredCard = nil
        hoverTimer = 0
    end
end

function love.mousemoved(x, y, dx, dy)
    hoverTimer = 0
end

function love.mousereleased(x, y, button)
    if button == 1 and gameState == "playing" and gamePhase == "staging" and currentPlayer == 1 then
        local locationDropped = checkLocationDrop(x, y)
        grabber:onMouseReleased(x, y, player1Hand, stagedCards, cardWidth, cardHeight, handY, currentPlayer, player1Mana, locations, locationDropped)
    end
end

function checkLocationDrop(x, y)
    local totalWidth = screenWidth - 100
    local locationSpacing = totalWidth / 3
    local playerAreaY = locationY + 200
    local playerAreaHeight = 115
    
    for i, location in ipairs(locations) do
        local locationX = 50 + (i - 1) * locationSpacing
        
        if x >= locationX + 8 and x <= locationX + locationWidth - 8 and
           y >= playerAreaY and y <= playerAreaY + playerAreaHeight then
            return i
        end
    end
    
    return nil
end

function love.keypressed(key)
    print("Key pressed: " .. key .. " | Game state: " .. gameState)
    
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        print("RESTARTING GAME...")
        initializeGame()
        print("Game restarted successfully! New state: " .. gameState)
    elseif gameState == "playing" then
        if key == "return" or key == "enter" then
            if gamePhase == "staging" and currentPlayer == 1 then
                submitPlayerCards()
            end
        elseif key == "space" then
            if gamePhase == "staging" and currentPlayer == 1 then
                -- Skip to AI
                currentPlayer = 2
            end
        elseif key == "d" then
            -- Debug: Print discard pile info for both
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
                        local powerDef = cardPowers.getPowerDefinition(card.id)
                        local abilityText = powerDef and powerDef.description or "No ability"
                        print("    " .. j .. ": " .. (card.name or "Unknown") .. " (Power: " .. (card.power or 0) .. ", ID: " .. (card.id or "None") .. ", Ability: " .. abilityText .. ")")
                    end
                end
                if #location.player2Cards > 0 then
                    print("  P2 Card Details:")
                    for j, card in ipairs(location.player2Cards) do
                        local powerDef = cardPowers.getPowerDefinition(card.id)
                        local abilityText = powerDef and powerDef.description or "No ability"
                        print("    " .. j .. ": " .. (card.name or "Unknown") .. " (Power: " .. (card.power or 0) .. ", ID: " .. (card.id or "None") .. ", Ability: " .. abilityText .. ")")
                    end
                end
            end
            
            print("\n=== DEBUG: Card Powers System ===")
            print("Player 1 next turn mana bonus: " .. player1ManaBonus)
            print("Player 2 next turn mana bonus: " .. player2ManaBonus)
            print("Current game state: " .. gameState)
            print("Current game phase: " .. gamePhase)
            print("Current player: " .. currentPlayer)
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
    
    print("Player1 Mana: " .. player1Mana .. ", Total Cost: " .. totalCost)
    
    local gameStateData = {
        locations = locations,
        player1Hand = player1Hand,
        player2Hand = player2Hand,
        player1Deck = player1Deck,
        player2Deck = player2Deck,
        player1ManaBonus = player1ManaBonus,
        player2ManaBonus = player2ManaBonus
    }
    
    -- Process each staged card
    for _, stagedCard in ipairs(stagedCards) do
        local location = locations[stagedCard.locationIndex]
        
        local originalCard = cardData.getCard(stagedCard.card.id)
        if not originalCard then
            print("ERROR: Could not find original card data for ID " .. tostring(stagedCard.card.id))
            return
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
        
        -- Remove from hand
        for i = #player1Hand, 1, -1 do
            if player1Hand[i].id == stagedCard.card.id then
                table.remove(player1Hand, i)
                break
            end
        end
        
        -- Add to location
        table.insert(location.player1Cards, cardToPlay)
        
        -- Trigger on play powers 
        if cardPowers.hasSpecialAbility(cardToPlay.id) then
            cardPowers.triggerPower(cardToPlay.id, "on_play", gameStateData, 1, stagedCard.locationIndex, cardToPlay)
        end
        
        -- Handle ongoing effects 
        cardPowers.handleStinkTrapEffect(gameStateData, stagedCard.locationIndex, cardToPlay)
        
        print("✓ SUCCESSFULLY played " .. cardToPlay.name .. " to " .. location.name .. " slot " .. #location.player1Cards .. " (Power: " .. cardToPlay.power .. ", Cost: " .. cardToPlay.manaCost .. ")")
        
        local newPower = calculateLocationPowerCorrectly(location.player1Cards)
        location.player1Power = newPower
        print("✓ Location " .. location.name .. " new P1 power: " .. newPower)
    end
    
    -- Update mana bonuses from game state
    player1ManaBonus = gameStateData.player1ManaBonus or 0
    player2ManaBonus = gameStateData.player2ManaBonus or 0
    
    -- Deduct mana
    player1Mana = player1Mana - totalCost
    print("Player1 Mana: " .. player1Mana .. " (deducted " .. totalCost .. ")")
    
    stagedCards = {}
    currentPlayer = 2
    print("Turn complete! AI's turn...")
end

function aiStageCards()
    print("AI staging cards...")
    print("AI starting mana: " .. player2Mana)
    
    local gameStateData = {
        locations = locations,
        player1Hand = player1Hand,
        player2Hand = player2Hand,
        player1Deck = player1Deck,
        player2Deck = player2Deck,
        player1ManaBonus = player1ManaBonus,
        player2ManaBonus = player2ManaBonus
    }
    
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
                
                -- Trigger powers
                if cardPowers.hasSpecialAbility(cardToPlay.id) then
                    cardPowers.triggerPower(cardToPlay.id, "on_play", gameStateData, 2, targetLocation, cardToPlay)
                end
                
                -- ongoing effects
                cardPowers.handleStinkTrapEffect(gameStateData, targetLocation, cardToPlay)
                
                -- Deduct mana
                player2Mana = player2Mana - cardToPlay.manaCost
                
                print("✓ AI played " .. cardToPlay.name .. " to " .. location.name .. " slot " .. #location.player2Cards .. " (Power: " .. cardToPlay.power .. ", Cost: " .. cardToPlay.manaCost .. ", Remaining mana: " .. player2Mana .. ")")
                
                local newPower = calculateLocationPowerCorrectly(location.player2Cards)
                location.player2Power = newPower
                print("✓ Location " .. location.name .. " new P2 power: " .. newPower)
            else
                break 
            end
        end
        
        attempts = attempts + 1
    end
    
    -- Update mana bonuses from AI 
    player1ManaBonus = gameStateData.player1ManaBonus or 0
    player2ManaBonus = gameStateData.player2ManaBonus or 0
    
    print("AI finished staging. Final mana: " .. player2Mana)
    startRevealPhase()
end

function startRevealPhase()
    gamePhase = "reveal"
    revealPhase.isRevealing = true
    revealPhase.timer = 0
    revealPhase.currentLocation = 1
    
    -- Who reveals first 
    revealPhase.playerFirst = love.math.random(1, 2)
    
    print("Reavling Phase...")
end

function drawGameOverScreen()
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over", 0, screenHeight / 2 - 100, screenWidth, "center")

    local resultText = ""
    if player1Points > player2Points then
        resultText = "You Win!"
        love.graphics.setColor(0.3, 1, 0.3)
    elseif player2Points > player1Points then
        resultText = "You Lose!"
        love.graphics.setColor(1, 0.3, 0.3)
    else
        resultText = "It's a Tie!"
        love.graphics.setColor(1, 1, 0.3)
    end

    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(resultText, 0, screenHeight / 2 - 40, screenWidth, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("P1 Points: " .. player1Points .. " | P2 Points: " .. player2Points,
        0, screenHeight / 2 + 10, screenWidth, "center")
    love.graphics.printf("Press R to Restart or Esc to Quit",
        0, screenHeight / 2 + 50, screenWidth, "center")
end