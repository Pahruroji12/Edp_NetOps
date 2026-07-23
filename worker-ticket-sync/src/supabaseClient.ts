import { createClient } from "@supabase/supabase-js";
import { CONFIG } from "./config";
import { Ticket, ImapConfig } from "./types";

// ── Supabase Client (menggunakan anon key, bukan service role key) ──
// Auth dilakukan via signInWithPassword di initAuth()
export const supabase = createClient(
  CONFIG.supabaseUrl,
  CONFIG.supabaseAnonKey,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: true,
    },
  }
);

/**
 * Login ke Supabase sebagai user biasa.
 * Dipanggil 1x saat worker boot. SDK akan auto-refresh token.
 */
export async function initAuth(): Promise<void> {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: CONFIG.supabaseUserEmail,
    password: CONFIG.supabaseUserPassword,
  });

  if (error) {
    throw new Error(`[Auth] Login gagal: ${error.message}`);
  }

  console.log(`[Auth] Berhasil login sebagai ${data.user?.email}`);
}

/**
 * Fetch all tickets that don't have a ticket number yet.
 */
export async function getActiveTickets(): Promise<Ticket[]> {
  const { data, error } = await supabase
    .from("ticket_logs")
    .select("*")
    .or("nomor_tiket.is.null,nomor_tiket.eq.");

  if (error) {
    throw new Error(`Failed to fetch active tickets: ${error.message}`);
  }

  return data || [];
}

/**
 * Update the ticket with the newly found ticket number.
 */
export async function updateTicket(
  id: string,
  nomorTiket: string,
  status: string
): Promise<void> {
  const { error } = await supabase
    .from("ticket_logs")
    .update({
      nomor_tiket: nomorTiket,
      status: status,
    })
    .eq("id", id);

  if (error) {
    throw new Error(`Failed to update ticket ${id}: ${error.message}`);
  }
}

/**
 * Batch fetch ALL processed email message IDs in a single query.
 * Returns a Set<string> for O(1) lookup performance.
 *
 * Optimasi: Menggantikan N request individual (isEmailProcessed per email)
 * dengan 1 batch query. Untuk 193 email = hemat 192 HTTP request per siklus.
 */
export async function getProcessedEmailIds(): Promise<Set<string>> {
  const { data, error } = await supabase
    .from("processed_emails")
    .select("message_id");

  if (error) {
    console.error(`Error fetching processed email IDs: ${error.message}`);
    return new Set();
  }

  return new Set((data || []).map((d) => d.message_id));
}

/**
 * Mark a message ID as processed in Supabase.
 */
export async function markEmailAsProcessed(messageId: string): Promise<void> {
  const { error } = await supabase
    .from("processed_emails")
    .insert({ message_id: messageId });

  if (error) {
    console.error(
      `Error saving processed email message ID: ${error.message}`
    );
  }
}

/**
 * Retrieve IMAP settings from the app_settings table.
 */
export async function getImapConfigFromDb(): Promise<ImapConfig> {
  // First, check if configured in ENV
  if (CONFIG.imapHost && CONFIG.imapPort && CONFIG.imapUser && CONFIG.imapPass) {
    return {
      host: CONFIG.imapHost,
      port: CONFIG.imapPort,
      user: CONFIG.imapUser,
      pass: CONFIG.imapPass,
      secure: CONFIG.imapSecure,
    };
  }

  const { data, error } = await supabase
    .from("app_settings")
    .select("key, value");

  if (error) {
    throw new Error(`Failed to fetch app_settings: ${error.message}`);
  }

  const cfg: Record<string, string> = {};
  for (const row of data || []) {
    cfg[row.key] = row.value;
  }

  const host = cfg["imap_host"] || "imap.gmail.com";
  const port = parseInt(cfg["imap_port"] || "993", 10);
  const user = cfg["imap_user"] || "";
  const pass = cfg["imap_pass"] || "";
  const secure = port === 993;

  if (!user || !pass) {
    throw new Error(
      "IMAP configuration is incomplete! Please set in environment or fill 'imap_user' and 'imap_pass' in app_settings table."
    );
  }

  return { host, port, user, pass, secure };
}
