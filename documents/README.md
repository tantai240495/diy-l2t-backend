# Bắt đầu từ đây

Hướng đã chọn là **Hermes-first**: dùng upstream Hermes Agent làm runtime, không
tự xây một assistant runtime khác trong repository này.

## Chỉ cần đọc theo thứ tự này

1. `NOW.md`: checkpoint duy nhất đang được phép thực thi.
2. `TARGET.md`: tiêu chí sản phẩm và những gì repository phải/không phải sở hữu.
3. Chỉ mở `reference/` khi active checkpoint yêu cầu.

Sau mỗi checkpoint: chạy checks, ghi evidence và chờ người dùng chọn
`verify`, `revise`, `pause`, hoặc `replace`.

## Vai trò của từng tài liệu

- `NOW.md`: plan step-by-step và active checkpoint;
- `TARGET.md`: Hermes-first product contract;
- `reference/ARCHITECTURE.md`: ranh giới Hermes/profile/MCP/coding agents;
- `reference/INTERNAL_MCP_SETUP.md`: capability và cách kết nối
  `company-gateway` vào Hermes;
- `reference/ROADMAP.md`: capability chỉ cân nhắc sau MVP.

## Cấu trúc hiện tại

```text
documents/        # nguồn hướng dẫn hiện tại
backend/          # FastAPI application hiện có, không phải Hermes runtime
assistant_profile/# chỉ được tạo khi checkpoint tương ứng cần
```

Khi một checkpoint cần config, skill hoặc hook thật, nó sẽ tạo phần tối thiểu
trong `assistant_profile/`. Không tạo trước toàn bộ cấu trúc đích.

## Việc đang làm

Active checkpoint là CP1 trong `NOW.md`: chứng minh upstream Hermes chạy local
từ một profile riêng.
