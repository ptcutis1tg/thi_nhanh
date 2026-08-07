# Supabase data

## Apply

1. Run `migrations/202608070001_exam_schema.sql` in the Supabase SQL Editor.
2. Run `seed.sql` to add four teachers, four published exams, eight questions, thirty-two options, and two rooms.

No environment variable or API key is committed here. Keep `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` only in the ignored `.env` file or deployment secret store.

## Security boundary

`question_options.is_correct`, `questions.explanation`, and `rooms.password_hash` are private data. The schema enables RLS and deliberately gives clients no direct `SELECT` policy for questions, options, or rooms. Use `room_summaries` to browse rooms. Add a server-side RPC or Edge Function that:

1. validates the room password with `crypt(submitted_password, password_hash) = password_hash`;
2. returns options without `is_correct` or explanations;
3. accepts an answer and calculates the score server-side after submission.

Do not use the Supabase service-role key in Flutter. It is server-only.
