export interface VendorItem {
  name: string;
  label: string;
  price: number;
  category?: string;
  limitPerPlayer?: number;
  limitGlobal?: number;
  buyPrice?: number;
  jobRequirement?: { job: string; minGrade: number };
}

export interface Vendor {
  id: string;
  label: string;
  icon?: string;
  model: string;
  coords: {
    x: number;
    y: number;
    z: number;
  };
  heading: number;
  scenario?: string;
  theme?: number;
  categories?: { id: string; label: string; icon: string; order: number }[];
  items: VendorItem[];
}

export interface VendorData {
  vendor: Vendor;
  stock: Record<string, number>;
  limits?: Record<string, { remainingPlayer?: number; remainingGlobal?: number; cooldownMs?: number }>;
}

export interface CartItem {
  item: VendorItem;
  quantity: number;
  available: number;
}

export interface PaymentMethod {
  id: string;
  label: string;
  icon: string;
}

export interface SellResult {
  success: boolean;
  message: string;
  paid?: number;
  left?: number;
}

export interface NuiMessage {
  type: string;
  vendor?: Vendor;
  stock?: Record<string, number>;
  limits?: Record<string, { remainingPlayer?: number; remainingGlobal?: number; cooldownMs?: number }>;
}

export interface Category {
  id: string;
  label: string;
  icon: string;
}

export interface NuiCallbackData {
  vendorId?: string;
  name?: string;
  quantity?: number;
}
