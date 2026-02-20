export interface LocalizedString {
  ru: string;
  en: string;
}

export interface Category {
  id?: string;
  order: number;
  isVisible: boolean;
  isPaid: boolean;
  iapProductId?: string | null;
  priceRub?: number | null; // для отображения в UI/админке
  title: LocalizedString;
  tabIconAssetPath: string; // Storage path (или legacy url)
  heroImageAssetPath?: string;
  heroVideoAssetPath?: string;
  backgroundColorHex?: string;
  gridCardStyle?: {
    backgroundColor?: string;
    cornerRadius?: number;
  };
}

export interface Animal {
  id?: string;
  order: number;
  isVisible: boolean;
  name: LocalizedString;
  topText?: LocalizedString; // текст сверху на странице животного
  bgAssetPath: string;
  bgVideoAssetPath?: string; // mp4 фон (Storage path или legacy url)
  previewAssetPath: string;
  voiceAssetPath?: {
    ru?: string;
    en?: string;
  };
  soundAssetPath: string;
  animationAssetPath?: string;
  animationVideoAssetPath?: string;
}

export interface OfferItem {
  label: LocalizedString;
  productId: string;
  badge?: LocalizedString;
}

export interface Offer {
  id?: string;
  isActive: boolean;
  title: LocalizedString;
  heroAssets: string[];
  items: OfferItem[];
  primaryProductId: string;
}

export interface ParentalTest {
  id?: string;
  order: number;
  isActive: boolean;
  left: number;
  right: number;
  operator: '+' | '-';
  answers: number[];
  correctAnswer: number;
}

export interface Promotion {
  id?: string;
  order: number;
  isActive: boolean;
  title: LocalizedString;
  message: LocalizedString;
  discountPercent: number;
  target: 'all' | 'device';
  deviceIds: string[];
  startsAt?: string | null;
  endsAt?: string | null;
}

export interface OnboardingSlide {
  id?: string;
  order: number;
  isActive: boolean;
  title?: LocalizedString;
  subtitle?: LocalizedString;
  imageAssetPath: string;
  backgroundColorHex?: string;
}
