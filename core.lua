
local config = {
    autoSell = true,
    autoRepair = true,
    autoSell_MaxLevelOnly = true,
    autoRepair_MaxLevelOnly = true,
    useGuildBank = true,
    sell = {
        -- [itemid] = true,
    },
    wontsell = {
        -- [itemid] = true,
    },
    restocklist = {
        -- [itemid] = size,
    },
}

if(string.upper(UnitName'player') == '\66\65\83\72' and GetRealmName() == '\229\175\146\229\134\176\231\154\135\229\134\160')
    or (string.upper(UnitName'player') == '\89\97\114\111\111\116' and GetRealmName() == '\228\188\138\231\145\159\230\139\137')
    then
    config.restocklist[58257] = 40 -- 高地泉水
    config.wontsell[6196] = true -- Noboru's Cudgel
    config.wontsell[3300] = true -- Rabbit's Foot
end

--======================== CONFIG END ========================
local eventFrame = CreateFrame'Frame'
local addon = {}
addon.config = config
addon.eventFrame = eventFrame

local function formatMoney(value)
    local str = ''
    if value >= 10000 then
        str = str .. format('|c00ffd700%dg|r', floor(value / 10000))
    end
    if value >= 100 then
        str = str .. format('|c00c7c7cf%ds|r', (floor(value / 100) % 100))
    end

    local cooper = floor(value)%100
    if(cooper>0) then
        str = str .. format('|c00eda55f%dc|r', cooper)
    end

    return str
end

local GetItemID = function(link)
    return tonumber(link:match'item:(%d+):')
end

local BuyItem = function(itemid, tobuy)
    -- find item merchant index
    local index
    for i = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(i)
        local id = link and GetItemID(link)
        if(id and id == itemid) then
            index = i
            break
        end
    end

    if(not index) then return end

    local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(index)
    local stacksize = GetMerchantItemMaxStack(index)

    if(numAvailable > 0) then
        tobuy = min(tobuy, numAvailable)
    end
    if(tobuy<1) then
        return
    end

    local loops = floor(tobuy / stacksize)
    local leftover = tobuy % stacksize

    if(loops > 0) then
        for i = 1, loops do
            BuyMerchantItem(index, stacksize)
        end
    end

    if(leftover > 0) then
        BuyMerchantItem(index, leftover)
    end
end

local Sell = function()
    if(not config.autoSell) then return end
    if(config.autoSell_MaxLevelOnly and (UnitLevel'player' ~= MAX_PLAYER_LEVEL)) then return end

    for bag = 0, 4 do
        for slot = 0, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local id = link and GetItemID(link)
            if(id) then
                if ((select(3, GetItemInfo(id)) == 0) or config.sell[id]) and (not config.wontsell[id]) then
                    ShowMerchantSellCursor(1)
                    UseContainerItem(bag, slot)
                end
            end
        end
    end
end

local Repair = function()
    if(not config.autoRepair) then return end
    if(not CanMerchantRepair()) then return end
    if(config.autoRepair_MaxLevelOnly and (UnitLevel'player' ~= MAX_PLAYER_LEVEL)) then return end

    local cost, canRepair = GetRepairAllCost()
    if(config.useGuildBank and IsInGuild() and CanGuildBankRepair()) then
        RepairAllItems(1)
    end
    local gbused = cost - GetRepairAllCost()
    RepairAllItems()

    if(gbused>0) then
        print('Repair cost guildbank '.. formatMoney(gbused))
    end
    if(gbused ~= cost) then
        print('Repair cost ' .. formatMoney(cost-gbused))
    end
end

local Restock = function()
    for i = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(i)
        local itemID = link and GetItemID(link)
        local holdsize = itemID and config.restocklist[itemID]
        if(holdsize) then
            local has = GetItemCount(itemID)
            local tobuy = holdsize - has
            BuyItem(itemID, tobuy)
        end
    end
end

eventFrame:RegisterEvent'MERCHANT_SHOW'
eventFrame:SetScript('OnEvent', function()
    Sell()
    Repair()
    Restock()
end)

SLASH_YMERCHANT1 = '/buy'
SLASH_YMERCHANT2 = '/ymerchant'
function SlashCmdList.YMERCHANT(msg)
    local item, tobuy = strsplit(' ', msg)
    if(not item or item=='') then return end
    if(not tobuy or tobuy == '') then
        tobuy = 1
    end

    local itemid = GetItemID(item)
    BuyItem(itemid, tobuy)
end

