import React, { useState, useEffect, useCallback } from 'react';
import { Vendor, VendorItem, VendorData, SellResult, Category } from './types';
import { useNui } from './hooks/useNui';
import Header from './components/Header';
import CategorySidebar from './components/CategorySidebar';
import ItemGrid from './components/ItemGrid';

const App: React.FC = () => {
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [stock, setStock] = useState<Record<string, number>>({});
  const [selectedItem, setSelectedItem] = useState<VendorItem | null>(null);
  const [activeCategory, setActiveCategory] = useState<string>('all');
  const [isLoading, setIsLoading] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  const [isClosing, setIsClosing] = useState(false);
  const [isOpening, setIsOpening] = useState(false);
      const [sellResults, setSellResults] = useState<Record<string, 'success' | 'error' | null>>({});
      const [limits, setLimits] = useState<Record<string, { remainingPlayer?: number; remainingGlobal?: number; cooldownMs?: number }>>({});
  const [currentTheme, setCurrentTheme] = useState<number>(1);

  const { sendNuiCallback, closeNui, listenForNuiMessages } = useNui();

  const getThemeClasses = useCallback((baseClasses: string) => {
    if (currentTheme === 2) {
      return baseClasses
        .replace(/bg-bg/g, 'bg-premium-bg')
        .replace(/bg-surface-0/g, 'bg-premium-surface-0')
        .replace(/bg-surface-1/g, 'bg-premium-surface-1')
        .replace(/bg-surface-2/g, 'bg-premium-surface-2')
        .replace(/bg-surface-hover/g, 'bg-premium-surface-hover')
        .replace(/bg-accent-red/g, 'bg-premium-accent-red')
        .replace(/bg-accent-red-pressed/g, 'bg-premium-accent-red-pressed')
        .replace(/text-text-primary/g, 'text-premium-text-primary')
        .replace(/text-text-secondary/g, 'text-premium-text-secondary')
        .replace(/text-text-muted/g, 'text-premium-text-muted')
        .replace(/text-text-inverse/g, 'text-premium-text-inverse')
        .replace(/text-accent-red/g, 'text-premium-accent-red')
        .replace(/text-price-text/g, 'text-premium-price-text')
        .replace(/border-border-outline/g, 'border-premium-border-outline')
        .replace(/rounded-sm/g, 'rounded-premium-card')
        .replace(/rounded-none/g, 'rounded-premium-input');
    }
    return baseClasses;
  }, [currentTheme]);

  const loadVendorData = useCallback(async (vendorId: string) => {
    try {
      const data = await new Promise<VendorData>((resolve) => {
        sendNuiCallback('vendor:requestData', { vendorId }, resolve);
      });
      
      console.log('Received vendor data:', data);
      if (data && !(data as any).error) {
        setVendor(data.vendor);
        setStock(data.stock || {});
        setIsVisible(true);
        console.log('Vendor set:', data.vendor);
      }
    } catch (error) {
      console.error('Failed to load vendor data:', error);
    }
  }, [sendNuiCallback]);

  const handleClose = useCallback(() => {
    setIsClosing(true);
    setTimeout(() => {
      setIsVisible(false);
      setIsClosing(false);
      setSelectedItem(null);
      setActiveCategory('all');
      setVendor(null);
      setStock({});
      setSellResults({});
      closeNui();
    }, 200);
  }, [closeNui]);

  const handleSell = useCallback(async (item: VendorItem, quantity: number) => {
    if (!vendor) return;

    setIsLoading(true);
    
    try {
      const result = await new Promise<SellResult>((resolve) => {
        sendNuiCallback(
          'vendor:sell',
          {
            vendorId: vendor.id,
            name: item.name,
            quantity: quantity
          },
          resolve
        );
      });

      setSellResults(prev => ({
        ...prev,
        [item.name]: result.success ? 'success' : 'error'
      }));

      if (result.success) {
        setSelectedItem(null);
        await loadVendorData(vendor.id);
      }
      setTimeout(() => {
        setSellResults(prev => ({
          ...prev,
          [item.name]: null
        }));
      }, 2000);

    } catch (error) {
      console.error('Sell failed:', error);
      setSellResults(prev => ({
        ...prev,
        [item.name]: 'error'
      }));
      setTimeout(() => {
        setSellResults(prev => ({
          ...prev,
          [item.name]: null
        }));
      }, 2000);
    } finally {
      setIsLoading(false);
    }
  }, [vendor, sendNuiCallback, loadVendorData]);

  const handleBuy = useCallback(async (item: VendorItem, quantity: number) => {
    if (!vendor) return;

    setIsLoading(true);
    try {
      const result = await new Promise<SellResult>((resolve) => {
        sendNuiCallback(
          'vendor:buy',
          {
            vendorId: vendor.id,
            name: item.name,
            quantity: quantity
          },
          resolve
        );
      });

      setSellResults(prev => ({
        ...prev,
        [item.name]: result.success ? 'success' : 'error'
      }));

      if (result.success) {
        setSelectedItem(null);
        await loadVendorData(vendor.id);
      }

      setTimeout(() => {
        setSellResults(prev => ({
          ...prev,
          [item.name]: null
        }));
      }, 2000);
    } catch (error) {
      console.error('Buy failed:', error);
      setSellResults(prev => ({
        ...prev,
        [item.name]: 'error'
      }));
      setTimeout(() => {
        setSellResults(prev => ({
          ...prev,
          [item.name]: null
        }));
      }, 2000);
    } finally {
      setIsLoading(false);
    }
  }, [vendor, sendNuiCallback, loadVendorData]);

  const getCategories = useCallback((): Category[] => {
    if (!vendor) return [];
    const base: Category[] = [{ id: 'all', label: 'All Items', icon: 'fas fa-box' }];
    if (vendor.categories && vendor.categories.length > 0) {
      const ordered = [...vendor.categories].sort((a, b) => (a.order || 0) - (b.order || 0));
      return base.concat(ordered.map(c => ({ id: c.id, label: c.label, icon: c.icon })));
    }
    const seen = new Set<string>();
    vendor.items.forEach(i => { if (i.category) seen.add(i.category); });
    return base.concat(Array.from(seen).map(id => ({ id, label: id, icon: 'box' })));
  }, [vendor]);

  const getFilteredItems = useCallback((): VendorItem[] => {
    if (!vendor) return [];
    
    if (activeCategory === 'all') {
      return vendor.items;
    }
    
    return vendor.items.filter(item => item.category === activeCategory);
  }, [vendor, activeCategory]);

  useEffect(() => {
    const cleanup = listenForNuiMessages((message) => {
      if (message.type === 'vendor:open' && message.vendor && message.stock) {
        setVendor(message.vendor);
        setStock(message.stock);
        setIsVisible(true);
        setIsOpening(true);
        if (message.limits) setLimits(message.limits);
        setCurrentTheme(message.vendor.theme || 1);
        
        setTimeout(() => {
          setIsOpening(false);
        }, 200);
      }
    });
    return cleanup;
  }, [listenForNuiMessages]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && isVisible) {
        handleClose();
      }
    };

    if (isVisible) {
      document.addEventListener('keydown', handleKeyDown);
      return () => document.removeEventListener('keydown', handleKeyDown);
    }
  }, [isVisible, handleClose]);

  if (!isVisible || !vendor) {
    return null;
  }

  return (
    <div className="fixed inset-0 flex items-center justify-center p-4 z-50">
          <div className={`${getThemeClasses('bg-bg rounded-sm')} shadow-2xl w-full max-w-7xl h-[75vh] overflow-hidden transition-opacity duration-200 ${isClosing ? 'opacity-0' : isOpening ? 'opacity-0' : 'opacity-100'}`}>
            <Header vendorName={vendor.label} onClose={handleClose} icon={vendor.icon} theme={currentTheme} />
        
        <div className="flex h-[calc(72vh)]">
          <div className="flex flex-col h-full">
            <CategorySidebar
              categories={getCategories()}
              activeCategory={activeCategory}
              onCategoryChange={setActiveCategory}
              theme={currentTheme}
            />
          </div>
          
          <ItemGrid
            items={getFilteredItems()}
            stock={stock}
            selectedItem={selectedItem}
            onItemSelect={setSelectedItem}
            onSell={handleSell}
            onBuy={handleBuy}
            isLoading={isLoading}
                sellResults={sellResults}
                limits={limits}
            theme={currentTheme}
          />
        </div>
      </div>
    </div>
  );
};

export default App;