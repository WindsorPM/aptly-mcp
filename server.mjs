#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const API_KEY = process.env.APTLY_API_KEY;
if (!API_KEY) {
  console.error("APTLY_API_KEY environment variable is required");
  process.exit(1);
}

const BASE_URL = "https://core-api.getaptly.com";
const BOARD_ID = "5BnS34PgWL6SEtBmm";

async function aptlyFetch(path, options = {}) {
  const url = `${BASE_URL}${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      "x-token": API_KEY,
      "Content-Type": "application/json",
      ...options.headers,
    },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Aptly API ${res.status}: ${body}`);
  }
  return res.json();
}

const server = new McpServer(
  { name: "aptly", version: "1.0.0" },
  {
    instructions: [
      "Aptly Work Orders board. Always call get_schema first to learn field keys before reading or writing cards.",
      "Card data uses field keys (UUIDs), not field names. The schema maps keys to labels.",
    ].join(" "),
  }
);

// --- Tools ---

server.registerTool(
  "get_schema",
  {
    description:
      "Fetch the field schema for the Work Orders board. Returns field keys, labels, and types. Call this first before reading or creating cards — field data uses keys, not names.",
    inputSchema: {},
    annotations: { readOnlyHint: true },
  },
  async () => {
    const schema = await aptlyFetch(`/api/schema/${BOARD_ID}`);
    return {
      content: [{ type: "text", text: JSON.stringify(schema, null, 2) }],
    };
  }
);

server.registerTool(
  "list_cards",
  {
    description:
      "List cards on the Work Orders board with pagination. Returns card data keyed by field keys. Use get_schema to understand field keys.",
    inputSchema: {
      page: z.number().int().min(0).default(0).describe("Zero-based page number"),
      pageSize: z.number().int().min(1).max(100).default(20).describe("Cards per page, max 100"),
      updatedAtMin: z
        .string()
        .optional()
        .describe("ISO date — only return cards updated after this time"),
      includeArchived: z
        .boolean()
        .default(false)
        .describe("Include archived cards in results"),
    },
    annotations: { readOnlyHint: true },
  },
  async ({ page, pageSize, updatedAtMin, includeArchived }) => {
    const params = new URLSearchParams({
      page: String(page),
      pageSize: String(pageSize),
    });
    if (updatedAtMin) params.set("updatedAtMin", updatedAtMin);
    if (includeArchived) params.set("includeArchived", "true");

    const cards = await aptlyFetch(`/api/board/${BOARD_ID}?${params}`);
    return {
      content: [{ type: "text", text: JSON.stringify(cards, null, 2) }],
    };
  }
);

server.registerTool(
  "get_card",
  {
    description:
      "Fetch a single card by its ID. Returns all field data keyed by field keys.",
    inputSchema: {
      cardId: z.string().describe("The card's unique ID"),
    },
    annotations: { readOnlyHint: true },
  },
  async ({ cardId }) => {
    const card = await aptlyFetch(`/api/board/${BOARD_ID}/${cardId}`);
    return {
      content: [{ type: "text", text: JSON.stringify(card, null, 2) }],
    };
  }
);

server.registerTool(
  "create_or_update_card",
  {
    description:
      "Create a new card or update an existing one. Send a JSON object with field keys and values. Use get_schema to find valid field keys. To update, include the cardId field.",
    inputSchema: {
      cardData: z
        .record(z.string(), z.any())
        .describe(
          "Object with field keys as keys and values as values. Include 'cardId' to update an existing card."
        ),
    },
    annotations: { readOnlyHint: false },
  },
  async ({ cardData }) => {
    const result = await aptlyFetch(`/api/board/${BOARD_ID}`, {
      method: "POST",
      body: JSON.stringify(cardData),
    });
    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  }
);

server.registerTool(
  "add_comment",
  {
    description:
      "Add a comment to a card. Requires the card ID and comment text. userId is optional.",
    inputSchema: {
      cardId: z.string().describe("The card's unique ID"),
      content: z.string().describe("Comment text"),
      userId: z
        .string()
        .optional()
        .describe("Aptly user ID for the commenter. Omit if unknown."),
    },
    annotations: { readOnlyHint: false },
  },
  async ({ cardId, content, userId }) => {
    const body = { content };
    if (userId) body.userId = userId;
    const result = await aptlyFetch(`/api/board/${BOARD_ID}/${cardId}/comment`, {
      method: "POST",
      body: JSON.stringify(body),
    });
    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  }
);

// --- Start ---

const transport = new StdioServerTransport();
await server.connect(transport);
