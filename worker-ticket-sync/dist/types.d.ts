export interface Ticket {
    id: string;
    store_code: string;
    store_name: string;
    provider: string;
    nomor_tiket: string | null;
    status: string;
    created_at: string;
    created_by?: string;
}
export interface ImapConfig {
    host: string;
    port: number;
    user: string;
    pass: string;
    secure: boolean;
}
export interface WorkerStatus {
    id: string;
    status: "idle" | "running" | "success" | "error";
    last_run: string | null;
    last_success: string | null;
    last_error: string | null;
    error_message: string | null;
    processed_count: number;
    updated_at: string;
}
export interface ProcessedEmail {
    message_id: string;
    processed_at: string;
}
//# sourceMappingURL=types.d.ts.map