
import React from 'react';
import {
  AlertCircle,
  CheckCircle2,
  Clock,
  MessageSquare,
  Package,
  Truck,
  Settings,
  FileText,
  HelpCircle,
  AlertTriangle
} from 'lucide-react';
import { TicketStatus, TicketCategory } from './types';

export const STATUS_COLORS: Record<TicketStatus, string> = {
  [TicketStatus.NEW]: 'bg-blue-100 text-blue-700 border-blue-200',
  [TicketStatus.ACKNOWLEDGED]: 'bg-indigo-100 text-indigo-700 border-indigo-200',
  [TicketStatus.IN_PROGRESS]: 'bg-yellow-100 text-yellow-700 border-yellow-200',
  [TicketStatus.HOLD_FOR_INFO]: 'bg-purple-100 text-purple-700 border-purple-200',
  [TicketStatus.RESOLVED]: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  [TicketStatus.CLOSED]: 'bg-gray-100 text-gray-600 border-gray-200',
};

export const CATEGORY_ICONS: Record<TicketCategory, React.ReactNode> = {
  [TicketCategory.PRODUCT_QUALITY]: <AlertTriangle className="w-4 h-4" />,
  [TicketCategory.LOGISTICS]: <Truck className="w-4 h-4" />,
  [TicketCategory.TECHNICAL_SUPPORT]: <Settings className="w-4 h-4" />,
  [TicketCategory.COMMERCIAL]: <FileText className="w-4 h-4" />,
  [TicketCategory.GENERAL]: <HelpCircle className="w-4 h-4" />,
};
