import {
  getActiveTickets,
  getImapConfigFromDb,
  getProcessedEmailIds,
  markEmailAsProcessed,
  updateTicket,
} from "./supabaseClient";
import { fetchRecentEmails } from "./imapClient";
import { extractStoreCodes, extractTicketNumber } from "./ticketParser";

/**
 * Core ticket-email synchronization worker task.
 * Returns the number of updated tickets.
 *
 * Optimasi yang diterapkan:
 * 1. Batch fetch processed_emails (1 query vs N query per email)
 * 2. Skip email yang sudah diproses di level IMAP fetch (hemat bandwidth)
 * 3. Early return jika tidak ada tiket aktif (skip koneksi IMAP)
 */
export async function syncTicketsFromEmail(): Promise<number> {
  // 1. Fetch active tickets from Supabase (where nomor_tiket is null/empty)
  const activeTickets = await getActiveTickets();
  console.log(
    `[Sync] Found ${activeTickets.length} active tickets waiting for ticket numbers.`
  );

  if (activeTickets.length === 0) {
    console.log("[Sync] No active tickets need updating. Skipping IMAP sync.");
    return 0;
  }

  // 2. ─── OPTIMASI: Batch fetch semua processed email IDs (1 query) ───
  const processedIds = await getProcessedEmailIds();
  console.log(
    `[Sync] Loaded ${processedIds.size} already-processed email IDs from database.`
  );

  // 3. Fetch IMAP config (from environment or database)
  const config = await getImapConfigFromDb();
  console.log(
    `[Sync] Connecting to IMAP server: ${config.host}:${config.port}`
  );

  // 4. Fetch recent emails (past 3 days) — skip already-processed at IMAP level
  const recentEmails = await fetchRecentEmails(config, 3, processedIds);
  console.log(
    `[Sync] Retrieved ${recentEmails.length} unprocessed emails from INBOX.`
  );

  if (recentEmails.length === 0) {
    console.log("[Sync] No new emails to process.");
    return 0;
  }

  let updatedCount = 0;

  // 5. Process emails and match with active tickets
  for (const email of recentEmails) {
    // A. Try extracting store codes from subject or body
    const searchString = `${email.subject} ${email.bodyText}`;
    const storeCodes = extractStoreCodes(searchString);
    if (storeCodes.length === 0) {
      continue;
    }

    // B. Check if any active ticket matches this store code
    const matchingTickets = activeTickets.filter(
      (t) => storeCodes.includes(t.store_code.toUpperCase()) && !t.nomor_tiket
    );

    if (matchingTickets.length === 0) {
      continue;
    }

    // C. Match provider and extract ticket number
    let matchedAny = false;
    for (const ticket of matchingTickets) {
      const ticketNumber = extractTicketNumber(ticket.provider, searchString);

      if (ticketNumber) {
        console.log(
          `[Sync] Match! Store: ${ticket.store_code}, Provider: ${ticket.provider} -> Ticket No: ${ticketNumber}`
        );

        // Update database (status becomes "In Progress")
        await updateTicket(ticket.id, ticketNumber, "In Progress");

        // Mark locally to prevent matching again
        ticket.nomor_tiket = ticketNumber;

        updatedCount++;
        matchedAny = true;
      }
    }

    // D. Save message ID so we don't scan this email again
    if (matchedAny) {
      await markEmailAsProcessed(email.messageId);
    }
  }

  return updatedCount;
}
