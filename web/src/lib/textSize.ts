export type TextSize = 'normal' | 'large' | 'larger';

export const TEXT_SIZE_STORAGE_KEY = 'bongo_text_size_v1';

export const TEXT_SIZE_OPTIONS: ReadonlyArray<{ value: TextSize; label: string }> = [
  { value: 'normal', label: 'Kawaida' },
  { value: 'large', label: 'Kubwa' },
  { value: 'larger', label: 'Kubwa zaidi' },
];

export function isTextSize(value: unknown): value is TextSize {
  return value === 'normal' || value === 'large' || value === 'larger';
}
