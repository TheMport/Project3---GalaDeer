local Vector = require "Vector"

local GrabberClass = {}
GrabberClass.__index = GrabberClass

function GrabberClass:new()
    local grabber = setmetatable({}, GrabberClass)
    grabber.currentMousePos = Vector(0, 0)
    grabber.grabOffset = Vector(0, 0)
    grabber.heldCard = nil
    grabber.sourceType = nil  -- "hand" or "field"
    grabber.sourceIndex = nil -- index in hand or field
    grabber.originalX = 0     -- store original position
    grabber.originalY = 0
    return grabber
end

function GrabberClass:update(dt)
    self.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())
    
    -- Update position of held card
    if self.heldCard then
        self.heldCard.dragX = self.currentMousePos.x - self.grabOffset.x
        self.heldCard.dragY = self.currentMousePos.y - self.grabOffset.y
    end
end

function GrabberClass:onMousePressed(x, y, playerHand, stagedCards, cardWidth, cardHeight, handY)
    self.currentMousePos = Vector(x, y)
    
    -- Check if clicking on a card in hand
    local handStartX = 100
    local handSpacing = 120
    
    for i, card in ipairs(playerHand) do
        local cardX = handStartX + (i - 1) * handSpacing
        local cardY = handY
        
        if x >= cardX and x <= cardX + cardWidth and 
           y >= cardY and y <= cardY + cardHeight then
            
            self.heldCard = card
            self.sourceType = "hand"
            self.sourceIndex = i
            self.originalX = cardX
            self.originalY = cardY
            self.grabOffset = Vector(x - cardX, y - cardY)
            
            -- Initialize drag position
            card.dragX = cardX
            card.dragY = cardY
            card.isDragging = true
            
            print("Grabbed card from hand: " .. card.name)
            return true
        end
    end
    
    -- Check if clicking on a staged card
    local fieldStartX = 100
    local fieldSpacing = 120
    local fieldY = 350 -- Playing field Y position
    
    for i, card in ipairs(stagedCards) do
        local cardX = fieldStartX + (i - 1) * fieldSpacing
        local cardY = fieldY
        
        if x >= cardX and x <= cardX + cardWidth and 
           y >= cardY and y <= cardY + cardHeight then
            
            self.heldCard = card
            self.sourceType = "field"
            self.sourceIndex = i
            self.originalX = cardX
            self.originalY = cardY
            self.grabOffset = Vector(x - cardX, y - cardY)
            
            -- Initialize drag position
            card.dragX = cardX
            card.dragY = cardY
            card.isDragging = true
            
            print("Grabbed card from field: " .. card.name)
            return true
        end
    end
    
    return false
end

function GrabberClass:onMouseReleased(x, y, playerHand, stagedCards, cardWidth, cardHeight, handY, currentPlayer, currentMana)
    if not self.heldCard then return false end
    
    local card = self.heldCard
    local placed = false
    
    -- drop zones
    local handStartX = 100
    local handSpacing = 120
    local fieldY = 350
    local fieldStartX = 100
    local fieldSpacing = 120
    
    -- checking placement on field
    if y >= fieldY - 50 and y <= fieldY + cardHeight + 50 and
       x >= fieldStartX and x <= fieldStartX + 6 * fieldSpacing then -- Allow 6 cards max on field
        

        if currentPlayer == 1 then
            if self.sourceType == "hand" then
                -- Check mana cost 
                if card.manaCost <= currentMana then
                    -- Remove from hand
                    for i = #playerHand, 1, -1 do
                        if playerHand[i] == card then
                            table.remove(playerHand, i)
                            break
                        end
                    end
                    

                    table.insert(stagedCards, card)
                    placed = true
                    print("Staged card for play: " .. card.name)
                else
                    print("Not enough mana to play " .. card.name .. " (Cost: " .. card.manaCost .. ", Available: " .. currentMana .. ")")
                end
            elseif self.sourceType == "field" then
                -- Moving within field - just update position
                placed = true
                print("Repositioned card on field: " .. card.name)
            end
        else
            print("It's not your turn!")
        end
    end
    
    -- check if removing it back to hand
    if not placed and y >= handY - 50 and y <= handY + cardHeight + 50 and
       x >= handStartX and x <= handStartX + 10 * handSpacing then -- Allow space for hand
        
        if self.sourceType == "field" then
            -- Remove from staged cards
            for i = #stagedCards, 1, -1 do
                if stagedCards[i] == card then
                    table.remove(stagedCards, i)
                    break
                end
            end
            
            -- Add back to hand
            table.insert(playerHand, card)
            placed = true
            print("Returned card to hand: " .. card.name)
        elseif self.sourceType == "hand" then
            -- Already in hand, just repositioning
            placed = true
        end
    end
    
    -- checking if its a valid placement
    if not placed then
        self:returnToOriginalPosition(playerHand, stagedCards)
    end
    
    -- Clean up drag state
    card.isDragging = false
    card.dragX = nil
    card.dragY = nil
    
    -- Reset grabber
    self.heldCard = nil
    self.sourceType = nil
    self.sourceIndex = nil
    self.originalX = 0
    self.originalY = 0
    
    return placed
end

function GrabberClass:returnToOriginalPosition(playerHand, stagedCards)
    local card = self.heldCard
    
    if self.sourceType == "hand" then
        -- check card is in hand at correct position
        local found = false
        for i, handCard in ipairs(playerHand) do
            if handCard == card then
                found = true
                break
            end
        end
        if not found then

            if self.sourceIndex <= #playerHand + 1 then
                table.insert(playerHand, self.sourceIndex, card)
            else
                table.insert(playerHand, card)
            end
        end
        print("Returned " .. card.name .. " to hand")
        
    elseif self.sourceType == "field" then

        local found = false
        for i, stagedCard in ipairs(stagedCards) do
            if stagedCard == card then
                found = true
                break
            end
        end
        if not found then
            table.insert(stagedCards, card)
        end
        print("Returned " .. card.name .. " to field")
    end
end

function GrabberClass:isHolding()
    return self.heldCard ~= nil
end

function GrabberClass:getHeldCard()
    return self.heldCard
end

    -- calculates total mana cost of staged cards
function GrabberClass:calculateStagedManaCost(stagedCards)
    local totalCost = 0
    for i, card in ipairs(stagedCards) do
        totalCost = totalCost + (card.manaCost or 0)
    end
    return totalCost
end

return GrabberClass