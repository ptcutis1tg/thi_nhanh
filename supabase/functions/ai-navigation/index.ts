import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { command } = await request.json();
    if (typeof command !== "string" || command.trim().length === 0) {
      return Response.json(
        { error: "command is required" },
        { status: 400, headers: corsHeaders },
      );
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) throw new Error("OPENAI_API_KEY is not configured");

    const openAiResponse = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-6-astra",
        input: command,
        tools: [
          {
            type: "function",
            name: "navigate_to_home",
            description:
              "Call this only when the user asks to open, return to, or navigate to the home page.",
            strict: true,
            parameters: {
              type: "object",
              properties: {},
              required: [],
              additionalProperties: false,
            },
          },
        ],
        tool_choice: "auto",
      }),
    });

    if (!openAiResponse.ok) {
      throw new Error(`OpenAI returned ${openAiResponse.status}`);
    }

    const result = await openAiResponse.json();
    const calledHomeTool = Array.isArray(result.output) &&
      result.output.some((item: { type?: string; name?: string }) =>
        item.type === "function_call" && item.name === "navigate_to_home"
      );

    return Response.json(
      { action: calledHomeTool ? "go_home" : "none" },
      { headers: corsHeaders },
    );
  } catch (error) {
    return Response.json(
      { error: error instanceof Error ? error.message : "Unknown error" },
      { status: 500, headers: corsHeaders },
    );
  }
});
