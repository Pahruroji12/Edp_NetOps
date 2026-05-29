"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const supabaseClient_1 = require("./supabaseClient");
async function run() {
    try {
        const tickets = await (0, supabaseClient_1.getActiveTickets)();
        console.log("Active tickets in DB:");
        console.log(JSON.stringify(tickets, null, 2));
    }
    catch (err) {
        console.error("Error fetching tickets:", err);
    }
}
run();
//# sourceMappingURL=test_fetch.js.map