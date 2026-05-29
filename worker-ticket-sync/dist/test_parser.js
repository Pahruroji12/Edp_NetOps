"use strict";
function extractStoreCodes(text) {
    const matches = text.matchAll(/\b([A-Z][A-Z0-9]{3})\b/gi);
    const codes = new Set();
    for (const match of matches) {
        codes.add(match[1].toUpperCase());
    }
    return Array.from(codes);
}
function extractTicketNumber(provider, text) {
    const cleanProvider = provider.toLowerCase();
    if (cleanProvider === "astinet") {
        const match = text.match(/\b(TKT-\d+|INC\d+|IN\d+)\b/i);
        return match ? match[1].toUpperCase() : null;
    }
    if (cleanProvider === "icon") {
        const match = text.match(/\b(CS-\d+|ID-\d+|\d{9})\b/i);
        return match ? match[1].toUpperCase() : null;
    }
    if (cleanProvider === "fiberstar") {
        const match = text.match(/\b(FIB-\d+)\b/i);
        return match ? match[1].toUpperCase() : null;
    }
    const genericMatch = text.match(/\b(TKT-\d+|INC\d+|IN\d+|CS-\d+|ID-\d+|FIB-\d+|\d{9})\b/i);
    return genericMatch ? genericMatch[1].toUpperCase() : null;
}
const emailSubject = "Re: Mohon dibantu open tiket toko IDM Cab LEBAK - TGPJ RAYA SAMPAY CILELES";
const emailBody = `On 28 May 2026 07:23, Edp Net Lebak wrote:

Dengan hormat,Tim IT EDP IDM.

Terima kasih telah menghubungi EOS SDA Telkom dan mohon maaf atas ketidaknyamanannya.
Bersama ini kami sampaikan informasi sehubungan dengan gangguan layanan yang sedang Anda alami.

Nama Perusahaan/Customer: INDOMARCO PRISMATAMA TGPJ - RAYA SAMPAY CILELES
Nomor Layanan/Service ID: 1537053313
Nomor Tiket Gangguan: INC48679925 Indikasi Gangguan Berulang

Jika Anda memerlukan penjelasan lebih lanjut, silakan menghubungi EOS SDA Telkom atau ke Telkom Enhanced Enterprise Solution Assurance (TENESA) melalui telepon di nomor 0-800-1-835566 (bebas biaya), serta email: tenesa@telkom.co.id

Terimakasih,
Salam3S.`;
const searchString = `${emailSubject} ${emailBody}`;
const candidates = extractStoreCodes(searchString);
console.log("Candidate store codes found:", candidates);
const ticketNo = extractTicketNumber("Astinet", searchString);
console.log("Extracted ticket number:", ticketNo);
// Simulate matching with ticket in DB
const activeTickets = [
    {
        store_code: "TGPJ",
        store_name: "RAYA SAMPAY CILELES",
    }
];
const matched = activeTickets.filter(t => candidates.includes(t.store_code.toUpperCase()));
console.log("Matched tickets:", matched);
//# sourceMappingURL=test_parser.js.map