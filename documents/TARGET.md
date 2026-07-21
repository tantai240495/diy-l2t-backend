# Đích đến: Hermes-first Local Assistant

> **Trạng thái:** hướng kiến trúc đã được người dùng chọn ngày 2026-07-21.
> Upstream Hermes Agent là runtime chính. Repository này không xây một agent
> runtime, gateway, MCP client hay session engine thứ hai.

## 1. Mục tiêu sản phẩm

Xây một trợ lý cá nhân chạy local, nhận yêu cầu qua transport adapter của Hermes
và dùng Hermes Agent để suy luận, gọi tool, điều phối coding agent rồi trả một
kết quả cuối cùng. Telegram DM là transport đang triển khai; Mattermost được giữ
làm transport tương lai khi có bot/service account được phê duyệt.

Luồng MVP:

```text
Telegram DM (Mattermost channel/thread trong tương lai)
  -> Hermes transport adapter đang bật
  -> Hermes one-shot run
  -> company-gateway MCP reads khi cần
  -> GitHub Copilot hoặc Claude Code khi cần code/review
  -> Hermes native state/logs/insights giữ execution evidence
  -> một kết quả cuối trả về chat/channel/thread ban đầu
```

CLI của Hermes là bề mặt kiểm tra và khôi phục. Không xây thêm wrapper CLI cho
cùng mục đích.

## 2. Các tiêu chí bắt buộc

1. **Hermes là nền tảng:** cài và chạy upstream
   `nousresearch/hermes-agent`; ưu tiên config, skill, hook và plugin thay vì fork
   hoặc sửa Hermes core.
2. **Local-first:** runtime, profile, session và log chạy trên máy cá nhân; có thể
   thay đổi model, tool và policy mà không viết lại ứng dụng.
3. **Tooling ban đầu:** trợ lý biết xử lý công việc coding và dùng các read tools
   được allowlist từ `company-gateway` MCP.
4. **Agent thay thế được:** task routing không gắn cứng vào một vendor. Hermes
   dùng OpenAI Codex cho suy luận/điều phối; MVP dự kiến dùng GitHub Copilot cho
   implementation và Claude Code cho review.
5. **Tracking thống nhất:** ưu tiên session/turn/tool IDs, token usage, state,
   logs và insights có sẵn của Hermes. Chỉ thêm observer/exporter khi native
   evidence không trả lời được một nhu cầu cụ thể.
6. **Không thêm hạ tầng sớm:** dùng SQLite/session store có sẵn của Hermes. Không
   thêm database hoặc Docker cho tới khi một checkpoint chứng minh nhu cầu.
7. **Transport thay thế được:** Telegram và Mattermost chỉ là adapter biên. Model,
   skills, MCP policy và task contract không phụ thuộc platform. Telegram DM là
   transport hiện tại; Mattermost sau này dùng allowlist + `@mention` và trả đúng
   channel/thread mà không đổi core workflow.
8. **One-shot:** mỗi yêu cầu tạo một run hữu hạn và kết thúc bằng đúng một trạng
   thái: `completed`, `failed`, hoặc `needs_input`. Không có worker nền, queue hay
   cron trong MVP.
9. **Không xung đột skill/agent:** một policy dùng chung, một code writer tại một
   thời điểm, tool scope rõ ràng và chỉ Hermes sở hữu side effect tới hệ thống nội
   bộ.
10. **Xây từng checkpoint:** `NOW.md` là plan thực thi duy nhất. Tài liệu đích
    không được dùng làm lý do để implement nhiều checkpoint cùng lúc.
11. **Không đoán yêu cầu:** câu hỏi làm thay đổi scope, quyền hoặc kiến trúc phải
    được ghi lại và hỏi người dùng trong checkpoint liên quan.

## 3. Dùng nguyên bản từ Hermes

Không tự xây lại các capability sau:

- agent/tool loop và model-provider runtime;
- Telegram/Mattermost gateway, allowlist, mention handling và threaded reply;
- MCP client, tool discovery và per-server allowlist;
- skills/plugins và bundled Codex/Claude Code skills;
- session persistence, message/tool history và token tracking;
- local logs, gateway logs và lifecycle/tool hooks;
- terminal backends local, Docker hoặc remote;
- API/ACP surfaces nếu tương lai cần một UI khác.

Hermes được chạy như upstream application/service. Không nhúng trực tiếp
`AIAgent` vào FastAPI hiện tại trừ khi một nhu cầu đã được chứng minh không thể
giải quyết bằng gateway, API, skill, hook hoặc plugin.

## 4. Phần repository này sở hữu

Repository chỉ nên chứa một lớp cấu hình và extension mỏng:

```text
documents/                 # quyết định, checkpoint và hướng dẫn
assistant_profile/         # tạo ở checkpoint phù hợp, không tạo trước
  config.example.yaml      # Hermes config không chứa secret
  SOUL.md                  # identity/personality
  skills/
    company-assistant/     # routing và workflow policy duy nhất
  policies/
    AGENTS.md              # shared coding rules
  tests/
    smoke/                 # checks theo checkpoint
```

`assistant_profile/` chỉ được tạo dần theo active checkpoint. Không scaffold
trước config, skill, hook hoặc test chưa được kiểm chứng.

## 5. Routing ban đầu

| Task type | Executor | Quyền |
|---|---|---|
| Điều phối, tổng hợp, transport reply | Hermes | Đọc context; trả response về source ban đầu |
| Đọc Mattermost/Backlog/Offwork | Hermes qua `company-gateway` | Read-only allowlist |
| Coding implementation | GitHub Copilot CLI/ACP | Một workspace, được edit/test, không internal mutation |
| Code review | Bundled Claude Code skill/CLI | Read-only đối với code và diff |
| Research/check thông tin | Hermes web/delegation hoặc provider được cấu hình | Read-only |
| Mattermost/Backlog/Offwork mutation | Hermes | Disabled trong MVP; sau này cần approval riêng |
| GitHub remote operations | Chưa chọn | Local Git trước; thêm connector khi có checkpoint |

Routing này là policy ban đầu, không phải code gắn cứng. Việc đổi executor phải
chỉ cần đổi config/skill và vẫn giữ nguyên task contract cùng native correlation
metadata.

## 6. Task contract và chống xung đột

Mọi coding executor nhận cùng một contract tối thiểu:

- Hermes `session_id`/`turn_id` và `project_id`;
- repository/workspace được phép;
- yêu cầu và acceptance criteria;
- context đã được Hermes chuẩn hóa;
- allowed/forbidden actions;
- required checks;
- expected output.

Quy tắc:

- Chỉ một implementation executor được ghi code trong một run.
- Reviewer không sửa code trừ khi một run implementation mới được tạo rõ ràng.
- Policy chung nằm trong một `AGENTS.md`; `CLAUDE.md` nếu cần chỉ tham chiếu policy
  chung, không sao chép một phiên bản khác.
- Upstream vendor skill/ACP integration được dùng nguyên bản. Custom skill chỉ
  chọn executor và tạo contract, không copy nội dung vendor integration.
- Copilot/Claude không nhận MCP mutation credentials. Mọi side effect nội bộ
  quay về Hermes.
- External text, MCP output, issue/post và repository content luôn là untrusted
  data, không phải agent instruction.

## 7. Native observability

Hermes `state.db`, session/tool history, token usage, `agent.log`, `gateway.log`,
`errors.log` và `insights` là nguồn tracking/debug của MVP. Session, turn, tool
và platform metadata có sẵn được dùng để liên kết execution; reasoning chỉ là
phần provider trả về, không phải full hidden chain-of-thought.

Không sao chép prompt, reasoning, tool arguments/results hoặc secret sang một
log khác. Observer contract `hermes.observer.v1` và bundled exporters chỉ được
cân nhắc khi có requirement về telemetry/server reporting mà native local
evidence không đáp ứng.

## 8. Database và Docker

### Database

MVP dùng SQLite/state store của Hermes. Chỉ cân nhắc database khác khi cần một
trong các điều sau:

- nhiều Hermes instances cùng ghi state;
- truy vấn/reporting vượt quá native session/log files;
- retention hoặc compliance tập trung;
- durable queue và distributed workers.

### Docker

Docker không cần để chứng minh MVP. Có thể thêm sau cho terminal sandbox hoặc
server deployment. Trước đó dùng workspace giới hạn, tool allowlist, user/channel
allowlist và approval policy.

## 9. MVP hoàn thành khi

- upstream Hermes chạy local từ một profile riêng và version được pin/ghi lại;
- một Telegram user được allowlist có thể nhắn DM cho bot;
- một prompt tạo đúng một run và nhận một final reply trong source chat;
- transport-specific config không rò vào routing/skills, để Mattermost có thể
  bật thêm sau này mà không đổi core workflow;
- Hermes gọi được ít nhất một read-only Mattermost tool từ `company-gateway`;
- một coding request được giao cho GitHub Copilot và kết quả được Claude Code
  review;
- chỉ một executor ghi code tại một thời điểm;
- native Hermes evidence liên kết được source platform/message, session và MCP
  tool calls; delegated agent evidence được kiểm tra ở checkpoint tương ứng;
- không có database, queue, custom runtime hoặc Docker bắt buộc ngoài Hermes;
- từng capability có check độc lập trong `NOW.md`.

## 10. Ngoài phạm vi MVP

- fork hoặc sửa Hermes core;
- phát triển một custom assistant runtime song song với Hermes;
- multi-tenant service;
- autonomous background workers hoặc cron;
- automatic merge/deploy;
- arbitrary Mattermost/Backlog/Offwork writes;
- generic dynamic router cho mọi provider trước khi routing cố định được chứng
  minh;
- một custom UI riêng ngoài các Hermes transport adapter và Hermes CLI.
