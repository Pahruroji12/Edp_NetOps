"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.extractStoreCodes = extractStoreCodes;
exports.extractStoreCode = extractStoreCode;
exports.extractTicketNumber = extractTicketNumber;
/**
 * Extract store codes from email subject or body content.
 * Matches code format like T567 (letter + 3 digits) or TGPJ (4 letters).
 */
function extractStoreCodes(text) {
    const matches = text.matchAll(/\b([A-Z]\d{3}|[A-Z]{4})\b/gi);
    const codes = new Set();
    for (const match of matches) {
        codes.add(match[1].toUpperCase());
    }
    return Array.from(codes);
}
/**
 * Extract store code from email subject or body content (returns first match).
 */
function extractStoreCode(text) {
    const codes = extractStoreCodes(text);
    return codes.length > 0 ? codes[0] : null;
}
/**
 * Extract ticket number based on provider type.
 */
function extractTicketNumber(provider, text) {
    const cleanProvider = provider.toLowerCase();
    if (cleanProvider === "astinet") {
        // Telkom Astinet format: TKT-123456789 or INC12345678 or IN12345678
        const match = text.match(/\b(TKT-\d+|INC\d+|IN\d+)\b/i);
        return match ? match[1].toUpperCase() : null;
    }
    if (cleanProvider === "icon") {
        // 1. Cari setelah kata "No Ticket" (misal: "( No Ticket REWRRQ36 )" atau "No Ticket: CS-123456")
        const prefixMatch = text.match(/(?:No\s+Ticket|NoTicket)\s*:?\s*\b([A-Z0-9-]+)\b/i);
        if (prefixMatch) {
            return prefixMatch[1].toUpperCase();
        }
        // 2. Fallback menggunakan format lama jika kata "No Ticket" tidak ditemukan
        const match = text.match(/\b(REW[A-Z0-9]{5}|CS-\d+|ID-\d+|\d{9})\b/i);
        return match ? match[1].toUpperCase() : null;
    }
    if (cleanProvider === "fiberstar") {
        // Fiberstar format: FIB-123456
        const match = text.match(/\b(FIB-\d+)\b/i);
        return match ? match[1].toUpperCase() : null;
    }
    // Fallback pattern matching
    const genericMatch = text.match(/\b(TKT-\d+|INC\d+|IN\d+|CS-\d+|ID-\d+|FIB-\d+|REW[A-Z0-9]{5}|\d{9})\b/i);
    return genericMatch ? genericMatch[1].toUpperCase() : null;
}
//# sourceMappingURL=ticketParser.js.map