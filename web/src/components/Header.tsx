import React from 'react';
import { Store } from 'lucide-react';

interface HeaderProps {
  vendorName: string;
  onClose: () => void;
  icon?: string;
  theme?: number;
}

const Header: React.FC<HeaderProps> = ({ vendorName, onClose, icon, theme }) => {
  const getThemeClasses = (baseClasses: string) => {
    if (theme === 2) {
      return baseClasses
        .replace(/bg-surface-0/g, 'bg-premium-surface-0')
        .replace(/bg-accent-red/g, 'bg-premium-accent-red')
        .replace(/bg-accent-red-pressed/g, 'bg-premium-accent-red-pressed')
        .replace(/text-text-primary/g, 'text-premium-text-primary')
        .replace(/text-text-inverse/g, 'text-premium-text-inverse')
        .replace(/border-border-outline/g, 'border-premium-border-outline')
        .replace(/rounded-sm/g, 'rounded-premium-card');
    }
    return baseClasses;
  };

  return (
    <div className={getThemeClasses("flex items-center justify-between px-4 py-2 border-b border-border-outline bg-surface-0")}>
      <div className="flex items-center gap-3">
        <div className={getThemeClasses("w-8 h-8 bg-accent-red rounded-sm flex items-center justify-center")}>
          {icon ? (
            <i className={`${icon} ${getThemeClasses("text-text-inverse text-base")}`}></i>
          ) : (
            <Store className={getThemeClasses("w-5 h-5 text-text-inverse")} />
          )}
        </div>
        <h1 className={getThemeClasses("text-text-primary font-bold text-lg uppercase font-sans")}>{vendorName}</h1>
      </div>
      
      <button
        onClick={onClose}
        className={getThemeClasses("px-4 py-2 bg-accent-red hover:bg-accent-red-pressed rounded-sm text-text-inverse font-bold text-sm uppercase font-sans transition-colors duration-150 flex items-center gap-2")}
      >
        <span className="text-lg font-black" style={{fontFamily: 'Arial Black, sans-serif', transform: 'rotate(15deg)', display: 'inline-block'}}>✕</span>
        <span>CLOSE</span>
      </button>
    </div>
  );
};

export default Header;
