-- Complete teacher result/analytics views and real student room rankings.

create or replace function public.teacher_student_results()
returns jsonb language sql security definer set search_path = public as $$
  with current_teacher as (
    select id from public.teachers where owner_user_id = auth.uid()
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'attemptId', a.id,
    'roomId', a.room_id,
    'studentName', coalesce(nullif(p.display_name, ''), a.guest_name, 'Học sinh'),
    'score', a.score,
    'status', a.status,
    'submittedAt', a.submitted_at,
    'examTitle', e.title,
    'subject', e.subject
  ) order by a.submitted_at desc), '[]'::jsonb)
  from public.attempts a
  join public.exams e on e.id = a.exam_id
  join current_teacher t on t.id = e.teacher_id
  left join public.profiles p on p.id = a.user_id
  where a.status in ('submitted', 'expired') and a.score is not null;
$$;

create or replace function public.current_student_top3_attempt_ids()
returns jsonb language sql security definer set search_path = public as $$
  select coalesce(jsonb_agg(id), '[]'::jsonb)
  from (
    select id from (
      select a.id, a.user_id,
        row_number() over (partition by a.room_id order by a.score desc,
          extract(epoch from (a.submitted_at - a.started_at)) asc, a.started_at asc) rank_no
      from public.attempts a
      where a.room_id is not null and a.status in ('submitted', 'expired') and a.score is not null
    ) ranked
    where ranked.user_id = auth.uid() and ranked.rank_no <= 3
  ) top_attempts;
$$;

create or replace function public.teacher_profile_payload()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_teacher_id uuid;
  v_created_exams integer := 0;
  v_created_rooms integer := 0;
  v_total_attempts integer := 0;
  v_completed_attempts integer := 0;
  v_average_score numeric := 0;
  v_busiest_room integer := 0;
  v_total_questions integer := 0;
  v_hardest_question text := 'Chưa có dữ liệu câu hỏi';
  v_popular_exam text := 'Chưa có lượt thi';
  v_recent_rooms jsonb := '[]'::jsonb;
  v_recent_exams jsonb := '[]'::jsonb;
  v_chart_values jsonb := '[]'::jsonb;
  v_chart_labels jsonb := '[]'::jsonb;
begin
  select id into v_teacher_id from public.teachers where owner_user_id = auth.uid();
  if v_teacher_id is null then raise exception 'Teacher profile not found'; end if;

  select count(*) into v_created_exams from public.exams where teacher_id = v_teacher_id;
  select count(*) into v_created_rooms from public.rooms where teacher_id = v_teacher_id;
  select count(*) into v_total_questions from public.questions q
    join public.exams e on e.id = q.exam_id where e.teacher_id = v_teacher_id;

  select count(*),
    count(*) filter (where a.status in ('submitted', 'expired') and a.score is not null),
    coalesce(avg(a.score) filter (where a.status in ('submitted', 'expired') and a.score is not null), 0)
  into v_total_attempts, v_completed_attempts, v_average_score
  from public.attempts a join public.exams e on e.id = a.exam_id
  where e.teacher_id = v_teacher_id;

  select coalesce(max(participant_count), 0) into v_busiest_room
  from (select count(*) participant_count from public.attempts a
    join public.rooms r on r.id = a.room_id where r.teacher_id = v_teacher_id group by a.room_id) counts;

  select format('%s — %s (%s%% trả lời sai)', e.title, left(q.body, 100),
      round(100.0 * count(*) filter (where not qo.is_correct) / nullif(count(*), 0), 0))
  into v_hardest_question
  from public.attempt_answers aa
  join public.question_options qo on qo.id = aa.selected_option_id
  join public.questions q on q.id = aa.question_id
  join public.exams e on e.id = q.exam_id
  where e.teacher_id = v_teacher_id
  group by q.id, e.title, q.body
  having count(*) > 0
  order by count(*) filter (where not qo.is_correct)::numeric / count(*) desc, count(*) desc
  limit 1;
  v_hardest_question := coalesce(v_hardest_question, 'Chưa có dữ liệu trả lời');

  select format('%s (%s lượt thi)', e.title, count(a.id)) into v_popular_exam
  from public.exams e left join public.attempts a on a.exam_id = e.id
  where e.teacher_id = v_teacher_id
  group by e.id, e.title order by count(a.id) desc, e.created_at desc limit 1;
  v_popular_exam := coalesce(v_popular_exam, 'Chưa có lượt thi');

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', room_stats.id, 'title', room_stats.name, 'roomCode', room_stats.code,
    'createdAt', room_stats.created_at, 'studentsCount', room_stats.students_count,
    'status', room_stats.status
  ) order by room_stats.created_at desc), '[]'::jsonb)
  into v_recent_rooms from (
    select r.*, count(a.id)::integer students_count from public.rooms r
    left join public.attempts a on a.room_id = r.id
    where r.teacher_id = v_teacher_id group by r.id order by r.created_at desc limit 10
  ) room_stats;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', exam_stats.id, 'title', exam_stats.title, 'durationMinutes', exam_stats.duration_minutes,
    'questionCount', exam_stats.question_count, 'attemptCount', exam_stats.attempt_count,
    'updatedAt', exam_stats.updated_at
  ) order by exam_stats.updated_at desc), '[]'::jsonb)
  into v_recent_exams from (
    select e.id, e.title, e.duration_minutes, coalesce(e.updated_at, e.created_at) updated_at,
      count(distinct q.id)::integer question_count, count(distinct a.id)::integer attempt_count
    from public.exams e left join public.questions q on q.exam_id = e.id
    left join public.attempts a on a.exam_id = e.id
    where e.teacher_id = v_teacher_id group by e.id order by coalesce(e.updated_at, e.created_at) desc limit 10
  ) exam_stats;

  select coalesce(jsonb_agg(participant_count order by created_at), '[]'::jsonb),
    coalesce(jsonb_agg(label order by created_at), '[]'::jsonb)
  into v_chart_values, v_chart_labels
  from (select r.created_at, concat('Phòng ', row_number() over (order by r.created_at)) label,
      count(a.id)::integer participant_count
    from public.rooms r left join public.attempts a on a.room_id = r.id
    where r.teacher_id = v_teacher_id group by r.id order by r.created_at desc limit 6) chart;

  return jsonb_build_object(
    'createdExamsCount', v_created_exams, 'createdRoomsCount', v_created_rooms,
    'totalParticipants', v_total_attempts, 'studentAverageScore', round(v_average_score, 2),
    'completionRate', case when v_total_attempts > 0 then round(v_completed_attempts::numeric / v_total_attempts * 100, 2) else 0 end,
    'busiestRoomCount', v_busiest_room, 'totalQuestionsCount', v_total_questions,
    'overallCorrectRate', round(v_average_score * 10, 2),
    'hardestQuestionInfo', v_hardest_question, 'mostPopularExamInfo', v_popular_exam,
    'recentRooms', v_recent_rooms, 'recentExams', v_recent_exams,
    'chartValues', v_chart_values, 'chartLabels', v_chart_labels
  );
end;
$$;

grant execute on function public.teacher_student_results() to authenticated;
grant execute on function public.current_student_top3_attempt_ids() to authenticated;
grant execute on function public.teacher_profile_payload() to authenticated;

