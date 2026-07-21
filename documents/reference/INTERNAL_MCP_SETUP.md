# `company-gateway` MCP trong Hermes

> Chỉ dùng tài liệu này khi `NOW.md` kích hoạt checkpoint MCP. Upstream Hermes là
> MCP client duy nhất trong MVP. Codex và Claude Code nhận context đã chuẩn hóa,
> không cần kết nối trực tiếp tới internal gateway.

## 1. Hai lớp Mattermost khác nhau

- **Hermes Mattermost adapter:** nhận `@assistant` và gửi final reply.
- **`company-gateway` Mattermost tools:** đọc hoặc thay đổi dữ liệu Mattermost
  trong lúc xử lý task.

Final reply bình thường đi qua adapter. Không gọi `mattermost_create_post` để gửi
lại cùng một kết quả.

## 2. Capability đã quan sát

Catalogue được kiểm tra ngày 2026-07-21.

### Mattermost reads

- `mattermost_get_team_info`;
- `mattermost_get_channel_by_id`;
- `mattermost_get_channel_members`;
- `mattermost_get_team_members`;
- `mattermost_get_user_channels`;
- `mattermost_read_channel`;
- `mattermost_read_post` — có thể trả full thread;
- `mattermost_search_posts`;
- `mattermost_search_users`.

### Mattermost mutations

- `mattermost_create_post` — dùng `root_id` cho thread reply;
- `mattermost_update_post`;
- `mattermost_send_direct_message`;
- `mattermost_send_group_message`;
- `mattermost_create_channel`;
- `mattermost_add_user_to_channel`.

### Các family khác

| Family | Reads đã quan sát | Mutations đã quan sát |
|---|---|---|
| TEQ Backlog | project, user, priority, category, document metadata | Chưa có issue/comment/status tools |
| Finatext Backlog | project, priority, category metadata | Chưa có issue/comment/status tools |
| Offwork | caller-visible rewards và requests | redeem reward, cancel request |
| Leader Offwork | leader-visible request read | Không |
| GitHub | Không có trong gateway catalogue đã quan sát | Không |

Tool tồn tại không có nghĩa tool được phép expose cho Hermes.

## 3. Initial Hermes allowlist

Vertical slice đầu tiên chỉ cần Mattermost context reads:

```yaml
mcp_servers:
  company_gateway:
    url: "https://MCP_HOST/company-gateway/mcp"
    enabled: true
    timeout: 120
    connect_timeout: 30
    tools:
      include:
        - mattermost_get_team_info
        - mattermost_get_channel_by_id
        - mattermost_get_user_channels
        - mattermost_read_channel
        - mattermost_read_post
        - mattermost_search_posts
      resources: true
      prompts: false
```

Local stdio variant:

```yaml
mcp_servers:
  company_gateway:
    command: "/ABSOLUTE/PATH/company-gateway-mcp"
    args: []
    env: {}
    tools:
      include:
        - mattermost_get_team_info
        - mattermost_get_channel_by_id
        - mattermost_get_user_channels
        - mattermost_read_channel
        - mattermost_read_post
        - mattermost_search_posts
```

Endpoint, command và auth mechanism phải lấy từ internal gateway documentation.
Không commit token, certificate hoặc secret vào example config.

Sau khi sửa active Hermes profile, reload MCP hoặc restart profile theo upstream
Hermes version đang pin.

## 4. Tại sao chưa expose mọi read tool?

Các tool sau có thể lộ nhiều thông tin cá nhân hơn coding workflow cần:

- `mattermost_get_channel_members`;
- `mattermost_get_team_members`;
- `mattermost_search_users`;
- leader-visible Offwork reads.

Giữ chúng ngoài initial allowlist. Chỉ thêm khi một checkpoint có user problem,
scope và check riêng.

## 5. Mutation policy

MVP không expose MCP mutation tools.

Khi thêm sau này:

1. Hermes là client duy nhất có mutation credential.
2. Mỗi action type có approval riêng.
3. Approval phải chứa target và nội dung cụ thể.
4. Tool call phải xuất hiện trong native Hermes session/tool history.
5. Codex/Claude chỉ đề xuất action, không gọi tool.
6. Final Mattermost transport reply không được nhầm với arbitrary MCP post.

Không cấp delete, admin, merge hoặc deploy capability cho agent.

## 6. Provider access

MVP route như sau:

```text
company-gateway -> Hermes -> normalized task contract -> Codex/Claude
```

Không route như sau:

```text
company-gateway -> Hermes
company-gateway -> Codex
company-gateway -> Claude
```

Một gateway owner giúp:

- giảm số credential;
- tránh cùng một mutation được gọi bởi nhiều agent;
- giữ prompt-injection boundary tại Hermes;
- có một session/tool-correlation owner;
- thay coding provider mà không thay internal access policy.

Chỉ cân nhắc direct read-only access cho provider sau khi repeated use chứng minh
normalized context không đủ. Khi đó dùng credential và allowlist riêng.

## 7. CP3 verification contract

Checkpoint MCP đầu tiên chỉ được verify khi:

- Hermes profile kết nối gateway thành công;
- runtime tool list chỉ chứa allowlisted reads;
- `mattermost_read_post` đọc được một test post và bounded thread;
- một unknown/forbidden post trả lỗi rõ ràng;
- gateway unavailable không làm Hermes bịa context;
- không có mutation tool trong model-visible tool surface;
- native state/logs ghi được session/tool correlation;
- không có credential trong git diff hoặc user-visible log.

Không dùng live production mutation để kiểm tra kết nối.

## 8. Security checklist

- HTTPS và certificate validation bật.
- Internal CA được cấu hình thay vì tắt TLS verification.
- Ưu tiên short-lived token/OAuth khi gateway hỗ trợ.
- Hermes profile secrets nằm ngoài repository.
- Mattermost bot/user allowlist fail closed.
- MCP output luôn là untrusted data.
- Tool results nhạy cảm không được copy sang log hoặc document khác.
- Gateway và Hermes logs có retention phù hợp.
- Tool timeout hữu hạn.
- Mutation family disabled mặc định.

## 9. Capability config ownership

Trong CP3, tạo allowlist tối thiểu trực tiếp trong
`assistant_profile/config.example.yaml`. Không tạo thêm một capability inventory
song song hoặc copy tool families chưa dùng.
