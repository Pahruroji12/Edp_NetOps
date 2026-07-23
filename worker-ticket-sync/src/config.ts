import * as dotenv from "dotenv";
import * as path from "path";

// Load environment variables from .env file (try process.cwd() first, then relative path)
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, "../.env") });

export const CONFIG = {
  supabaseUrl: process.env.SUPABASE_URL || "",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",

  // ─── Auth: Login sebagai user biasa (menghormati RLS) ───
  supabaseUserEmail: process.env.SUPABASE_USER_EMAIL || "",
  supabaseUserPassword: process.env.SUPABASE_USER_PASSWORD || "",

  port: parseInt(process.env.PORT || "8080", 10),
  syncIntervalMinutes: parseInt(process.env.SYNC_INTERVAL_MINUTES || "10", 10),

  // ─── Jam Operasional (default: 06:00 - 22:30) ───
  // Di luar jam ini, worker akan skip sync untuk menghemat bandwidth
  workingHourStart: parseFloat(process.env.WORKING_HOUR_START || "6"),
  workingHourEnd: parseFloat(process.env.WORKING_HOUR_END || "22.5"), // 22.5 = 22:30

  // Optional IMAP Env variables (can override db configuration)
  imapHost: process.env.IMAP_HOST,
  imapPort: process.env.IMAP_PORT
    ? parseInt(process.env.IMAP_PORT, 10)
    : undefined,
  imapUser: process.env.IMAP_USER,
  imapPass: process.env.IMAP_PASS,
  imapSecure: process.env.IMAP_SECURE === "true",
};

// Validate critical parameters
if (!CONFIG.supabaseUrl || !CONFIG.supabaseAnonKey) {
  console.warn(
    "WARNING: SUPABASE_URL and SUPABASE_ANON_KEY are not set in environment variables! " +
      "Supabase integration will fail."
  );
}

if (!CONFIG.supabaseUserEmail || !CONFIG.supabaseUserPassword) {
  console.warn(
    "WARNING: SUPABASE_USER_EMAIL and SUPABASE_USER_PASSWORD are not set! " +
      "Worker cannot authenticate with Supabase."
  );
}
