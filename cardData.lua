

local cardData = {}

-- Card definitions with their properties
-- Will be mimicing the google sheet card definitions from template from the professor 
-- altered to fit the game design cards 

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
        name = "Market",
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
        description = "Take something from opponent",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/5_Steal.png",
        manaCost = 5,
        power = 7
    },
    {
        id = 6,
        name = "King",
        type = "creature",
        description = "Powerful royal leader",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/6_King.png",
        manaCost = 8,
        power = 11
    },
    {
        id = 7,
        name = "Stink Trap",
        type = "trap",
        description = "Foul-smelling defensive trap",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/7_StinkTrap.png",
        manaCost = 3,
        power = 4
    },
    {
        id = 8,
        name = "Lightning Wizard",
        type = "creature",
        description = "Master of electrical magic",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/8_LightningWizard.png",
        manaCost = 4,
        power = 3
    },
    {
        id = 9,
        name = "Hypnosis",
        type = "spell",
        description = "Control opponent's mind",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/9_Hypnosis.png",
        manaCost = 3,
        power = 4
    },
    {
        id = 10,
        name = "Beehive",
        type = "structure",
        description = "Produces buzzing defenders",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/10_Beehive.png",
        manaCost = 7,
        power = 8
    },
    {
        id = 11,
        name = "Pollination",
        type = "spell",
        description = "Nature's spreading magic",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/11_Polinization.png",
        manaCost = 5,
        power = 6
    },
    {
        id = 12,
        name = "Mimic",
        type = "creature",
        description = "Shapeshifting trickster",
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
        description = "Currency for trading",
        imagePath = "cardSprites/3D Card Kit - Fantasy [Standard]/Renders/14_Coin.png",
        manaCost = 2,
        power = 3
    },
    {
        id = 15,
        name = "Cult",
        type = "organization",
        description = "Dark religious gathering",
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

-- images table
cardData.images = {}

-- preload 
function cardData.loadImages()
    print("Loading card images...")
    

    local success, cardBack = pcall(love.graphics.newImage, cardData.cardBackImage)
    if success then
        cardData.images.cardBack = cardBack
        print("✓ Card back loaded")
    else
        print("✗ Failed to load card back: " .. cardData.cardBackImage)
    end
    

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

-- call by ID
function cardData.getCard(id)
    for i, card in ipairs(cardData.definitions) do
        if card.id == id then
            return card
        end
    end
    return nil
end

-- call by ID
function cardData.getCardImage(id)
    return cardData.images[id]
end


function cardData.getCardBackImage()
    return cardData.images.cardBack
end

-- card type call
function cardData.getCardsByType(cardType)
    local result = {}
    for i, card in ipairs(cardData.definitions) do
        if card.type == cardType then
            table.insert(result, card)
        end
    end
    return result
end

-- RNG card distribution
function cardData.getRandomCards(count)
    local result = {}
    local availableCards = {}
    
    -- copy of cards
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

-- Mana manger
function cardData.setManaCosts(manaCostTable)
    for id, cost in pairs(manaCostTable) do
        local card = cardData.getCard(id)
        if card then
            card.manaCost = cost
            print("Set mana cost for " .. card.name .. ": " .. cost)
        end
    end
end

return cardData