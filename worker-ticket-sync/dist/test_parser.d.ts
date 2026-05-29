declare function extractStoreCodes(text: string): string[];
declare function extractTicketNumber(provider: string, text: string): string | null;
declare const emailSubject = "Re: Mohon dibantu open tiket toko IDM Cab LEBAK - TGPJ RAYA SAMPAY CILELES";
declare const emailBody = "On 28 May 2026 07:23, Edp Net Lebak wrote:\n\nDengan hormat,Tim IT EDP IDM.\n\nTerima kasih telah menghubungi EOS SDA Telkom dan mohon maaf atas ketidaknyamanannya.\nBersama ini kami sampaikan informasi sehubungan dengan gangguan layanan yang sedang Anda alami.\n\nNama Perusahaan/Customer: INDOMARCO PRISMATAMA TGPJ - RAYA SAMPAY CILELES\nNomor Layanan/Service ID: 1537053313\nNomor Tiket Gangguan: INC48679925 Indikasi Gangguan Berulang\n\nJika Anda memerlukan penjelasan lebih lanjut, silakan menghubungi EOS SDA Telkom atau ke Telkom Enhanced Enterprise Solution Assurance (TENESA) melalui telepon di nomor 0-800-1-835566 (bebas biaya), serta email: tenesa@telkom.co.id\n\nTerimakasih,\nSalam3S.";
declare const searchString = "Re: Mohon dibantu open tiket toko IDM Cab LEBAK - TGPJ RAYA SAMPAY CILELES On 28 May 2026 07:23, Edp Net Lebak wrote:\n\nDengan hormat,Tim IT EDP IDM.\n\nTerima kasih telah menghubungi EOS SDA Telkom dan mohon maaf atas ketidaknyamanannya.\nBersama ini kami sampaikan informasi sehubungan dengan gangguan layanan yang sedang Anda alami.\n\nNama Perusahaan/Customer: INDOMARCO PRISMATAMA TGPJ - RAYA SAMPAY CILELES\nNomor Layanan/Service ID: 1537053313\nNomor Tiket Gangguan: INC48679925 Indikasi Gangguan Berulang\n\nJika Anda memerlukan penjelasan lebih lanjut, silakan menghubungi EOS SDA Telkom atau ke Telkom Enhanced Enterprise Solution Assurance (TENESA) melalui telepon di nomor 0-800-1-835566 (bebas biaya), serta email: tenesa@telkom.co.id\n\nTerimakasih,\nSalam3S.";
declare const candidates: string[];
declare const ticketNo: string | null;
declare const activeTickets: {
    store_code: string;
    store_name: string;
}[];
declare const matched: {
    store_code: string;
    store_name: string;
}[];
//# sourceMappingURL=test_parser.d.ts.map