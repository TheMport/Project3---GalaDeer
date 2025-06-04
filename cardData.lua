local cardData = {}

cardData.definitions = {
    {
        id = 1,
        name = "Fireball",
        type = "spell",
        description = "Deal damage to target",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/1_Fireball.png",
        manaCost = 3, 
        power = 5
    },
    {
        id = 2,
        name = "Trenchcoat Mushrooms",
        type = "creature",
        description = "Mysterious fungal creatures",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/2_TrenchcoatMushrooms.png",
        manaCost = 5,
        power = 9
    },
    {
        id = 3,
        name = "Monk",
        type = "creature",
        description = "Holy warrior with divine powers",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/3_Monk.png",
        manaCost = 1,
        power = 1
    },
    {
        id = 4,
        name = "Market Hustler",
        type = "location",
        description = "Trade and commerce hub",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/4_Market.png",
        manaCost = 6,
        power = 12
    },
    {
        id = 5,
        name = "Steal",
        type = "spell",
        description = "When Revealed: Lower the power of each card in your opponent's hand by 1",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/5_Steal.png",
        manaCost = 5,
        power = 7
    },
    {
        id = 6,
        name = "King",
        type = "creature",
        description = "When Revealed: Gain +2 power for each enemy card here",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/6_King.png",
        manaCost = 8,
        power = 11
    },
    {
        id = 7,
        name = "Stink Trap",
        type = "trap",
        description = "When ANY other card is played here, lower that card's power by 1",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/7_StinkTrap.png",
        manaCost = 3,
        power = 4
    },
    {
        id = 8,
        name = "Lightning Wizard",
        type = "creature",
        description = "When Revealed: Discard your other cards here, gain +2 power for each discarded",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/8_LightningWizard.png",
        manaCost = 4,
        power = 3
    },
    {
        id = 9,
        name = "Hypnosis",
        type = "spell",
        description = "When Revealed: Move away an enemy card here with the lowest power",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/9_Hypnosis.png",
        manaCost = 3,
        power = 4
    },
    {
        id = 10,
        name = "Beehive",
        type = "structure",
        description = "When Revealed: Gain +5 power if there is exactly one enemy card here",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/10_Beehive.png",
        manaCost = 7,
        power = 8
    },
    {
        id = 11,
        name = "Pollination",
        type = "spell",
        description = "When Revealed: Give cards in your hand +1 power",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/11_Polinization.png",
        manaCost = 5,
        power = 6
    },
    {
        id = 12,
        name = "Mimic",
        type = "creature",
        description = "Add a copy to your hand after this card is played",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/12_Mimic.png",
        manaCost = 8,
        power = 10
    },
    {
        id = 13,
        name = "Sea Monster",
        type = "creature",
        description = "Fearsome aquatic beast",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/13_SeaMonster.png",
        manaCost = 4,
        power = 5
    },
    {
        id = 14,
        name = "Coin",
        type = "resource",
        description = "When Revealed: Gain +2 mana next turn",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/14_Coin.png",
        manaCost = 2,
        power = 3
    },
    {
        id = 15,
        name = "Cult",
        type = "organization",
        description = "When Revealed: Both players draw a card",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/15_Cult.png",
        manaCost = 2,
        power = 4
    },
    {
        id = 16,
        name = "Bell Towers",
        type = "structure",
        description = "Sound the alarm across lands",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/16_Belltowers.png",
        manaCost = 3,
        power = 1
    },
    {
        id = 17,
        name = "Rebirth",
        type = "spell",
        description = "Bring back from the dead",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/17_Rebirth.png",
        manaCost = 5,
        power = 5
    },
    {
        id = 18,
        name = "Water Dragon",
        type = "creature",
        description = "Ancient aquatic dragon",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/18_WaterDragon.png",
        manaCost = 3,
        power = 1
    },
    {
        id = 19,
        name = "Ocean Treasure",
        type = "artifact",
        description = "Valuable sunken riches",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/19_OceanTreasure.png",
        manaCost = 2,
        power = 1
    },
    {
        id = 20,
        name = "Fire Element",
        type = "element",
        description = "Pure fire essence",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/20_Element_Fire.png",
        manaCost = 1,
        power = 2
    },
    {
        id = 21,
        name = "Lightning Element",
        type = "element",
        description = "Pure lightning essence",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/21_Element_Lightning.png",
        manaCost = 3,
        power = 3
    },
    {
        id = 22,
        name = "Air Element",
        type = "element",
        description = "Pure air essence",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/22_Element_Air.png",
        manaCost = 6,
        power = 3
    },
    {
        id = 23,
        name = "Water Element",
        type = "element",
        description = "Pure water essence",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/23_Element_Water.png",
        manaCost = 1,
        power = 2
    },
    {
        id = 24,
        name = "Dark Element",
        type = "element",
        description = "Pure dark essence",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/24_Element_Dark.png",
        manaCost = 2,
        power = 3
    },
    {
        id = 25,
        name = "Earth Element",
        type = "element",
        description = "Pure earth essence",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/25_Element_Earth.png",
        manaCost = 1,
        power = 2
    },
    {
        id = 26,
        name = "Blood Ring",
        type = "artifact",
        description = "Dark magical ring",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/26_BloodRing.png",
        manaCost = 3,
        power = 6
    },
    {
        id = 27,
        name = "Book",
        type = "artifact",
        description = "Ancient tome of knowledge",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/27_Book.png",
        manaCost = 5,
        power = 3
    },
    {
        id = 28,
        name = "Roll Dice",
        type = "spell",
        description = "Random chance effect",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/28_RollDice.png",
        manaCost = 2,
        power = 2
    },
    {
        id = 29,
        name = "Block",
        type = "spell",
        description = "Defensive barrier",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/29_Block.png",
        manaCost = 3,
        power = 3
    },
    {
        id = 30,
        name = "Wizard",
        type = "creature",
        description = "Master of arcane arts",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/30_Wizard.png",
        manaCost = 8,
        power = 10
    }
}

cardData.cardBackImage = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/0_CardBack.png"

-- Images table
cardData.images = {}

-- Preload all images
function cardData.loadImages()
    print("Loading card images...")
    
    -- Load card back
    local success, cardBack = pcall(love.graphics.newImage, cardData.cardBackImage)
    if success then
        cardData.images.cardBack = cardBack
        print("✓ Card back loaded")
    else
        print("✗ Failed to load card back: " .. cardData.cardBackImage)
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
            print("✗ Failed to load: " .. card.name .. " (" .. card.imagePath .. ")")
            failedCount = failedCount + 1
        end
    end
    
    print("Card loading complete: " .. loadedCount .. " loaded, " .. failedCount .. " failed")
end

-- Get card by ID
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

-- Get random cards for deck building
function cardData.getRandomCards(count)
    local result = {}
    local availableCards = {}
    
    -- Create copy of all cards
    for i, card in ipairs(cardData.definitions) do
        table.insert(availableCards, card)
    end
    
    -- Randomly select cards
    for i = 1, math.min(count, #availableCards) do
        local randomIndex = love.math.random(1, #availableCards)
        table.insert(result, availableCards[randomIndex])
        table.remove(availableCards, randomIndex)
    end
    
    return result
end

-- Mana cost manager (if needed for balancing)
function cardData.setManaCosts(manaCostTable)
    for id, cost in pairs(manaCostTable) do
        local card = cardData.getCard(id)
        if card then
            card.manaCost = cost
            print("Set mana cost for " .. card.name .. ": " .. cost)
        end
    end
end

-- Get all cards with special abilities
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

-- Get card statistics
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
        -- totals
        totalManaCost = totalManaCost + (card.manaCost or 0)
        totalPower = totalPower + (card.power or 0)
        
        local manaCost = card.manaCost or 0
        local power = card.power or 0
        local cardType = card.type or "unknown"
        
        stats.manaCostDistribution[manaCost] = (stats.manaCostDistribution[manaCost] or 0) + 1
        stats.powerDistribution[power] = (stats.powerDistribution[power] or 0) + 1
        stats.typeDistribution[cardType] = (stats.typeDistribution[cardType] or 0) + 1
        
        -- special abilities
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

-- Print card database info (for debugging)
function cardData.printCardDatabase()
    print("\n=== CARD DATABASE INFO ===")
    local stats = cardData.getCardStats()
    
    print("Total Cards: " .. stats.totalCards)
    print("Average Mana Cost: " .. string.format("%.1f", stats.averageManaCost))
    print("Average Power: " .. string.format("%.1f", stats.averagePower))
    print("Cards with Special Abilities: " .. stats.cardsWithAbilities)
    
    print("\nMana Cost Distribution:")
    for cost, count in pairs(stats.manaCostDistribution) do
        print("  " .. cost .. " mana: " .. count .. " cards")
    end
    
    print("\nCard Type Distribution:")
    for cardType, count in pairs(stats.typeDistribution) do
        print("  " .. cardType .. ": " .. count .. " cards")
    end
    
    print("\nCards with Special Abilities:")
    local cardPowers = require("cardPowers")
    for i, card in ipairs(cardData.definitions) do
        if cardPowers.hasSpecialAbility(card.id) then
            local powerDef = cardPowers.getPowerDefinition(card.id)
            print("  " .. card.name .. " (" .. card.manaCost .. "/" .. card.power .. "): " .. (powerDef.description or "Unknown ability"))
        end
    end
    print("========================\n")
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