import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const sha256 = async (value: string) => {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
};

const extractOutputText = (response: Record<string, unknown>) => {
  if (typeof response.output_text === "string") return response.output_text;
  const output = Array.isArray(response.output) ? response.output : [];
  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = Array.isArray((item as { content?: unknown }).content)
      ? (item as { content: unknown[] }).content
      : [];
    for (const part of content) {
      if (
        part &&
        typeof part === "object" &&
        (part as { type?: string }).type === "output_text" &&
        typeof (part as { text?: unknown }).text === "string"
      ) {
        return (part as { text: string }).text;
      }
    }
  }
  throw new Error("OpenAI response did not contain output text");
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  const authorization = request.headers.get("Authorization");

  if (!supabaseUrl || !anonKey || !serviceRoleKey || !openAiKey) {
    return jsonResponse({ error: "Server configuration is incomplete." }, 500);
  }
  if (!authorization) {
    return jsonResponse({ error: "Please sign in before using Mohalla AI." }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Your session has expired. Please sign in again." }, 401);
  }

  let payload: { text?: unknown; target_language?: unknown };
  try {
    payload = await request.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid request body." }, 400);
  }

  const text = typeof payload.text === "string" ? payload.text.trim() : "";
  const targetLanguage = typeof payload.target_language === "string"
    ? payload.target_language
    : "Original";
  const allowedLanguages = new Set(["Original", "English", "Hindi"]);

  if (text.length < 10 || text.length > 500) {
    return jsonResponse({ error: "Post must contain 10 to 500 characters." }, 400);
  }
  if (!allowedLanguages.has(targetLanguage)) {
    return jsonResponse({ error: "Unsupported translation language." }, 400);
  }

  const inputHash = await sha256(
    `${text.toLocaleLowerCase()}|${targetLanguage}`,
  );
  const today = new Date().toISOString().slice(0, 10);

  const { data: cached } = await userClient
    .from("ai_post_generations")
    .select("result")
    .eq("user_id", userData.user.id)
    .eq("input_hash", inputHash)
    .eq("target_language", targetLanguage)
    .maybeSingle();

  const { data: usage } = await userClient
    .from("ai_daily_usage")
    .select("request_count")
    .eq("user_id", userData.user.id)
    .eq("request_date", today)
    .maybeSingle();
  const used = Number(usage?.request_count ?? 0);

  if (cached?.result) {
    return jsonResponse({
      ...(cached.result as Record<string, unknown>),
      cached: true,
      remaining_requests: Math.max(0, 3 - used),
    });
  }

  const { data: remaining, error: claimError } = await userClient.rpc(
    "claim_ai_post_request",
  );
  if (claimError) {
    const isLimit = claimError.message.includes("daily_limit_reached");
    return jsonResponse(
      {
        error: isLimit
          ? "Aaj ke 3 AI requests use ho chuke hain. Kal dobara try karo."
          : "AI usage check failed. Please try again.",
      },
      isLimit ? 429 : 500,
    );
  }

  try {
    const openAiResponse = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openAiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-5.6-luna",
        reasoning: { effort: "none" },
        max_output_tokens: 450,
        instructions:
          "You improve hyperlocal community posts for Indian neighbourhoods. Preserve facts, never invent names, dates, locations, emergencies, or accusations. Keep wording neutral, useful, and safe. Choose exactly one category: safety, info, or issue. If translation is requested, translate faithfully; otherwise return an empty translated_text.",
        input:
          `Original post:\n${text}\n\nRequested translation: ${targetLanguage}`,
        text: {
          format: {
            type: "json_schema",
            name: "mohalla_post_suggestion",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              properties: {
                title: { type: "string", maxLength: 80 },
                improved_text: { type: "string", maxLength: 380 },
                category: {
                  type: "string",
                  enum: ["safety", "info", "issue"],
                },
                translated_text: { type: "string", maxLength: 450 },
                language: { type: "string" },
              },
              required: [
                "title",
                "improved_text",
                "category",
                "translated_text",
                "language",
              ],
            },
          },
        },
      }),
    });

    const openAiBody = await openAiResponse.json();
    if (!openAiResponse.ok) {
      console.error("OpenAI request failed", openAiResponse.status, openAiBody);
      throw new Error("OpenAI request failed");
    }

    const result = JSON.parse(
      extractOutputText(openAiBody as Record<string, unknown>),
    ) as Record<string, unknown>;

    await adminClient.from("ai_post_generations").upsert(
      {
        user_id: userData.user.id,
        input_hash: inputHash,
        target_language: targetLanguage,
        result,
      },
      { onConflict: "user_id,input_hash,target_language" },
    );

    return jsonResponse({
      ...result,
      cached: false,
      remaining_requests: Number(remaining),
    });
  } catch (error) {
    console.error("AI post generation failed", error);
    await userClient.rpc("release_ai_post_request");
    return jsonResponse(
      { error: "AI assistant abhi available nahi hai. Dobara try karo." },
      502,
    );
  }
});
