/**
 * Core ticket-email synchronization worker task.
 * Returns the number of updated tickets.
 *
 * Optimasi yang diterapkan:
 * 1. Batch fetch processed_emails (1 query vs N query per email)
 * 2. Skip email yang sudah diproses di level IMAP fetch (hemat bandwidth)
 * 3. Early return jika tidak ada tiket aktif (skip koneksi IMAP)
 */
export declare function syncTicketsFromEmail(): Promise<number>;
//# sourceMappingURL=syncTicketEmail.d.ts.map