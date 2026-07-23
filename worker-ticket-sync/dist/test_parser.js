"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const ticketParser_1 = require("./ticketParser");
// Test store code extraction
console.log("=== Test Store Code Extraction ===");
console.log("T567:", (0, ticketParser_1.extractStoreCodes)("toko T567 di Lebak")); // [T567]
console.log("TGPJ:", (0, ticketParser_1.extractStoreCodes)("toko TGPJ Raya")); // [TGPJ]
console.log("FRS9:", (0, ticketParser_1.extractStoreCodes)("toko FRS9 RUKO SEION")); // [FRS9]
console.log("T1LX:", (0, ticketParser_1.extractStoreCodes)("toko T1LX SADELI")); // [T1LX]
console.log("T119:", (0, ticketParser_1.extractStoreCodes)("toko T119 WARUNG JAUD")); // [T119]
// Test ICON cases
console.log("\n=== Test ICON Ticket Extraction ===");
const iconRRV = `
Nama Pelanggan : PT. INDOMARCO PRISMATAMA
1. INTERNET IIX (DOMESTIC) ONLY - IIX - - - (LEBAK)(FRS9)(RUKO SEION BLOK K2 NO 7 -001)
( No Ticket RRV73GZY )
( Open Ticket : 2026-07-20 17:52 WIB )
`;
console.log("RRV (dari screenshot):", (0, ticketParser_1.extractTicketNumber)("ICON", iconRRV));
// Expected: RRV73GZY
const iconREW = `
Nama Pelanggan : PT. INDOMARCO PRISMATAMA
( No Ticket REWRRQ36 )
`;
console.log("REW:", (0, ticketParser_1.extractTicketNumber)("ICON", iconREW));
// Expected: REWRRQ36
const iconREN = `
Nama Pelanggan : PT. INDOMARCO PRISMATAMA
( No Ticket RENEXRH3 )
`;
console.log("REN:", (0, ticketParser_1.extractTicketNumber)("ICON", iconREN));
// Expected: RENEXRH3
const iconCS = `(NoTicket: CS-123456789)`;
console.log("CS-:", (0, ticketParser_1.extractTicketNumber)("ICON", iconCS));
// Expected: CS-123456789
// Test Astinet
console.log("\n=== Test Astinet Ticket Extraction ===");
const astinetBody = `
Nomor Tiket Gangguan: INC48679925 Indikasi Gangguan Berulang
`;
console.log("INC:", (0, ticketParser_1.extractTicketNumber)("Astinet", astinetBody));
// Expected: INC48679925
// Test store code from ICON email subject
console.log("\n=== Test Store Code from ICON Subject ===");
const iconSubject = "[In Progress] Pengecekan Link Icon IIX toko FRS9 - RUKO SEION BLOK K2 NO 7 - 8 Terpantau Down";
console.log("Store codes from subject:", (0, ticketParser_1.extractStoreCodes)(iconSubject));
// Expected: should include FRS9
//# sourceMappingURL=test_parser.js.map