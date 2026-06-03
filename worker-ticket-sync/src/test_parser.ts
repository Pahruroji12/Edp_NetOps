import { extractStoreCodes, extractTicketNumber } from "./ticketParser";

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
console.log("Extracted ticket number (Astinet):", ticketNo);

// Test ICON cases
console.log("\n--- Testing ICON cases ---");
const iconEmailBody1 = `
Nama Pelanggan : PT. INDOMARCO PRISMATAMA
1. INTERNET CORPORATE LITE : 0 - (LEBAK) (TOLY) (MEKAR AGUNG LEBAK)
( No Ticket REWRRQ36 )
`;
console.log("ICON Case 1 (REW):", extractTicketNumber("ICON", iconEmailBody1)); // Expected: REWRRQ36

const iconEmailBody2 = `
Nama Pelanggan : PT. INDOMARCO PRISMATAMA
( No Ticket RENEXRH3 )
`;
console.log("ICON Case 2 (REN):", extractTicketNumber("ICON", iconEmailBody2)); // Expected: RENEXRH3

const iconEmailBody3 = `
(NoTicket: CS-123456789)
`;
console.log("ICON Case 3 (CS- with colon):", extractTicketNumber("ICON", iconEmailBody3)); // Expected: CS-123456789

const iconEmailBody4 = `
Nomor tiket gangguan Anda adalah ID-987654321
`;
console.log("ICON Case 4 (Fallback ID-):", extractTicketNumber("ICON", iconEmailBody4)); // Expected: ID-987654321
