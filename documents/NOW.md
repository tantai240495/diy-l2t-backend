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
- dùng Telegram DM làm transport hiện tại; giữ Mattermost làm transport tương
  lai có thể bật thêm mà không đổi core workflow;
- dùng `company-gateway` qua MCP;
- routing đã chọn: Hermes runtime, OpenAI Codex suy luận/điều phối, GitHub
  Copilot implementation và Claude Code review;
- triển khai one-shot và local-first;
- dùng observability native của Hermes; chưa thêm database hoặc Docker khi chưa
  có gap thực tế.

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

## Checkpoint đã đóng: CP1 — Upstream Hermes local baseline

Status: `verified`

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
- Docker;
- database mới;

### Checks

- [x] `hermes --version` hoặc command tương đương trả version rõ ràng.
- [x] Hermes chạy trực tiếp từ upstream installation.
- [x] Profile/state directory của trợ lý tách khỏi source repository.
- [x] Một prompt local nhận final response thành công.
- [x] Session và runtime log có thể được tìm thấy.
- [x] Không có secret mới trong git diff.
- [x] Exact install/run commands được ghi lại.
- [x] Người dùng quyết định verify/revise/pause/replace.

### Evidence

Đã verify ngày 2026-07-21:

- Hermes Agent `v0.19.0 (2026.7.20)`, upstream commit
  `f4df260f26c93f15694698869f3ea8e965eea301`;
- upstream installation ở `~/.hermes/hermes-agent`, CLI ở
  `~/.local/bin/hermes`;
- profile riêng `diy-l2t` ở `~/.hermes/profiles/diy-l2t`;
- provider/model `openai-codex` / `gpt-5.5`, dùng OAuth session riêng;
- one-shot prompt trả `CP1_HERMES_OK`, session
  `20260721_153325_4fcd8a`;
- session list, `state.db` và `logs/agent.log` cùng xác nhận session trên;
- repository secret scan không phát hiện credential và Git chỉ có tài liệu tiến
  độ thay đổi;
- exact commands và evidence chi tiết nằm trong `PROGRESS.md`;
- người dùng quyết định `verify`.

Observation không chặn CP1: smoke prompt dùng 15,840 tokens do baseline context
lớn; cần cân nhắc tool/skill scope ở checkpoint phù hợp, không tối ưu trong CP1.

## Checkpoint đã đóng: CP2 — Một Telegram DM, một final reply

Status: `verified`

### Câu hỏi

Upstream Hermes có thể nhận một Telegram DM từ đúng user được allowlist, tạo một
run hữu hạn và trả một final reply về cùng chat hay không?

### Observable outcome

Từ Telegram trên điện thoại, user được allowlist gửi một DM cho bot, Hermes local
trên Mac xử lý message và trả một final response về cùng cuộc trò chuyện.

### Trong phạm vi

- dùng Telegram adapter có sẵn của upstream Hermes;
- tạo bot thủ công qua `@BotFather` và lưu token trong profile `diy-l2t`, ngoài
  Git;
- allowlist đúng một Telegram numeric user ID và không bật allow-all;
- dùng DM và long polling mặc định, không mở inbound port;
- giữ model, skills, MCP policy và task contract độc lập với transport;
- chạy gateway foreground trong lúc smoke test;
- ghi session/log và exact commands không chứa token.

### Ngoài phạm vi

- `company-gateway` MCP hoặc Mattermost read tools;
- Telegram group/channel/topic, webhook mode hoặc allow-all-users;
- kích hoạt Mattermost adapter; việc này cần checkpoint/evidence riêng khi admin
  cấp bot/service account;
- cron/home-channel notifications;
- cài gateway thành launchd/system service;
- coding agent, Docker hoặc database mới;
- sửa hoặc fork Hermes core.

### Checks

- [x] Bot xác thực được với `TELEGRAM_BOT_TOKEN`.
- [x] `TELEGRAM_ALLOWED_USERS` chỉ chứa numeric user ID đã chọn và
  `TELEGRAM_ALLOW_ALL_USERS` không được bật.
- [x] Gateway kết nối bằng long polling, không bind public inbound port.
- [x] Một authorized DM tạo đúng một Hermes session/run.
- [x] Final response trả về đúng Telegram chat.
- [x] Run kết thúc sau final reply, không để agent task nền.
- [x] Lỗi/warning transport được ghi rõ; nonfatal DNS/IP fallback tự phục hồi và
  không bị diễn giải thành kết quả giả.
- [x] Routing/skills không hardcode Telegram; Mattermost sau này chỉ cần thêm
  adapter-specific credential/allowlist và restart gateway.
- [x] Repository không chứa token; exact commands/evidence được ghi trong
  `PROGRESS.md`.
- [x] Người dùng quyết định verify/revise/pause/replace.

### Evidence

Đã verify ngày 2026-07-21:

- bot được tạo thủ công qua `@BotFather`; token chỉ nằm trong profile local;
- profile có đúng `TELEGRAM_BOT_TOKEN` và `TELEGRAM_ALLOWED_USERS`, không có
  allow-all, home-channel hoặc webhook config;
- gateway kết nối Telegram bằng long polling, một platform, không bind inbound
  public port;
- `/start` được bỏ qua như platform ping, không tạo model run;
- smoke prompt trả đúng `CP2_TELEGRAM_OK`, session
  `20260721_170402_e4ec4e1a`;
- run dùng một API call, 0 tool turns, kết thúc bình thường và gửi đúng một model
  final response về source chat;
- optional tool warnings không chặn transport/model; DNS/IP fallback tự phục hồi;
- repository secret/ID scan và `git diff --check` pass;
- transport-specific config tách theo namespace; Mattermost có thể thêm vào cùng
  profile mà không đổi model, skills, MCP policy hoặc task contract;
- người dùng quyết định `verify`.

Mattermost evidence đã giữ trong `PROGRESS.md`; adapter chưa bật vì admin reject
bot account.

## Checkpoint đã đóng: CP3 — Một read-only `company-gateway` source

Status: `verified`

### Câu hỏi

Hermes có thể kết nối trực tiếp tới `company-gateway`, chỉ expose
`mattermost_read_post` và đọc một post/thread hữu hạn mà không cấp mutation tool
hay không?

### Observable outcome

Từ profile `diy-l2t`, một prompt có post ID hợp lệ khiến Hermes gọi đúng
`mattermost_read_post`, coi nội dung trả về là untrusted data và trả một bản tóm
tắt hữu hạn. Credential chỉ nằm ngoài Git và mọi tool mutation đều vắng khỏi
Hermes tool surface.

### Trong phạm vi

- xử lý việc hai gateway header credential đã xuất hiện trong diagnostic
  output; rotation được khuyến nghị nhưng người dùng đã chấp nhận tiếp tục với
  credential hiện tại;
- thêm remote HTTP MCP server `company-gateway` vào profile `diy-l2t`;
- lưu credential mới trong profile `.env`, chỉ tham chiếu bằng biến môi trường
  từ Hermes config;
- allowlist duy nhất `mattermost_read_post`;
- đọc một post và optional thread bằng post ID do người dùng chủ động chọn;
- ghi connection/tool/session evidence nhưng không ghi credential, post ID hoặc
  raw nội dung Mattermost vào repository.

### Ngoài phạm vi

- dùng `company-gateway` làm Telegram/Mattermost transport;
- expose Mattermost search/list hoặc bất kỳ Backlog/Offwork/GitHub tool nào;
- mọi mutation tool, kể cả tạo post/channel hoặc gửi message;
- sửa/fork Hermes core, tạo custom MCP client hoặc thêm database/Docker;
- coding agent và review agent.

### Checks

- [x] Sự cố credential đã được thông báo; người dùng quyết định tiếp tục mà
  không rotate. Không đọc/in lại giá trị và không ghi chúng vào Git.
- [x] `diy-l2t mcp test company-gateway` kết nối và discover tool thành công.
- [x] Hermes config chỉ include `mattermost-read_post` cho server này.
- [x] Tool policy của Hermes không chứa mutation tool từ `company-gateway`;
  catalog discovery có 144 tools nhưng Telegram surface chỉ include một tool.
- [x] Một post ID hợp lệ đọc được post và optional thread hữu hạn.
- [x] Sentinel test xác nhận MCP output được coi là untrusted data, không phải
  agent instruction.
- [x] Input không hợp lệ tạo kết quả lỗi rõ và final
  `CP3_INVALID_ID_HANDLED`, không bịa context.
- [x] Session metadata liên kết được turn với đúng MCP tool mà không đọc/ghi
  secret, post ID, tool arguments hoặc raw nội dung vào repository.
- [x] Repository secret scan và `git diff --check` pass.
- [x] Người dùng quyết định verify/revise/pause/replace.

### Evidence

Đã verify ngày 2026-07-21:

- profile `diy-l2t` kết nối `company-gateway` qua HTTPS bằng credential references
  trong profile `.env`, ngoài Git;
- `mcp test` connected, discover 144 server tools, có
  `mattermost-read_post` và không lỗi;
- MCP policy của Telegram chỉ include `mattermost-read_post`; ba tool results
  thực tế đều dùng đúng read tool và không có mutation call;
- positive test đọc được root post cùng thread và trả hai expected markers;
- invalid-ID test trả lỗi hữu hạn, không bịa Mattermost context;
- untrusted-data sentinel bị bỏ qua, không trở thành agent instruction;
- session metadata liên kết được các turn/tool/final response mà không đọc hoặc
  ghi post ID, tool arguments hay raw content vào repository;
- secret-pattern scan và `git diff --check` pass;
- người dùng quyết định `verify`.

CP3 đã đóng. Hiện không có checkpoint `active`; CP4 vẫn là `candidate` cho tới
khi người dùng yêu cầu bắt đầu. Tracking hiện dùng `state.db`, session/tool
history, token usage, native logs và `insights` của Hermes. Chỉ cân nhắc thêm
observer/exporter nếu một checkpoint sau chứng minh gap cụ thể.

## Candidate Checkpoints

Thứ tự dưới đây là đề xuất. Chỉ kích hoạt checkpoint tiếp theo sau quyết định của
người dùng.

### CP4 — GitHub Copilot implementation handoff

Dùng upstream Copilot CLI/ACP integration; không tự viết agent runtime hoặc copy
vendor integration.

Checks gợi ý:

- một repository/workspace test được chọn rõ;
- Copilot nhận task contract và context allowlist đã chốt;
- Copilot chỉ sửa allowed workspace;
- checks được thực thi và kết quả quay về Hermes;
- không push, PR, merge, deploy hoặc internal MCP mutation;
- source chat hiện tại nhận một final summary.

### CP5 — Claude Code read-only review

Thêm reviewer sau khi CP4 ổn định.

Checks gợi ý:

- Claude Code nhận brief, diff và test results;
- reviewer không sửa workspace;
- blocking findings tách khỏi suggestions;
- Hermes tổng hợp implementation và review thành một final response;
- Codex và Claude không chạy như hai code writers đồng thời.

### CP6 — Explicit task routing

Tạo một `company-assistant` skill mỏng để routing theo intent.

Checks gợi ý:

- coding implementation route tới GitHub Copilot;
- code review route tới Claude Code;
- research route tới Hermes/read-only provider;
- unknown intent trả `needs_input` hoặc dùng default an toàn;
- đổi executor bằng config/skill mà vẫn giữ native session/turn correlation;
- bundled vendor skills không bị copy hoặc override.

### CP7 — Hardening và deployment decision

Chỉ đánh giá Docker/database sau khi local workflow được dùng thực tế.

Checks gợi ý:

- xác định rủi ro thật của local terminal backend;
- quyết định có cần Docker sandbox hay không;
- xác định retention/backup cho Hermes SQLite và native logs;
- chỉ đề xuất database ngoài nếu có multi-instance, durable queue hoặc reporting
  requirement cụ thể;
- ghi rollback và recovery procedure.

## Câu hỏi mở

Các câu hỏi này phải được trả lời trước checkpoint tương ứng:

- Telegram bot token và allowed user ID được giữ trong profile local; cần xác
  minh setup không ghi chúng vào repository.
- Mattermost tương lai vẫn cần admin cấp bot/service account; credential và
  allowlist sẽ dùng namespace `MATTERMOST_*` riêng.
- GitHub Copilot và Claude Code dùng subscription/OAuth hay API credentials nào?
- coding workspace đầu tiên là repository nào?
- Hermes state và native logs cần retention bao lâu?
- final reply có cần progress updates hay chỉ một message cuối?

Không ghi câu trả lời suy đoán vào architecture. Ghi quyết định khi người dùng
chọn và checkpoint có evidence.
