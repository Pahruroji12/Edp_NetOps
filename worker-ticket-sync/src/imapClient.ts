import { ImapFlow } from "imapflow";
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
export async function fetchRecentEmails(
  config: ImapConfig,
  daysToScan: number = 3,
  skipMessageIds: Set<string> = new Set()
): Promise<ParsedEmailMessage[]> {
  const client = new ImapFlow({
    host: config.host,
    port: config.port,
    // Proteksi: Hanya port 993 yang menggunakan SSL/TLS implisit dari awal.
    // Jika port adalah 143 (atau non-993), paksa secure: false agar imapflow menggunakan 
    // koneksi plaintext dahulu lalu melakukan STARTTLS secara otomatis/oportunistik.
    // Ini mencegah error "tls_validate_record_header: wrong version number".
    secure: config.port === 993 ? true : false,
    auth: {
      user: config.user,
      pass: config.pass,
    },
    tls: {
      rejectUnauthorized: false, // Bypass expired or self-signed certificate validation
    },
    logger: false as any,
    // Timeout: mencegah koneksi hang tanpa batas
    connectionTimeout: 30_000,  // 30 detik timeout untuk koneksi awal
    greetingTimeout: 15_000,    // 15 detik timeout untuk greeting dari server
    socketTimeout: 60_000,      // 60 detik timeout untuk operasi socket
  });

  await client.connect();
  const lock = await client.getMailboxLock("INBOX");

  const parsedMessages: ParsedEmailMessage[] = [];
  let skippedCount = 0;

  try {
    // Calculate the date threshold
    const dateThreshold = new Date();
    dateThreshold.setDate(dateThreshold.getDate() - daysToScan);

    console.log(
      `[IMAP] Connected. Scanning INBOX for emails since ${dateThreshold.toLocaleDateString()}...`
    );

    // ─── Fetch envelope + beberapa text part ───
    // Email yang sudah di-reply berkali-kali (seperti ICON) bisa punya
    // struktur MIME berbeda: text/plain bisa di part "1", "1.1", "1.2", atau "2"
    // Kita fetch semua kemungkinan part dan gabungkan
    const messages = client.fetch(
      { since: dateThreshold },
      { envelope: true, uid: true, bodyParts: ["1", "1.1", "1.2", "2"] }
    );

    for await (const msg of messages) {
      try {
        // Extract messageId from envelope
        const messageId =
          (msg.envelope as any)?.messageId || `uid-${msg.uid}`;

        // ─── OPTIMASI: Skip email yang sudah diproses SEBELUM parsing body ───
        if (skipMessageIds.has(messageId)) {
          skippedCount++;
          continue;
        }

        // Extract subject and date from envelope (no parsing needed)
        const subject: string = (msg.envelope as any)?.subject || "";
        const date: Date = (msg.envelope as any)?.date
          ? new Date((msg.envelope as any).date)
          : new Date();

        // Gabungkan semua body parts yang tersedia
        let bodyText = "";
        if (msg.bodyParts) {
          for (const [, partBuffer] of msg.bodyParts) {
            if (partBuffer) {
              bodyText += partBuffer.toString("utf-8") + "\n";
            }
          }
        }

        parsedMessages.push({
          uid: msg.uid,
          messageId: messageId,
          subject: subject,
          bodyText: bodyText,
          date: date,
        });
      } catch (err) {
        console.error(`[IMAP] Failed to process email uid ${msg.uid}:`, err);
      }
    }

    if (skippedCount > 0) {
      console.log(
        `[IMAP] Skipped ${skippedCount} already-processed emails at IMAP level.`
      );
    }
  } finally {
    lock.release();
    await client.logout();
  }

  // Sort messages descending by date (newest first)
  return parsedMessages.sort((a, b) => b.date.getTime() - a.date.getTime());
}
