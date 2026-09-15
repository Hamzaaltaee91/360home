// Maps Arabic-Indic digits (U+0660 .. U+0669) to Western digits 0-9.
// Every other character is returned unchanged.

const ARABIC_INDIC_ZERO = 0x0660;
const ARABIC_INDIC_NINE = 0x0669;
const WESTERN_ZERO = 0x0030;

export function toWesternDigits(str) {
  let result = '';
  for (let i = 0; i < str.length; i++) {
    const code = str.charCodeAt(i);
    result +=
      code >= ARABIC_INDIC_ZERO && code <= ARABIC_INDIC_NINE
        ? String.fromCharCode(code - ARABIC_INDIC_ZERO + WESTERN_ZERO)
        : str[i];
  }
  return result;
}

// Inserts Western-digit thousands separators (commas) every 3 digits
// from the right. Non-digit characters are dropped first, so Arabic-Indic
// digits, spaces and stray punctuation are tolerated.
// `750000` -> `'750,000'`; `''`, `null`, `'abc'` -> `''`.

export function formatThousands(value) {
  const digits = toWesternDigits(String(value)).replace(/[^0-9]/g, '');
  if (digits === '') return '';
  return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Removes comma characters from a numeric string and normalises any
// Arabic-Indic digits to Western ones.
// `'750,000'` -> `'750000'`.

export function stripThousands(str) {
  return toWesternDigits(String(str)).replace(/,/g, '');
}
