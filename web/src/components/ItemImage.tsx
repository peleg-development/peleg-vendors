import React, { useState } from 'react';
import { Package } from 'lucide-react';

interface ItemImageProps {
  itemName: string;
  className?: string;
}

const ItemImage: React.FC<ItemImageProps> = ({ itemName, className = '' }) => {
  const [imageError, setImageError] = useState(false);
  
  const imagePath = `nui://ox_inventory/web/images/${itemName}.png`;
  
  const handleImageError = () => {
    setImageError(true);
  };

  if (imageError) {
    return (
      <div className={`flex items-center justify-center bg-surface-2 border border-border-outline rounded-sm ${className}`}>
        <Package className="w-8 h-8 text-text-muted" />
      </div>
    );
  }

  return (
    <img
      src={imagePath}
      alt={itemName}
      className={`object-cover rounded-sm border border-border-outline ${className}`}
      onError={handleImageError}
    />
  );
};

export default ItemImage;