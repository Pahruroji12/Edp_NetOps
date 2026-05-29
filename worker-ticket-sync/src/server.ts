import * as http from "http";
import { CONFIG } from "./config";
import { syncTicketsFromEmail } from "./syncTicketEmail";
import { WorkerStatusService } from "./workerStatusService";

const startTime = Date.now();

export function startHttpServer(): void {
  console.log(`[HTTP Server] Starting API on port ${CONFIG.port}...`);

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url || "/", `http://localhost:${CONFIG.port}`);
    const method = req.method || "GET";

    // CORS Headers for Flutter Web/Desktop compatibility
    res.setHeader("Content-Type", "application/json");
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization"
    );

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
        res.end(
          JSON.stringify({
            name: "EDP NetOps IMAP Sync Worker",
            status: "online",
            uptime_seconds: uptimeSeconds,
            interval_minutes: CONFIG.syncIntervalMinutes,
            port: CONFIG.port,
            timestamp: new Date().toISOString(),
          })
        );
        return;
      }

      // ── Trigger Sync Endpoint ──
      if (url.pathname === "/sync") {
        console.log("[HTTP Server] Manual sync trigger received.");

        await WorkerStatusService.setRunning();
        try {
          const updatedCount = await syncTicketsFromEmail();
          await WorkerStatusService.setSuccess(updatedCount);
          await WorkerStatusService.setIdle();

          res.writeHead(200);
          res.end(
            JSON.stringify({
              success: true,
              message: "Sync completed successfully.",
              updated_tickets_count: updatedCount,
              timestamp: new Date().toISOString(),
            })
          );
        } catch (syncErr) {
          const errMsg =
            syncErr instanceof Error ? syncErr.message : String(syncErr);
          await WorkerStatusService.setError(errMsg);
          await WorkerStatusService.setIdle();

          res.writeHead(500);
          res.end(
            JSON.stringify({
              success: false,
              error: errMsg,
              timestamp: new Date().toISOString(),
            })
          );
        }
        return;
      }

      // ── Shutdown Endpoint ──
      if (url.pathname === "/shutdown" && method === "POST") {
        console.log("[HTTP Server] Shutdown request received. Shutting down...");

        await WorkerStatusService.setIdle();

        res.writeHead(200);
        res.end(
          JSON.stringify({
            success: true,
            message: "Worker is shutting down...",
            timestamp: new Date().toISOString(),
          })
        );

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
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : String(e);
      res.writeHead(500);
      res.end(JSON.stringify({ error: errMsg }));
    }
  });

  server.listen(CONFIG.port, () => {
    console.log(
      `[HTTP Server] Listening on http://localhost:${CONFIG.port}`
    );
  });
}
