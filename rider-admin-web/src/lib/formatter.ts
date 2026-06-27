import { env } from "@/config/env";

export const formatCurrency = (
  amount: number,
  currency = env.defaultCurrency,
  locale = env.defaultLocale,
) =>
  new Intl.NumberFormat(locale, {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(amount);

export const formatNumber = (value: number, locale = env.defaultLocale) =>
  new Intl.NumberFormat(locale).format(value);

export const formatDate = (
  value: string | number | Date,
  locale = env.defaultLocale,
) =>
  new Intl.DateTimeFormat(locale, {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(value));

export const formatDateTime = (
  value: string | number | Date,
  locale = env.defaultLocale,
) =>
  new Intl.DateTimeFormat(locale, {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));

export const formatPercentage = (value: number) => `${value.toFixed(1)}%`;
