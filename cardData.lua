

local json = require("dkjson")

-- tables !!!
local cardData = {}

cardData.images = {}
cardData.definitions = {}
cardData.cardBackImage = ""

-- card data from JSON
function LoadCardData()

    local content, err = love.filesystem.read("cardDataInfo.json")

    local cardDataInfo, pos, jsonErr = json.decode(content)
    
    return cardDataInfo
end


local function initializeCardData()
    print("Initializing card data...")
    
    local gameData = LoadCardData()
    cardData.definitions = gameData.definitions
    cardData.cardBackImage = gameData.cardBackImage
    
    print("Loaded " .. #cardData.definitions .. " card definitions")
    print("Card back image path: " .. cardData.cardBackImage)
    
    return cardData
end

if love and love.filesystem then
    initializeCardData()
else
    print("card data not loaded")
end

-- Preload all images
function cardData.loadImages()
    print("Loading card images...")
    
    -- back of card 
local success, cardBack = pcall(love.graphics.newImage, cardData.cardBackImage)
if success then
    cardData.images.cardBack = cardBack 
    print("Card back loaded successfully: " .. cardData.cardBackImage)
else
    print("Failed to load card back: " .. cardData.cardBackImage)
end
    
    -- Load all card images
    local loadedCount = 0
    local failedCount = 0
    
    for i, card in ipairs(cardData.definitions) do
        local success, image = pcall(love.graphics.newImage, card.imagePath)
        if success then
            cardData.images[card.id] = image
            loadedCount = loadedCount + 1
        else
            print("Failed to load: " .. card.name .. " (" .. card.imagePath .. ")")
            failedCount = failedCount + 1
        end
    end
    
    print("Card loading complete: " .. loadedCount .. " loaded, " .. failedCount .. " failed")
end

-- fetch card by ID
function cardData.getCard(id)
    for i, card in ipairs(cardData.definitions) do
        if card.id == id then
            return card
        end
    end
    return nil
end

-- Get card image by ID
function cardData.getCardImage(id)
    return cardData.images[id]
end

-- Get card back image
function cardData.getCardBackImage()
    return cardData.images.cardBack
end

-- Get cards by type
function cardData.getCardsByType(cardType)
    local result = {}
    for i, card in ipairs(cardData.definitions) do
        if card.type == cardType then
            table.insert(result, card)
        end
    end
    return result
end

-- RNG card selection for player decks
function cardData.getRandomCards(count)
    local result = {}
    local availableCards = {}
    
    -- Create copies of all cards
    for i, card in ipairs(cardData.definitions) do
        table.insert(availableCards, card)
    end

    for i = 1, math.min(count, #availableCards) do
        local randomIndex = love.math.random(1, #availableCards)
        table.insert(result, availableCards[randomIndex])
        table.remove(availableCards, randomIndex)
    end
    
    return result
end

-- Mana cost manager
function cardData.setManaCosts(manaCostTable)
    for id, cost in pairs(manaCostTable) do
        local card = cardData.getCard(id)
        if card then
            card.manaCost = cost
            print("Set mana cost for " .. card.name .. ": " .. cost)
        end
    end
end

-- Card data with powers
function cardData.getCardsWithAbilities()
    local result = {}
    local cardPowers = require("cardPowers")
    
    for i, card in ipairs(cardData.definitions) do
        if cardPowers.hasSpecialAbility(card.id) then
            table.insert(result, card)
        end
    end
    
    return result
end

-- Card stats
function cardData.getCardStats()
    local stats = {
        totalCards = #cardData.definitions,
        averageManaCost = 0,
        averagePower = 0,
        manaCostDistribution = {},
        powerDistribution = {},
        typeDistribution = {},
        cardsWithAbilities = 0
    }
    
    local totalManaCost = 0
    local totalPower = 0
    local cardPowers = require("cardPowers")
    
    for i, card in ipairs(cardData.definitions) do

        totalManaCost = totalManaCost + (card.manaCost or 0)
        totalPower = totalPower + (card.power or 0)
        
        local manaCost = card.manaCost or 0
        local power = card.power or 0
        local cardType = card.type or "unknown"
        
        stats.manaCostDistribution[manaCost] = (stats.manaCostDistribution[manaCost] or 0) + 1
        stats.powerDistribution[power] = (stats.powerDistribution[power] or 0) + 1
        stats.typeDistribution[cardType] = (stats.typeDistribution[cardType] or 0) + 1
        
        -- card Powers
        if cardPowers.hasSpecialAbility(card.id) then
            stats.cardsWithAbilities = stats.cardsWithAbilities + 1
        end
    end
    
    -- Calculate averages
    if stats.totalCards > 0 then
        stats.averageManaCost = totalManaCost / stats.totalCards
        stats.averagePower = totalPower / stats.totalCards
    end
    
    return stats
end


-- Validate card data integrity
function cardData.validateCardData()
    local errors = {}
    local warnings = {}
    
    for i, card in ipairs(cardData.definitions) do
        if not card.id then
            table.insert(errors, "Card at index " .. i .. " missing ID")
        end
        if not card.name or card.name == "" then
            table.insert(errors, "Card " .. (card.id or i) .. " missing name")
        end
        if not card.manaCost or card.manaCost < 0 then
            table.insert(warnings, "Card " .. (card.name or card.id or i) .. " has invalid mana cost: " .. tostring(card.manaCost))
        end
        if not card.power or card.power < 0 then
            table.insert(warnings, "Card " .. (card.name or card.id or i) .. " has invalid power: " .. tostring(card.power))
        end
        if not card.imagePath or card.imagePath == "" then
            table.insert(warnings, "Card " .. (card.name or card.id or i) .. " missing image path")
        end
        
        -- Check for duplicate IDs
        for j, otherCard in ipairs(cardData.definitions) do
            if i ~= j and card.id == otherCard.id then
                table.insert(errors, "Duplicate card ID: " .. card.id .. " (cards: " .. (card.name or "Unknown") .. " and " .. (otherCard.name or "Unknown") .. ")")
            end
        end
    end
    
    if #errors > 0 then
        print("CARD DATA ERRORS:")
        for _, error in ipairs(errors) do
            print("  ERROR: " .. error)
        end
    end
    
    if #warnings > 0 then
        print("CARD DATA WARNINGS:")
        for _, warning in ipairs(warnings) do
            print("  WARNING: " .. warning)
        end
    end
    
    if #errors == 0 and #warnings == 0 then
        print("Card data validation passed - no errors or warnings found!")
    end
    
    return #errors == 0, errors, warnings
end

return cardData