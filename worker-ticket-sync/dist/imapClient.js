"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fetchRecentEmails = fetchRecentEmails;
const imapflow_1 = require("imapflow");
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
async function fetchRecentEmails(config, daysToScan = 3, skipMessageIds = new Set()) {
    const client = new imapflow_1.ImapFlow({
        host: config.host,
        port: config.port,
        secure: config.secure,
        auth: {
            user: config.user,
            pass: config.pass,
        },
        tls: {
            rejectUnauthorized: false, // Bypass expired or self-signed certificate validation
        },
        logger: false,
    });
    await client.connect();
    const lock = await client.getMailboxLock("INBOX");
    const parsedMessages = [];
    let skippedCount = 0;
    try {
        // Calculate the date threshold
        const dateThreshold = new Date();
        dateThreshold.setDate(dateThreshold.getDate() - daysToScan);
        console.log(`[IMAP] Connected. Scanning INBOX for emails since ${dateThreshold.toLocaleDateString()}...`);
        // ─── OPTIMASI: Fetch hanya envelope + text part (BUKAN full source) ───
        // envelope = subject, messageId, date, from, to (~0.5 KB per email)
        // bodyParts['1'] = text/plain content saja (~1-5 KB per email)
        // vs source: true = seluruh email termasuk HTML + attachment (~50-200 KB per email)
        const messages = client.fetch({ since: dateThreshold }, { envelope: true, uid: true, bodyParts: ["1"] });
        for await (const msg of messages) {
            try {
                // Extract messageId from envelope
                const messageId = msg.envelope?.messageId || `uid-${msg.uid}`;
                // ─── OPTIMASI: Skip email yang sudah diproses SEBELUM parsing body ───
                if (skipMessageIds.has(messageId)) {
                    skippedCount++;
                    continue;
                }
                // Extract subject and date from envelope (no parsing needed)
                const subject = msg.envelope?.subject || "";
                const date = msg.envelope?.date
                    ? new Date(msg.envelope.date)
                    : new Date();
                // Extract text body from bodyParts (lightweight, text/plain only)
                let bodyText = "";
                if (msg.bodyParts) {
                    const textPart = msg.bodyParts.get("1");
                    if (textPart) {
                        bodyText = textPart.toString("utf-8");
                    }
                }
                parsedMessages.push({
                    uid: msg.uid,
                    messageId: messageId,
                    subject: subject,
                    bodyText: bodyText,
                    date: date,
                });
            }
            catch (err) {
                console.error(`[IMAP] Failed to process email uid ${msg.uid}:`, err);
            }
        }
        if (skippedCount > 0) {
            console.log(`[IMAP] Skipped ${skippedCount} already-processed emails at IMAP level.`);
        }
    }
    finally {
        lock.release();
        await client.logout();
    }
    // Sort messages descending by date (newest first)
    return parsedMessages.sort((a, b) => b.date.getTime() - a.date.getTime());
}
//# sourceMappingURL=imapClient.js.map