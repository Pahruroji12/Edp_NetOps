"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.startHttpServer = startHttpServer;
const http = __importStar(require("http"));
const config_1 = require("./config");
const syncTicketEmail_1 = require("./syncTicketEmail");
const workerStatusService_1 = require("./workerStatusService");
const startTime = Date.now();
function startHttpServer() {
    console.log(`[HTTP Server] Starting API on port ${config_1.CONFIG.port}...`);
    const server = http.createServer(async (req, res) => {
        const url = new URL(req.url || "/", `http://localhost:${config_1.CONFIG.port}`);
        const method = req.method || "GET";
        // CORS Headers for Flutter Web/Desktop compatibility
        res.setHeader("Content-Type", "application/json");
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
        if (method === "OPTIONS") {
            res.writeHead(204);
            res.end();
            return;
        }
        try {
            // ── Status Endpoint ──
            if (url.pathname === "/" || url.pathname === "/status") {
                const uptimeSeconds = Math.floor((Date.now() - startTime) / 1000);
                res.writeHead(200);
                res.end(JSON.stringify({
                    name: "EDP NetOps IMAP Sync Worker",
                    status: "online",
                    uptime_seconds: uptimeSeconds,
                    interval_minutes: config_1.CONFIG.syncIntervalMinutes,
                    port: config_1.CONFIG.port,
                    timestamp: new Date().toISOString(),
                }));
                return;
            }
            // ── Trigger Sync Endpoint ──
            if (url.pathname === "/sync") {
                console.log("[HTTP Server] Manual sync trigger received.");
                await workerStatusService_1.WorkerStatusService.setRunning();
                try {
                    const updatedCount = await (0, syncTicketEmail_1.syncTicketsFromEmail)();
                    await workerStatusService_1.WorkerStatusService.setSuccess(updatedCount);
                    await workerStatusService_1.WorkerStatusService.setIdle();
                    res.writeHead(200);
                    res.end(JSON.stringify({
                        success: true,
                        message: "Sync completed successfully.",
                        updated_tickets_count: updatedCount,
                        timestamp: new Date().toISOString(),
                    }));
                }
                catch (syncErr) {
                    const errMsg = syncErr instanceof Error ? syncErr.message : String(syncErr);
                    await workerStatusService_1.WorkerStatusService.setError(errMsg);
                    await workerStatusService_1.WorkerStatusService.setIdle();
                    res.writeHead(500);
                    res.end(JSON.stringify({
                        success: false,
                        error: errMsg,
                        timestamp: new Date().toISOString(),
                    }));
                }
                return;
            }
            // ── Shutdown Endpoint ──
            if (url.pathname === "/shutdown" && method === "POST") {
                console.log("[HTTP Server] Shutdown request received. Shutting down...");
                await workerStatusService_1.WorkerStatusService.setIdle();
                res.writeHead(200);
                res.end(JSON.stringify({
                    success: true,
                    message: "Worker is shutting down...",
                    timestamp: new Date().toISOString(),
                }));
                // Graceful shutdown: tutup server lalu exit process
                server.close(() => {
                    console.log("[HTTP Server] Server closed. Exiting process.");
                    process.exit(0);
                });
                // Fallback: jika server tidak tutup dalam 3 detik, paksa keluar
                setTimeout(() => {
                    console.log("[HTTP Server] Force exit after timeout.");
                    process.exit(0);
                }, 3000);
                return;
            }
            // ── 404 Not Found ──
            res.writeHead(404);
            res.end(JSON.stringify({ error: "Not Found" }));
        }
        catch (e) {
            const errMsg = e instanceof Error ? e.message : String(e);
            res.writeHead(500);
            res.end(JSON.stringify({ error: errMsg }));
        }
    });
    server.listen(config_1.CONFIG.port, () => {
        console.log(`[HTTP Server] Listening on http://localhost:${config_1.CONFIG.port}`);
    });
}
//# sourceMappingURL=server.js.map