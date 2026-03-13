import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (_req) => {
  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // ❌ BAD: service role bypasses RLS
  const supabase = createClient(url, serviceKey);

  const { data, error } = await supabase
    .from("posts")
    .select("id,family_id,body,created_at");

  if (error) {
    return new Response(JSON.stringify({ ok: false, error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true, posts: data }), {
    headers: { "Content-Type": "application/json" },
  });
});