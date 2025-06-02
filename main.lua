

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
local player1Mana = 5
local player2Mana = 5
local maxMana = 10
local currentTurn = 1 -- Track turns
local currentPlayer = 1 -- 1 for player, 2 for AI

local grabber = nil
local N = 15 -- Points needed to win (between 10-25)
local player1Points = 0
local player2Points = 0
local locations = {
    {name = "Left", 
     player1Cards = {}, player1Power = 0,
     player2Cards = {}, player2Power = 0},
    {name = "Middle", 
     player1Cards = {}, player1Power = 0,
     player2Cards = {}, player2Power = 0},
    {name = "Right", 
     player1Cards = {}, player1Power = 0,
     player2Cards = {}, player2Power = 0}
}
local stagedCards = {} -- Cards staged for play this turn
local revealedCards = {} -- Cards that have been revealed
local gamePhase = "setup" -- setup, staging, reveal, scoring


-- Card image details
local cardWidth = 100
local cardHeight = 140
local handY = 600
local enemyHandY = 50

function love.load()

    -- game title and window settings (adjustable)
    love.window.setMode(1280, 720)
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

function initializeGame()
    print("Initializing game with official rules...")
    
    -- Deck creation (20 cards, max 2 copies of a card allowed)
    player1Deck = gameRules.createValidDeck(cardData)
    player2Deck = gameRules.createValidDeck(cardData)
    
    -- deck check
    local p1Valid, p1Errors = gameRules.validateDeck(player1Deck)
    local p2Valid, p2Errors = gameRules.validateDeck(player2Deck)
    
    if not p1Valid then
        print("Player 1 deck validation failed:")
        for i, error in ipairs(p1Errors) do
            print("  " .. error)
        end
    end
    
    if not p2Valid then
        print("Player 2 deck validation failed:")
        for i, error in ipairs(p2Errors) do
            print("  " .. error)
        end
    end
    
    -- Deal starting hands (3 cards each)
    player1Hand, player2Hand = gameRules.dealStartingHands(player1Deck, player2Deck)
    
    -- Reset turn counter
    currentTurn = 1
    currentPlayer = 1
    
    -- Draw initial cards for turn 1
    gameRules.drawCardsForTurn(player1Deck, player1Hand, "Player 1")
    gameRules.drawCardsForTurn(player2Deck, player2Hand, "Player 2")
    
    print("Game initialized with official rules:")
    print("- Player 1: " .. #player1Hand .. " cards in hand, " .. #player1Deck .. " in deck")
    print("- Player 2: " .. #player2Hand .. " cards in hand, " .. #player2Deck .. " in deck")
    print("- Turn " .. currentTurn .. " begins")
    
    -- Print deck compositions (debugger tool)
    gameRules.printDeckComposition(player1Deck, "Player 1 Deck")
    gameRules.printDeckComposition(player2Deck, "Player 2 Deck")
end

function love.update(dt)
    if gameState == "playing" then
        -- end condition checker 
        grabber:update(dt)
        local gameEnded, winner, reason = gameRules.checkGameEnd(player1Deck, player1Hand, player2Deck, player2Hand)
        if gameEnded then
            print("Game Over! " .. winner .. " wins! Reason: " .. reason)
            gameState = "gameOver"
        end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.1, 0.3, 0.1) -- Dark green background
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    
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
    love.graphics.printf("Loading Fantasy Card Game...", 0, 350, 1280, "center")
end

    -- game visual display func
function drawGameScreen()

    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.rectangle("fill", 0, 200, 1280, 320) -- Game field
    
    drawManaDisplay()
    drawPlayerHand()
    drawEnemyHand()
    drawStagedCards() -- Add this line
    drawDeckInfo()
    drawGameInfo()
    
    -- Draw drop zones hints
    drawDropZoneHints()
end

function drawDropZoneHints()
    if grabber:isHolding() then
        -- Draw field drop zone
        love.graphics.setColor(0, 1, 0, 0.3) -- Green transparent
        love.graphics.rectangle("fill", 100, 300, 720, 140)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", 100, 300, 720, 140)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf("DROP HERE TO STAGE CARD", 100, 360, 720, "center")
        
        -- Draw hand drop zone
        love.graphics.setColor(0, 0, 1, 0.3) -- Blue transparent
        love.graphics.rectangle("fill", 100, handY - 20, 800, 180)
        love.graphics.setColor(0, 0, 1)
        love.graphics.rectangle("line", 100, handY - 20, 800, 180)
        love.graphics.printf("DROP HERE TO RETURN TO HAND", 100, handY + 50, 800, "center")
    end
end

function playAllStagedCards()
    if currentPlayer ~= 1 then
        print("It's not your turn!")
        return false
    end
    
    -- Check total mana cost
    local totalCost = grabber:calculateStagedManaCost(stagedCards)
    
    if totalCost > player1Mana then
        print("Not enough mana! Need " .. totalCost .. ", have " .. player1Mana)
        return false
    end
    
    -- Play all staged cards
    for i, card in ipairs(stagedCards) do
        print("Playing card: " .. card.name)
        -- Deduct mana cost
        player1Mana = player1Mana - card.manaCost
    end
    
    -- Clear staged cards
    stagedCards = {}
    
    print("All staged cards played! Remaining mana: " .. player1Mana)
    return true
end

function drawManaDisplay()
    love.graphics.setColor(0.2, 0.4, 1) -- Blue for mana
    love.graphics.setFont(love.graphics.newFont(16))
    
    -- Player mana
    love.graphics.printf("Player Mana: " .. player1Mana .. "/" .. maxMana, 50, 550, 200, "left")

    -- Enemy mana
    love.graphics.printf("Enemy Mana: " .. player2Mana .. "/" .. maxMana, 50, 100, 200, "left")
end

function drawPlayerHand()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    
    local startX = 100
    local spacing = 120
    
    for i, card in ipairs(player1Hand) do
        local x, y
        
        -- Use drag position if card is being dragged
        if card.isDragging and card.dragX and card.dragY then
            x = card.dragX
            y = card.dragY
        else
            x = startX + (i - 1) * spacing
            y = handY
        end
        
        -- Draw card
        drawCard(card, x, y)
    end
end

function drawStagedCards()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    
    local startX = 100
    local spacing = 120
    local fieldY = 350
    
    for i, card in ipairs(stagedCards) do
        local x, y
        
        -- Use drag position if card is being dragged
        if card.isDragging and card.dragX and card.dragY then
            x = card.dragX
            y = card.dragY
        else
            x = startX + (i - 1) * spacing
            y = fieldY
        end
        
        -- Draw card with slight highlight to show it's staged
        love.graphics.setColor(0.9, 0.9, 1) -- Slight blue tint
        drawCard(card, x, y)
        
        -- Draw "STAGED" indicator
        love.graphics.setColor(0, 0.8, 0)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("STAGED", x, y - 15, cardWidth, "center")
    end
end

function drawEnemyHand()
    love.graphics.setColor(1, 1, 1)
    
    local startX = 100
    local spacing = 120
    
    for i, card in ipairs(player2Hand) do
        local x = startX + (i - 1) * spacing
        local y = enemyHandY
        
        -- Draw card back for enemy hand
        love.graphics.setColor(0.6, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
        love.graphics.setColor(0.3, 0.1, 0.1)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
        

        local cardBackImage = cardData.getCardBackImage()
        if cardBackImage then
            love.graphics.setColor(1, 1, 1)
            local scale = math.min(cardWidth / cardBackImage:getWidth(), cardHeight / cardBackImage:getHeight())
            local imgX = x + (cardWidth - cardBackImage:getWidth() * scale) / 2
            local imgY = y + (cardHeight - cardBackImage:getHeight() * scale) / 2
            love.graphics.draw(cardBackImage, imgX, imgY, 0, scale, scale)
        end
    end
end

function drawCard(card, x, y)
    -- Card background
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("line", x, y, cardWidth, cardHeight)
    
    -- Card image
    local cardImage = cardData.getCardImage(card.id)
    if cardImage then
        love.graphics.setColor(1, 1, 1)
        local scale = math.min(cardWidth / cardImage:getWidth(), (cardHeight - 40) / cardImage:getHeight())
        local imgX = x + (cardWidth - cardImage:getWidth() * scale) / 2
        local imgY = y + 5
        love.graphics.draw(cardImage, imgX, imgY, 0, scale, scale)
    end
    
    -- Card info
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf(card.name, x + 2, y + cardHeight - 35, cardWidth - 4, "center")
    love.graphics.printf("Mana: " .. card.manaCost, x + 2, y + cardHeight - 20, cardWidth - 4, "center")
end

function drawDeckInfo()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    
    -- cards in deck left
    love.graphics.printf("Deck: " .. #player1Deck, 950, 600, 100, "left")
    
    -- cards in deck left of ai
    love.graphics.printf("Enemy Deck: " .. #player2Deck, 950, 50, 100, "left")
end

function drawGameInfo()
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Fantasy Card Game - Turn " .. currentTurn, 0, 10, 1280, "center")
    
    -- current player turn visual
    local turnText = currentPlayer == 1 and "Your Turn" or "AI Turn"
    love.graphics.setColor(currentPlayer == 1 and {0.2, 1, 0.2} or {1, 0.2, 0.2})
    love.graphics.printf(turnText, 0, 30, 1280, "center")
    
    -- Show staged cards count and cost
    if #stagedCards > 0 then
        local totalCost = grabber:calculateStagedManaCost(stagedCards)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Staged: " .. #stagedCards .. " cards (Cost: " .. totalCost .. ")", 0, 50, 1280, "center")
    end
    
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.8, 0.8, 0.8)
    local rulesText = "Drag cards to field to stage them. ENTER: Play staged cards"
    love.graphics.printf(rulesText, 0, 680, 1280, "center")
    love.graphics.printf("SPACE: End Turn | R: Restart | ESC: Quit", 0, 695, 1280, "center")
end

-- mouse handling 
-- will likely change this to use my grabber from solitaire project


function love.mousepressed(x, y, button)
    if button == 1 and gameState == "playing" then
        -- Let grabber handle mouse press first
        local handled = grabber:onMousePressed(x, y, player1Hand, stagedCards, cardWidth, cardHeight, handY)
        
        if not handled then
    if button == 1 and gameState == "playing" then 

        local startX = 100
        local spacing = 120
        
        for i, card in ipairs(player1Hand) do
            local cardX = startX + (i - 1) * spacing
            local cardY = handY
            
            if x >= cardX and x <= cardX + cardWidth and 
               y >= cardY and y <= cardY + cardHeight then
                playCard(i)
                break
            end
        end
    end
        end
    end
end

-- Add this new function for mouse release
function love.mousereleased(x, y, button)
    if button == 1 and gameState == "playing" then
        grabber:onMouseReleased(x, y, player1Hand, stagedCards, cardWidth, cardHeight, handY, currentPlayer, player1Mana)
    end
end

function playCard(handIndex)
    if currentPlayer ~= 1 then
        print("It's not your turn!")
        return
    end
    
    local card = player1Hand[handIndex]
    if card then
        local canPlay, reason = gameRules.canPlayCard(player1Hand, handIndex, player1Mana, card)
        
        if canPlay then
            print("Playing card: " .. card.name)
            -- remove card from hand
            table.remove(player1Hand, handIndex)
            -- Mana managment 
            -- player1Mana = player1Mana - card.manaCost
            
            print("Card played successfully. Hand size: " .. #player1Hand)
        else
            print("Cannot play card: " .. reason)
        end
    end
end

-- Key master
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" and gameState == "playing" then
        -- Restart game
        initializeGame()
    elseif key == "space" and gameState == "playing" then
        -- End turn
        endTurn()
    elseif key == "return" or key == "enter" then
        -- Submit/play staged cards
        if #stagedCards > 0 then
            local success = playAllStagedCards()
            if success then
                print("Cards played successfully!")
            end
        else
            print("No cards staged to play!")
        end
    end
end


function endTurn()
    print("\n=== Ending Turn " .. currentTurn .. " ===")
    
    -- Switch players
    if currentPlayer == 1 then
        currentPlayer = 2
        print("AI's turn begins")
        -- AI will play automatically after a short delay
        love.timer.sleep(0.5) -- pause for effect
        aiTurn()
    else
        currentPlayer = 1
        currentTurn = currentTurn + 1
        print("Player's turn " .. currentTurn .. " begins")
        
        -- Draw cards for every new turn
        gameRules.drawCardsForTurn(player1Deck, player1Hand, "Player 1")
        gameRules.drawCardsForTurn(player2Deck, player2Hand, "Player 2")
        
        -- hand size limits
        gameRules.enforceHandSizeLimit(player1Hand, "Player 1")
        gameRules.enforceHandSizeLimit(player2Hand, "Player 2")
    end
    
    print("=== Turn transition complete ===\n")
end

function aiTurn()
    print("AI turn processing...")
    
    -- ai plays a random card if possible
    if #player2Hand > 0 then
        local attempts = 0
        local maxAttempts = #player2Hand
        
        while attempts < maxAttempts do
            local randomIndex = love.math.random(1, #player2Hand)
            local card = player2Hand[randomIndex]
            
            local canPlay, reason = gameRules.canPlayCard(player2Hand, randomIndex, player2Mana, card)
            
            if canPlay then
                print("AI playing: " .. card.name)
                table.remove(player2Hand, randomIndex)
                -- mana management
                -- player2Mana = player2Mana - card.manaCost
                break
            else
                print("AI cannot play " .. card.name .. ": " .. reason)
                attempts = attempts + 1
            end
        end
        
        if attempts >= maxAttempts then
            print("AI cannot play any cards this turn")
        end
    else
        print("AI has no cards to play")
    end
    
    -- End AI turn and return to player
    love.timer.sleep(1) -- delay to see AI action
    endTurn()
end

-- Game Over screen
function drawGameOverScreen()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("GAME OVER", 0, 250, 1280, "center")
    
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Press R to play again", 0, 350, 1280, "center")
    love.graphics.printf("Press ESC to quit", 0, 400, 1280, "center")
end