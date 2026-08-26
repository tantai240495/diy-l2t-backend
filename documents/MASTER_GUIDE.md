# DIY-L2T Local Assistant — Master Guide

> Nguồn sự thật duy nhất cho product contract, kiến trúc, capability, security,
> vận hành và roadmap. Trạng thái triển khai hiện tại nằm ở
> [NOW.md](NOW.md); evidence đã quan sát nằm ở [PROGRESS.md](PROGRESS.md).

## 1. Mục tiêu sản phẩm

DIY-L2T là assistant cá nhân chạy local trên máy macOS của chủ sở hữu. Người
dùng gửi yêu cầu qua Telegram; Hermes Agent tiếp nhận, chọn cách thực thi phù
hợp và gửi đúng một kết quả cuối về cuộc trò chuyện ban đầu.

```text
Telegram
  → diy-l2t orchestrator
  → direct MCP/native tool | delegate_task | Hermes Kanban
  → coder → [chờ người dùng xác nhận] → reviewer / future profiles
  → final result về Telegram
```

MVP phải hỗ trợ:

- vận hành on-demand trên Mac, sau khi người dùng đăng nhập;
- đọc Mattermost, pull request và task backlog qua MCP;
- làm việc trên một repository đã đăng ký, tự code, kiểm tra và review độc lập;
- tạo AI news brief có nguồn, ngày và mức độ chắc chắn;
- mở rộng capability, profile, transport và tool backend mà không thay runtime
  lõi.

### Product contract

- Upstream `nousresearch/hermes-agent` là runtime, gateway, profile/session
  owner, Kanban dispatcher và task-state owner.
- Repository này chỉ sở hữu policy, route registry, envelope schema, project
  conventions, tài liệu và smoke/acceptance evidence.
- Project là khái niệm project-owned (không phải Hermes "Project" — tool đó
  chỉ dùng được trong GUI/desktop session). Mỗi codebase đăng ký một project
  slug, một primary repository và một Kanban board tương ứng, orchestrator tự
  nhớ qua Memory (§5).
- Named profile luôn đi qua Hermes Kanban — đây là cơ chế duy nhất Hermes cung
  cấp để orchestrator handoff việc cho một profile có tên/model riêng biệt
  (không tool nào khác trong Hermes làm được việc này; xem §13). Giữa coder và
  reviewer có một điểm block/unblock chủ đích: coder xong tự block task, chờ
  người dùng xác nhận qua Telegram rồi mới dispatch sang reviewer. Không tạo
  FastAPI dispatcher, custom queue, custom MCP dispatcher hoặc database song
  song ngoài Kanban có sẵn của Hermes.
- `delegate_task` chỉ phục vụ reasoning/research ngắn cần trả ngay về parent.
- Coding mặc định bàn giao một branch trong preserved Git worktree của
  repository thật, đã commit và chưa push.
- Mọi quyền fail closed: nếu project, target, credential, environment hoặc
  approval không đủ rõ, route phải là `needs_input`.

### Non-goals của MVP

- Không chạy cron, scheduled digest hoặc proactive message.
- Không có cloud fallback, external database, Docker sandbox hoặc custom queue.
- Không tự push, mở PR, merge, deploy hay thao tác production.
- Không biến assistant thành một hosting platform hoặc thay thế Hermes.
- FastAPI skeleton hiện có không phải control plane của sản phẩm.

## 2. Ownership và kiến trúc

| Thành phần | Sở hữu | Trách nhiệm |
|---|---|---|
| Telegram adapter/gateway | Hermes | Polling, allowlist, session, correlation và gửi reply |
| Orchestrator `diy-l2t` | Hermes profile + policy của project | Hiểu intent, chọn route, xin input/approval, tổng hợp final |
| Kanban board/dispatcher | Hermes | Durable task lifecycle, dependency, retry, comments, runs và handoff |
| Project mapping | Orchestrator Memory (`MEMORY.md`) | Slug, board, primary repository |
| Named workers | Hermes profiles | Coder, reviewer và profile tương lai |
| MCP transport/tool execution | Hermes | Credential, connection và bounded tool call |
| Route/envelope contract | Repository này | Schema v2, capability registry và workflow gate |
| Repository conventions | Repository đích | `AGENTS.md`, startup/test commands và local constraints |
| Model/provider | Provider được cấu hình theo profile | Inference và usage/cost tương ứng |
| Evidence | Hermes state/Kanban + repository artifacts | Run metadata, checks, commits, findings và audit |

Kanban là control plane cho công việc qua nhiều named profile — đây là cách
duy nhất Hermes hỗ trợ để orchestrator handoff việc cho một profile có tên và
model riêng biệt (`delegate_task` chỉ spawn subagent ẩn danh, không target
được named profile). Mỗi board dùng SQLite local riêng và worker được
dispatcher khởi chạy như một process có profile riêng. Gateway đang chạy cũng
chứa dispatcher; không chạy thêm daemon cạnh tranh.

`delegate_task` và Kanban cùng tồn tại nhưng không thay thế nhau:

| Tình huống | Primitive |
|---|---|
| Một MCP/native call hữu hạn | `direct_tool` |
| Parent cần một câu trả lời reasoning/research ngắn trước khi tiếp tục | `delegate_task` |
| Qua named role, cần workspace riêng, model riêng, durable state hoặc audit | `named_profile` qua Kanban |
| Thiếu project, target, credential, environment hoặc quyền | `needs_input` |

Kanban worker có thể dùng `delegate_task` bên trong run cho một subtask ngắn,
nhưng kết quả chính và handoff vẫn phải hoàn tất qua Kanban.

## 3. Capability matrix

`Trạng thái` dùng `verified`, `planned`, `blocked` hoặc `future`. `Approval`
`task-policy` nghĩa là hành động đã được TaskEnvelope cho phép; `explicit` nghĩa
là phải preview và nhận xác nhận riêng ngay trước mutation.

| Capability | Telegram intent | Route kind | Executor/profile | Tools | Workspace/environment | Approval | Output/evidence | Cost source | Phase | Trạng thái |
|---|---|---|---|---|---|---|---|---|---|---|
| Chat/final reply | Câu hỏi thông thường | orchestrator | `diy-l2t` | Hermes gateway/model | Profile session | task-policy | Một final reply, session ID | Model/provider | 1 | verified foreground; service planned |
| MCP read | Đọc Mattermost/PR/Backlog | direct_tool | `diy-l2t` | Allowlisted MCP read tool | Không workspace | task-policy | Bounded result + tool evidence | MCP backend nếu có | 4 | Mattermost slice verified; mở rộng planned |
| Short synthesis | So sánh/tổng hợp hữu hạn | delegate | Fresh subagent | `delegate_task` | Fresh context, bounded inputs | task-policy | Summary về parent | Delegation model | 4 | primitive verified |
| Code implementation | Sửa code project X | named_profile | `diy-l2t-coder` | File/terminal/test tools | Preserved Git worktree, local/test | task-policy | Commit SHA, files, checks | Copilot/model | 2 | planned Kanban slice |
| Independent review | Review thay đổi | named_profile | `diy-l2t-reviewer` | Read/diff/test tools | Exact coder worktree, read-only tracked files | task-policy | Findings + `approved`/`changes_requested` | OpenAI/model | 2 | profile verified; Kanban slice planned |
| Mattermost reply | Trả lời thread/post | direct_tool | `diy-l2t` | Một allowlisted MCP mutation | External service | explicit target + exact content | Mutation ID, no duplicate final | MCP backend nếu có | 4 | planned first write |
| AI news brief | Tin AI hôm nay/tuần này | direct_tool hoặc delegate | `diy-l2t` | Curated RSS/HTTP + search fallback | Read-only web | task-policy | Links, dates, dedupe, uncertainty | Search/backend/model | 5 | planned |
| Push/open PR/merge/deploy | Xuất bản code | direct_tool hoặc future workflow | Chưa promote | Git/MCP/CI tools | Repo/remote/environment cụ thể | explicit per action | Remote ID/SHA/checks | Git host/CI/model | 6+ | future |
| Slack/Mattermost ingress | Chat từ transport khác | transport adapter | Cùng core profiles | Hermes gateway adapter | Transport metadata only | policy riêng | Correlated final reply | Transport/backend | 6+ | future |

## 4. Routing, context và handoff

### RouteDecision v2

Orchestrator tạo một quyết định route với:

- `route_kind`: `direct_tool`, `delegate`, `named_profile` hoặc `needs_input`;
- `dispatch_mode`: `direct`, `delegate`, `kanban` hoặc `user`;
- target capability/profile;
- project slug và board slug khi route gắn với project;
- `approval_class`: `none`, `task_policy`, `explicit_user` hoặc
  `not_applicable`;
- lý do ngắn, không chứa hidden reasoning.

Transport chỉ tạo correlation để trả kết quả. Telegram, Mattermost hay Slack
không xuất hiện trong core TaskEnvelope/ResultEnvelope.

### TaskEnvelope v2 trong Kanban

Trusted task context chứa JSON khớp `diy-l2t.task.v2`, gồm:

- project slug, primary repository, board/task lineage;
- role, capability, objective và bounded inputs;
- base ref; workspace kind/path/branch;
- environment identifier và cờ production luôn `false` trong MVP;
- acceptance criteria, allowed/forbidden actions và required checks;
- approval class và correlation không chứa secret.

Parent không truyền toàn bộ conversation hoặc hidden reasoning. Worker gọi
`kanban_show` và nhận TaskEnvelope, parent summaries/metadata, comments, prior
attempts và exact workspace. Chỉ đưa vào bounded facts cần thiết.

Khi caller đã biết Kanban task ID, TaskEnvelope nên nằm trực tiếp trong body.
CLI `kanban create` tự sinh ID nên staged flow được phép: dừng/pause dispatcher,
tạo stub, lấy actual ID, materialize/validate TaskEnvelope rồi append nó bằng
trusted pre-dispatch comment. Không dựa riêng vào `--initial-status blocked`;
phải xác minh task có sticky `blocked` event hoặc giữ gateway dừng cho tới khi
envelope đã attach. Task chỉ được `unblock` sau khi envelope và workspace/branch
lineage validate. Stub body một mình không được dispatch.

### ResultEnvelope v2

`kanban_complete.metadata` chứa JSON khớp `diy-l2t.result.v2`, gồm:

- Kanban run ID, executor profile/model/session;
- workspace, branch, base/head commit và changed files;
- check commands, exit status/evidence, artifacts và findings;
- residual risks, usage/cost nếu quan sát được;
- workflow gate: review status, rework count và `finalizable`.

`summary` là mô tả cô đọng (tối đa 4000 ký tự), không phải nơi nhúng raw diff.
Khi orchestrator relay kết quả coder về Telegram, chỉ gửi bảng tóm tắt dựng từ
`summary` + `files_changed` + `checks` + `workspace.path`; người dùng tự xem
diff đầy đủ trực tiếp trong worktree.

Reviewer phải để `finalizable=false` trừ khi `review_status=approved`. Status
khác `approved` không được diễn giải thành success ở Telegram.

Raw logs, credential, token, OAuth material, full external content và hidden
reasoning không được đưa vào task metadata.

## 5. Project và workspace policy

### Đăng ký project

Orchestrator tự nhớ project qua **Memory** (`MEMORY.md`, ghi bằng tool
`memory`) — không dùng Hermes "Project" (`project_create`/`project_list`),
vì tool đó chỉ chạy trong GUI/desktop session, không gọi được từ session do
Telegram trigger. Mỗi project có:

- một slug, dùng khi cần phân biệt nhiều project trong hội thoại;
- một Kanban board cùng phạm vi;
- một primary repository canonical;
- `AGENTS.md` trong repository mô tả conventions, startup command, test command,
  cấu trúc và các constraint riêng — Hermes tự nạp khi làm việc trong repo đó,
  không cần orchestrator nhớ thay.

Đăng ký project mới qua chat: người dùng cho biết tên và path repo, orchestrator
tự chạy `hermes kanban boards create <slug> --switch` rồi ghi một entry vào
Memory (`memory(action='add', ...)`) — không ai sửa file nào bằng tay.

Nếu prompt không nói project và Memory chỉ có đúng một project → orchestrator
tự suy ra, khỏi hỏi. Nếu Memory có nhiều project và không suy ra được duy nhất
một cái → bot phải hỏi lại. Không đoán đường dẫn từ tên gần giống.

### Worktree mặc định

Temp directory chỉ phù hợp với scratch task không cần lịch sử Git. Coding/review
trên project thật dùng:

```text
<repository>/.worktrees/<task-id>/
```

Mỗi task tạo branch/worktree dưới repository thật. `.worktrees/` phải bị ignore
khỏi Git status. Coder và reviewer chạy tuần tự trên cùng exact worktree; không
có hai writer đồng thời.

Worktree được giữ sau khi task hoàn tất để người dùng kiểm tra. Không tự xóa
dirty/unmerged worktree. Cleanup chỉ xảy ra khi target đã được xác nhận và trạng
thái recoverable.

### Coding pipeline

```text
TaskEnvelope
  → coder: implementation + unit/integration tests
  → [task blocks; chờ người dùng xác nhận qua Telegram]
  → reviewer: diff + checks + independent review, không sửa tracked files
  → approved | changes_requested | blocked
```

Coder và reviewer là Kanban worker, dispatch qua board của project — cách duy
nhất Hermes hỗ trợ để handoff cho một profile có tên/model riêng biệt (xem
§13). Mỗi khi coder hoàn tất một phiên bản (kể cả sau rework), task tự chuyển
`blocked` thay vì tự động dispatch sang reviewer. Orchestrator gửi Telegram
một bảng tóm tắt ngắn — task ID, commit SHA, đường dẫn worktree, danh sách
file đổi, kết quả checks — không nhúng raw diff; người dùng tự xem diff đầy
đủ trực tiếp trong worktree. Khi người dùng xác nhận (ví dụ "review đi"),
orchestrator unblock task và reviewer được dispatcher pick lên.

- Coder sở hữu implementation và unit/integration tests.
- Reviewer đọc diff, chạy checks cần thiết và không sửa tracked files.
- Không giới hạn cứng số vòng `changes_requested`; sau mỗi vòng sửa, coder
  quay lại `blocked` chờ xác nhận trước khi reviewer chạy lại. Nếu hai vòng
  liên tiếp trả cùng finding (không tiến triển), orchestrator phải dừng và
  trả `needs_input` thay vì lặp vô hạn.
- Bàn giao mặc định: local branch đã commit, commit SHA, changed files, checks
  và residual risks. Không push, PR, merge hoặc deploy.
- Main checkout không được thay đổi bởi task worker.

Initial profiles:

| Role | Profile | Provider/model |
|---|---|---|
| Orchestrator | `diy-l2t` | OpenAI Codex `gpt-5.5` |
| Coder | `diy-l2t-coder` | direct Copilot `claude-sonnet-5` |
| Reviewer | `diy-l2t-reviewer` | OpenAI Codex `gpt-5.6-sol` |

Model names là baseline đã chọn, không phải secret. Khi provider đổi model,
profile config, smoke evidence và cost assumptions phải được cập nhật.

### SOUL.md, Skill và Memory — nội dung mỗi profile

Hermes không có registry riêng cho danh sách profile/route/policy. Policy sản
phẩm này (route theo capability, Kanban, TaskEnvelope, chờ xác nhận...) không
thuộc `SOUL.md` (chỉ dành cho giọng điệu/tính cách, xem ví dụ chuẩn ở
[Personality & SOUL.md](https://hermes-agent.nousresearch.com/docs/user-guide/features/personality))
và cũng không thuộc `AGENTS.md` (chỉ dành cho quy ước riêng của repository
đích). Bốn chỗ thật sự cần điền cho mỗi profile:

| Hermes concept | Chứa gì | Ai ghi | Khi nào nạp |
|---|---|---|---|
| `SOUL.md` | Giọng điệu, tính cách | Người viết tay, hiếm sửa | Luôn luôn |
| Skill | Quy trình vận hành (routing, Kanban, TaskEnvelope, chờ xác nhận) | Người viết tay | On-demand khi cần |
| `AGENTS.md` (trong repo đích) | Quy ước riêng một codebase (lệnh test, stack) | Người viết tay | Khi làm việc trong repo đó |
| Memory (`MEMORY.md`) | Sự thật động — project nào, repo nào, board nào | Agent tự ghi qua tool `memory` | Luôn luôn (frozen snapshot đầu session) |

**Orchestrator (`diy-l2t`)** — không phải Kanban worker nên không cần
`--description`.
- SOUL.md: chỉ giọng điệu (ngắn gọn, trực tiếp, không sycophancy) — không
  chứa policy.
- Skill (vd `diy-l2t-coding-pipeline`, "When to Use" = có yêu cầu code trên
  project đã biết): tra Memory tìm project → tạo board/ghi Memory nếu là
  project mới (§5 "Đăng ký project") → tạo Kanban task theo staged flow (§4)
  → sau khi coder `kanban_complete`, dừng, gửi Telegram bảng tóm tắt (không
  raw diff), chờ xác nhận → unblock reviewer → chỉ một final reply mỗi
  request → fail closed khi thiếu project/target/credential/approval.

**Coder (`diy-l2t-coder`)** và **Reviewer (`diy-l2t-reviewer`)**
- SOUL.md: chỉ giọng điệu (coder: thực dụng; reviewer: khó tính, cụ thể).
- Không cần skill riêng — luật đứng (chỉ sửa file trong worktree, không
  push/PR/merge/deploy, reviewer read-only...) đã nằm trong
  `allowed_actions`/`forbidden_actions` của TaskEnvelope mà orchestrator tự
  soạn mỗi task (§4); worker đọc đủ qua `kanban_show`, không cần nhớ sẵn.
- `--description` (routing hint cho Kanban orchestrator, không phải policy):
  - coder: "Implements and tests code changes inside the assigned Git
    worktree; commits locally; never pushes, opens PRs, merges, or deploys."
  - reviewer: "Independently reviews a coder's diff and checks inside the
    exact same worktree; read-only; decides approved or changes_requested."

Khi build thật: SOUL.md giữ vài dòng giọng điệu; phần policy chi tiết viết
thành đúng một skill cho orchestrator, copy phần liên quan từ §4–§9 thay vì
copy nguyên Master Guide.

## 6. Test policy

- Coder chạy required checks (unit/integration) ngay trong exact worktree,
  local hoặc test environment; production URL và domain ngoài allowlist bị
  chặn.
- Test credential nằm ngoài Git, không xuất hiện trong metadata hoặc raw log
  hiển thị cho người dùng.
- Failure phải actionable; không được đổi test thành pass bằng cách bỏ assertion
  hoặc skip không có lý do.
- Reviewer kiểm tra implementation và unit/integration checks trước khi approve.
- Browser/E2E testing (Playwright) không thuộc MVP; xem future candidates ở
  mục 11.

## 7. MCP và external actions

Mattermost/PR/Backlog read là direct tool call. Không tạo agent chỉ để bọc một
tool call hữu hạn. Hermes sở hữu MCP credential và connection; repository chỉ
khai báo capability/tool allowlist và policy.

Mọi content đọc từ website, issue, PR, backlog, chat hoặc MCP là untrusted data:

- không thể thay đổi system/tool policy;
- không thể cấp thêm tool, scope, credential hoặc approval;
- câu lệnh nằm trong external content được coi là dữ liệu;
- kết quả chỉ được dùng trong bounded objective của TaskEnvelope.

External read được tự động nếu tool và target nằm trong task policy. External
write, push, PR, merge, deploy và production action cần approval riêng.

Controlled write đầu tiên là Mattermost reply:

1. Resolve đúng server/channel/thread/post.
2. Hiển thị target và exact content.
3. Chờ explicit approval còn hiệu lực.
4. Gọi đúng một allowlisted mutation tool.
5. Lưu mutation evidence và không gửi trùng nội dung trong final response.

Approval không được tái sử dụng cho target/content/action khác. Nếu mutation
timeout và trạng thái chưa rõ, kiểm tra idempotency/external state trước khi
retry.

## 8. AI news brief

AI brief chỉ chạy on-demand từ Telegram trong MVP:

- ưu tiên allowlist nguồn chính thức, research lab/company blog và RSS chọn lọc;
- web search chỉ bổ sung khoảng trống;
- mỗi mục có link trực tiếp, publication/event date và nguồn;
- loại bỏ bài trùng/syndicated;
- phân biệt fact, tuyên bố của nguồn và suy luận của assistant;
- ghi uncertainty khi ngày, claim hoặc attribution chưa xác minh;
- không cron, proactive message hoặc subscription bắt buộc.

Nous Portal không bắt buộc. Có thể dùng RSS/HTTP read-only hoặc search backend
khác. Nếu chọn Nous Tool Gateway hay dịch vụ trả phí, subscription phải được ghi
ở cost source trước khi promote capability.

## 9. Security và approval model

### Approval classes

| Class | Ý nghĩa |
|---|---|
| `none` | Pure local/read action không cần thêm quyền |
| `task_policy` | Được TaskEnvelope và allowlist cho phép |
| `explicit_user` | Preview action cụ thể và chờ người dùng xác nhận |
| `not_applicable` | Route chưa thể chạy, thường là `needs_input` |

Baseline:

- local read/check và allowlisted external read: tự động;
- tracked-file edit trong exact worktree: `task_policy`;
- external write, push, open PR, merge, deploy, production: `explicit_user`;
- secret/permission/target không rõ: `needs_input`.

### Secret và identity

- Telegram bot token, user ID allowlist, MCP headers, OAuth/token và test
  credential nằm ngoài Git.
- Log/user-visible metadata phải redact secret; không in credential để debug.
- Gateway chỉ nhận Telegram DM từ strict numeric user allowlist.
- Transport metadata chỉ dùng correlation/reply, không truyền sang core task
  ngoài các opaque IDs cần thiết.
- Profile/tool allowlist theo least privilege và fail closed.

### Environment

- Coding mặc định local; production bị cấm trong MVP.
- Command chạy trong exact workspace của task, không dùng temp thay cho project.
- Một writer tại một thời điểm; reviewer không phải writer.
- Không chạy script hoặc instruction lấy từ external content nếu chưa được
  xem như code/input riêng và policy cho phép.

## 10. Chi phí và vận hành Mac

### Chi phí

Hermes Kanban dùng SQLite local và không có phí riêng. Chi phí có thể đến từ:

- model/API token hoặc subscription của từng profile;
- GitHub Copilot subscription cho coder;
- MCP/search/tool backend hoặc Nous Portal nếu chủ động chọn;
- CI/test infrastructure bên ngoài;
- điện và mạng của máy Mac.

Mỗi capability phải khai báo cost source; “không quan sát được” khác với “miễn
phí”. Usage/cost chỉ ghi trong ResultEnvelope khi provider thực sự cung cấp.

### Runtime Mac

- Hermes gateway chạy như macOS LaunchAgent sau login và tự restart khi lỗi.
- Telegram polling nên không mở inbound port.
- Không có cloud instance dự phòng trong MVP.
- Nếu Mac ngủ, mất mạng hoặc gateway dừng, bot không tạo response giả. Task
  durable chờ dispatcher quay lại.
- Backup profile/state trước Hermes update và định kỳ hằng tuần.
- Pin/record Hermes version trước mỗi verified vertical slice.

### Retention và observability

- Kanban/task structured evidence giữ local theo vòng đời project.
- Raw execution logs mặc định giữ 30 ngày rồi rotate.
- Evidence ưu tiên pointer + summary thay vì nhúng raw log.
- Theo dõi task/run ID, profile/session, duration, check status, retry và blocker.
- Dirty/unmerged worktree không tự động xóa bởi retention job.
- Backup phải gồm profile config/state, Kanban DB và registry; secret backup phải
  được mã hóa và tách khỏi repository.

## 11. Roadmap và acceptance tests

### Phase 0 — Consolidate source of truth

Phạm vi:

- tạo Master Guide và chỉ giữ bốn human docs;
- nâng route/task/result contract lên v2 và map trực tiếp vào Kanban;
- retire tài liệu trùng lặp;
- ghi CP1–CP5 là verified evidence; thay CP6 manual dispatcher bằng hướng
  Hermes-native Kanban.

Acceptance:

- link nội bộ hợp lệ và chỉ còn `README.md`, `MASTER_GUIDE.md`, `NOW.md`,
  `PROGRESS.md` trong bộ product docs;
- JSON examples validate với schema v2; YAML registry parse được;
- security requirement và quyết định cũ còn trong master/progress;
- `.worktrees/` được ignore.

### Phase 1 — Always-on Telegram control plane

- Cài LaunchAgent, gateway auto-restart và strict Telegram user allowlist.
- Reboot/login smoke: một authorized DM nhận đúng một final reply.
- Unauthorized user bị từ chối.
- Mac/gateway unavailable không tạo response giả.
- Không token/user ID trong Git hoặc user-visible logs.

### Phase 2 — Project + Kanban coding vertical slice

- Đăng ký một project (Memory + Kanban board) gắn với repository thử nghiệm
  thật, qua chat.
- Telegram request nhắc đúng project tạo được coder → reviewer dependency, có
  điểm block/unblock chờ người dùng xác nhận qua Telegram giữa hai bước.
- Coder tạo worktree/branch, commit và chạy required checks; Telegram nhận
  bảng tóm tắt (không phải raw diff).
- Reviewer dùng exact worktree, không sửa tracked files.
- Chỉ `approved` mới final success; main checkout không đổi; không push/PR/merge/
  deploy.

### Phase 4 — MCP workflows

- Mỗi read capability có bounded smoke và tool allowlist.
- PR/Backlog/Mattermost reads gọi trực tiếp.
- Mattermost reply bắt buộc preview + approval + đúng một mutation.
- Prompt-injection sentinel không đổi route hoặc mở rộng quyền.

### Phase 5 — On-demand AI brief

- Telegram request tạo brief từ nguồn chọn lọc và search bổ sung.
- Có citations, dates, deduplication và uncertainty.
- Không cron, proactive message hoặc subscription bắt buộc.

### Phase 6 — Extension framework

Mỗi capability mới phải khai báo:

1. user story;
2. route kind;
3. profile/tool và least-privilege allowlist;
4. credentials;
5. project/workspace/environment;
6. approval class;
7. input/output contract;
8. independent smoke test;
9. cost source;
10. rollback và observability.

Chỉ promote khi một vertical slice pass độc lập. Future candidates: QA/browser
E2E profile (Playwright), Slack hoặc Mattermost ingress, scheduled AI digest,
Backlog/GitHub controlled writes, PR creation, research/translation profiles
và optional Docker sandbox.

## 12. Quy trình thêm profile, capability hoặc transport

### Capability

1. Thêm một dòng `planned` vào capability matrix.
2. Khai route, tool/profile, environment, approval và cost.
3. Tạo/điều chỉnh TaskEnvelope/ResultEnvelope nếu contract thực sự thiếu dữ
   liệu; không thêm transport-specific field.
4. Cấu hình allowlist tối thiểu.
5. Chạy bounded smoke độc lập và ghi evidence vào `PROGRESS.md`.
6. Chỉ đổi thành `verified` sau khi acceptance pass.

### Named profile

1. Chứng minh direct tool hoặc delegate không phù hợp.
2. Chọn role, provider/model và least-privilege toolsets.
3. Tạo Hermes profile, pin board assignee và chạy profile smoke.
4. Thêm Kanban dependency/workflow gate.
5. Chứng minh restart/retry/handoff và chi phí.

### Transport

1. Giữ nguyên core envelope và route semantics.
2. Cấu hình adapter, identity allowlist và reply correlation riêng.
3. Chứng minh unauthorized rejection, đúng một final reply và secret redaction.
4. External mutation policy không thay đổi theo transport.

## 13. Canonical artifacts và nguồn upstream

Machine-readable artifacts:

- `assistant_profile/contracts/agent-contracts.schema.json`: JSON Schema v2 cho
  RouteDecision/TaskEnvelope/ResultEnvelope — nội dung thật sự đi vào Kanban
  task body/comment/metadata (`kanban_create`, `kanban_comment`,
  `kanban_complete`), không phải một registry riêng của Hermes;
- ba JSON examples cùng thư mục: route, task và result mẫu.

Không có registry YAML riêng ở tầng repo cho danh sách profile/route/workflow —
Hermes không đọc dạng file đó. Mapping capability → profile và thứ tự
coder → reviewer chỉ tồn tại ở hai nơi thật: `--description` lúc tạo profile
(Kanban orchestrator dùng để route) và nội dung `SOUL.md`/policy nạp vào từng
profile (xem §5 "SOUL.md và description mỗi profile").

Human docs:

- root `README.md`: entrypoint và quick start;
- file này: product/architecture contract;
- `NOW.md`: đúng một checkpoint active;
- `PROGRESS.md`: evidence, quyết định và smoke history.

Nguồn upstream dùng để kiểm chứng direction:

- [Hermes Kanban](https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban)
- [Profiles](https://hermes-agent.nousresearch.com/docs/user-guide/profiles/)
- [Subagent delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation)
- [Git worktrees](https://hermes-agent.nousresearch.com/docs/user-guide/git-worktrees)
- [Toolsets, gồm Kanban và Project](https://hermes-agent.nousresearch.com/docs/reference/toolsets-reference)

Khi Master Guide mâu thuẫn với một historical note, Master Guide thắng. Khi
upstream behavior đổi, phải verify version mới rồi cập nhật contract và evidence
trước khi dựa vào behavior đó.
