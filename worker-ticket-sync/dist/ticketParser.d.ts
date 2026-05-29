/**
 * Extract store codes from email subject or body content.
 * Matches code format like T567 (letter + 3 digits) or TGPJ (4 letters).
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