# API 草案 v1

所有端點使用 HTTPS、JSON 與 UTC ISO-8601 時間。這是 API 契約草案，尚未代表服務已部署。

## 公開讀取
- GET /api/v1/events?category=sports&from=&to=&cursor=：活動列表，使用 cursor 分頁。
- GET /api/v1/events/:eventId：活動詳情，依 visibility 決定是否可讀。
- GET /api/v1/posts?category=&cursor=：只回傳可見且通過審核的貼文。
- GET /api/v1/interests：興趣分類。

## 已登入使用者
- GET /api/v1/me：目前使用者的最小必要資料。
- PATCH /api/v1/me：更新暱稱、簡介、可見性；不可由客戶端修改角色或審核狀態。
- POST /api/v1/posts：建立貼文，預設進入審核流程。
- DELETE /api/v1/posts/:postId：作者或具權限管理員可刪除。
- POST /api/v1/events/:eventId/attendance：報名；需在交易中檢查名額與重複報名。
- DELETE /api/v1/events/:eventId/attendance：取消報名。
- POST /api/v1/blocks/:userId 與 DELETE /api/v1/blocks/:userId：封鎖／解除封鎖。
- POST /api/v1/reports：提交檢舉。

## 管理員
- GET /api/v1/admin/reports?status=open
- PATCH /api/v1/admin/reports/:reportId
- PATCH /api/v1/admin/posts/:postId/moderation

管理端點需獨立 RBAC 權限及稽核紀錄；管理員操作需記錄原因。

## 錯誤格式
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "請檢查輸入內容",
    "requestId": "server-generated-id"
  }
}

## 安全要求
- 使用成熟 OIDC／託管身份服務；Cookie 使用 HttpOnly、Secure、SameSite。
- 對建立貼文、登入、檢舉及報名設定速率限制。
- 使用 schema 驗證輸入，限制字數與上傳檔案類型。
- 每次讀寫都驗證資源所有權與角色，避免 IDOR。
- CORS 使用明確允許清單；設定 CSP、安全標頭與適當 CSRF 防護。
- 上傳媒體需掃毒、限制檔案大小，並移除不必要的 EXIF 定位資訊。
- 不在分析工具或日誌中記錄敏感個資。
