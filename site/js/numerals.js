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
