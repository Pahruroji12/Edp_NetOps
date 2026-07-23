"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabase = void 0;
exports.initAuth = initAuth;
exports.getActiveTickets = getActiveTickets;
exports.updateTicket = updateTicket;
exports.getProcessedEmailIds = getProcessedEmailIds;
exports.markEmailAsProcessed = markEmailAsProcessed;
exports.getImapConfigFromDb = getImapConfigFromDb;
const supabase_js_1 = require("@supabase/supabase-js");
const config_1 = require("./config");
// ── Supabase Client (menggunakan anon key, bukan service role key) ──
// Auth dilakukan via signInWithPassword di initAuth()
exports.supabase = (0, supabase_js_1.createClient)(config_1.CONFIG.supabaseUrl, config_1.CONFIG.supabaseAnonKey, {
    auth: {
        persistSession: false,
        autoRefreshToken: true,
    },
});
/**
 * Login ke Supabase sebagai user biasa.
 * Dipanggil 1x saat worker boot. SDK akan auto-refresh token.
 */
async function initAuth() {
    const { data, error } = await exports.supabase.auth.signInWithPassword({
        email: config_1.CONFIG.supabaseUserEmail,
        password: config_1.CONFIG.supabaseUserPassword,
    });
    if (error) {
        throw new Error(`[Auth] Login gagal: ${error.message}`);
    }
    console.log(`[Auth] Berhasil login sebagai ${data.user?.email}`);
}
/**
 * Fetch all tickets that don't have a ticket number yet.
 */
async function getActiveTickets() {
    const { data, error } = await exports.supabase
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
async function updateTicket(id, nomorTiket, status) {
    const { error } = await exports.supabase
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
async function getProcessedEmailIds() {
    const { data, error } = await exports.supabase
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
async function markEmailAsProcessed(messageId) {
    const { error } = await exports.supabase
        .from("processed_emails")
        .insert({ message_id: messageId });
    if (error) {
        console.error(`Error saving processed email message ID: ${error.message}`);
    }
}
/**
 * Retrieve IMAP settings from the app_settings table.
 */
async function getImapConfigFromDb() {
    // First, check if configured in ENV
    if (config_1.CONFIG.imapHost && config_1.CONFIG.imapPort && config_1.CONFIG.imapUser && config_1.CONFIG.imapPass) {
        return {
            host: config_1.CONFIG.imapHost,
            port: config_1.CONFIG.imapPort,
            user: config_1.CONFIG.imapUser,
            pass: config_1.CONFIG.imapPass,
            secure: config_1.CONFIG.imapSecure,
        };
    }
    const { data, error } = await exports.supabase
        .from("app_settings")
        .select("key, value");
    if (error) {
        throw new Error(`Failed to fetch app_settings: ${error.message}`);
    }
    const cfg = {};
    for (const row of data || []) {
        cfg[row.key] = row.value;
    }
    const host = cfg["imap_host"] || "imap.gmail.com";
    const port = parseInt(cfg["imap_port"] || "993", 10);
    const user = cfg["imap_user"] || "";
    const pass = cfg["imap_pass"] || "";
    const secure = port === 993;
    if (!user || !pass) {
        throw new Error("IMAP configuration is incomplete! Please set in environment or fill 'imap_user' and 'imap_pass' in app_settings table.");
    }
    return { host, port, user, pass, secure };
}
//# sourceMappingURL=supabaseClient.js.map