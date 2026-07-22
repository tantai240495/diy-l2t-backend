# Nhật ký triển khai

> File này chỉ ghi tiến độ và evidence thực tế. `NOW.md` vẫn là plan/checkpoint
> có thẩm quyền duy nhất. Không dùng file này để tự kích hoạt checkpoint mới.

## Trạng thái tổng quát

- Cập nhật gần nhất: 2026-07-22
- Checkpoint: chưa có; candidate tiếp theo là CP5 — independent code verification
  and review
- Trạng thái checkpoint theo `NOW.md`: không có checkpoint `active`
- Trạng thái làm việc: `checkpoint_ready`
- Người thực hiện thay đổi chức năng: người dùng; CP4 đã đóng
- Vai trò của Codex `gpt-5.5` trong phiên này: hướng dẫn, kiểm tra evidence và cập
  nhật file tiến độ; không tự kích hoạt CP5

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

Coding workflow được người dùng chốt theo ba role tách context: Copilot ACP làm
implementation, reviewer được bind bằng config tự verify/review bắt buộc, và
Hermes/Codex `gpt-5.5` chỉ điều hướng/tổng hợp structured results. CP4 chứng minh
implementation handoff; CP5 chứng minh independent verification/review; CP6 mã
hóa workflow theo intent trong custom routing skill.

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
được kích hoạt.

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
| 2026-07-22 | Dành custom workflow routing cho CP6 | `company-assistant` skill sẽ route theo intent; coding bắt buộc review, non-coding có workflow/review policy riêng |
| 2026-07-22 | Verify CP4 | Copilot ACP implementation handoff, isolated workspace, bounded tool/context scope, expected patch, manual functional check, forbidden-action checks và repository closure checks đều pass; người dùng chấp nhận evidence |

## Câu hỏi chưa chặn bước hiện tại

- CP5 phải xác minh cách bind `gpt-5.6-sol` thành reviewer child fresh-context;
  Claude/model khác vẫn là replacement candidate, không hardcode vào workflow.
- CP5 phải chọn bounded check output để reviewer không nhận toàn repository hoặc
  test log không cần thiết.
- CP6 phải quyết định skill-only enforcement đã đủ hay cần hook/plugin để chặn
  coding final khi chưa có `ReviewResult.status=approved`.
- Telegram/Mattermost tokens nằm trong profile local `.env`; cần quyết định cơ
  chế backup/rotation ở checkpoint hardening, không đưa secret vào Git.

## Lịch sử cập nhật

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
