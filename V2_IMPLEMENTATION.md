# 慢慢来 App V2.0 改造说明

## 架构审计

- 原生 HTML/CSS/JavaScript PWA，使用 `?tab=` 单页路由。
- Supabase Email/Password Auth；未配置时为明确标识的本地演示。
- 本机先写 LocalStorage，登录后通过 `app_snapshots` 云快照同步。
- 旧目标、打卡、财务、物品、复盘和积分结构全部保留。

## V2.0 增量模型

- `goalNodes` / `goalMilestones` / `goalHistory`
- `actionTasks` / `taskOccurrences`
- `dailyJournals` / `journalDrafts` / `journalImages`

旧状态首次加载只做向前兼容迁移，为旧年度/月度/周挑战生成节点，不删除或覆盖旧集合。

## 安全与积分

- `supabase/migrations/002_goals_tasks_journals.sql` 只新增表、索引、RLS 和私有图片桶。
- 新表按 `auth.uid()` 隔离；图片路径第一段必须是用户 ID，限 JPG/PNG/WebP、5MB。
- 任务积分键为 `task:{taskId}:{date}`，取消完成时撤销，每日任务积分最高 20 分。
- 日记和每周目标使用稳定业务键，重复保存不重复发分。

## 部署

1. 新环境先执行 `001_initial.sql`；现有环境只执行 `002_goals_tasks_journals.sql`。
2. 静态文件继续部署到现有 GitHub Pages，无构建步骤。
3. `config.js` 填写 Supabase URL 与 anon key 后，登录用户可以跨设备同步。
4. 回滚文件仅在明确回退且完成备份后使用。

