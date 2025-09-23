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
