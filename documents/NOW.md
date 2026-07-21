# Kế hoạch triển khai theo checkpoint

## Cách dùng file này

Đây là plan thực thi duy nhất. Chỉ một checkpoint được `active`.

Mỗi checkpoint phải:

1. tạo một observable outcome nhỏ;
2. ghi rõ phần không làm;
3. có check chạy độc lập;
4. ghi evidence thực tế;
5. kết thúc bằng quyết định `verify`, `revise`, `pause`, hoặc `replace` của người
   dùng.

Không implement checkpoint tiếp theo chỉ vì nó đã xuất hiện trong tài liệu.

## Trạng thái

- `candidate`: có thể làm, chưa được chọn;
- `active`: checkpoint duy nhất đang thực thi;
- `implemented`: đã có thay đổi nhưng chưa đủ evidence;
- `verified`: checks pass và người dùng chấp nhận;
- `paused`: tạm dừng có chủ ý;
- `replaced`: hướng cũ đã được thay thế.

## Quyết định nền tảng

Ngày 2026-07-21, người dùng chọn:

- dùng upstream `nousresearch/hermes-agent` làm runtime chính;
- không xây một custom assistant runtime song song;
- giữ Mattermost làm giao diện chính;
- dùng `company-gateway` qua MCP;
- routing coding ban đầu: Codex implementation, Claude Code review;
- triển khai one-shot và local-first;
- thêm unified audit log nhưng chưa thêm database hoặc Docker.

## Checkpoint đã đóng: CP0 — Chọn nền tảng

Status: `verified`

Kết quả:

- hướng custom runtime chưa có external gateway/provider end-to-end evidence;
- upstream Hermes đã có các capability nền cần thiết;
- người dùng đã chọn Hermes-first;
- custom runtime prototype và blueprint assets đã được xóa để tránh nhầm lẫn.

Evidence đã ghi nhận: `company-gateway` catalogue hiện có Mattermost
channel/post/thread/search reads và các mutation tools riêng biệt.

CP0 không chứng minh Hermes đã được cài hoặc workflow mới đã chạy.

## Active Checkpoint: CP1 — Upstream Hermes local baseline

Status: `active`

### Câu hỏi

Một upstream Hermes profile sạch có thể chạy local ổn định mà không cần một
runtime wrapper riêng hay không?

### Observable outcome

Từ repository root, có một hướng dẫn ngắn và reproducible để:

- cài hoặc nhận diện upstream Hermes;
- ghi lại version/commit đang dùng;
- tạo một profile riêng cho trợ lý;
- mở Hermes CLI và hoàn thành một prompt local đơn giản;
- xác nhận state/log được ghi trong profile đó.

### Trong phạm vi

- kiểm tra môi trường và Hermes installation hiện có;
- chọn cách pin upstream version;
- tạo profile/config tối thiểu không chứa secret trong git;
- chạy CLI smoke test;
- ghi exact commands và kết quả.

### Ngoài phạm vi

- Mattermost setup;
- `company-gateway` MCP;
- Codex/Claude delegation;
- custom routing skill;
- audit hook;
- Docker;
- database mới;

### Checks

- [ ] `hermes --version` hoặc command tương đương trả version rõ ràng.
- [ ] Hermes chạy trực tiếp từ upstream installation.
- [ ] Profile/state directory của trợ lý tách khỏi source repository.
- [ ] Một prompt local nhận final response thành công.
- [ ] Session và runtime log có thể được tìm thấy.
- [ ] Không có secret mới trong git diff.
- [ ] Exact install/run commands được ghi lại.
- [ ] Người dùng quyết định verify/revise/pause/replace.

### Evidence

Chưa chạy. Không đánh dấu checkpoint này completed chỉ vì tài liệu Hermes nói
capability tồn tại.

## Candidate Checkpoints

Thứ tự dưới đây là đề xuất. Chỉ kích hoạt checkpoint tiếp theo sau quyết định của
người dùng.

### CP2 — Một Mattermost mention, một final reply

Chứng minh transport trước khi thêm MCP hoặc coding agents.

Checks gợi ý:

- bot chỉ chấp nhận Mattermost user/channel đã allowlist;
- bot bỏ qua channel message không có `@mention`;
- một mention tạo một Hermes run;
- kết quả trả đúng channel/thread;
- run kết thúc sau final reply, không có background task;
- lỗi được trả về rõ ràng thay vì im lặng.

### CP3 — Một read-only `company-gateway` source

Chọn `mattermost_read_post` làm vertical slice đầu tiên.

Checks gợi ý:

- Hermes kết nối được `company-gateway`;
- allowlist chỉ expose nhóm read tối thiểu;
- một post ID đọc được post và thread hữu hạn;
- MCP output được coi là untrusted data;
- mutation tools không xuất hiện trong Hermes tool surface;
- gateway unavailable tạo `failed`/`needs_input`, không bịa context.

### CP4 — Unified audit event

Chứng minh có thể theo dấu một request trước khi thêm nhiều executor.

Checks gợi ý:

- hook ghi JSONL hợp lệ;
- `run_id`, Hermes `session_id`, Mattermost message/thread và MCP tool được liên
  kết;
- event names/tags theo schema trong `TARGET.md`;
- secret và raw sensitive content không bị ghi;
- hook failure không làm mất final user response;
- có thể lọc toàn bộ events của một run.

### CP5 — Codex implementation handoff

Dùng bundled Hermes Codex skill; không tự viết agent runtime hoặc copy skill.

Checks gợi ý:

- một repository/workspace test được chọn rõ;
- Codex nhận cùng task contract đã audit;
- Codex chỉ sửa allowed workspace;
- checks được thực thi và kết quả quay về Hermes;
- không push, PR, merge, deploy hoặc internal MCP mutation;
- Mattermost nhận một final summary.

### CP6 — Claude Code read-only review

Thêm reviewer sau khi CP5 ổn định.

Checks gợi ý:

- Claude Code nhận brief, diff và test results;
- reviewer không sửa workspace;
- blocking findings tách khỏi suggestions;
- Hermes tổng hợp implementation và review thành một final response;
- Codex và Claude không chạy như hai code writers đồng thời.

### CP7 — Explicit task routing

Tạo một `company-assistant` skill mỏng để routing theo intent.

Checks gợi ý:

- coding implementation route tới Codex;
- code review route tới Claude Code;
- research route tới Hermes/read-only provider;
- unknown intent trả `needs_input` hoặc dùng default an toàn;
- đổi executor bằng config/skill mà không đổi audit schema;
- bundled vendor skills không bị copy hoặc override.

### CP8 — Hardening và deployment decision

Chỉ đánh giá Docker/database sau khi local workflow được dùng thực tế.

Checks gợi ý:

- xác định rủi ro thật của local terminal backend;
- quyết định có cần Docker sandbox hay không;
- xác định retention/backup cho Hermes SQLite và JSONL logs;
- chỉ đề xuất database ngoài nếu có multi-instance, durable queue hoặc reporting
  requirement cụ thể;
- ghi rollback và recovery procedure.

## Câu hỏi mở

Các câu hỏi này chưa chặn CP1, nhưng phải được trả lời trước checkpoint tương ứng:

- Hermes sẽ dùng provider/model chính nào cho orchestration?
- Mattermost bot token và allowed user/channel được quản lý ở đâu?
- Codex và Claude Code dùng subscription/OAuth hay API credentials nào?
- coding workspace đầu tiên là repository nào?
- audit log local cần retention bao lâu?
- final reply có cần progress updates hay chỉ một message cuối?

Không ghi câu trả lời suy đoán vào architecture. Ghi quyết định khi người dùng
chọn và checkpoint có evidence.
