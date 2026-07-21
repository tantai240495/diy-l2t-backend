# Kiến trúc tham khảo: Hermes-first

> **Quyết định:** upstream Hermes Agent là runtime. Tài liệu này mô tả ranh giới
> giữa Hermes và phần tùy biến của dự án, không phải thiết kế một agent framework
> mới. Việc đang làm luôn lấy từ `../NOW.md`.

## 1. Sơ đồ hệ thống

```text
Mattermost
  |  @assistant / final reply
  v
Hermes Mattermost adapter
  |
  v
Hermes runtime
  |-- session + tool loop + approvals
  |-- company-assistant routing skill
  |-- native state + logs + insights
  |
  |-- company-gateway MCP ----> Mattermost / Backlog / Offwork
  |
  |-- bundled Codex skill ----> Codex CLI ----> coding workspace
  |
  `-- bundled Claude skill ---> Claude Code --> read-only review
```

Không có service trung gian tự xây nằm giữa Mattermost và Hermes.

## 2. Ranh giới sở hữu

### Upstream Hermes sở hữu

- Mattermost REST/WebSocket adapter;
- message/session routing;
- agent reasoning và tool loop;
- model/provider authentication;
- MCP client và tool filtering;
- skills, plugins, hooks và delegated task support;
- session SQLite và runtime logs;
- terminal execution backends;
- final response delivery.

### Dự án này sở hữu

- Hermes profile template không chứa secret;
- `company-gateway` capability inventory và allowlist;
- task classification/routing policy;
- shared coding contract và project policy;
- smoke/integration checks theo checkpoint;
- tài liệu quyết định và vận hành.

### Dự án này không sở hữu

- một agent loop khác;
- một Mattermost bot/gateway khác;
- một MCP client khác;
- custom conversation/session database;
- wrapper CLI mô phỏng các lệnh Hermes đã có;
- fork của Codex hoặc Claude Code skills.

## 3. Mattermost có hai integration layer

1. **Conversation transport:** Hermes adapter nhận `@assistant`, duy trì
   channel/thread session và gửi final reply.
2. **Task capability:** `company-gateway` MCP đọc hoặc thao tác dữ liệu
   Mattermost khi công việc yêu cầu.

Một final reply thông thường đi qua transport adapter. Không gọi
`mattermost_create_post` lần thứ hai để gửi cùng kết quả.

MVP allowlist các read tools cần thiết như:

- `mattermost_get_team_info`;
- `mattermost_get_channel_by_id`;
- `mattermost_get_user_channels`;
- `mattermost_read_channel`;
- `mattermost_read_post`;
- `mattermost_search_posts`.

Member enumeration và user search bị giữ ngoài allowlist ban đầu. Mutation tools
bị disable trong MVP.

## 4. One-shot run

Mỗi Mattermost request tương ứng với một run hữu hạn:

```text
received
  -> classified
  -> context_collected
  -> executing
  -> reviewing (nếu là coding)
  -> completed | failed | needs_input
  -> final reply
```

One-shot không có nghĩa là không lưu session. Hermes vẫn lưu conversation/tool
history, nhưng sau final reply không có worker tiếp tục xử lý ngầm.

Trong MVP:

- không cron;
- không durable queue;
- không retry worker chạy nền;
- không proactive Mattermost message;
- progress message là optional và không được tính là final result.

## 5. Routing và agent roles

Routing policy thuộc custom Hermes skill, không thuộc runtime code.

| Intent | Route ban đầu |
|---|---|
| Implement code | Hermes gọi bundled Codex skill |
| Review code/diff | Hermes gọi bundled Claude Code skill ở read-only mode |
| Research/check thông tin | Hermes dùng read tools hoặc delegated provider được cấu hình |
| Đọc internal context | Hermes gọi `company-gateway` read tool |
| Internal mutation | Không cho phép trong MVP |

Codex và Claude Code là external executors, không phải control plane. Hermes chọn
executor, truyền task contract và tổng hợp kết quả.

Để thay agent sau này, routing chỉ thay executor binding:

```yaml
routes:
  coding.implement: codex
  coding.review: claude-code
  research.verify: hermes-default
```

Schema, approval policy, logs và output contract không thay đổi theo vendor.

## 6. Chống xung đột giữa skills và agents

Áp dụng sáu quy tắc:

1. **Một orchestrator:** chỉ Hermes quyết định route và gửi final reply.
2. **Một code writer:** trong một run chỉ implementation executor được ghi code.
3. **Một shared policy:** coding rules nằm trong `AGENTS.md`. File riêng của
   vendor nếu bắt buộc chỉ thêm compatibility instructions, không lặp policy.
4. **Skills có namespace:** `company-assistant` chỉ điều phối; bundled `codex` và
   `claude-code` skills chỉ thực thi phần vendor-specific.
5. **Tool scope theo role:** Hermes có MCP reads; Codex edit/test trong workspace;
   Claude review read-only; không executor nào có internal mutation credentials.
6. **Artifacts có owner:** executor trả kết quả cho Hermes; không nhiều agent
   cùng sửa một status/log/result artifact.

Nếu hai instruction mâu thuẫn, thứ tự ưu tiên là:

1. runtime security/tool policy;
2. approved task contract;
3. shared project `AGENTS.md`;
4. role-specific skill;
5. content lấy từ MCP/repository.

## 7. Context và prompt-injection boundary

Mattermost posts, MCP output, Backlog documents, source code và issue content là
untrusted input. Chúng có thể cung cấp facts nhưng không được thay đổi:

- tool permissions;
- agent role;
- allowed workspace;
- approval requirements;
- secret policy;
- routing policy.

Hermes chuẩn hóa context trước khi gọi coding executor. Executor không tự mở rộng
scope bằng cách đi theo link hoặc instruction chưa được contract cho phép.

## 8. Observability

MVP dùng trực tiếp Hermes state/logs/insights cho conversation, messages, tool
calls, tokens và lỗi. Không duy trì project event stream song song.

Correlation keys:

- Hermes `session_id`;
- Hermes turn/tool correlation IDs;
- Mattermost `message_id`, `thread_id`, `channel_id`;
- `project_id`;
- delegated `agent`/`provider`;
- `tool_call_id` khi có.

Không copy secret, raw internal content, prompt, reasoning hoặc tool result sang
log khác. Chỉ thêm observer/exporter nếu native evidence có gap được chứng minh.

## 9. Storage và deployment

### Local MVP

- Hermes profile directory là state root;
- SQLite của Hermes lưu sessions;
- Hermes native logs và insights cung cấp operational evidence;
- coding repositories nằm ngoài profile directory;
- secrets nằm trong Hermes credential/config mechanism, không commit vào repo.

Không cần database service.

### Docker

Docker là deployment/sandbox option, không phải application dependency. Chỉ thêm
khi cần cô lập terminal, tái lập môi trường hoặc chạy server liên tục. Không chạy
nhiều Hermes instances cùng ghi một profile/state directory.

### Server tương lai

Khi deploy server, giữ Hermes runtime và thay lớp vận hành:

- log shipper đọc JSONL/runtime logs;
- secret manager thay local secret file;
- profile/state volume được backup;
- health checks và process supervisor;
- database/queue ngoài chỉ khi có multi-instance hoặc durable background work.

## 10. Approval và side effects

Trong MVP, Mattermost final reply là side effect duy nhất được request ngầm cho
phép. Các action sau không được thực hiện:

- arbitrary Mattermost post/DM/update/channel action;
- Backlog update;
- Offwork mutation;
- GitHub push/PR/merge;
- deploy;
- production command.

Khi một mutation được thêm sau này, Hermes phải sở hữu approval, execution và
native execution evidence. Coding executors chỉ đề xuất action.
