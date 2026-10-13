# 慢慢来 · 365天生活重建 PWA

> V2.0 已加入多层目标、每日行动和生活手账。详见 [V2_IMPLEMENTATION.md](./V2_IMPLEMENTATION.md)。

“少买一点，多活一点。”这是一个手机优先、可安装、离线可用的生活重建应用。当前源码使用原生 HTML/CSS/JavaScript，因此无需安装依赖即可运行；正式账号与跨设备同步由 Supabase 提供。

## 本地启动

不能直接双击 `index.html`（Service Worker 需要 HTTP）。在项目目录运行任一静态服务器：

```bash
python -m http.server 4173
```

访问 `http://localhost:4173`，点击“进入独立本地演示”。演示数据使用专门的 `slowly_demo_v2` 存储键，不会上传，也不会混入正式账号。

## 配置 Supabase

1. 新建 Supabase 项目，在 SQL Editor 执行 `supabase/migrations/001_initial.sql`。
2. 在 Authentication → Providers 中启用 Email；生产环境建议开启邮箱验证。
3. 从 Project Settings → API 复制 Project URL 和公开的 anon key。
4. 编辑 `config.js`：

```js
window.SLOWLY_CONFIG = {
  supabaseUrl: 'https://YOUR_PROJECT.supabase.co',
  supabaseAnonKey: 'YOUR_PUBLIC_ANON_KEY'
};
```

不要将 `service_role` key 写入前端。配置后，首页会显示注册/登录。所有云端表都启用了 RLS，策略限定 `auth.uid() = user_id`。

## 同步与冲突规则

- 每次操作先写入当前账号的本地缓存，再异步写入 `app_snapshots`；断网不会静默丢失。
- 恢复联网后自动拉取并合并。数组记录按稳定 ID 合并，同一记录以 `updatedAt` 较新者为准。
- 删除操作写入 tombstone，避免另一台设备把已删除记录重新带回。
- 每日打卡按日期合并；正式部署建议避免两台设备在完全相同的日期同时离线修改同一项。
- 积分由 `pointEvents` 业务事件计算，事件键唯一；取消打卡或周挑战时会撤回对应事件。

## 数据导入与导出

“我的 → 导出 JSON 备份”会下载完整备份。导入时先校验应用标识和必要结构，再按记录 ID 合并，不会盲目覆盖现有数据。建议导入前额外导出一次当前数据。

## PWA 与手机安装

- Android/桌面 Chrome：使用应用内“安装到主屏幕”或浏览器“安装应用”。
- iPhone/iPad：使用 Safari 打开 HTTPS 站点，点“分享” → “添加到主屏幕”。
- 首次联网访问会缓存应用壳；离线时可查看缓存并继续记录，联网后自动同步。
- Service Worker 在 `localhost` 或 HTTPS 下生效。

## 部署到 Vercel

1. 将本目录推送到 GitHub/GitLab，或在 Vercel 中直接导入目录。
2. Framework Preset 选择 “Other”，Build Command 留空，Output Directory 填 `.`。
3. 部署后将正式域名加入 Supabase Authentication → URL Configuration 的 Site URL 与 Redirect URLs。
4. 确认 `/manifest.webmanifest`、`/sw.js`、`/icon-192.png`、`/icon-512.png` 均可通过 HTTPS 访问。

## 测试

```bash
node --test tests/core.test.js
```

测试结果和人工验收范围见 `TEST_REPORT.md`，功能边界见 `FEATURE_STATUS.md`。

