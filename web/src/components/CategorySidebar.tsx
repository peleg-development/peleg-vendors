import React from 'react';
import { Category } from '../types';

interface CategorySidebarProps {
  categories: Category[];
  activeCategory: string;
  onCategoryChange: (categoryId: string) => void;
  theme?: number;
}

const CategorySidebar: React.FC<CategorySidebarProps> = ({
  categories,
  activeCategory,
  onCategoryChange,
  theme
}) => {
  const getThemeClasses = (baseClasses: string) => {
    if (theme === 2) {
      return baseClasses
        .replace(/bg-surface-0/g, 'bg-premium-surface-0')
        .replace(/bg-accent-red-pressed/g, 'bg-premium-accent-red-pressed')
        .replace(/bg-surface-2/g, 'bg-premium-surface-2')
        .replace(/text-text-secondary/g, 'text-premium-text-secondary')
        .replace(/text-text-primary/g, 'text-premium-text-primary')
        .replace(/text-text-inverse/g, 'text-premium-text-inverse')
        .replace(/border-border-outline/g, 'border-premium-border-outline')
        .replace(/rounded-none/g, 'rounded-premium-input');
    }
    return baseClasses;
  };

  return (
    <div className={getThemeClasses("w-48 bg-surface-0 border-r border-border-outline flex-1")}>
      <div className="p-1 space-y-1">
        {categories.map((category) => (
          <button
            key={category.id}
            onClick={() => onCategoryChange(category.id)}
            className={`w-full flex items-center gap-3 px-3 py-2.5 ${getThemeClasses("rounded-none")} text-sm font-sans transition-colors duration-150 ${
              activeCategory === category.id
                ? getThemeClasses("bg-accent-red-pressed text-text-inverse font-bold")
                : getThemeClasses("text-text-secondary hover:bg-surface-2 hover:text-text-primary font-medium")
            }`}
          >
            <i className={`${category.icon} text-base`}></i>
            <span className="font-medium truncate">{category.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default CategorySidebar;
