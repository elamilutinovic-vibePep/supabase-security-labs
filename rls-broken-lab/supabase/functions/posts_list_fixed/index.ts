import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const authHeader = req.headers.get("authorization");
  if (!authHeader?.toLowerCase().startsWith("bearer ")) {
    return new Response(JSON.stringify({ ok: false, error: "Missing JWT" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ✅ Good: anon key + user JWT => DB sees auth.uid()
  const supabase = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data, error } = await supabase
    .from("posts")
    .select("id,family_id,body,created_at")
    .order("created_at", { ascending: false });

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