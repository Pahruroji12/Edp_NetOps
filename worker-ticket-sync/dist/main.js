"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("./config");
const server_1 = require("./server");
const syncTicketEmail_1 = require("./syncTicketEmail");
const workerStatusService_1 = require("./workerStatusService");
/**
 * Cek apakah waktu sekarang berada dalam jam operasional.
 * Default: 06:00 - 22:30 (dikonfigurasi via WORKING_HOUR_START & WORKING_HOUR_END)
 */
function isWorkingHours() {
    const now = new Date();
    const currentTime = now.getHours() + now.getMinutes() / 60;
    return (currentTime >= config_1.CONFIG.workingHourStart &&
        currentTime <= config_1.CONFIG.workingHourEnd);
}
/**
 * Format jam operasional untuk display di console.
 */
function formatWorkingHours() {
    const startH = Math.floor(config_1.CONFIG.workingHourStart);
    const startM = Math.round((config_1.CONFIG.workingHourStart - startH) * 60);
    const endH = Math.floor(config_1.CONFIG.workingHourEnd);
    const endM = Math.round((config_1.CONFIG.workingHourEnd - endH) * 60);
    return `${String(startH).padStart(2, "0")}:${String(startM).padStart(2, "0")} - ${String(endH).padStart(2, "0")}:${String(endM).padStart(2, "0")}`;
}
/**
 * Helper retry dengan exponential backoff.
 * Jika fungsi gagal, akan dicoba ulang hingga maxRetries kali dengan jeda yang meningkat.
 */
async function withRetry(fn, label, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await fn();
        }
        catch (err) {
            const errMsg = err instanceof Error ? err.message : String(err);
            if (attempt === maxRetries) {
                console.error(`[Retry] ${label} gagal setelah ${maxRetries} percobaan: ${errMsg}`);
                throw err;
            }
            const delayMs = 2000 * attempt; // 2s, 4s, 6s
            console.warn(`[Retry] ${label} gagal (percobaan ${attempt}/${maxRetries}): ${errMsg}. Retry dalam ${delayMs / 1000}s...`);
            await new Promise((r) => setTimeout(r, delayMs));
        }
    }
    throw new Error("Unreachable");
}
async function runIntervalSync() {
    // ─── CEK JAM OPERASIONAL ───
    if (!isWorkingHours()) {
        const now = new Date();
        console.log(`[Scheduler] Di luar jam operasional (${formatWorkingHours()}). Sekarang ${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}. Skip sync.`);
        return;
    }
    console.log(`[Scheduler] Starting scheduled sync...`);
    await workerStatusService_1.WorkerStatusService.setRunning();
    try {
        // ─── RETRY: Otomatis coba ulang jika IMAP/Supabase gagal ───
        const updatedCount = await withRetry(() => (0, syncTicketEmail_1.syncTicketsFromEmail)(), "Ticket Sync");
        await workerStatusService_1.WorkerStatusService.setSuccess(updatedCount);
    }
    catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err);
        console.error(`[Scheduler Error]`, err);
        await workerStatusService_1.WorkerStatusService.setError(errMsg);
    }
    finally {
        await workerStatusService_1.WorkerStatusService.setIdle();
    }
}
async function main() {
    console.log("=========================================");
    console.log("  EDP NETOPS TICKET IMAP SYNC WORKER     ");
    console.log("=========================================");
    console.log(`Supabase URL: ${config_1.CONFIG.supabaseUrl}`);
    console.log(`Sync Interval: every ${config_1.CONFIG.syncIntervalMinutes} minutes`);
    console.log(`Jam Operasional: ${formatWorkingHours()}`);
    console.log("=========================================");
    // 1. Set initial state to idle in database
    try {
        await workerStatusService_1.WorkerStatusService.setIdle();
    }
    catch (e) {
        console.error("Failed to connect to Supabase or set worker status to idle. Continuing...", e);
    }
    // 2. Start HTTP Server for UI interaction (Port: 8080)
    (0, server_1.startHttpServer)();
    // 3. Run first sync immediately on boot (if within working hours)
    console.log("[Scheduler] Booting up: Running initial synchronization...");
    await runIntervalSync();
    // 4. Start periodic scheduler loop
    const intervalMs = config_1.CONFIG.syncIntervalMinutes * 60 * 1000;
    setInterval(async () => {
        await runIntervalSync();
    }, intervalMs);
    console.log(`[Scheduler] Scheduled task initialized to run every ${config_1.CONFIG.syncIntervalMinutes} minutes.`);
}
// Start application
main().catch((err) => {
    console.error("Fatal error starting worker:", err);
    process.exit(1);
});
//# sourceMappingURL=main.js.map