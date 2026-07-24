# Checkpoint đang active

> File này chỉ chứa một checkpoint đang active. Product contract và roadmap nằm
> ở [MASTER_GUIDE.md](MASTER_GUIDE.md); evidence nằm ở
> [PROGRESS.md](PROGRESS.md).

## P1 — Always-on Telegram control plane

- Trạng thái: `ready`
- Owner thực thi local/runtime command: người dùng
- Baseline: CP1–CP5 đã có verified evidence; Phase 0 đã hợp nhất tài liệu và
  chuyển contract sang Hermes-native Kanban v2.

### Mục tiêu

Chứng minh Hermes gateway của profile `diy-l2t` chạy như macOS LaunchAgent sau
login, tự restart khi process lỗi, chỉ nhận Telegram DM từ strict allowlist và
trả đúng một final reply cho một request được phép.

### In scope

- backup profile/state trước thay đổi;
- pin/record Hermes version và config baseline;
- cài một LaunchAgent user service cho gateway;
- polling Telegram, không mở inbound port;
- strict numeric user allowlist;
- login/restart/authorized/unauthorized/unavailable smokes;
- secret redaction trong Git và user-visible logs;
- rollback service về trạng thái foreground trước checkpoint.

### Out of scope

- Không tạo Hermes Project/Kanban coding task.
- Không tạo coder/QA/reviewer workflow.
- Không bật external write, push, PR, merge hoặc deploy.
- Không cron, cloud fallback, Docker, custom API, queue hoặc database.
- Không sửa application code chỉ để pass gateway smoke.

### Checklist

- [ ] Chụp baseline: Hermes version, profile name, gateway status và config
      checksum không chứa secret.
- [ ] Backup profile config/state và xác minh backup có thể đọc; secret backup
      được mã hóa/tách khỏi repository.
- [ ] Xác nhận upstream command/service shape cho Hermes version đang pin; không
      đoán plist arguments từ version khác.
- [ ] Cài LaunchAgent dưới user account và load sau login.
- [ ] Xác minh gateway process tự khởi động và chỉ có một dispatcher instance.
- [ ] Kill process có kiểm soát và xác minh LaunchAgent tự restart.
- [ ] Gửi một authorized Telegram DM và nhận đúng một final reply cùng chat.
- [ ] Gửi từ unauthorized user fixture/account và xác minh bị từ chối, không tạo
      agent run hay lộ allowlist.
- [ ] Mô phỏng gateway/Mac unavailable và xác minh không có response giả.
- [ ] Scan repository và user-visible logs: không token, numeric user ID, MCP
      header, OAuth material hoặc credential.
- [ ] Ghi command đã redact, timestamps, process/service status, session/run IDs
      opaque và pass/fail vào `PROGRESS.md`.
- [ ] Chứng minh rollback: unload service và chạy foreground gateway được mà
      không mất profile/state.

### Acceptance criteria

P1 chỉ `verified` khi đồng thời đạt:

1. Sau login, LaunchAgent tự chạy gateway mà không cần terminal đang mở.
2. Gateway chết bất ngờ được restart và không tạo dispatcher trùng.
3. Authorized DM nhận đúng một final reply có correlation đúng.
4. Unauthorized sender không khởi chạy assistant.
5. Khi Mac/gateway unavailable, hệ thống không báo thành công giả.
6. Không có secret hoặc raw user ID trong Git/user-visible logs.
7. Backup và rollback đã được smoke bằng evidence thực tế.

Nếu thiếu credential, service permission, exact upstream command hoặc identity
fixture, checkpoint chuyển `blocked/needs_input`; không nới policy để tiếp tục.

### Điều kiện kết thúc

Khi acceptance pass, cập nhật `PROGRESS.md`, đánh dấu P1 verified rồi thay toàn
bộ nội dung active của file này bằng P2 — Project + Kanban coding vertical
slice. Không tự kích hoạt P2 chỉ vì P1 gần hoàn tất.
