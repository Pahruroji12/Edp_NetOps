import { ImapConfig } from "./types";
export interface ParsedEmailMessage {
    uid: number;
    messageId: string;
    subject: string;
    bodyText: string;
    date: Date;
}
/**
 * Connect to IMAP and fetch recent emails using LIGHTWEIGHT mode.
 *
 * Optimasi bandwidth:
 * - Hanya mengambil envelope (subject, messageId, date) + bodyParts['1'] (text/plain).
 * - TIDAK mengunduh full source email (HTML, attachment, header lengkap).
 * - Estimasi penghematan: ~97% bandwidth dibanding source: true.
 *
 * @param config  IMAP configuration
 * @param daysToScan  Number of days to look back (default: 3)
 * @param skipMessageIds  Set of messageIds to skip (already processed)
 */
export declare function fetchRecentEmails(config: ImapConfig, daysToScan?: number, skipMessageIds?: Set<string>): Promise<ParsedEmailMessage[]>;
//# sourceMappingURL=imapClient.d.ts.map