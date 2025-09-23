
import React, { useEffect, useState } from 'react';
import { VendorItem } from '../types';
import ItemImage from './ItemImage';
import { Check, X } from 'lucide-react';

interface ItemTileProps {
  item: VendorItem;
  available: number;
  isSelected: boolean;
  onClick: () => void;
  onSell: (item: VendorItem, quantity: number) => void;
  onBuy?: (item: VendorItem, quantity: number) => void;
  isLoading: boolean;
  sellResult?: 'success' | 'error' | null;
  limitInfo?: { remainingPlayer?: number; remainingGlobal?: number; cooldownMs?: number };
  theme?: number;
}

const ItemTile: React.FC<ItemTileProps> = ({
  item,
  available,
  isSelected,
  onClick,
  onSell,
  onBuy,
  isLoading,
  sellResult,
  limitInfo,
  theme,
}) => {
  if (!item) {
    return null;
  }

  const [quantity, setQuantity] = useState(1);

  useEffect(() => {
    if (isSelected) setQuantity(1);
  }, [isSelected]);

  const handleQuantityChange = (value: string) => {
    const num = parseInt(value) || 0;
    const limit = item.buyPrice ? 9999 : available;
    setQuantity(Math.max(1, Math.min(limit, num)));
  };

  const handleSell = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (quantity > 0 && quantity <= available) {
      onSell(item, quantity);
      setQuantity(1);
    }
  };

  const handleBuy = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!onBuy) return;
    if (quantity > 0) {
      onBuy(item, quantity);
      setQuantity(1);
    }
  };

  const totalValue = item.price * quantity;

  const getThemeClasses = (baseClasses: string) => {
    if (theme === 2) {
      return baseClasses
        .replace(/bg-surface-1/g, 'bg-premium-surface-1')
        .replace(/bg-surface-2/g, 'bg-premium-surface-2')
        .replace(/bg-surface-0/g, 'bg-premium-surface-0')
        .replace(/bg-accent-red-pressed/g, 'bg-premium-accent-red-pressed')
        .replace(/bg-accent-red/g, 'bg-premium-accent-red')
        .replace(/text-text-primary/g, 'text-premium-text-primary')
        .replace(/text-text-inverse/g, 'text-premium-text-inverse')
        .replace(/text-accent-red/g, 'text-premium-accent-red')
        .replace(/border-border-outline/g, 'border-premium-border-outline')
        .replace(/rounded/g, 'rounded-premium-card')
        .replace(/rounded-none/g, 'rounded-premium-input');
    }
    return baseClasses;
  };

  return (
    <div
      className={`relative group aspect-square ${
        (!item.buyPrice && available === 0) ? 'opacity-50' : ''
      }`}
    >
      <div className={getThemeClasses("relative w-full h-full bg-surface-1 hover:bg-surface-2 rounded overflow-hidden")}>
        <button onClick={onClick} disabled={!item.buyPrice && available === 0} className="absolute inset-0">
          <ItemImage itemName={item.name} className="w-full h-full" />

          {!isSelected && (
            <div className={getThemeClasses("absolute bottom-2 right-2 bg-accent-red-pressed text-text-inverse text-sm px-2 py-1 rounded-none font-bold font-sans")}>
              ${ (item.buyPrice ?? item.price) }
            </div>
          )}

          {!item.buyPrice && typeof available === 'number' && (
            <div className={getThemeClasses("absolute top-2 left-2 bg-black/80 text-text-primary text-sm px-2 py-1 rounded-none font-sans")}>
              {available}
            </div>
          )}

          {!item.buyPrice && available === 0 && (
            <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
              <span className={getThemeClasses("text-accent-red text-base font-bold uppercase font-sans")}>Missing Items</span>
            </div>
          )}

          {sellResult && (
            <div className="absolute inset-0 flex items-center justify-center">
              {sellResult === 'success' ? (
                <Check className="w-24 h-24 text-text-inverse drop-shadow-lg" strokeWidth={4} />
              ) : (
                <X className="w-24 h-24 text-accent-red drop-shadow-lg" strokeWidth={4} />
              )}
            </div>
          )}
          {limitInfo && ((limitInfo.remainingPlayer === 0) || (limitInfo.remainingGlobal === 0)) && limitInfo.cooldownMs && limitInfo.cooldownMs > 0 && (
            <div className="absolute inset-0 flex items-end justify-center p-2 pointer-events-none">
              <div className=" text-text-inverse text-xs px-2 py-1 rounded-sm">
                Resets in {Math.ceil(limitInfo.cooldownMs / 1000 / 60)}m
              </div>
            </div>
          )}
        </button>

        {isSelected && (
          <>
            <button
              onClick={(e) => {
                e.stopPropagation();
                const newQty = Math.max(1, quantity - 1);
                setQuantity(newQty);
              }}
              disabled={isLoading || quantity <= 1}
              className={getThemeClasses("absolute top-2 left-2 w-6 h-6 bg-surface-0 border border-border-outline rounded-none text-text-primary text-center text-sm font-sans hover:bg-surface-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center z-10")}
            >
              <i className="fas fa-minus text-xs"></i>
            </button>
            
            <button
              onClick={(e) => {
                e.stopPropagation();
                const max = item.buyPrice ? 9999 : Math.max(available, 1);
                const newQty = Math.min(max, quantity + 1);
                setQuantity(newQty);
              }}
              disabled={isLoading || quantity >= (item.buyPrice ? 9999 : Math.max(available, 1))}
              className={getThemeClasses("absolute top-2 right-2 w-6 h-6 bg-surface-0 border border-border-outline rounded-none text-text-primary text-center text-sm font-sans hover:bg-surface-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center z-10")}
            >
              <i className="fas fa-plus text-xs"></i>
            </button>
          </>
        )}

        {isSelected && (
          <div className="absolute bottom-0 left-0 right-0 p-2 flex items-center gap-2">
            <input
              type="number"
              min="1"
              max={item.buyPrice ? 9999 : Math.max(available, 1)}
              value={quantity}
              onChange={(e) => handleQuantityChange(e.target.value)}
              className={getThemeClasses("w-12 px-2 py-2 bg-surface-0 border border-border-outline rounded-none text-text-primary text-center text-sm font-sans focus:outline-none focus:ring-1 focus:ring-accent-red [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none")}
              disabled={isLoading}
              onClick={(e) => e.stopPropagation()}
            />

            {!item.buyPrice && typeof available === 'number' && available > 0 && (
              <button
                onClick={handleSell}
                disabled={isLoading || quantity === 0 || quantity > available}
                className={getThemeClasses("flex-1 px-3 py-2 bg-accent-red hover:bg-accent-red-pressed disabled:opacity-50 disabled:cursor-not-allowed text-text-inverse font-bold rounded-none text-sm uppercase font-sans transition-colors duration-150")}
              >
                {isLoading ? (
                  <div className="flex items-center justify-center gap-1">
                    <div className="w-3 h-3 border border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Selling...</span>
                  </div>
                ) : (
                  `SELL $${totalValue.toLocaleString()}`
                )}
              </button>
            )}

            {item.buyPrice && (
              <button
                onClick={handleBuy}
                disabled={isLoading || quantity === 0}
                className="flex-1 px-3 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold rounded-none text-sm uppercase font-sans transition-colors duration-150"
              >
                {isLoading ? (
                  <div className="flex items-center justify-center gap-1">
                    <div className="w-3 h-3 border border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Buying...</span>
                  </div>
                ) : (
                  `BUY $${(item.buyPrice * quantity).toLocaleString()}`
                )}
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ItemTile;
