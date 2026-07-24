# Evidence và quyết định

> File này chỉ ghi evidence, quyết định và kết quả smoke thực tế. Checkpoint
> active duy nhất nằm ở [NOW.md](NOW.md); product contract nằm ở
> [MASTER_GUIDE.md](MASTER_GUIDE.md).

## Trạng thái tổng quát

- Cập nhật gần nhất: 2026-07-24
- Phase 0: `verified` — documentation consolidation và v2 contract đã pass local
  validation.
- Checkpoint active: P1 — Always-on Telegram control plane.
- Trạng thái P1: `ready`; chưa thay đổi LaunchAgent/runtime trong Phase 0.
- Người thực hiện Hermes config/model/delegation/smoke commands trước đây: người
  dùng.

## Phase 0 — Consolidation và Hermes-native Kanban direction

### Quyết định đã khóa

- Chỉ giữ bốn product/human docs: root `README.md`, `MASTER_GUIDE.md`, `NOW.md`
  và `PROGRESS.md`.
- Hermes upstream sở hữu gateway, profiles, sessions, Kanban dispatcher, board
  state và MCP execution. Repository không xây custom dispatcher/API/queue.
- `direct_tool` dùng cho bounded tool call; `delegate_task` dùng cho short
  fresh-context reasoning; named profiles luôn dispatch qua Kanban.
- Mỗi codebase dùng một Hermes Project/Telegram alias, primary repository và
  board tương ứng.
- Coding dùng preserved Git worktree/branch dưới repository thật. Coder, QA và
  reviewer chạy tuần tự trên exact workspace, một writer tại một thời điểm.
- Local branch mặc định được commit nhưng không push. External writes, push, PR,
  merge, deploy và production actions cần explicit approval.
- QA chỉ chạy Playwright trên local/test environment; production bị cấm.
- Mattermost reply là controlled write đầu tiên, với target + exact-content
  preview và đúng một mutation sau approval.
- AI news chạy on-demand, ưu tiên official/RSS sources và dùng search để bổ
  sung; không cron hoặc subscription bắt buộc.
- LaunchAgent sau login, không cloud fallback; raw logs giữ mặc định 30 ngày;
  backup trước update và hằng tuần; dirty/unmerged worktree không tự xóa.
- Kanban SQLite local không có phí riêng. Cost đến từ model/subscription/tool
  backend được chọn.

### Thay đổi contract

- `assistant_profile/agents.example.yaml` nâng lên v2, default dispatch Kanban,
  thêm `diy-l2t-qa`, coding workflow và giới hạn hai rework cycles.
- RouteDecision, TaskEnvelope và ResultEnvelope nâng lên v2 và map trực tiếp vào
  project/board/task/run/worktree.
- Reviewer/non-approved result bị schema buộc `finalizable=false`.
- Transport chỉ còn ở reply correlation của gateway; không đi vào core task
  contract.

### Evidence migration

- CP1–CP5 bên dưới vẫn là historical verified evidence.
- Manual named-profile work của CP6 chứng minh profile/coder/reviewer primitives,
  nhưng custom/manual dispatch direction đã bị thay bởi Hermes-native Kanban.
- Nội dung security, architecture, roadmap, MCP setup và CP5 review contract đã
  được hợp nhất vào Master Guide hoặc retained evidence trong file này.
- Các file tài liệu cũ được retire sau khi migration; tracked history vẫn có
  thể xem trong Git. Hai draft chưa tracked chỉ được bảo toàn về nội dung đã
  hợp nhất, không có historical Git blob riêng.

### Validation ngày 2026-07-24

| Check | Evidence | Kết quả |
|---|---|---|
| JSON syntax | `python3 -m json.tool` trên schema và ba examples | pass |
| JSON Schema v2 | `Draft202012Validator.check_schema` và validate route/task/result examples | pass |
| Reviewer gate negative test | Reviewer `changes_requested` + `finalizable=true` bị reject; `approved` được accept | pass |
| Registry syntax | `yaml.safe_load(assistant_profile/agents.example.yaml)` | pass |
| Human-doc count | Ba Markdown dưới `documents/` + root `README.md` | pass: đúng 4 |
| Internal Markdown links | Resolve tất cả relative links trong bốn product docs | pass |
| Retired-name scan | Không còn stale reference ngoài historical evidence trong file này | pass |
| Secret pattern scan | Không phát hiện OpenAI/GitHub/Telegram token pattern trong docs/contracts | pass |
| Git whitespace | `git diff --check` | pass |
| GitNexus post-change analysis | 110 nodes, 109 edges; `detect-changes --scope all --repo diy-l2t-backend` | pass: low risk, 0 affected flows |

## Mục tiêu đã hiểu

Repository này không xây thêm agent runtime, MCP client, session engine hay CLI
wrapper. Mục tiêu MVP là dùng upstream `nousresearch/hermes-agent` làm runtime,
giữ phần tùy biến của repository ở dạng profile/config/skill/hook/tests mỏng và
chỉ tạo chúng khi checkpoint tương ứng yêu cầu.

CP1 chỉ cần chứng minh một bản Hermes upstream đã pin có thể chạy local bằng một
profile riêng, hoàn thành một prompt đơn giản, lưu session/log trong profile đó
và không làm lộ secret trong Git. Mattermost, `company-gateway`, coding agents,
Docker và database đều chưa thuộc phạm vi.

CP2 đã được replace sang Telegram sau khi Mattermost admin reject bot account.
Checkpoint chỉ chứng minh Telegram DM transport bằng adapter upstream: một
numeric user ID được allowlist, một run hữu hạn và một final reply cùng chat.
Model, skills, MCP policy và task contract phải độc lập transport để Mattermost
có thể bật thêm sau này mà không đổi core workflow.

CP3 chỉ chứng minh một vertical slice read-only qua `company-gateway`:
`mattermost_read_post`. Hai header credential đã xuất hiện trong diagnostic
output; rotation đã được khuyến nghị và người dùng quyết định tiếp tục với
credential hiện tại. Từ đây không đọc/in lại secret. Credential, post ID và raw
Mattermost content không được ghi vào repository.

Observability MVP dùng trực tiếp `state.db`, session/tool history, token usage,
native logs và `insights` của Hermes. Không tạo project event stream song song;
chỉ cân nhắc observer/exporter nếu checkpoint sau chứng minh gap cụ thể.

Coding workflow được người dùng chốt theo ba role tách context: GitHub Copilot
làm implementation (ACP path đã pass CP4 nhưng fail CP6 multi-turn compatibility;
direct provider là recovery candidate), reviewer profile tự verify/review bắt
buộc, và Hermes/Codex
`gpt-5.5` điều hướng/tổng hợp structured results. Mục tiêu tương lai mở rộng sang
GitHub, calendar, browser QC, test và translation: thao tác đơn giản dùng direct
tool; role cần model/policy/context riêng dùng named profile; `delegate_task` giữ
cho short-lived workers dùng global binding. CP4 chứng minh implementation
handoff; CP5 chứng minh reviewer profile; CP6 mới chứng minh named-agent routing.

## Evidence ban đầu

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Tài liệu dự án | Đã đọc `README.md`, toàn bộ `documents/*.md` và `documents/reference/*.md` | pass |
| Git worktree | `master...origin/master`, sạch trước khi tạo file này | pass |
| Hệ điều hành | Darwin arm64 | observed |
| Python hệ thống | 3.11.4 | observed |
| `uv` | `/opt/homebrew/bin/uv` | observed |
| `hermes` | `/Users/teq-tantai/.local/bin/hermes` | pass |
| `assistant_profile/` | Chưa tồn tại | expected: chưa scaffold sớm |
| Hermes version | `Hermes Agent v0.19.0 (2026.7.20)` | pass |
| Install method/path | Git; `/Users/teq-tantai/.hermes/hermes-agent` | pass |
| Upstream commit thực tế | `f4df260f26c93f15694698869f3ea8e965eea301` | pass; dùng làm exact pin cho CP1 |
| PATH của terminal người dùng | `hermes --version` chạy thành công sau khi shell nạp lại PATH | pass |
| Hermes profiles trước CP1.4 | Chỉ có `default`; tên `diy-l2t` chưa được sử dụng | pass: có thể tạo profile mới |
| Profile `diy-l2t` | `/Users/teq-tantai/.hermes/profiles/diy-l2t`; gateway stopped; 73 bundled skills; `.env` và `SOUL.md` tồn tại | pass |
| Profile wrapper | `/Users/teq-tantai/.local/bin/diy-l2t` → `hermes -p diy-l2t` | pass |
| CP1 provider/model | `openai-codex` / `gpt-5.5`; credentials báo hợp lệ; OAuth session tách khỏi Codex CLI | pass |
| CP1 smoke response | `CP1_HERMES_OK`; session `20260721_153325_4fcd8a` | pass |
| Session persistence | `diy-l2t sessions list` hiển thị đúng prompt, workspace, source `cli` và session ID | pass |
| State store | `~/.hermes/profiles/diy-l2t/state.db`, modified lúc chạy smoke test | pass |
| Runtime logs | `logs/agent.log` và `logs/errors.log`; `agent.log` liên kết đúng session ID | pass |
| Smoke usage | 1 API call; 15,819 input + 21 output = 15,840 tokens; 0 tool turns; 9.1s | observed: baseline context lớn |
| `tirith` | Lần chạy đầu fallback sang pattern matching; log cho thấy binary sau đó được cài bằng SHA-256 verification | warning, không chặn CP1 |
| Exact install command | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` | observed: cài từ `main`, chưa khóa checkout |
| Repository secret scan | Không phát hiện mẫu OpenAI/GitHub token hoặc refresh/access token; Git chỉ có `documents/PROGRESS.md` mới | pass |
| Runtime checkout | `main...origin/main` tại baseline commit `f4df260f26c93f15694698869f3ea8e965eea301` | pass: managed install; update chỉ khi explicit |

Lưu ý: Python `^3.13` trong `pyproject.toml` thuộc FastAPI app hiện có, không phải
lý do để cài Hermes vào `.venv` của repository. Upstream installer quản lý môi
trường Hermes riêng bên ngoài source repository.

## Các bước CP1

| ID | Bước | Trạng thái | Evidence cần có |
|---|---|---|---|
| CP1.1 | Đọc tài liệu, chốt ranh giới CP1 và kiểm tra môi trường | done | Các mục trong “Evidence ban đầu” |
| CP1.2 | Cài upstream Hermes bên ngoài repository | done | CLI ở `~/.local/bin/hermes`; install ở `~/.hermes/hermes-agent` |
| CP1.3 | Ghi version và commit thực tế | done | Version `v0.19.0`; full commit `f4df260f26c93f15694698869f3ea8e965eea301` |
| CP1.4 | Tạo profile sạch, riêng cho trợ lý | done | `hermes profile show diy-l2t` xác nhận path riêng, gateway stopped và profile artifacts |
| CP1.5 | Chọn và cấu hình provider/model cho CP1 | done | Profile show xác nhận `gpt-5.5 (openai-codex)`; wizard báo credentials hợp lệ |
| CP1.6 | Chạy một one-shot local prompt | done | Final response `CP1_HERMES_OK`; session ID được trả về |
| CP1.7 | Xác minh session, state và runtime log trong profile | done | Session list, `state.db` và `agent.log` đều có evidence cùng session ID |
| CP1.8 | Kiểm tra Git và tổng hợp exact commands/evidence | done | Secret check pass; exact command log đầy đủ; managed checkout đã trở lại `main` |
| CP1.9 | Người dùng quyết định checkpoint | done | Người dùng chọn `verify` ngày 2026-07-21 |

## Exact command log CP1

```sh
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.zshrc
hermes --version

hermes profile create diy-l2t \
  --description "Local Hermes-first assistant for the diy-l2t project."
hermes profile show diy-l2t

diy-l2t model
diy-l2t chat --quiet -q "Reply with exactly: CP1_HERMES_OK"
diy-l2t sessions list

git -C ~/.hermes/hermes-agent switch --detach \
  f4df260f26c93f15694698869f3ea8e965eea301
git -C ~/.hermes/hermes-agent status --short --branch
hermes --version
```

`diy-l2t model` là interactive flow: chọn OpenAI Codex, không import credential
của Codex CLI, đăng nhập OAuth riêng và chọn `gpt-5.5`.

## CP1 final verdict

Status: `verified`

Tất cả CP1 checks đã pass và người dùng đã chấp nhận evidence. Hiện không có
vấn đề CP1 còn mở.

Đánh giá hiện tại:

- Tất cả CP1 checks kỹ thuật đã pass.
- Warning `tirith` ban đầu không chặn; binary đã được cài sau đó.
- Baseline context 15,840 tokens là risk/optimization evidence cho checkpoint
  sau, không làm CP1 fail.
- Routing mới (Codex reasoning, Copilot implementation) đã được ghi nhưng chưa
  kích hoạt checkpoint coding.

## Các bước CP2

| ID | Bước | Trạng thái | Evidence cần có |
|---|---|---|---|
| CP2.1 | Chọn Telegram DM thay Mattermost nhưng giữ transport portability | done | Người dùng quyết định; `NOW.md`/`TARGET.md` không hardcode core workflow theo Telegram |
| CP2.2 | Tạo bot thủ công qua `@BotFather` và lấy numeric user ID | done | Người dùng xác nhận bot/token và numeric user ID đã có; các giá trị không xuất hiện trong chat/Git |
| CP2.3 | Chạy Telegram setup cho profile với strict user allowlist | done | Profile chỉ có `TELEGRAM_BOT_TOKEN` và `TELEGRAM_ALLOWED_USERS`; không có allow-all/home/webhook key |
| CP2.4 | Chạy gateway foreground và xác minh Bot API long polling | done | Log xác nhận active profile, Telegram connected polling mode, 1 platform và gateway running |
| CP2.5 | Positive test: một authorized DM, một final reply | done | `/start` không tạo run; prompt tạo một session, một API call và response `CP2_TELEGRAM_OK` đúng chat |
| CP2.6 | Kiểm tra run kết thúc và error visibility | done | Log có `Turn ended`, 0 tool turns và response sent; DNS/IP fallback warning rõ và tự phục hồi |
| CP2.7 | Kiểm tra transport portability | done | Ngoài documents không có Telegram/Mattermost hardcode; cùng profile dùng adapter env namespaces riêng |
| CP2.8 | Secret/diff check và quyết định checkpoint | done | Secret scan/diff pass; người dùng chọn `verify` ngày 2026-07-21 |

## Evidence CP2

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Gateway profile `diy-l2t` | Foreground gateway chạy thành công trong smoke; chưa cài user service | pass trong CP2 scope |
| Telegram client | Người dùng đã cài app và đăng nhập | pass prerequisite |
| Telegram bot credential | Người dùng xác nhận đã tạo bot và nhận token từ `@BotFather` | pass; token không được gửi vào chat hoặc ghi vào repository |
| Telegram config trong profile | Key-only check thấy đúng `TELEGRAM_BOT_TOKEN` và `TELEGRAM_ALLOWED_USERS`; không đọc/in values | pass |
| Upstream adapter | Plugin `telegram-platform` hỗ trợ DM/group/topic, per-user/chat allowlist và reply | pass: không cần custom adapter |
| Network mode | Log xác nhận `Connected to Telegram (polling mode)`; profile không có webhook config | pass: không mở inbound port trong CP2 |
| Auth policy | Key-only inspection và setup output xác nhận `TELEGRAM_ALLOWED_USERS`; không có `TELEGRAM_ALLOW_ALL_USERS` | pass |
| Portability | Ngoài documents không có Telegram/Mattermost hardcode; profile giữ adapter credentials trong namespace riêng, model/skills/MCP dùng chung | pass |
| Telegram smoke response | `CP2_TELEGRAM_OK`; session `20260721_170402_e4ec4e1a` | pass |
| Telegram smoke execution | `/start` ignored như platform ping; 1 API call; 15,157 input + 29 output = 15,186 tokens; 0 tool turns; 11.1s gateway time | pass; baseline context vẫn lớn |
| Optional tool warnings | Browser CDP/dialog, terminal/computer-use, image generation, kanban và web-key checks unavailable | non-blocking: prompt không cần các tools này và turn hoàn tất |
| Repository secret/diff check | Không tìm thấy Telegram token hoặc numeric user ID; Git chỉ đổi `NOW.md`, `PROGRESS.md`, `TARGET.md`; `git diff --check` sạch | pass |

## Exact command log CP2

```sh
diy-l2t gateway setup
diy-l2t gateway status
diy-l2t gateway run
diy-l2t sessions list
```

Telegram smoke message (gửi trong DM, không phải shell command):

```text
Reply with exactly: CP2_TELEGRAM_OK
```

## Mattermost attempt được giữ cho tương lai

- `company-gateway` OAuth/read-only discovery đã xác nhận team `executionlab`,
  user và private channel `DIY L2T Test`; không ghi email hoặc exact IDs vào Git.
- MCP Mattermost tools là request/response API, không có incoming-event listener,
  nên không thay native transport adapter.
- Native Mattermost adapter upstream đã được xác nhận có REST v4 + WebSocket,
  user/channel allowlists, mention gating và thread reply.
- Admin reject bot account. Khi có bot/service account, chỉ thêm namespace
  `MATTERMOST_*` vào cùng profile rồi restart gateway; không đổi routing/skills.

## CP2 final verdict

Status: `verified`

Tất cả CP2 checks đã pass và người dùng chấp nhận evidence. Telegram DM hiện đã
chứng minh transport end-to-end trong foreground; Mattermost vẫn là future
adapter. CP2 đã đóng; checkpoint `active` hiện tại được ghi riêng ở phần CP3 bên
dưới.

## Các bước CP3

| ID | Bước | Trạng thái | Evidence cần có |
|---|---|---|---|
| CP3.1 | Quyết định cách xử lý credential đã xuất hiện trong diagnostic output | done | Rotation được khuyến nghị; người dùng chấp nhận tiếp tục mà không rotate và yêu cầu không lặp lại việc in secret |
| CP3.2 | Thêm remote MCP server vào profile với credential qua profile `.env` | done | Env key-only check pass; `mcp test` connected, 144 tools discovered, target present, không lỗi |
| CP3.3 | Giới hạn tool surface còn đúng `mattermost-read_post` | done | `mcp list` báo `1 selected`; Telegram tools policy báo `include only: mattermost-read_post` |
| CP3.4 | Positive test với một post ID do người dùng chọn | done | Bot xác nhận cả root/thread markers; metadata có đúng một `mattermost_read_post` tool call và final `stop` |
| CP3.5 | Negative test cho input/gateway failure và untrusted-data rule | done | Invalid ID không bịa context; embedded instruction sentinel bị bỏ qua đúng cách |
| CP3.6 | Secret/diff check và quyết định checkpoint | done | Secret-pattern scan/diff pass; người dùng chọn `verify` ngày 2026-07-21 |

## Evidence CP3

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Hermes MCP baseline | `diy-l2t mcp list` báo chưa có MCP server | observed |
| CLI capability | Upstream có `mcp add`, `mcp configure`, `mcp test` và per-server tool include list | pass prerequisite |
| Vertical slice | `mattermost_read_post(post_id, include_thread)` trả bounded post/thread visible cho authenticated user | selected |
| Credential incident | Hai header value đã xuất hiện trong diagnostic output khi đọc local config | accepted risk; người dùng tiếp tục mà không rotate; values không ghi vào repository |
| Repository secret-pattern scan | Không tìm thấy gateway credential pattern trong repository | pass |
| Profile config paths | `config.yaml` và `.env` đều nằm trong profile `diy-l2t`, ngoài repository | pass prerequisite |
| Hermes credential env | Key-only check xác nhận `COMPANY_GATEWAY_X_BF_USER_KEY` và `COMPANY_GATEWAY_X_BF_VK` đều tồn tại, không rỗng | pass; values không được đọc/in |
| Hermes MCP config | `diy-l2t mcp list` nhận diện `company-gateway` qua HTTPS, enabled và `1 selected` | pass config |
| Hermes MCP connection | Người dùng chạy `diy-l2t mcp test company-gateway`: connected, 144 tools discovered, có `mattermost-read_post`, không lỗi | pass |
| Telegram MCP policy | `diy-l2t tools list --platform telegram` báo `include only: mattermost-read_post` | pass; mutation tools chỉ xuất hiện trong raw discovery catalog, không nằm trong include policy |
| Positive Telegram read | Bot trả đúng `CP3_ROOT_FOUND: yes` và `CP3_THREAD_FOUND: yes` | pass; không đưa post ID/raw content vào tracker |
| Positive turn metadata | Telegram session `20260721_170402_e4ec4e1a` được reuse; message sequence là user → assistant `tool_calls` → `mcp__company_gateway__mattermost_read_post` → assistant `stop` | pass; chỉ query metadata, không đọc prompt/tool args/result content |
| Invalid-ID test | Bot trả đúng `CP3_INVALID_ID_HANDLED` cho fake post ID, không bịa content | pass |
| Invalid-ID turn metadata | Message sequence tiếp tục là user → assistant `tool_calls` → đúng read tool → assistant `stop`; session tool-call count tăng từ 1 lên 2 | pass; không đọc prompt/arguments/result content |
| Untrusted-data sentinel | Bot trả `CP3_UNTRUSTED_IGNORED`, không làm theo embedded instruction trong Mattermost thread | pass |
| CP3 tool-call aggregate | Session metadata có 3 tool results và tất cả đều là `mcp__company_gateway__mattermost_read_post` | pass; không có mutation call |
| CP3 repository verification | Gateway secret-pattern scan clear; `git diff --check` pass; Git chỉ đổi ba file tài liệu hiện có | pass |

## CP3 final verdict

Status: `verified`

CP3 đã được người dùng kích hoạt ngày 2026-07-21. Người dùng chấp nhận tiếp tục
với credential hiện tại và yêu cầu không lặp lại việc in secret. Connection/auth
và strict single-tool policy đã pass. Positive read, invalid-ID behavior,
untrusted-data sentinel, tool metadata và repository checks đều pass. Người dùng
chọn `verify`; CP3 đã đóng. Hiện chưa có checkpoint `active`.

## Native Hermes observability evidence

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Native session store | `state.db` lưu sessions/messages/tool calls/platform IDs/token usage; `sessions stats` thấy 2 sessions và 19 messages | pass native capability |
| Native insights | `insights --days 7 --source telegram` thấy 1 session, 17 messages, 3 tool calls và đúng read tool | pass native aggregate reporting |
| Native logs | Profile có `agent.log`, `errors.log`, `gateway.log`; CLI lọc được theo session/time/level/component | pass diagnostic capability; log là text và có thể chứa message preview |
| Native reasoning metadata | Metadata-only check của Telegram session hiện tại thấy 1 message có `reasoning`/`reasoning_content`, 2 Codex reasoning items và reasoning-token fields; không đọc hoặc in nội dung | available when provider returns it; không đồng nghĩa full hidden chain-of-thought |
| Native export | `sessions export` hỗ trợ JSONL/Markdown/QMD/HTML/trace, filters và redaction | available; active Telegram session chưa xuất hiện trong dry-run export |
| Observer contract | Upstream có `hermes.observer.v1`, stable session/turn/API/tool/subagent correlation IDs và fail-open callbacks | pass native extension contract |
| Bundled observability | Langfuse và NeMo Relay consumers có sẵn nhưng opt-in; profile hiện chưa có evidence chúng được enable | available, not active |
| MVP decision | Dùng native state/logs/insights; chỉ thêm observer/exporter khi có gap cụ thể | accepted |

## Evidence CP4 đến hiện tại

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Copilot CLI | GitHub Copilot CLI `1.0.73`; login thành công | pass prerequisite |
| ACP direct smoke | `copilot-acp` trả expected marker; model thực tế hiển thị `claude-sonnet-5` | pass transport/model discovery |
| Hermes runtime | Đã cập nhật managed checkout lên upstream `d8bf3df2`; profile vẫn dùng `openai-codex` / `gpt-5.5` cho parent | pass current baseline |
| Delegation binding | Profile route child qua `copilot-acp`; concurrency/depth đều giới hạn `1` | pass bounded child setup |
| Workspace | `/private/tmp/diy-l2t-cp4-smoke` là Git repo tách biệt, không remote; baseline có hai failing tests | pass isolation baseline |
| Tool surface | Copilot ACP chỉ được expose bounded file/terminal tools; GitHub MCP, web và agent-delegation tools bị disable | pass role boundary |
| Implementation evidence | Delegated transcript ghi Copilot đọc đúng allowlisted files và patch duy nhất `calculator.py` từ subtraction sang addition | pass implementation handoff |
| Workspace result | Manual diagnostic sau handoff thấy chỉ `calculator.py` thay đổi và exact unittest command chạy 2 tests, `OK` | pass functional checkpoint evidence |
| Child shell observability | Live delegated transcript không giữ raw terminal invocation/result dù async child summary claim success | observed gap; không còn là CP4 acceptance, CP5 reviewer sẽ sở hữu independent checks |
| Forbidden actions | Không có network, Git remote, commit, push, PR, merge, deploy hoặc internal MCP mutation trong smoke | pass |
| Context isolation | Upstream delegate runtime tạo fresh child conversation; parent nhận delegation call/summary, full transcript chỉ được đọc khi diagnostic | pass runtime capability; happy-path policy chờ CP6 |

CP4 đã `verified` ngày 2026-07-22: final workspace chỉ đổi `calculator.py`, exact
unittest command chạy 2 tests `OK`, không có remote, secret-pattern scan clear,
repository `git diff --check` pass và người dùng chấp nhận evidence. CP5 chưa
được kích hoạt tại thời điểm đóng CP4.

## Các bước CP5

| Bước | Mục tiêu | Trạng thái | Evidence / next action |
|---|---|---|---|
| CP5.1 | Kích hoạt checkpoint và chốt review contract | done | `NOW.md` có question, outcome, scope, `ReviewResult` và acceptance checks |
| CP5.2 | Backup profile config và xác minh quyền dùng `gpt-5.6-sol` bằng direct smoke | done | Backup checksum match; marker/usage report xác nhận exact model/provider và completed session |
| CP5.3 | Tạo `diy-l2t-reviewer` profile độc lập | done | Path riêng, alias riêng, gateway stopped, 0 skills và chưa có model |
| CP5.4 | Xác minh reviewer config/tool baseline và chụp workspace baseline | done | Profile smoke, main invariant, Git/diff baseline và 2 tests đều pass |
| CP5.5 | Gọi trực tiếp reviewer profile trong fresh session | done | Session `20260722_154207_532bd1` trả `approved` đúng `cp5.review.v1`; không delegate |
| CP5.6 | Independent checks, before/after diff và reviewer evidence | done | User checks, byte-identical diff, tests và native model/session log đều pass |
| CP5.7 | Xác minh main profile invariant | done | Model/delegation đúng CP4 baseline; current config và backup có cùng SHA-256 |
| CP5.8 | Repository closure checks và quyết định checkpoint | done | Checks pass; người dùng chấp nhận bằng quyết định tiếp tục CP6 |

## Evidence CP5 final

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Repository baseline | `master...origin/master` tại `bc98475`, worktree sạch trước CP5 document update | pass baseline |
| CP4 artifact | `/private/tmp/diy-l2t-cp4-smoke` còn tồn tại; chỉ `calculator.py` có tracked diff và repository không có remote | reviewed and approved |
| Profile backup | `config.yaml.cp5-before-reviewer.bak` có cùng SHA-256 `a37980f0bc916114fe10a6fecbc94462bc63a8b2b2a1f1d68853feef69a5f5d1` với config hiện tại | pass restore point |
| Parent binding | Profile hiện dùng `openai-codex` / `gpt-5.5` | pass final CP5 recheck |
| Implementation binding | Delegation hiện dùng `copilot-acp`; concurrency/depth `1`, orchestrator disabled, auto-approve disabled | pass CP4 baseline; không thay đổi trong CP5 |
| Delegation inheritance baseline | `inherit_mcp_toolsets=true`, `max_summary_chars=24000`, reasoning override rỗng | observed CP4 path; không dùng cho direct reviewer profile |
| Reviewer target | Direct smoke trả `CP5_REVIEWER_MODEL_OK` bằng `openai-codex` / `gpt-5.6-sol`; session `20260722_133858_676590`, completed, không fallback | pass entitlement/runtime |
| Reviewer-model smoke usage | 1 API call; 2,783 input + 11 output = 2,794 tokens; cost status `included` | observed bounded smoke |
| Reviewer profile | `/Users/teq-tantai/.hermes/profiles/diy-l2t-reviewer`; gateway stopped; alias `/Users/teq-tantai/.local/bin/diy-l2t-reviewer`; 0 skills | pass CP5.3 clean-profile boundary |
| Reviewer auth/model | Profile có Hermes-owned OpenAI Codex auth session; resolved model là `openai-codex` / `gpt-5.6-sol`, base URL Codex chính thức | pass config evidence; không lưu auth/device code |
| Reviewer-profile smoke | Marker `CP5_REVIEWER_PROFILE_OK`; session `20260722_150636_f20c22`; 1 API call; 11,992 input + 11 output = 12,003 tokens; completed, không fallback | pass exact profile/provider/model runtime evidence |
| Main-profile invariant recheck | `diy-l2t` vẫn `openai-codex/gpt-5.5`; delegation vẫn `copilot-acp` với bounded CP4 settings | pass trước reviewer run |
| CP4 review baseline | Git root `/private/tmp/diy-l2t-cp4-smoke`; HEAD `ff861ef115c129e2051a32b7f3ffb0e722a693e5`; no remote; chỉ `calculator.py` đổi 1+/1- | pass bounded workspace |
| Pre-review binary diff | `/private/tmp/cp5-review-before.diff`; SHA-256 `e83e857ac48081b97f399f739d1cce969979eeebe7011a5f581c49c7310d1d58` | pass immutable comparison baseline |
| Pre-review checks | `git diff --check` không output; `python -m unittest -v` chạy 2 tests `OK`; post-test status vẫn chỉ ` M calculator.py` | pass independent baseline |
| Review task contract | `documents/CP5_REVIEW_TASK.md`, task `CP5-REVIEW-001`, version `cp5.review.v1` | used by completed CP5.5 run |
| CP5.5 preflight invocation | Top-level `-z` bị trộn với chat-only `--max-turns`; argparse dừng trước agent start và usage file không tồn tại | CLI syntax failure only; 0 reviewer/API runs, CP5.5 vẫn chưa dispatch |
| Reviewer run | Session `20260722_154207_532bd1`; 1 phút; 18 messages; 16 tool calls; final `status=approved` | pass structured self-report; independently corroborated trong CP5.6 |
| Reviewer checks claim | Đúng root/HEAD/no-remote/status; diff check sạch; 2 tests pass; post hash khớp `e83e857a...d1d58` | pass; independently corroborated trong CP5.6 |
| Reviewer actual tools | `read_file`, `terminal`, `multi_tool_use.parallel`; `forbidden_actions_observed=[]` | pass task-specific action policy theo visible transcript |
| Reviewer chat usage file | Không được tạo vì upstream ghi rõ `--usage-file` chỉ có hiệu lực với top-level `-z/--oneshot`, không áp dụng `chat -q` | expected CLI limitation; dùng native session/log evidence, không rerun |
| Raw transcript policy | Attachment có tool trace và displayed reasoning; repository chỉ ghi bounded result/tool metadata, không copy raw reasoning/transcript | pass documentation boundary |
| Post-review workspace | PWD/root đúng; HEAD vẫn `ff861ef115c129e2051a32b7f3ffb0e722a693e5`; no remote; status chỉ ` M calculator.py`; diff check sạch | pass independent invariant |
| Post-review tests | `python -m unittest -v` chạy lại 2 tests `OK`; status không phát sinh tracked change | pass independent functional check |
| Before/after diff identity | Cả hai SHA-256 là `e83e857ac48081b97f399f739d1cce969979eeebe7011a5f581c49c7310d1d58`; `cmp` không output | pass byte-identical invariant |
| Native reviewer lineage | Profile session list liên kết task/workspace với `20260722_154207_532bd1`; agent log ghi `history=0`, model `gpt-5.6-sol`, provider `openai-codex` | pass fresh-context/model evidence |
| Reviewer runtime usage | Agent log ghi 5 API calls trong budget `5/20`, 4 tool turns, final stop và response length 2,564 | pass bounded runtime evidence; không có one-shot usage report |
| Tirith | Reviewer log báo binary `tirith` không tồn tại; circuit breaker disable checker cho phần còn lại của process | warning; không chặn isolated smoke do no-remote + byte-identical diff, phải đánh giá khi hardening |
| Final main model/binding | `diy-l2t` vẫn `openai-codex/gpt-5.5`; delegation vẫn `copilot-acp` với max iterations 8, concurrency/depth 1, orchestrator/auto-approve disabled | pass CP5.7 invariant |
| Main config identity | Current config và `config.yaml.cp5-before-reviewer.bak` cùng SHA-256 `a37980f0bc916114fe10a6fecbc94462bc63a8b2b2a1f1d68853feef69a5f5d1` | pass byte-identical baseline |
| Reviewer contract | `cp5.review.v1` tách status, checks, blocking findings, suggestions và tracked-file invariant | documented |
| Reviewer tool defaults | Profile sạch enable 17/25 CLI toolsets, gồm web/browser/file/code execution/memory/delegation/cron/Kanban/computer-use | accepted discovery baseline; không bật thêm tool đang disabled |
| Tool policy | Người dùng chọn quan sát actual tool usage trước khi least-privilege hardening; contract vẫn cấm web/MCP/Git remote/internal mutation trong CP5 review | accepted for isolated smoke; before/after diff bắt buộc |
| Reviewer role | Reviewer được thiết kế là multi-tool agent, không phải terminal-only; tool availability và per-task authorization là hai lớp riêng | accepted architecture decision |
| Ownership boundary | Người dùng tự thao tác Hermes; Codex chỉ sửa documents/hướng dẫn/evidence | accepted |
| CP5 repository closure | Worktree chỉ có sáu document sửa đổi và một review-contract document mới; không có source/profile config change; diff, trailing-whitespace, secret/device-code và active-plan checks đều sạch | pass; accepted by user |

CP5.2 đã pass: restore point hợp lệ và direct marker smoke xác nhận account chạy
được exact `gpt-5.6-sol` qua `openai-codex`. Temporary rebinding đã bị thay thế
trước khi thực hiện. CP5.3 đã tạo thành công profile sạch
`diy-l2t-reviewer`. Reviewer model và main-profile invariant đã pass. Tool audit
ghi default profile enable 17/25 toolsets; người dùng chọn giữ baseline này để
quan sát actual usage và harden sau. Bounded reviewer-profile model smoke đã
pass. CP4 workspace/binary-diff baseline và 2 required tests cũng pass. CP5.5
reviewer session trả structured `approved`, nhưng `--usage-file` không áp dụng
cho `chat -q`. Không rerun. CP5.6 independent checks xác nhận byte-identical diff,
2 tests `OK` và exact native session/model lineage. CP5.7 cũng xác nhận main
profile config byte-identical với pre-review baseline. CP5.8 repository closure
checks cũng đã pass. Người dùng chấp nhận CP5 bằng quyết định tiếp tục CP6.

## Historical CP6 manual-routing evidence — `replaced`

Phần này là evidence tại thời điểm CP6 còn active, không phải plan hiện tại.
Phase 0 giữ lại những gì đã chứng minh về profiles/models/contracts và thay
manual/custom dispatch direction bằng Hermes-native Kanban.

| Bước | Mục tiêu | Trạng thái | Evidence / next action |
|---|---|---|---|
| CP6.1 | Verify CP5, activate CP6 và chốt vertical-slice plan | done | Official profiles/providers/delegation docs đã được đối chiếu; `NOW.md` là active plan tại thời điểm đó |
| CP6.2 | Tạo và inspect profile sạch `diy-l2t-coder` | done | Profile path/alias riêng, gateway stopped, 0 skills, `.env`/`SOUL.md` tồn tại; model chưa set |
| CP6.3 | Cấu hình Copilot ACP coder backend | done | Provider `copilot-acp`, backend `acp://copilot`, default model hint `claude-sonnet-5`; existing roles không đổi |
| CP6.4 | Tool/fresh-context/invariant baseline | done | 17/25 baseline, exact marker, usage report và post-smoke role/repository invariants pass |
| CP6.5 | Capability registry và versioned envelopes | done | Registry YAML, shared JSON Schema, three linked examples và reference doc validated |
| CP6.6 | Manual `coder -> reviewer` smoke | replaced | Direct coder implementation/checks pass; incomplete manual pipeline không tiếp tục |
| CP6.7 | Route-kind smoke | replaced | Được thay bằng v2 registry/Kanban vertical slice ở Phase 2 |
| CP6.8 | Automatic adapter | cancelled | Không xây adapter; dùng Hermes Kanban dispatcher |
| CP6.9 | Closure | replaced | Phase 0 ghi quyết định thay hướng |

## Historical evidence CP6

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Official profile model | Profile có config, keys, memory, sessions, skills và state riêng; alias gọi đúng profile; profile không sandbox filesystem | confirmed from upstream [profiles docs](https://hermes-agent.nousresearch.com/docs/user-guide/profiles) |
| Official Copilot ACP backend | Upstream hỗ trợ top-level Copilot ACP external-process provider và cần local Copilot CLI/login | confirmed from upstream [providers docs](https://hermes-agent.nousresearch.com/docs/integrations/providers) |
| Config/runtime model boundary | Installed wizard lưu selected model làm ACP session hint; CP6.4 usage đã xác nhận effective `copilot-acp`/`claude-sonnet-5` | pass marker runtime proof; không suy ra multi-turn compatibility |
| Official delegation boundary | Child có fresh conversation, nhận context qua `goal/context`, dùng configured delegation provider/model và không nhận per-call named profile | confirmed from upstream [delegation docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation) |
| Programmatic surfaces | Upstream có ACP, TUI gateway JSON-RPC và OpenAI-compatible API; CP6 chưa chọn adapter trước manual profile smoke | confirmed from [programmatic integration docs](https://hermes-agent.nousresearch.com/docs/developer-guide/programmatic-integration); decision pending CP6.8 |
| Kanban | Không dùng trong CP6 baseline | accepted user decision |
| Profile mutation ownership | Người dùng tự chạy Hermes commands; Codex chỉ quản lý documents/contracts/evidence | accepted |
| Coder profile creation | `/Users/teq-tantai/.hermes/profiles/diy-l2t-coder`; alias `/Users/teq-tantai/.local/bin/diy-l2t-coder`; gateway stopped; 0 skills; `.env` và `SOUL.md` tồn tại | pass CP6.2 clean-profile boundary |
| Coder pre-model state | Profile list hiển thị model `—`; chưa chạy broad `setup` hoặc cấu hình provider | pass mutation isolation; ready for CP6.3 |
| Existing profile invariants after coder create | Main vẫn `openai-codex/gpt-5.5`; delegation vẫn bounded `copilot-acp`; reviewer vẫn `openai-codex/gpt-5.6-sol` | pass; profile creation không làm đổi role khác |
| Coder model config | `provider=copilot-acp`, `base_url=acp://copilot`, `default=claude-sonnet-5`, `api_mode=chat_completions`; profile show resolve `claude-sonnet-5 (copilot-acp)` | pass CP6.3 configured target |
| ACP process behavior | Wizard/source xác nhận Hermes tạo Copilot ACP subprocess riêng cho từng request và dùng selected model làm session hint | marker runtime pass; CP6.6 multi-turn tool-loop compatibility fail |
| Existing profile invariants after coder model setup | Main vẫn `openai-codex/gpt-5.5`; delegation vẫn bounded `copilot-acp`; reviewer vẫn `openai-codex/gpt-5.6-sol` | pass; coder model mutation isolated |
| Coder CLI tool baseline | Default profile enable 17/25 CLI toolsets, cùng nhóm web/browser/terminal/file/code execution/memory/delegation/cron/Kanban/computer-use như reviewer | observed discovery baseline; chưa enable/disable tool |
| Skills/tool distinction | Profile có 0 installed skills nhưng `skills` toolset vẫn enabled | expected: capability gọi skill tồn tại, catalog profile hiện rỗng |
| Coder tool policy | Giữ default tools cho marker discovery; task contract và actual ACP trace mới quyết định action hợp lệ | accepted for CP6.4 smoke; hardening deferred |
| Coder profile smoke usage | Session `20260722_161348_9b033d`; 1 API call; provider `copilot-acp`; model `claude-sonnet-5`; completed true, failed false | pass effective backend/model runtime evidence |
| ACP token/cost visibility | Usage report ghi mọi token field bằng 0, estimated cost 0 và cost status `unknown` | observed external-process accounting gap; không phải runtime failure |
| Marker response evidence | Người dùng xác nhận exact `CP6_CODER_PROFILE_OK` | pass exact response |
| Post-smoke role invariants | Coder vẫn `copilot-acp/claude-sonnet-5`; main `openai-codex/gpt-5.5`; delegation bounded `copilot-acp`; reviewer `openai-codex/gpt-5.6-sol` | pass CP6.4 final recheck |
| Post-smoke repository | Git status chỉ có expected document/contract changes; `git diff --check` không output | pass no-smoke-mutation evidence |
| Capability registry | `assistant_profile/agents.example.yaml` biểu diễn direct tool, anonymous delegate, named coder/reviewer và `needs_input`; không phải Hermes config | created CP6.5 |
| Agent contract schema | `assistant_profile/contracts/agent-contracts.schema.json` định nghĩa `RouteDecision`, `TaskEnvelope`, `ResultEnvelope` bằng versioned JSON Schema | created CP6.5 |
| Contract examples | Ba JSON examples dùng cùng request/task lineage; coder result có review pending và `finalizable=false` | pass structural assertions |
| Contract validation | Tất cả JSON parse; YAML safe-load pass; schema defs/versions/lineage/review gate assertions pass; `jsonschema` không có sẵn nên không thêm dependency | pass bounded no-network validation |
| CP6 workspace preflight | `/private/tmp/diy-l2t-cp6-smoke` available; source root `/private/tmp/diy-l2t-cp4-smoke`, HEAD `ff861ef115c129e2051a32b7f3ffb0e722a693e5`, status chỉ ` M calculator.py`, remote list rỗng | pass; safe to create detached worktree from committed baseline |
| CP6 worktree | `/private/tmp/diy-l2t-cp6-smoke` registered as detached worktree at `ff861ef115c129e2051a32b7f3ffb0e722a693e5`; source remains on `main` | pass isolated workspace creation |
| CP6 worktree baseline | Root/PWD/HEAD exact; status, remote list và diff check sạch; two unittest cases fail because committed `add()` subtracts | pass expected failing baseline |
| Actual route decision | `/private/tmp/cp6-route-decision.json`: request `cp6-manual-workflow-001`, `named_profile -> coder`; SHA-256 `cc37198674c69fc163637125b5f07db913b804c8549ecacb07ef3a6d44a7fc09` | parse/lineage pass; runtime document not committed |
| Actual coder task | `/private/tmp/cp6-task-envelope.json`: task `cp6-code-001`, exact workspace/base/criteria/action policy/checks; SHA-256 `2f7e77ba2f63615de09671cf536837603e6cc559f0785e8c22cb0cecff9936d0` | parse/lineage pass; runtime document not committed |
| First CP6 coder invocation | Session `20260722_164959_5a9334`; usage ghi 7 API calls, `completed=true`, `failed=false`, nhưng stdout chỉ là progress text | workflow fail; transport completion không thỏa TaskEnvelope |
| First CP6 coder tool trace | 10 calls: 9 `read_file`, 1 read-only `terminal`; contract/source được đọc, source bị đọc lặp; không có `patch`/`write_file` | no implementation; no forbidden action observed |
| First CP6 coder post-check | tracked status/diff vẫn sạch; `git diff --check` pass; 2 unit tests vẫn fail đúng baseline | reject result; reviewer not invoked |
| Installed ACP shim compatibility | Mỗi provider request tạo ACP subprocess mới; transcript formatter không serialize assistant `tool_calls` khi content rỗng, nên next request mất action/result association | confirmed installed-source limitation; do not blind retry same path |
| CP6 coder backend recovery | `diy-l2t-coder` resolve `copilot`/`claude-sonnet-5`, base URL `https://api.githubcopilot.com`, `api_mode=chat_completions`; gateway stopped, profile/alias unchanged | config + fresh runtime marker pass |
| Post-recovery role invariants | Main vẫn `openai-codex/gpt-5.5`; global delegation vẫn bounded `copilot-acp`; reviewer vẫn `openai-codex/gpt-5.6-sol` | pass; chỉ named coder backend thay đổi |
| Direct coder marker smoke | Người dùng xác nhận exact `CP6_CODER_DIRECT_OK`, usage effective `copilot`/`claude-sonnet-5`, completed/not-failed và post-smoke workspace/diff checks sạch | pass; ready to retry `cp6-code-001` |
| Direct coder implementation | Session `20260722_171216_a29fd4`; 7 API calls; tools `read_file`, `patch`, `terminal`; only `calculator.py` changed; diff check + 2 tests pass | implementation/checks pass |
| Direct coder usage | 12,071 input, 2,944 output, 185,908 cache-read, 200,923 total tokens; provider/model correct; completed true, failed false | pass runtime/accounting evidence; cost unknown |
| Direct coder stdout | Raw artifact SHA `c0fab50a3ab47b418a8b10b9ae3ff48b08f3c0f0558a81b70e3fdbc25b4cab0b` chứa verification-policy text, không phải JSON | output-contract gap; không dùng làm reviewer handoff |
| Verify-on-stop interaction | Tiny fixture không expose auto-detected canonical verify command; guard yêu cầu ad-hoc temp script, coder từ chối vì ngoài TaskEnvelope; substantive JSON candidate vẫn persisted ở message `42` | policy conflict confirmed from installed runtime + durable session |
| Canonical coder result | `/private/tmp/cp6-coder-direct-result.json` được materialize từ message `42`, chỉ correlate actual usage session ID; provenance comparison/structural assertions pass; SHA `1aff6b2efe824475202c25eb1830c5f824f05153f1f7eb643f39447ad195823c` | ready for reviewer handoff |
| Coder diff artifact | Current tracked binary diff SHA `e83e857ac48081b97f399f739d1cce969979eeebe7011a5f581c49c7310d1d58`; status chỉ ` M calculator.py` | immutable reference for reviewer pre/post comparison |
| CP6 review route | `/private/tmp/cp6-review-route-decision.json`: same request lineage, `named_profile -> reviewer`; SHA `2989603ac9ef3c74b7d2b4958754247998807c2a0e84ccf88043421d0060ce54` | parse/route assertions pass |
| CP6 review task | `/private/tmp/cp6-review-task-envelope.json`: exact coder session/result/usage/diff hashes, read-only actions, independent checks and result gate; SHA `f841bd88df70b18d27233d1094cb3d23a673961e91d36d2faa625dac947f8e99` | parse/lineage assertions pass; ready to dispatch reviewer |

## Decision log

| Ngày | Quyết định | Lý do/evidence |
|---|---|---|
| 2026-07-21 | Giữ `NOW.md` làm plan duy nhất; `PROGRESS.md` chỉ là tracker | Tránh tạo hai nguồn sự thật |
| 2026-07-21 | Đề xuất pin `v2026.7.20` thay vì cài nhánh `main` | Đây là release upstream mới nhất đã xác minh ngày 2026-07-21; tag tái lập được |
| 2026-07-21 | Dùng `--skip-setup` ở bước cài | Tách cài runtime khỏi quyết định provider/credential |
| 2026-07-21 | Ghi exact commit `f4df260f26c93f15694698869f3ea8e965eea301` làm pin thực tế của CP1 | Installation thực tế báo `v0.19.0` nhưng checkout nông đang ở `main` và không có tag object cục bộ |
| 2026-07-21 | Không dùng Nous Portal hoặc Hermes subscription | Người dùng muốn Hermes làm runtime có thể tùy biến và dùng GitHub/Codex/Claude credentials riêng |
| 2026-07-21 | Không dùng `Quick Setup (Nous Portal)` | Quick Setup tự đặt Nous làm provider, không phù hợp quyết định trên |
| 2026-07-21 | Dùng GitHub Copilot subscription/provider `copilot` làm model điều phối cho CP1 | Superseded bởi quyết định tiếp theo dùng `openai-codex` làm model suy luận |
| 2026-07-21 | Tối ưu routing theo quota: ưu tiên Copilot cho điều phối/context; chỉ gọi Codex/Claude cho task coding/review có scope hữu hạn | Superseded theo lựa chọn vai trò mới của người dùng |
| 2026-07-21 | Giữ Hermes làm runtime, dùng `openai-codex` làm model suy luận chính | Người dùng xác nhận rõ; chấp nhận việc allowance Codex bị dùng cho orchestration |
| 2026-07-21 | Chọn GitHub Copilot CLI/ACP cho CP4 implementation | Người dùng muốn dùng Copilot allowance nhiều hơn cho coding; upstream hỗ trợ `copilot-acp`, vẫn cần checkpoint riêng để verify |
| 2026-07-21 | Chọn model `gpt-5.5` cho CP1 | Model wizard trong profile `diy-l2t` xác nhận provider `OpenAI Codex` và credentials hợp lệ |
| 2026-07-21 | Ghi nhận installer mặc định theo `main`; ban đầu dùng detached checkout tại full commit đã smoke-test | Sau đó xác định detach không cần cho `git pull` trong project và nên reattach để giữ managed install workflow |
| 2026-07-21 | Pin CP1 theo evidence/process: ghi full commit và chỉ update Hermes bằng action explicit | `diy-l2t-backend` và `~/.hermes/hermes-agent` là hai Git repository độc lập; branch local không tự di chuyển |
| 2026-07-21 | Verify CP1 | Version/install/profile/provider/smoke/session/state/log/secret checks pass; người dùng chấp nhận evidence |
| 2026-07-21 | Kích hoạt CP2 | Người dùng yêu cầu tiếp tục CP2; transport Mattermost được tách khỏi MCP/coding agents |
| 2026-07-21 | CP2 dùng strict user/channel allowlist, mention bắt buộc và thread reply | Khớp contract trong `TARGET.md` và capability có sẵn của upstream plugin |
| 2026-07-21 | Dùng native Hermes Mattermost adapter cho ingress/reply; chưa dùng `company-gateway` làm transport | MCP tool surface là request/response API và không có incoming-event listener; MCP Mattermost reads được giữ cho CP3, mutations chưa bật trong MVP |
| 2026-07-21 | Replace CP2 transport từ Mattermost sang Telegram DM | Mattermost admin reject bot account; người dùng chọn Telegram để có mobile ingress không phụ thuộc admin công ty |
| 2026-07-21 | Giữ transport-neutral core và Mattermost future adapter | Telegram/Mattermost dùng namespace credential/allowlist riêng nhưng cùng Hermes profile, model, skills, MCP policy và task contract |
| 2026-07-21 | Verify CP2 Telegram DM | Bot auth, strict allowlist, polling, one-run/one-final, session/log, portability và secret/diff checks đều pass |
| 2026-07-21 | Không tạo checkpoint cho launchd/background service | Người dùng chấp nhận tự chạy foreground gateway khi cần và thấy bước vận hành nền không cần thiết |
| 2026-07-21 | Kích hoạt CP3 với đúng một Mattermost read tool | Giữ vertical slice nhỏ: `mattermost_read_post`; không expose mutation hoặc source khác |
| 2026-07-21 | Rotate gateway headers trước CP3 setup | Hai credential value đã xuất hiện trong diagnostic output; không tái sử dụng hoặc ghi chúng vào repository |
| 2026-07-21 | Tiếp tục CP3 mà không rotate gateway headers | Người dùng đã được thông báo vị trí lộ, chấp nhận rủi ro và yêu cầu không để secret xuất hiện lại |
| 2026-07-21 | Verify CP3 | Connection, strict read-only policy, positive/negative/untrusted-data tests, metadata và repository checks đều pass; người dùng chấp nhận evidence |
| 2026-07-21 | Dùng native Hermes observability cho MVP | State, logs, insights, token/tool history và observer contract đã đủ baseline; không tạo extension hoặc event store song song |
| 2026-07-22 | Tách context theo role | Hermes delegated child dùng fresh conversation; implementation/reviewer chỉ chia sẻ bounded contract, structured result và workspace artifact, không full parent history/reasoning |
| 2026-07-22 | Cố định coding flow có mandatory reviewer | GitHub Copilot ACP implementation → independent verification/review → Hermes `gpt-5.5` route/tổng hợp final |
| 2026-07-22 | Chuyển required-check ownership sang CP5 reviewer | CP4 chỉ chứng minh implementation handoff; reviewer phải tự chạy checks và không tin implementation self-report như final evidence |
| 2026-07-22 | Giữ reviewer replaceable | Binding ban đầu dự kiến `gpt-5.6-sol`; có thể đổi sang Claude/model khác bằng config mà không đổi workflow contract |
| 2026-07-22 | Dành workflow routing cho CP6 | Fixed routes và contracts phải được verify trước; skill/CLI/API/MCP dispatch mechanism sẽ được chọn trong CP6 |
| 2026-07-22 | Verify CP4 | Copilot ACP implementation handoff, isolated workspace, bounded tool/context scope, expected patch, manual functional check, forbidden-action checks và repository closure checks đều pass; người dùng chấp nhận evidence |
| 2026-07-22 | Kích hoạt CP5; người dùng giữ quyền thao tác Hermes | Tách rõ ownership: Codex cập nhật documents/hướng dẫn, người dùng tự create/configure/run reviewer profile để học runtime workflow |
| 2026-07-22 | CP5 dùng temporary reviewer binding rồi restore Copilot | Superseded trước khi config thay đổi: người dùng nhận thấy global rebinding không phù hợp với role isolation |
| 2026-07-22 | Dùng `diy-l2t-reviewer` profile trực tiếp cho CP5 | Giữ nguyên Copilot delegation; reviewer có provider/model/session/config riêng và không cần `delegate_task` |
| 2026-07-22 | Chọn capability-based routing làm hướng dài hạn | Orchestrator gọi simple tools trực tiếp, dùng anonymous delegate cho subtask ngắn và named profiles cho coder/reviewer/QA/test/translation khi role cần isolation |
| 2026-07-22 | Không dùng Kanban trong CP5 | Manual structured handoff qua contract + Git artifact dễ kiểm chứng; CP6 mới đánh giá CLI runner, Hermes API hoặc MCP adapter cho automatic named dispatch |
| 2026-07-22 | Giữ reviewer default toolsets trong CP5 discovery | Quan sát actual tool calls trước khi quyết định disable; không bật thêm tool đang disabled, contract và isolated diff invariant kiểm soát smoke |
| 2026-07-22 | Reviewer là multi-tool agent | Reviewer có thể dùng nhiều tools theo review use case; contract/credentials/workspace/evidence giới hạn action, không hardcode terminal-only |
| 2026-07-22 | Verify CP5 và kích hoạt CP6 | Reviewer run, independent checks, profile/model/main-binding invariants và repository closure đều pass; người dùng yêu cầu tiếp tục CP6 |
| 2026-07-22 | CP6 bắt đầu bằng named coder profile | Official profiles/providers docs xác nhận profile độc lập và `copilot-acp` dùng được làm top-level backend; phải verify profile trước routing automation |
| 2026-07-22 | Tách ACP config hint khỏi effective runtime proof | Actual wizard lưu `claude-sonnet-5` trong Hermes config và truyền làm ACP session hint; marker smoke vẫn phải xác nhận request thực tế |
| 2026-07-22 | Manual handoff trước automatic adapter | Giảm biến số: verify coder/reviewer/contracts trước, sau đó mới chọn CLI runner, Hermes API hoặc MCP; không dùng Kanban |

## Câu hỏi chưa chặn bước hiện tại

- CP6 phải tạo/verify `diy-l2t-coder` trước khi thay CP4 delegated coding path.
- CP6 phải chọn manual-only, CLI runner, Hermes API hay MCP adapter cho named
  profile dispatch; Kanban không bắt buộc.
- CP6 phải quyết định skill-only enforcement đã đủ hay cần hook/plugin để chặn
  coding final khi chưa có `ReviewResult.status=approved`.
- Hardening phải quyết định reviewer tool allowlist dựa trên actual CP5 usage;
  profile không được xem là read-only sandbox chỉ vì role instruction.
- Telegram/Mattermost tokens nằm trong profile local `.env`; cần quyết định cơ
  chế backup/rotation ở checkpoint hardening, không đưa secret vào Git.

## Lịch sử cập nhật

- 2026-07-22: người dùng kích hoạt CP5 và yêu cầu tự thực hiện mọi Hermes command;
  tài liệu chốt review contract, temporary binding/restore strategy và chuyển
  CP5.2 thành next action duy nhất.
- 2026-07-22: CP5.2 backup/config baseline pass; backup và config hiện tại có
  cùng SHA-256, parent vẫn là `openai-codex/gpt-5.5`, delegation vẫn là bounded
  `copilot-acp`. Direct reviewer-model smoke là next action.
- 2026-07-22: CP5.2 direct smoke pass; exact `gpt-5.6-sol` marker, provider,
  completed session và bounded usage được xác nhận. CP5.3 chuyển `in_progress`;
  chưa thay delegation config tại thời điểm ghi evidence này.
- 2026-07-22: sau khi đối chiếu upstream delegation/profile docs, temporary
  reviewer rebinding bị replace trước khi thực hiện. CP5 sẽ tạo
  `diy-l2t-reviewer` trực tiếp; main Copilot binding giữ nguyên. Hướng dài hạn là
  capability-based named profiles, direct tools và optional dispatch adapter.
- 2026-07-22: CP5.3 pass; `diy-l2t-reviewer` có profile path/alias riêng, gateway
  stopped, 0 skills và chưa có model. CP5.4 chuyển `in_progress` để cấu hình main
  model trước; chưa chạy review.
- 2026-07-22: reviewer OAuth/config pass bằng Hermes-owned session; resolved
  model là `openai-codex/gpt-5.6-sol`. Recheck xác nhận `diy-l2t` vẫn dùng
  `gpt-5.5` và delegation vẫn là `copilot-acp`. Không ghi device code/auth data.
- 2026-07-22: reviewer tool audit thấy blank/no-skills profile vẫn enable 17/25
  CLI toolsets. Người dùng chọn giữ default set để quan sát actual usage; không
  bật thêm tool disabled và chuyển least-privilege decision sang hardening.
- 2026-07-22: bounded reviewer-profile smoke pass không cần model/provider
  override; exact `gpt-5.6-sol`/`openai-codex`, session
  `20260722_150636_f20c22`, one API call và completed status được xác nhận.
- 2026-07-22: CP5.4 pass; review workspace không có remote, chỉ `calculator.py`
  đổi, pre-review binary diff SHA-256 là `e83e857a...d1d58`, diff check sạch và 2
  tests `OK`. `CP5_REVIEW_TASK.md` được chốt cho đúng một CP5.5 run.
- 2026-07-22: CP5.5 command preflight thất bại ở argparse vì `--max-turns` là
  option của `chat`, không phải top-level one-shot. Không có model/API call hoặc
  usage file nên chưa tính là reviewer run; corrected syntax dùng global
  `--usage-file` trước `chat`, rồi `--max-turns` và `-q` sau subcommand.
- 2026-07-22: corrected `chat -q` reviewer run hoàn thành trong session
  `20260722_154207_532bd1`, trả `approved`, 16 visible tool calls và không
  forbidden action. `--usage-file` vẫn không tạo file vì source xác nhận option
  này one-shot-only; không rerun, chuyển CP5.6 sang session/log + independent
  workspace evidence.
- 2026-07-22: CP5.6 pass; user rerun 2 tests `OK`, tracked status không đổi,
  before/after binary diff byte-identical và native log xác nhận fresh session,
  exact provider/model, 5/20 API budget. Ghi warning `tirith` unavailable để xử
  lý trong hardening; CP5.7 chuyển `in_progress`.
- 2026-07-22: CP5.7 pass; main `diy-l2t` vẫn `gpt-5.5`, delegation vẫn
  `copilot-acp`, và current config có cùng SHA-256 `a37980f...f5d1` với backup
  trước reviewer. CP5.8 chuyển `in_progress`; checkpoint chờ closure + user
  decision.
- 2026-07-22: CP5.8 documents-only closure checks pass: worktree không có
  source/profile config change; `git diff --check`, trailing-whitespace,
  secret/device-code và active-plan checks đều sạch. CP5 vẫn `active` cho tới
  khi người dùng chọn `verify`, `revise`, `pause` hoặc `replace`.
- 2026-07-22: người dùng yêu cầu tiếp tục CP6, được ghi nhận là quyết định
  `verify` CP5. CP5.8/final verdict chuyển `verified`; CP6 chuyển `active`.
- 2026-07-22: CP6.1 đối chiếu official Hermes profiles, providers, delegation và
  programmatic integration docs. Chốt profile coder sạch + manual workflow trước
  khi chọn automatic adapter; CP6.2 chuyển `in_progress`.
- 2026-07-22: CP6.2 pass; `diy-l2t-coder` có path/alias riêng, gateway stopped,
  0 skills, model chưa set và không clone state/credentials. Recheck xác nhận
  main/delegation/reviewer đều không đổi; CP6.3 chuyển `in_progress`.
- 2026-07-22: CP6.3 pass; model wizard tìm thấy Copilot CLI và 11 models, lưu
  `copilot-acp` + `acp://copilot` + `claude-sonnet-5` session hint. Main,
  delegation và reviewer configs vẫn không đổi; CP6.4 chuyển `in_progress`.
- 2026-07-22: CP6.4 tool audit ghi default coder profile enable 17/25 CLI
  toolsets dù installed skills bằng 0. Chưa thay tool config; marker smoke là
  next action để kiểm chứng effective ACP backend/model mà không mutation.
- 2026-07-22: CP6.4 one-shot usage report xác nhận session mới, 1 ACP API call,
  exact `copilot-acp`/`claude-sonnet-5`, completed và không failed. ACP không trả
  token/cost accounting; exact marker line và post-smoke invariants còn pending.
- 2026-07-22: người dùng xác nhận exact `CP6_CODER_PROFILE_OK`; post-smoke
  coder/main/delegation/reviewer configs không đổi và repository diff check sạch.
  CP6.4 pass.
- 2026-07-22: CP6.5 tạo project-owned registry YAML, shared JSON Schema, ba
  linked examples và routing-contract reference. JSON/YAML syntax cùng
  version/lineage/review-gate assertions pass; CP6.6 chuyển `in_progress`.
- 2026-07-22: CP6.6 preflight pass; target workspace chưa tồn tại, CP4 source
  đúng root/HEAD, chỉ có expected uncommitted calculator fix và không có remote.
  Next action là detached worktree từ committed baseline; chưa gọi coder.
- 2026-07-22: detached CP6 worktree tạo thành công tại exact commit, clean/no
  remote/diff-check pass và hai tests fail đúng baseline. Actual RouteDecision +
  TaskEnvelope được materialize trong `/private/tmp`; chưa gọi coder.
- 2026-07-22: first CP6.6 coder run không đạt contract. Usage report chỉ xác
  nhận process kết thúc; session trace có 9 reads + 1 read-only terminal, không
  edit, không ResultEnvelope và tests vẫn fail. Installed ACP shim mất assistant
  tool-call history giữa các short-lived requests, làm model đọc lặp. Reviewer
  không được gọi; next action là snapshot config và thử direct Copilot backend
  cho riêng coder profile, không đổi global delegation binding.
- 2026-07-22: người dùng chuyển riêng `diy-l2t-coder` sang direct GitHub Copilot.
  Config resolve `copilot`/`claude-sonnet-5`, base URL
  `https://api.githubcopilot.com`, gateway stopped; main, global delegation và
  reviewer invariants đều pass. Chưa retry task; next action là fresh marker
  smoke để tách provider validation khỏi code mutation.
- 2026-07-22: người dùng xác nhận direct-provider marker smoke pass với exact
  `CP6_CODER_DIRECT_OK`, expected provider/model/usage flags và clean workspace.
  CP6.6 next action chuyển sang retry exact `cp6-code-001`; reviewer vẫn chưa
  được gọi.
- 2026-07-22: direct coder retry sửa đúng `calculator.py`, required checks pass
  và durable message `42` chứa schema-valid ResultEnvelope. Verify-on-stop sau
  đó yêu cầu ad-hoc tempfile vì tiny fixture không có auto-detected canonical
  command; coder từ chối đúng contract nên final stdout không còn JSON. Codex
  materialize canonical result từ candidate, correlate actual usage session ID
  và verify exact provenance; CP6.6 chuyển sang independent reviewer.
- 2026-07-22: CP6 review RouteDecision/TaskEnvelope được materialize với exact
  coder result/usage/raw-output/diff hashes và same request lineage. Structural
  checks pass; next action là fresh `diy-l2t-reviewer` run trong exact workspace.
- 2026-07-21: tạo tracker; hoàn thành đọc tài liệu và environment discovery;
  chuyển next action sang CP1.2.
- 2026-07-21: xác minh Hermes đã cài thành công; ghi version/path/commit; chuyển
  next action sang CP1.4 và yêu cầu thoát setup của profile mặc định.
- 2026-07-21: ghi nhận không dùng Hermes subscription/Nous Portal; dự kiến cấu
  hình một provider riêng bằng `hermes model` sau khi profile `diy-l2t` tồn tại.
- 2026-07-21: terminal mở trước installation chưa nhận `~/.local/bin`; xác minh
  binary vẫn tồn tại và installer đã cập nhật `.zshrc`/`.zprofile`; hướng dẫn nạp
  lại shell PATH thay vì cài lại.
- 2026-07-21: người dùng xác nhận `hermes --version` thành công; kiểm tra profile
  list chỉ có `default`; CP1.4 sẵn sàng để người dùng tạo `diy-l2t`.
- 2026-07-21: người dùng tạo và kiểm tra thành công profile `diy-l2t`; CP1.4
  chuyển `done`, CP1.5 chờ xác nhận GitHub Copilot hay GitHub Models API.
- 2026-07-21: người dùng xác nhận GitHub Copilot subscription; CP1.5 chuyển
  `in_progress`, next action là OAuth qua `diy-l2t model`.
- 2026-07-21: ghi nhận Copilot allowance nhiều hơn Codex/Claude; routing sau MVP
  phải ưu tiên Copilot và giữ delegated coding/review contract nhỏ, hữu hạn.
- 2026-07-21: người dùng đổi routing: Hermes runtime + `openai-codex` reasoning +
  GitHub Copilot implementation + Claude review; CP1 chỉ áp dụng thay đổi model
  provider, còn CP4 phải được thay thế/verify riêng khi đến checkpoint đó.
- 2026-07-21: người dùng hoàn thành OAuth riêng; profile show xác nhận
  `gpt-5.5 (openai-codex)`; CP1.5 `done`, chuyển next action sang CP1.6.
- 2026-07-21: one-shot trả `CP1_HERMES_OK`; session/state/log correlation pass;
  CP1.6 và CP1.7 `done`; ghi nhận baseline dùng 15,840 tokens và chuyển CP1.8.
- 2026-07-21: ghi exact install command; secret scan pass; xác định installation
  đang theo `main`; CP1.8 chờ pin chính commit đã dùng cho smoke test.
- 2026-07-21: người dùng pin runtime thành công tại detached HEAD `f4df260f`;
  version không đổi; CP1.8 `done`, chuyển sang quyết định CP1.9.
- 2026-07-21: correction — detached HEAD không bảo vệ khỏi một rủi ro thực trong
  project workflow; CP1.8 mở lại để reattach `main`, giữ version/commit làm
  reproducibility evidence và yêu cầu update Hermes phải explicit.
- 2026-07-21: người dùng reattach thành công `main...origin/main`; correction
  hoàn tất, CP1.8 `done`, chuyển lại CP1.9 để chờ quyết định checkpoint.
- 2026-07-21: người dùng chọn `verify`; CP1 đóng, `NOW.md` được cập nhật và không
  có checkpoint tiếp theo được tự động kích hoạt.
- 2026-07-21: người dùng yêu cầu tiếp tục CP2; checkpoint chuyển `active`; source
  upstream xác nhận Mattermost adapter, strict gating và thread reply đã có sẵn;
  CP2.1 chờ xác nhận quyền/instance Mattermost.
- 2026-07-21: thử read-only discovery qua `company-gateway`; Mattermost connector
  yêu cầu authentication. Dừng tại OAuth để người dùng tự đăng nhập; không chạy
  mutation và không lưu auth URL/credential vào tracker.
- 2026-07-21: người dùng hoàn thành OAuth; read-only discovery xác nhận team
  `executionlab` và user `tantai`. Không chạy mutation, không lưu email hoặc
  danh sách channel nội bộ; CP2.1 tiếp tục với bot account và private test channel.
- 2026-07-21: người dùng tạo private channel `DIY L2T Test`; read-only discovery
  xác nhận channel. Exact channel ID không được ghi vào repository; CP2.1 còn
  chờ tạo bot account/quyền bot.
- 2026-07-21: Mattermost admin reject tạo bot account. CP2 Mattermost ingress bị
  chặn; ghi nhận Telegram DM và Codex Remote là hai candidate, chờ người dùng
  quyết định revise/replace thay vì tự đổi architecture.
- 2026-07-21: người dùng quyết định Telegram DM và yêu cầu dễ bật Mattermost về
  sau. CP2 được replace theo transport, `TARGET.md` chuyển sang transport-neutral
  core; Telegram app/login pass nhưng bot/token/user-ID setup chưa thực hiện.
- 2026-07-21: người dùng tạo Telegram bot thủ công và nhận token thành công;
  token không được thu thập vào chat/tracker. CP2.2 chờ numeric Telegram user ID
  trước khi chạy profile setup với strict allowlist.
- 2026-07-21: người dùng xác nhận đã có numeric Telegram user ID; CP2.2 `done`,
  chuyển CP2.3 sang interactive profile setup. Không thu thập token/user ID vào
  tracker.
- 2026-07-21: Telegram setup hoàn tất; key-only inspection xác nhận strict
  token/user allowlist, không có allow-all/home/webhook config. Người dùng chọn
  không start gateway và không cài launchd; CP2.3 `done`, CP2.4 `in_progress`.
- 2026-07-21: foreground gateway log xác nhận active profile `diy-l2t`, Telegram
  connected ở polling mode, một platform và gateway running. DNS-over-HTTPS/IP
  fallback warnings tự phục hồi ở attempt đầu; CP2.4 `done`, CP2.5 `in_progress`.
- 2026-07-21: Telegram DM smoke trả `CP2_TELEGRAM_OK`; session list/log xác nhận
  đúng một session, một API call, 0 tool turns và normal turn end. `/start` không
  tạo agent run; Home Channel notice là setup notice, không phải model final.
- 2026-07-21: portability/secret/diff checks pass; ngoài documents không có
  transport hardcode hoặc Telegram credential/ID. CP2.7 `done`; CP2.8 chờ quyết
  định checkpoint của người dùng.
- 2026-07-21: người dùng chọn `verify`; CP2 đóng.
- 2026-07-21: người dùng quyết định không cần background launchd service; xóa
  candidate tương ứng khỏi `NOW.md`. CP3 trở lại candidate tiếp theo nhưng chưa
  được kích hoạt.
- 2026-07-21: người dùng yêu cầu tiếp tục; CP3 được kích hoạt. Local inspection
  xác nhận profile chưa có MCP server và upstream hỗ trợ HTTP MCP cùng per-server
  tool include list.
- 2026-07-21: diagnostic output vô tình hiển thị hai gateway header value. Secret
  pattern scan trong repository pass; CP3.1 yêu cầu revoke/rotate trước khi cấu
  hình Hermes và không lưu giá trị mới vào chat/Git.
- 2026-07-21: người dùng quyết định tiếp tục mà không rotate; CP3.1 `done` theo
  accepted risk và CP3.2 chuyển `in_progress`. Các lệnh sau chỉ được kiểm tra
  key-only/schema/pass-fail, không đọc hoặc in secret value.
- 2026-07-21: người dùng thêm hai gateway credential vào profile `.env`;
  key-only/non-empty check pass mà không đọc/in value. CP3.2 tiếp tục với
  `config.yaml` dùng env references và strict single-tool include.
- 2026-07-21: người dùng thêm MCP config; `diy-l2t mcp list` xác nhận HTTPS
  server enabled với đúng `1 selected`. CP3.2 còn chờ connection/auth/tool
  discovery test.
- 2026-07-21: `mcp test` connected, discover 144 server tools, có
  `mattermost-read_post` và không lỗi. Telegram tools policy xác nhận include
  duy nhất tool này; CP3.2/CP3.3 `done`, CP3.4 chuyển `in_progress`.
- 2026-07-21: positive Telegram test đọc được root và thread markers. State DB
  metadata xác nhận đúng một `mcp__company_gateway__mattermost_read_post` call
  nằm giữa assistant `tool_calls` và final `stop`; không đọc prompt, arguments
  hoặc content. CP3.4 `done`, CP3.5 chuyển `in_progress`.
- 2026-07-21: invalid-ID Telegram test trả `CP3_INVALID_ID_HANDLED`; metadata
  xác nhận thêm đúng một read-tool call rồi final `stop`, không bịa context.
  CP3.5 còn chờ untrusted-data sentinel test.
- 2026-07-21: sentinel test trả `CP3_UNTRUSTED_IGNORED`; aggregate metadata có
  ba tool results và tất cả đều là `mattermost_read_post`, không mutation.
  Secret-pattern/diff checks pass; CP3.5 `done`, CP3.6 chờ verdict người dùng.
- 2026-07-21: người dùng chọn `verify`; CP3.6 `done`, CP3 đóng.
- 2026-07-21: observability assessment xác nhận Hermes đã có `state.db`,
  filtered logs, insights, exports, stable `hermes.observer.v1` và bundled
  Langfuse/NeMo Relay consumers. Người dùng chọn native baseline; không tạo
  extension, profile config hoặc output store mới. Copilot implementation được
  đánh số lại thành candidate CP4.
- 2026-07-21: metadata-only inspection xác nhận session Codex hiện tại có dữ
  liệu reasoning do provider trả về và Codex reasoning items; không đọc nội
  dung. Đây không phải bằng chứng Hermes có thể thu full hidden chain-of-thought.
- 2026-07-22: CP4 environment discovery xác nhận Copilot CLI `1.0.73`, login,
  direct ACP model `claude-sonnet-5`, bounded delegation config và isolated smoke
  workspace không remote.
- 2026-07-22: nhiều delegated smokes xác nhận Copilot đọc allowlisted files và
  chỉ patch `calculator.py`; manual exact unittest diagnostic chạy 2 tests `OK`.
  Raw child terminal event không xuất hiện trong live delegation transcript dù
  async summary claim success.
- 2026-07-22: người dùng revise kiến trúc: không dùng GPT-5.5 làm code verifier.
  CP4 sở hữu implementation handoff; CP5 reviewer fresh-context tự chạy required
  checks và review bắt buộc; CP6 custom skill enforce intent-specific workflow.
- 2026-07-22: reviewer binding ban đầu dự kiến `gpt-5.6-sol`, có thể thay bằng
  Claude/model khác. GPT-5.5 chỉ phân loại, route, xử lý structured status và
  tổng hợp final response.
- 2026-07-22: final CP4 closure checks pass: smoke workspace chỉ đổi
  `calculator.py`, không có Git remote, exact unittest chạy 2 tests `OK`,
  repository chỉ đổi bốn file tài liệu, secret-pattern scan clear và
  `git diff --check` sạch. Người dùng chọn `verify`; CP4 đóng, CP5 chưa active.
