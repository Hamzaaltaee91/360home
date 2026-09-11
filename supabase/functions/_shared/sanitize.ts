// Shared input sanitization helpers for Edge Functions.
// Pure functions so they can be unit-tested without a live client.

const CONTROL_CHARS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g;
const SCRIPT_TAGS = /<\s*\/?\s*(script|style|iframe|object|embed|link|meta)\b[^>]*>/gi;
const HTML_TAGS = /<\/?[a-z][^>]*>/gi;
const EVENT_HANDLERS = /\son[a-z]+\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)/gi;
const DANGEROUS_PROTOCOLS = /(javascript|data|vbscript)\s*:/gi;

export const DEFAULT_MAX_LENGTH = 2000;

/**
 * Sanitize a single string:
 * - coerce non-strings to "" (or String(value) when `coerce` is true)
 * - strip control characters
 * - strip script/style/iframe tags and inline event handlers
 * - strip dangerous URL protocols
 * - trim and cap length
 */
export function sanitizeString(
  value: unknown,
  maxLength: number = DEFAULT_MAX_LENGTH
): string {
  if (value === null || value === undefined) return "";
  const raw = typeof value === "string" ? value : String(value);

  const cleaned = raw
    .replace(CONTROL_CHARS, "")
    .replace(SCRIPT_TAGS, "")
    .replace(EVENT_HANDLERS, "")
    .replace(DANGEROUS_PROTOCOLS, "")
    .replace(HTML_TAGS, "")
    .trim();

  return cleaned.length > maxLength ? cleaned.slice(0, maxLength) : cleaned;
}

/** Sanitize and lowercase an email address. Returns "" when invalid. */
export function sanitizeEmail(value: unknown): string {
  const email = sanitizeString(value, 320).toLowerCase();
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email) ? email : "";
}

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Validate a UUID string. Returns "" when invalid. */
export function sanitizeUuid(value: unknown): string {
  const id = sanitizeString(value, 64);
  return UUID_PATTERN.test(id) ? id.toLowerCase() : "";
}

/** Restrict a value to a known allow-list of enum values. */
export function sanitizeEnum<T extends string>(
  value: unknown,
  allowed: readonly T[],
  fallback?: T
): T | undefined {
  const candidate = sanitizeString(value, 64);
  if ((allowed as readonly string[]).includes(candidate)) {
    return candidate as T;
  }
  return fallback;
}

/** Parse a finite number, clamped to [min, max]. Returns undefined when invalid. */
export function sanitizeNumber(
  value: unknown,
  options: { min?: number; max?: number } = {}
): number | undefined {
  const num = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(num)) return undefined;
  let result = num;
  if (options.min !== undefined && result < options.min) result = options.min;
  if (options.max !== undefined && result > options.max) result = options.max;
  return result;
}

/** Parse a finite integer, clamped to [min, max]. Returns undefined when invalid. */
export function sanitizeInt(
  value: unknown,
  options: { min?: number; max?: number } = {}
): number | undefined {
  const num = sanitizeNumber(value, options);
  return num === undefined ? undefined : Math.trunc(num);
}

/** Coerce a value to a boolean. */
export function sanitizeBoolean(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const v = value.trim().toLowerCase();
    return v === "true" || v === "1" || v === "yes";
  }
  if (typeof value === "number") return value !== 0;
  return false;
}

/** Sanitize an array of strings, dropping empties and capping the count. */
export function sanitizeStringArray(
  value: unknown,
  options: { maxItems?: number; maxLength?: number } = {}
): string[] {
  if (!Array.isArray(value)) return [];
  const maxItems = options.maxItems ?? 50;
  const maxLength = options.maxLength ?? DEFAULT_MAX_LENGTH;
  return value
    .slice(0, maxItems)
    .map((item) => sanitizeString(item, maxLength))
    .filter((item) => item.length > 0);
}

/**
 * Recursively sanitize an object's string values.
 * Arrays are sanitized element-wise; nested objects are recursed.
 * Non-string primitives are passed through unchanged.
 */
export function sanitizeObject<T = Record<string, unknown>>(input: unknown): T {
  if (Array.isArray(input)) {
    return input.map((item) => sanitizeObject(item)) as unknown as T;
  }
  if (input !== null && typeof input === "object") {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(input as Record<string, unknown>)) {
      result[sanitizeString(key, 128)] = sanitizeObject(value);
    }
    return result as T;
  }
  if (typeof input === "string") {
    return sanitizeString(input) as unknown as T;
  }
  return input as T;
}
