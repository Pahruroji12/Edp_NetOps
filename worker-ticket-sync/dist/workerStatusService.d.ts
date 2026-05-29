export declare const WORKER_ID = "ticket-sync-worker";
export declare class WorkerStatusService {
    /**
     * Initialize or update the status row.
     */
    private static updateStatus;
    /** Set status to RUNNING. */
    static setRunning(): Promise<void>;
    /** Set status to SUCCESS. */
    static setSuccess(processedCount: number): Promise<void>;
    /** Set status to ERROR. */
    static setError(errorMessage: string): Promise<void>;
    /** Set status to IDLE (back to waiting). */
    static setIdle(): Promise<void>;
}
//# sourceMappingURL=workerStatusService.d.ts.map