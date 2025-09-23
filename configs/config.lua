---@class VendorItemDef
---@field name string     
---@field label string  
---@field price number       
---@field category? string  
---@field limitPerPlayer? number  
---@field limitGlobal? number    

---@class VendorJobRequirement
---@field job string
---@field minGrade number

---@class VendorItemDefExt: VendorItemDef
---@field buyPrice? number    
---@field jobRequirement? VendorJobRequirement 

---@class VendorCategoryDef
---@field id string
---@field label string
---@field icon string
---@field order number

---@class VendorDef
---@field id string
---@field label string
---@field icon? string           
---@field model string
---@field coords vector3
---@field heading number
---@field scenario? string
---@field theme? number              -- theme number (1 = default, 2 = premium dark)
---@field categories? VendorCategoryDef[]  
---@field items (VendorItemDef|VendorItemDefExt)[]
---@field jobRequirement? VendorJobRequirement 
---@field blip? { enabled: boolean, sprite?: number, color?: number, scale?: number, label?: string }

Config = Config or {}

-- Core stack selection
Config.Framework = 'auto'       -- 'auto' | 'qb' | 'esx'
Config.Inventory = 'auto'       -- 'auto' | 'ox' | 'qb'
Config.Target    = 'auto'       -- 'auto' | 'ox_target' | 'qb-target' | 'qtarget' | 'drawtext'

-- Where to pay money to. For ESX supports: 'cash' | 'bank' | 'black_money' | 'auto'
-- For QBCore supports: 'cash' | 'bank' | 'auto' ; if 'black_money' is set, falls back to adding an item called 'black_money'
-- 'auto' tries cash first, then bank, fails if neither has sufficient funds
Config.PayoutAccount = 'auto'
Config.PaymentAccount = 'auto'

-- General behavior
Config.Debug = false

-- Optional SQL-based limit
Config.Limits = {
    Enabled = false,       -- set true to enable

    ---@NOTE: if u dont want to use auto migration and u still want limits run the sql file stock.sql
    AutoMigrate = false,    -- creates table automatically
}

-- Vendors definition: add as many as you like
Config.Vendors = {
    {
        id = 'vendor_fish_1',
        label = 'Fishmonger',
        icon = 'fas fa-fish',
        model = 's_m_m_linecook',
        coords = vec3(-1037.76, -1396.45, 5.55),
        heading = 118.0,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        theme = 1, -- Default theme
        jobRequirement = {}, -- No job requirement
        blip = {
            enabled = true,
            sprite = 68,
            color = 3, 
            scale = 0.8,
            label = 'Fishmonger'
        },
        categories = {
            { id = 'food', label = 'Food', icon = 'fas fa-utensils', order = 1 },
        },
        items = {
            { name = 'fish',       label = 'Fish',        price = 35, category = 'food', limitPerPlayer = 50 },
            { name = 'salmon',     label = 'Salmon',      price = 55, category = 'food' },
            { name = 'tuna',       label = 'Tuna',        price = 85, category = 'food' },
            { name = 'bait',       label = 'Fishing Bait', buyPrice = 5,  category = 'food', jobRequirement = { job = 'fisherman', minGrade = 0 } },
            { name = 'weapon_switchblade',       label = 'Switchblade', buyPrice = 2,  category = 'food' },
        }
    },
    {
        id = 'vendor_hunter_1',
        label = 'Game Buyer',
        icon = 'fas fa-crosshair',
        model = 'cs_old_man2',
        coords = vec3(-679.61, 5836.49, 16.33),
        heading = 215.0,
        scenario = 'WORLD_HUMAN_AA_COFFEE',
        theme = 2, -- Premium dark theme
        jobRequirement = { job = 'hunter', minGrade = 0 }, -- Requires hunter job
        blip = {
            enabled = true,
            sprite = 141,
            color = 1,
            scale = 0.8,
            label = 'Game Buyer'
        },
        categories = {
            { id = 'resources', label = 'Resources', icon = 'fas fa-leaf', order = 1 },
        },
        items = {
            { name = 'meat',       label = 'Raw Meat',    price = 28,  category = 'resources' },
            { name = 'pelt',       label = 'Animal Pelt', price = 45,  category = 'resources', limitGlobal = 200 },
            { name = 'antlers',    label = 'Antlers',     price = 120, category = 'resources' },
        }
    },
}
