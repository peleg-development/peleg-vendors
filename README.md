# Peleg Vendors

A comprehensive vendor system for FiveM with support for both ESX and QBCore frameworks, featuring a modern React-based UI, automatic framework detection, and advanced limit system.

## Features

- **Flexible Payment**: Support for cash, bank, black money, and auto payment (tries cash first, then bank)
- **Limit System**: Optional daily limits per player and global limits with SQL tracking **(OPTIONAL)**
- **Job Requirements**: Set job and grade requirements for vendors and individual items **(OPTIONAL)**
- **Dual Function**: Vendors can both buy items from players and sell items to players **(OPTIONAL)**
- **Categories**: Organize items with custom categories and icons **(OPTIONAL)**
- **Blips**: Automatic map blips with customizable sprites and colors
- **Themes**: Choose between 2 themes for each shop 

## Installation

### Dependencies

- **ox_lib** (Required)
- **oxmysql** (Required for limit system)
- **ox_inventory** or **qb-inventory** (For inventory management)
- **ox_target**, **qb-target**, or **qtarget** (For targeting, optional - has drawtext fallback)

### Setup

1. **Add to server.cfg**
   ```cfg
   ensure peleg-vendors
   ```

2. **Database Setup** (Only if using limits)
   ```sql
   -- Run this SQL if you want to use the limit system
   -- Or set Config.Limits.AutoMigrate = true
   CREATE TABLE IF NOT EXISTS peleg_vendor_limits (
     id INT AUTO_INCREMENT PRIMARY KEY,
     scope VARCHAR(16) NOT NULL,        
     identifier VARCHAR(64) DEFAULT NULL, 
     item VARCHAR(64) NOT NULL,
     quantity INT NOT NULL DEFAULT 0,
     day DATE NOT NULL,
     UNIQUE KEY uniq_player (scope, identifier, item, day),
     UNIQUE KEY uniq_global (scope, item, day),
     KEY idx_scope_day_item (scope, day, item),
     KEY idx_player_day_item (identifier, day, item)
   );
   ```

## Support

For support and updates, please check the resource documentation or contact the author.

## License

This resource is provided as-is. Please respect the terms of use and licensing requirements.

---