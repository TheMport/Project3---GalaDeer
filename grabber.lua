local Vector = require "Vector"

local GrabberClass = {}
GrabberClass.__index = GrabberClass

function GrabberClass:new()
    local grabber = setmetatable({}, GrabberClass)
    grabber.currentMousePos = Vector(0, 0)
    grabber.grabOffset = Vector(0, 0)
    grabber.heldCard = nil
    grabber.sourceType = nil  -- "hand", "staged", or "location"
    grabber.sourceIndex = nil -- index in hand, staged, or location
    grabber.sourceLocationIndex = nil -- which location if from location
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
    
    local screenWidth = love.graphics.getWidth()
    local handSpacing = math.min(95, (screenWidth - 200) / math.max(#playerHand, 1))
    local handStartX = (screenWidth - (handSpacing * (#playerHand - 1) + cardWidth)) / 2
    
    -- Check if clicking on a card in hand
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
            
            print("Grabbed card from hand: " .. card.name .. " (Power: " .. (card.power or 0) .. ", Cost: " .. (card.manaCost or 0) .. ")")
            
            -- Show card ability info when grabbing
            local cardPowers = require("cardPowers")
            if cardPowers.hasSpecialAbility(card.id) then
                local powerDef = cardPowers.getPowerDefinition(card.id)
                print("  Special Ability: " .. (powerDef.description or "Unknown"))
            end
            
            return true
        end
    end
    
    -- Check if clicking on a staged card
    local stagedStartX = 50
    local stagedSpacing = 90
    local stagedY = 530
    
    for i, stagedCard in ipairs(stagedCards) do
        local cardX = stagedStartX + (i - 1) * stagedSpacing
        local cardY = stagedY
        
        if x >= cardX and x <= cardX + cardWidth and 
           y >= cardY and y <= cardY + cardHeight then
            
            self.heldCard = stagedCard.card
            self.sourceType = "staged"
            self.sourceIndex = i
            self.originalX = cardX
            self.originalY = cardY
            self.grabOffset = Vector(x - cardX, y - cardY)
            
            stagedCard.card.dragX = cardX
            stagedCard.card.dragY = cardY
            stagedCard.card.isDragging = true
            
            print("Grabbed card from staged: " .. stagedCard.card.name .. " (Power: " .. (stagedCard.card.power or 0) .. ", Cost: " .. (stagedCard.card.manaCost or 0) .. ")")
            
            -- Show card ability info
            local cardPowers = require("cardPowers")
            if cardPowers.hasSpecialAbility(stagedCard.card.id) then
                local powerDef = cardPowers.getPowerDefinition(stagedCard.card.id)
                print("  Special Ability: " .. (powerDef.description or "Unknown"))
            end
            
            return true
        end
    end
    
    return false
end

function GrabberClass:onMouseReleased(x, y, playerHand, stagedCards, cardWidth, cardHeight, handY, currentPlayer, currentMana, locations, locationDropped)
    if not self.heldCard then return false end

    local card = self.heldCard
    local placed = false
    local cardPowers = require("cardPowers")

    if locationDropped then
        if currentPlayer == 1 then
            if self.sourceType == "hand" then
                local currentStagedCost = self:calculateStagedManaCost(stagedCards)
                local totalCostAfterStaging = currentStagedCost + card.manaCost

                if totalCostAfterStaging <= currentMana then
                    local location = locations[locationDropped]
                    if #location.player1Cards < 4 then
                        -- Remove card from hand
                        for i = #playerHand, 1, -1 do
                            if playerHand[i] == card then
                                table.remove(playerHand, i)
                                break
                            end
                        end
                        
                        local stagedCard = {
                            id = card.id,
                            name = card.name,
                            type = card.type,
                            description = card.description,
                            imagePath = card.imagePath,
                            manaCost = card.manaCost,
                            power = card.power or 0
                        }

                        table.insert(stagedCards, {
                            card = stagedCard,
                            locationIndex = locationDropped
                        })
                        placed = true

                        -- ability preview
                        if cardPowers.hasSpecialAbility(card.id) then
                            local powerDef = cardPowers.getPowerDefinition(card.id)
                            print("  Will trigger: " .. (powerDef.description or "Unknown ability"))
                        end
                    else
                        print("Location " .. locations[locationDropped].name .. " is full!")
                    end
                else
                    print("Cannot stage " .. card.name .. " - would exceed mana limit (" .. totalCostAfterStaging .. " > " .. currentMana .. ")")
                end
            elseif self.sourceType == "staged" then
                local stagedCard = stagedCards[self.sourceIndex]
                local location = locations[locationDropped]
                if #location.player1Cards < 4 then
                    local oldLocation = locations[stagedCard.locationIndex]
                    stagedCard.locationIndex = locationDropped
                    placed = true
                    print("Moved " .. card.name .. " from " .. oldLocation.name .. " to " .. location.name .. " (Power: " .. (stagedCard.card.power or 0) .. ")")
                    
                    if cardPowers.hasSpecialAbility(card.id) then
                        local powerDef = cardPowers.getPowerDefinition(card.id)
                        print("  Will trigger at " .. location.name .. ": " .. (powerDef.description or "Unknown ability"))
                    end
                else
                    print("Location " .. locations[locationDropped].name .. " is full!")
                end
            end
        else
            print("It's not your turn!")
        end
    end

    -- Check if dropping back to hand
    if not placed and y >= handY - 50 and y <= handY + cardHeight + 50 and 
       x >= 50 and x <= love.graphics.getWidth() - 50 then
        if self.sourceType == "staged" then
            local stagedCardData = stagedCards[self.sourceIndex]
            table.remove(stagedCards, self.sourceIndex)
            local cardToReturn = stagedCardData.card
            
            cardToReturn.dragX = nil
            cardToReturn.dragY = nil
            cardToReturn.isDragging = nil
            
            table.insert(playerHand, cardToReturn)
            placed = true
        elseif self.sourceType == "hand" then
            placed = true
            print("Card " .. card.name .. " returned to original hand position")
        end
    end

    -- Return to original position if not placed
    if not placed then
        self:returnToOriginalPosition(playerHand, stagedCards)
    end

    if card then
        card.isDragging = nil
        card.dragX = nil
        card.dragY = nil
    end

    -- Reset grabber
    self.heldCard = nil
    self.sourceType = nil
    self.sourceIndex = nil
    self.sourceLocationIndex = nil
    self.originalX = 0
    self.originalY = 0

    return placed
end

function GrabberClass:returnToOriginalPosition(playerHand, stagedCards)
    local card = self.heldCard
    
    if self.sourceType == "hand" then
        -- Ensure card is back in hand at correct position
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
            
            card.dragX = nil
            card.dragY = nil
            card.isDragging = nil
        end
        
    elseif self.sourceType == "staged" then
        -- Ensure card is back in staged cards
        local found = false
        for i, stagedCard in ipairs(stagedCards) do
            if stagedCard.card == card then
                found = true
                break
            end
        end
        if not found then
            local cleanCard = {
                id = card.id,
                name = card.name,
                type = card.type,
                description = card.description,
                imagePath = card.imagePath,
                manaCost = card.manaCost,
                power = card.power or 0
            }
            
            table.insert(stagedCards, {
                card = cleanCard,
                locationIndex = 1 -- Default to first location
            })
        end
        
        card.dragX = nil
        card.dragY = nil
        card.isDragging = nil
        

    end
end

function GrabberClass:isHolding()
    return self.heldCard ~= nil
end

function GrabberClass:getHeldCard()
    return self.heldCard
end

-- total mana cost of staged cards 
function GrabberClass:calculateStagedManaCost(stagedCards)
    local totalCost = 0
    for i, stagedCard in ipairs(stagedCards) do
        totalCost = totalCost + (stagedCard.card.manaCost or 0)
    end
    return totalCost
end

function GrabberClass:getCardsForLocation(stagedCards, locationIndex)
    local cards = {}
    for i, stagedCard in ipairs(stagedCards) do
        if stagedCard.locationIndex == locationIndex then
            table.insert(cards, stagedCard.card)
        end
    end
    return cards
end

-- Count cards staged for a specific location
function GrabberClass:countCardsForLocation(stagedCards, locationIndex)
    local count = 0
    for i, stagedCard in ipairs(stagedCards) do
        if stagedCard.locationIndex == locationIndex then
            count = count + 1
        end
    end
    return count
end

-- validation with card powers
function GrabberClass:validateStagedCards(stagedCards, locations, currentMana)
    local totalCost = self:calculateStagedManaCost(stagedCards)
    
    if totalCost > currentMana then
        return false, "Total mana cost (" .. totalCost .. ") exceeds available mana (" .. currentMana .. ")"
    end
    
    -- Check location capacity 
    local locationCounts = {}
    for i, stagedCard in ipairs(stagedCards) do
        local locationIndex = stagedCard.locationIndex
        locationCounts[locationIndex] = (locationCounts[locationIndex] or 0) + 1
        
        local location = locations[locationIndex]
        local totalCards = #location.player1Cards + locationCounts[locationIndex]
        
        if totalCards > 4 then -- MAX_CARDS_PER_LOCATION
            return false, "Too many cards for location " .. location.name .. " (" .. totalCards .. "/4)"
        end
    end
    
    local cardPowers = require("cardPowers")
    local synergies = {}
    for i, stagedCard in ipairs(stagedCards) do
        if cardPowers.hasSpecialAbility(stagedCard.card.id) then
            local powerDef = cardPowers.getPowerDefinition(stagedCard.card.id)
            local locationName = locations[stagedCard.locationIndex].name
            table.insert(synergies, stagedCard.card.name .. " will trigger at " .. locationName .. ": " .. (powerDef.description or "Unknown"))
        end
    end
    
    local validationMessage = "All staged cards are valid"
    if #synergies > 0 then
        validationMessage = validationMessage .. "\nSpecial abilities will trigger:\n" .. table.concat(synergies, "\n")
    end
    
    return true, validationMessage
end

function GrabberClass:clearStagedCards(stagedCards, playerHand)
    for i, stagedCard in ipairs(stagedCards) do
        local cardToReturn = stagedCard.card

        cardToReturn.dragX = nil
        cardToReturn.dragY = nil
        cardToReturn.isDragging = nil
        
        table.insert(playerHand, cardToReturn)
    end
    
    for i = #stagedCards, 1, -1 do
        stagedCards[i] = nil
    end
    
    print("Cleared all staged cards and returned to hand")
end

-- Get preview of what abilities will trigger this turn
function GrabberClass:previewAbilities(stagedCards, locations)
    local cardPowers = require("cardPowers")
    local previews = {}
    
    for i, stagedCard in ipairs(stagedCards) do
        if cardPowers.hasSpecialAbility(stagedCard.card.id) then
            local powerDef = cardPowers.getPowerDefinition(stagedCard.card.id)
            local location = locations[stagedCard.locationIndex]
            
            local preview = {
                cardName = stagedCard.card.name,
                locationName = location.name,
                abilityType = powerDef.type,
                description = powerDef.description,
                timing = powerDef.type == "on_reveal" and "When revealed" or 
                        powerDef.type == "on_play" and "When played" or 
                        powerDef.type == "ongoing" and "Ongoing effect" or "Unknown timing"
            }
            table.insert(previews, preview)
        end
    end
    
    return previews
end

return GrabberClass