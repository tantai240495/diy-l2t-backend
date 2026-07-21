# Capability Roadmap

Roadmap chỉ chứa lựa chọn sau MVP. Trình tự đang làm nằm trong `../NOW.md`.

## Điều đã quyết định

- upstream Hermes là runtime;
- Mattermost là interface chính;
- `company-gateway` là internal MCP boundary;
- one-shot và local-first;
- Codex implementation, Claude Code review là routing ban đầu;
- Hermes sở hữu side effects và native execution correlation;
- không thêm database/Docker khi chưa có evidence.

Các quyết định trên chỉ thay đổi khi một checkpoint ghi rõ lý do và người dùng
chọn `replace`.

## Sau khi MVP được dùng ổn định

### Thêm task types

- daily brief theo yêu cầu, chưa chạy cron;
- document/research workflows;
- GitHub issue/PR reads qua connector được chọn;
- Offwork read-only assistance;
- thêm implementation/review executor khác.

### Thêm controlled mutations

Chỉ thêm từng action với approval và native execution evidence riêng:

- Mattermost post/DM/update ngoài final transport reply;
- Backlog comment/status update;
- GitHub branch/push/draft PR;
- Offwork mutation.

Không cấp một nhóm write tools chỉ vì gateway đã expose chúng.

### Cải thiện routing

- cost/latency-aware model selection;
- task-specific research providers;
- fallback executor khi Codex/Claude unavailable;
- parallel read-only research;
- independent review/judge cho task rủi ro cao.

Chỉ phát triển generic router sau khi fixed routing tạo đủ execution evidence.

### Vận hành và scale

- Docker terminal sandbox;
- always-on server deployment;
- centralized secret manager;
- log shipping/OpenTelemetry mapping;
- retention và searchable telemetry store;
- backup/restore profile và Hermes SQLite;
- multi-profile hoặc multi-instance isolation.

Database service hoặc durable queue chỉ hợp lý khi có multi-instance,
background work, reporting/retention hoặc recovery requirement cụ thể.

## Không có kế hoạch tự xây lại

- agent runtime/tool loop;
- Mattermost gateway;
- MCP client;
- session database;
- provider authentication/model picker;
- Codex/Claude CLI skills đã có trong Hermes;
- custom UI khi Mattermost và Hermes CLI vẫn đủ.

## Promotion rule

Chuyển một item từ roadmap vào `../NOW.md` chỉ khi:

1. có user problem cụ thể;
2. có observable outcome nhỏ;
3. có check độc lập;
4. không phụ thuộc vào nhiều capability chưa hoàn thành;
5. người dùng đồng ý kích hoạt checkpoint đó.
