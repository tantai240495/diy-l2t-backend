# DIY-L2T Local Assistant

Assistant cá nhân chạy local trên macOS, nhận yêu cầu từ Telegram và dùng Hermes
Agent để gọi tool trực tiếp hoặc điều phối coder và reviewer qua Kanban, có
điểm chờ người dùng xác nhận giữa hai bước.

```text
Telegram → Hermes orchestrator → tool | delegate | Kanban (coder → [xác nhận] → reviewer) → final reply
```

MVP chạy on-demand, dùng Git worktree của repository thật cho coding, tự động
với read/local actions trong policy và yêu cầu approval trước external write,
push, PR, merge, deploy hoặc production action.

## Bắt đầu

1. Đọc [Master Guide](documents/MASTER_GUIDE.md) để hiểu product contract,
   kiến trúc, security, capability matrix và roadmap.
2. Thực hiện đúng checkpoint duy nhất trong [NOW](documents/NOW.md).
3. Ghi quyết định và smoke evidence vào [PROGRESS](documents/PROGRESS.md).

Machine-readable route, task và result contracts nằm trong
`assistant_profile/`. FastAPI skeleton hiện có không phải runtime/control plane
của assistant; Hermes upstream đảm nhiệm gateway, profiles, sessions và Kanban.

Không commit token, user ID, MCP credential, OAuth material hoặc test credential
vào repository.
