# Nhật ký triển khai

> File này chỉ ghi tiến độ và evidence thực tế. `NOW.md` vẫn là plan/checkpoint
> có thẩm quyền duy nhất. Không dùng file này để tự kích hoạt checkpoint mới.

## Trạng thái tổng quát

- Cập nhật gần nhất: 2026-07-21
- Checkpoint: CP1 — Upstream Hermes local baseline
- Trạng thái checkpoint theo `NOW.md`: `verified`
- Trạng thái làm việc: `checkpoint_closed`
- Người thực hiện thay đổi chức năng: người dùng
- Vai trò của Codex trong phiên này: hướng dẫn, kiểm tra evidence và cập nhật file
  tiến độ

## Mục tiêu đã hiểu

Repository này không xây thêm agent runtime, MCP client, session engine hay CLI
wrapper. Mục tiêu MVP là dùng upstream `nousresearch/hermes-agent` làm runtime,
giữ phần tùy biến của repository ở dạng profile/config/skill/hook/tests mỏng và
chỉ tạo chúng khi checkpoint tương ứng yêu cầu.

CP1 chỉ cần chứng minh một bản Hermes upstream đã pin có thể chạy local bằng một
profile riêng, hoàn thành một prompt đơn giản, lưu session/log trong profile đó
và không làm lộ secret trong Git. Mattermost, `company-gateway`, coding agents,
audit hook, Docker và database đều chưa thuộc phạm vi.

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
checkpoint `active`; CP2 vẫn là candidate cho tới khi người dùng chọn kích hoạt.

Đánh giá hiện tại:

- Tất cả CP1 checks kỹ thuật đã pass.
- Warning `tirith` ban đầu không chặn; binary đã được cài sau đó.
- Baseline context 15,840 tokens là risk/optimization evidence cho checkpoint
  sau, không làm CP1 fail.
- Routing mới (Codex reasoning, Copilot implementation) đã được ghi nhưng chưa
  kích hoạt checkpoint coding.

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
| 2026-07-21 | Dự kiến thay CP5 từ Codex implementation sang GitHub Copilot CLI implementation | Người dùng muốn dùng Copilot allowance nhiều hơn cho coding; upstream hỗ trợ `copilot-acp`, cần checkpoint riêng để verify |
| 2026-07-21 | Chọn model `gpt-5.5` cho CP1 | Model wizard trong profile `diy-l2t` xác nhận provider `OpenAI Codex` và credentials hợp lệ |
| 2026-07-21 | Ghi nhận installer mặc định theo `main`; ban đầu dùng detached checkout tại full commit đã smoke-test | Sau đó xác định detach không cần cho `git pull` trong project và nên reattach để giữ managed install workflow |
| 2026-07-21 | Pin CP1 theo evidence/process: ghi full commit và chỉ update Hermes bằng action explicit | `diy-l2t-backend` và `~/.hermes/hermes-agent` là hai Git repository độc lập; branch local không tự di chuyển |
| 2026-07-21 | Verify CP1 | Version/install/profile/provider/smoke/session/state/log/secret checks pass; người dùng chấp nhận evidence |

## Câu hỏi chưa chặn bước hiện tại

- Trước checkpoint coding, phải thay candidate CP5 trong `NOW.md` bằng Copilot
  implementation và xác minh Copilot CLI/ACP; chưa sửa/activate CP5 trong CP1.
- Trước CP5/CP6 cần đặt giới hạn context/checks để không gửi toàn repository hoặc
  test log không cần thiết sang Copilot/Claude.
- Secret sẽ được quản lý bằng cơ chế nào? CP1 chỉ yêu cầu giữ secret ngoài Git;
  không quyết định sớm thay cho người dùng.

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
  provider, còn CP5 phải được thay thế/verify riêng khi đến checkpoint đó.
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
