export const isEmail = (value: string) =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());

export const isStrongPassword = (value: string) =>
  value.length >= 8 && /[A-Z]/.test(value) && /\d/.test(value);
