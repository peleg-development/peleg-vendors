import React from 'react';
import { VendorItem } from '../types';
import ItemTile from './ItemTile';

interface ItemGridProps {
  items: VendorItem[];
  stock: Record<string, number>;
  selectedItem: VendorItem | null;
  onItemSelect: (item: VendorItem) => void;
  onSell: (item: VendorItem, quantity: number) => void;
  onBuy?: (item: VendorItem, quantity: number) => void;
  isLoading: boolean;
  sellResults: Record<string, 'success' | 'error' | null>;
  limits?: Record<string, { remainingPlayer?: number; remainingGlobal?: number; cooldownMs?: number }>;
  theme?: number;
}

const ItemGrid: React.FC<ItemGridProps> = ({
  items,
  stock,
  selectedItem,
  onItemSelect,
  onSell,
  onBuy,
  isLoading,
  sellResults,
  limits,
  theme,
}) => {

  if (items.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <p className="text-text-muted">No items in this category</p>
      </div>
    );
  }

  return (
    <div className="flex-1 p-3 overflow-hidden">
      <div className="h-full overflow-y-auto">
        <div className="grid grid-cols-4 gap-4 h-full">
          {items.filter(Boolean).map((item) => (
            <ItemTile
              key={item.name}
              item={item}
              available={stock[item.name] || 0}
              isSelected={selectedItem?.name === item.name}
              onClick={() => onItemSelect(item)}
              onSell={onSell}
              onBuy={onBuy}
              isLoading={isLoading}
              sellResult={sellResults[item.name]}
              limitInfo={limits ? limits[item.name] : undefined}
              theme={theme}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default ItemGrid;
