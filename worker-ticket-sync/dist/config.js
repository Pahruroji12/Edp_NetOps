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
exports.CONFIG = void 0;
const dotenv = __importStar(require("dotenv"));
const path = __importStar(require("path"));
// Load environment variables from .env file (try process.cwd() first, then relative path)
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, "../.env") });
exports.CONFIG = {
    supabaseUrl: process.env.SUPABASE_URL || "",
    supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || "",
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
if (!exports.CONFIG.supabaseUrl || !exports.CONFIG.supabaseServiceRoleKey) {
    console.warn("WARNING: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are not set in environment variables! " +
        "Supabase integration will fail.");
}
//# sourceMappingURL=config.js.map