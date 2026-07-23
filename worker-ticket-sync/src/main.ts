import { CONFIG } from "./config";
import { startHttpServer } from "./server";
import { syncTicketsFromEmail } from "./syncTicketEmail";
import { initAuth } from "./supabaseClient";
import { WorkerStatusService } from "./workerStatusService";

/**
 * Cek apakah waktu sekarang berada dalam jam operasional.
 * Default: 06:00 - 22:30 (dikonfigurasi via WORKING_HOUR_START & WORKING_HOUR_END)
 */
function isWorkingHours(): boolean {
  const now = new Date();
  const currentTime = now.getHours() + now.getMinutes() / 60;
  return (
    currentTime >= CONFIG.workingHourStart &&
    currentTime <= CONFIG.workingHourEnd
  );
}

/**
 * Format jam operasional untuk display di console.
 */
function formatWorkingHours(): string {
  const startH = Math.floor(CONFIG.workingHourStart);
  const startM = Math.round((CONFIG.workingHourStart - startH) * 60);
  const endH = Math.floor(CONFIG.workingHourEnd);
  const endM = Math.round((CONFIG.workingHourEnd - endH) * 60);
  return `${String(startH).padStart(2, "0")}:${String(startM).padStart(2, "0")} - ${String(endH).padStart(2, "0")}:${String(endM).padStart(2, "0")}`;
}

/**
 * Helper retry dengan exponential backoff.
 * Jika fungsi gagal, akan dicoba ulang hingga maxRetries kali dengan jeda yang meningkat.
 */
async function withRetry<T>(
  fn: () => Promise<T>,
  label: string,
  maxRetries: number = 3
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      if (attempt === maxRetries) {
        console.error(
          `[Retry] ${label} gagal setelah ${maxRetries} percobaan: ${errMsg}`
        );
        throw err;
      }
      const delayMs = 2000 * attempt; // 2s, 4s, 6s
      console.warn(
        `[Retry] ${label} gagal (percobaan ${attempt}/${maxRetries}): ${errMsg}. Retry dalam ${delayMs / 1000}s...`
      );
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw new Error("Unreachable");
}

async function runIntervalSync(): Promise<void> {
  // ─── CEK JAM OPERASIONAL ───
  if (!isWorkingHours()) {
    const now = new Date();
    console.log(
      `[Scheduler] Di luar jam operasional (${formatWorkingHours()}). Sekarang ${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}. Skip sync.`
    );
    return;
  }

  console.log(`[Scheduler] Starting scheduled sync...`);

  await WorkerStatusService.setRunning();
  try {
    // ─── TIMEOUT GLOBAL: Jika seluruh proses sync melebihi 2 menit, batalkan ───
    const SYNC_TIMEOUT_MS = 2 * 60 * 1000; // 2 menit
    const timeoutPromise = new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error("Sync timeout: proses melebihi 2 menit")), SYNC_TIMEOUT_MS)
    );

    const syncPromise = withRetry(
      () => syncTicketsFromEmail(),
      "Ticket Sync"
    );

    const updatedCount = await Promise.race([syncPromise, timeoutPromise]);
    await WorkerStatusService.setSuccess(updatedCount);
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : String(err);
    console.error(`[Scheduler Error]`, err);
    await WorkerStatusService.setError(errMsg);
  } finally {
    await WorkerStatusService.setIdle();
  }
}

async function main(): Promise<void> {
  console.log("=========================================");
  console.log("  EDP NETOPS TICKET IMAP SYNC WORKER     ");
  console.log("=========================================");
  console.log(`Supabase URL: ${CONFIG.supabaseUrl}`);
  console.log(`Sync Interval: every ${CONFIG.syncIntervalMinutes} minutes`);
  console.log(`Jam Operasional: ${formatWorkingHours()}`);
  console.log("=========================================");

  // 1. Login ke Supabase sebagai user (menghormati RLS)
  await initAuth();

  // 2. Set initial state to idle in database
  try {
    await WorkerStatusService.setIdle();
  } catch (e) {
    console.error(
      "Failed to connect to Supabase or set worker status to idle. Continuing...",
      e
    );
  }

  // 3. Start HTTP Server for UI interaction (Port: 8080)
  startHttpServer();

  // 4. Run first sync immediately on boot (if within working hours)
  console.log("[Scheduler] Booting up: Running initial synchronization...");
  await runIntervalSync();

  // 5. Start periodic scheduler loop
  const intervalMs = CONFIG.syncIntervalMinutes * 60 * 1000;
  setInterval(async () => {
    await runIntervalSync();
  }, intervalMs);

  console.log(
    `[Scheduler] Scheduled task initialized to run every ${CONFIG.syncIntervalMinutes} minutes.`
  );
}

// Start application
main().catch((err) => {
  console.error("Fatal error starting worker:", err);
  process.exit(1);
});
