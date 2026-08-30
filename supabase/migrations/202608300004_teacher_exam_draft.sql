create or replace function public.teacher_exam_draft(p_exam_id uuid)
returns jsonb language sql security definer set search_path = public as $$
  select jsonb_build_object(
    'id', e.id, 'code', e.code, 'title', e.title, 'subject', e.subject,
    'durationMinutes', e.duration_minutes, 'status', e.status,
    'questions', coalesce((select jsonb_agg(jsonb_build_object(
      'id', q.id, 'body', q.body, 'points', q.points,
      'answers', (select jsonb_agg(o.body order by o.position) from public.question_options o where o.question_id = q.id),
      'correctAnswer', coalesce((select o.position - 1 from public.question_options o where o.question_id = q.id and o.is_correct), 0)
    ) order by q.position) from public.questions q where q.exam_id = e.id), '[]'::jsonb)
  )
  from public.exams e
  where e.id = p_exam_id and e.teacher_id = public.ensure_current_teacher();
$$;

grant execute on function public.teacher_exam_draft(uuid) to authenticated;
