"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WorkerStatusService = exports.WORKER_ID = void 0;
const supabaseClient_1 = require("./supabaseClient");
exports.WORKER_ID = "ticket-sync-worker";
class WorkerStatusService {
    /**
     * Initialize or update the status row.
     */
    static async updateStatus(updateData) {
        try {
            const { error } = await supabaseClient_1.supabase.from("worker_status").upsert({
                id: exports.WORKER_ID,
                updated_at: new Date().toISOString(),
                ...updateData,
            });
            if (error) {
                console.error(`[WorkerStatus] Failed to update status in database: ${error.message}`);
            }
        }
        catch (e) {
            console.error("[WorkerStatus] Failed to update status:", e);
        }
    }
    /** Set status to RUNNING. */
    static async setRunning() {
        console.log(`[WorkerStatus] Status set to RUNNING`);
        await this.updateStatus({
            status: "running",
            last_run: new Date().toISOString(),
        });
    }
    /** Set status to SUCCESS. */
    static async setSuccess(processedCount) {
        console.log(`[WorkerStatus] Status set to SUCCESS. Processed: ${processedCount}`);
        await this.updateStatus({
            status: "success",
            last_success: new Date().toISOString(),
            processed_count: processedCount,
            last_error: null,
            error_message: null,
        });
    }
    /** Set status to ERROR. */
    static async setError(errorMessage) {
        console.error(`[WorkerStatus] Status set to ERROR: ${errorMessage}`);
        await this.updateStatus({
            status: "error",
            last_error: new Date().toISOString(),
            error_message: errorMessage,
        });
    }
    /** Set status to IDLE (back to waiting). */
    static async setIdle() {
        await this.updateStatus({
            status: "idle",
        });
    }
}
exports.WorkerStatusService = WorkerStatusService;
//# sourceMappingURL=workerStatusService.js.map