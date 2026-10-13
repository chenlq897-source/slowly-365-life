-- 仅在明确回滚且已备份后执行。
drop policy if exists "journal_images_select_own" on storage.objects;drop policy if exists "journal_images_insert_own" on storage.objects;drop policy if exists "journal_images_update_own" on storage.objects;drop policy if exists "journal_images_delete_own" on storage.objects;
delete from storage.buckets where id='journal-images';
drop table if exists public.journal_images;drop table if exists public.journal_drafts;drop table if exists public.daily_journals;drop table if exists public.task_occurrences;drop table if exists public.action_tasks;drop table if exists public.goal_milestones;drop table if exists public.goal_nodes;

