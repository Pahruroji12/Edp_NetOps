/**
 * Extract store codes from email subject or body content.
 * Matches various code formats:
 *   - T567  (1 letter + 3 digits)
 *   - TGPJ  (4 letters)
 *   - FRS9  (mixed: 2-3 letters + 1-2 digits, total 4 chars)
 *   - T1LX  (mixed: letter-digit-letter-letter)
 */
export declare function extractStoreCodes(text: string): string[];
/**
 * Extract store code from email subject or body content (returns first match).
 */
export declare function extractStoreCode(text: string): string | null;
/**
 * Extract ticket number based on provider type.
 */
export declare function extractTicketNumber(provider: string, text: string): string | null;
//# sourceMappingURL=ticketParser.d.ts.map