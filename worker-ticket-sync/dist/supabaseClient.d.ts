import { Ticket, ImapConfig } from "./types";
export declare const supabase: import("@supabase/supabase-js").SupabaseClient<any, "public", "public", any, any>;
/**
 * Fetch all tickets that don't have a ticket number yet.
 */
export declare function getActiveTickets(): Promise<Ticket[]>;
/**
 * Update the ticket with the newly found ticket number.
 */
export declare function updateTicket(id: string, nomorTiket: string, status: string): Promise<void>;
/**
 * Batch fetch ALL processed email message IDs in a single query.
 * Returns a Set<string> for O(1) lookup performance.
 *
 * Optimasi: Menggantikan N request individual (isEmailProcessed per email)
 * dengan 1 batch query. Untuk 193 email = hemat 192 HTTP request per siklus.
 */
export declare function getProcessedEmailIds(): Promise<Set<string>>;
/**
 * Mark a message ID as processed in Supabase.
 */
export declare function markEmailAsProcessed(messageId: string): Promise<void>;
/**
 * Retrieve IMAP settings from the app_settings table.
 */
export declare function getImapConfigFromDb(): Promise<ImapConfig>;
//# sourceMappingURL=supabaseClient.d.ts.map