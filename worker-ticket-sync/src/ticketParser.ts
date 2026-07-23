/**
 * Extract store codes from email subject or body content.
 * Matches various code formats:
 *   - T567  (1 letter + 3 digits)
 *   - TGPJ  (4 letters)
 *   - FRS9  (mixed: 2-3 letters + 1-2 digits, total 4 chars)
 *   - T1LX  (mixed: letter-digit-letter-letter)
 */
export function extractStoreCodes(text: string): string[] {
  // Match semua kemungkinan kode toko 4 karakter (huruf+angka, minimal 1 huruf)
  const matches = text.matchAll(/\b([A-Z][A-Z0-9]{3})\b/gi);
  const codes = new Set<string>();

  // Filter: harus mengandung minimal 1 huruf (sudah dijamin oleh [A-Z] di awal)
  // dan bukan kata umum bahasa Indonesia/Inggris
  const excludedWords = new Set([
    "DARI", "DARI", "YANG", "KAMI", "ANDA", "AKAN", "BISA", "JUGA",
    "DARI", "YANG", "KAMI", "ANDA", "AKAN", "BISA", "JUGA", "SAAT",
    "LINK", "DOWN", "WITH", "FROM", "HAVE", "BEEN", "THIS", "ONLY",
    "THAT", "YOUR", "OPEN", "CASE", "MEMO", "INFO", "NOTE", "WORK",
    "DATA", "RUKO", "BLOK", "KOTA", "DESA", "JAWA", "RAYA", "JAUD",
    "TOKO", "ICON", "IMAP", "SMTP", "BARU", "LAMA", "BUKA", "TIAP",
    "AKTF", "CALL", "MAIL", "PLUS", "PORT", "USER", "PASS", "HOST",
    "JIKA", "MAKA", "TIPE", "COPY", "SEND", "SENT", "EDIT", "DONE",
    "ATAS", "BAWH", "BUAT", "SINI", "SANA", "LALU", "TAPI", "MAIN",
  ]);

  for (const match of matches) {
    const code = match[1].toUpperCase();
    if (!excludedWords.has(code)) {
      codes.add(code);
    }
  }
  return Array.from(codes);
}

/**
 * Extract store code from email subject or body content (returns first match).
 */
export function extractStoreCode(text: string): string | null {
  const codes = extractStoreCodes(text);
  return codes.length > 0 ? codes[0] : null;
}

/**
 * Extract ticket number based on provider type.
 */
export function extractTicketNumber(
  provider: string,
  text: string
): string | null {
  const cleanProvider = provider.toLowerCase();

  if (cleanProvider === "astinet") {
    // Telkom Astinet format: TKT-123456789 or INC12345678 or IN12345678
    const match = text.match(/\b(TKT-\d+|INC\d+|IN\d+)\b/i);
    return match ? match[1].toUpperCase() : null;
  }

  if (cleanProvider === "icon") {
    // Strategi: HANYA ambil dari kata kunci "No Ticket"
    // Alasan: prefix tiket ICON berubah-ubah tiap bulan (REW, REN, RRV, dll)
    //         jadi tidak bisa hardcode pattern prefix
    //
    // Keamanan: sync flow sudah memfilter berdasarkan kode toko (FRS9, T1LX, dll)
    //           jadi meskipun ada banyak email, tiket hanya diambil untuk toko yang cocok
    //
    // Format yang didukung:
    //   "( No Ticket RRV73GZY )"
    //   "No Ticket: CS-123456"
    //   "(NoTicket RENEXRH3)"
    const match = text.match(
      /(?:No\s+Ticket|NoTicket)\s*:?\s*\(??\s*([A-Z0-9][-A-Z0-9]{4,})/i
    );
    return match ? match[1].toUpperCase() : null;
  }

  if (cleanProvider === "fiberstar") {
    // Fiberstar format: FIB-123456
    const match = text.match(/\b(FIB-\d+)\b/i);
    return match ? match[1].toUpperCase() : null;
  }

  // Fallback pattern matching (generic)
  const genericMatch = text.match(
    /\b(TKT-\d+|INC\d+|IN\d+|CS-\d+|ID-\d+|FIB-\d+|[A-Z]{3}[A-Z0-9]{5}|\d{9})\b/i
  );
  return genericMatch ? genericMatch[1].toUpperCase() : null;
}
