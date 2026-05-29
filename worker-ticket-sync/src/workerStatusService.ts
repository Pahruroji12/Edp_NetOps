import { supabase } from "./supabaseClient";

export const WORKER_ID = "ticket-sync-worker";

export class WorkerStatusService {
  /**
   * Initialize or update the status row.
   */
  private static async updateStatus(
    updateData: Record<string, unknown>
  ): Promise<void> {
    try {
      const { error } = await supabase.from("worker_status").upsert({
        id: WORKER_ID,
        updated_at: new Date().toISOString(),
        ...updateData,
      });

      if (error) {
        console.error(
          `[WorkerStatus] Failed to update status in database: ${error.message}`
        );
      }
    } catch (e) {
      console.error("[WorkerStatus] Failed to update status:", e);
    }
  }

  /** Set status to RUNNING. */
  public static async setRunning(): Promise<void> {
    console.log(`[WorkerStatus] Status set to RUNNING`);
    await this.updateStatus({
      status: "running",
      last_run: new Date().toISOString(),
    });
  }

  /** Set status to SUCCESS. */
  public static async setSuccess(processedCount: number): Promise<void> {
    console.log(
      `[WorkerStatus] Status set to SUCCESS. Processed: ${processedCount}`
    );
    await this.updateStatus({
      status: "success",
      last_success: new Date().toISOString(),
      processed_count: processedCount,
      last_error: null,
      error_message: null,
    });
  }

  /** Set status to ERROR. */
  public static async setError(errorMessage: string): Promise<void> {
    console.error(`[WorkerStatus] Status set to ERROR: ${errorMessage}`);
    await this.updateStatus({
      status: "error",
      last_error: new Date().toISOString(),
      error_message: errorMessage,
    });
  }

  /** Set status to IDLE (back to waiting). */
  public static async setIdle(): Promise<void> {
    await this.updateStatus({
      status: "idle",
    });
  }
}
