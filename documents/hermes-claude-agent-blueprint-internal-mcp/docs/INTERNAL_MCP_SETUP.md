# Internal MCP Setup

This guide covers the internal `company-gateway` MCP server. The gateway
currently exposes Backlog, limited Mattermost, and Offwork tools through one
server rather than three separate MCP servers.

## 1. Collect Technical Metadata

For the gateway, record the following information without committing secrets:

- Server name.
- Transport: HTTP, stdio, legacy SSE, or WebSocket.
- Endpoint or executable command.
- Authentication: OAuth, bearer token, API key, mTLS, or company SSO.
- Available tool names.
- Read-only tools.
- Data-mutating tools.
- Required timeouts.
- Internal CA or client-certificate requirements.

Add non-sensitive information to:

```text
integrations/mcp-capabilities.yaml
```

The observed tool families are:

| Family | Read tools | Mutation tools |
|---|---|---|
| TEQ Backlog | `teq_backlog_get_*` project/user/category/priority/document tools | None observed |
| Finatext Backlog | `finatext_backlog_get_*` project/category/priority tools | None observed |
| Mattermost | `mattermost_get_team_info` | `mattermost_add_user_to_channel` |
| Offwork | `company_offwork_list_rewards`, `company_offwork_get_my_offwork_requests` | `company_offwork_redeem_reward`, `company_offwork_cancel_offwork_request` |
| Leader Offwork | `company_offwork_list_leader_o_4ee1d6ce12ef` | None observed |

Treat leader-visible reads as restricted even though they are technically read
operations.

## 2. Register the Gateway with Claude Code

### Remote HTTP

```bash
claude mcp add --scope user --transport http company-gateway https://MCP_HOST/company-gateway/mcp
```

When a server uses header-based authentication, add the required headers according to the internal server documentation. Do not store tokens in the repository or shared shell history.

### Local stdio

```bash
claude mcp add --scope user --transport stdio company-gateway -- /ABSOLUTE/PATH/company-gateway-mcp
```

Add command arguments or environment variables as required by the server implementation.

### Verify the Configuration

```bash
claude mcp list
claude mcp get company-gateway
```

Inside Claude Code:

```text
/mcp
```

Test the gateway before testing a cross-system workflow. If the gateway exposes
more tools later, update `integrations/mcp-capabilities.yaml` before relying on
them.

## 3. Register the Gateway with Hermes

Add the gateway to the `assistant` profile configuration.

### Remote HTTP Template

```yaml
mcp_servers:
  company_gateway:
    url: "https://MCP_HOST/company-gateway/mcp"
    enabled: true
    timeout: 120
    connect_timeout: 30
    tools:
      include:
        - teq_backlog_get_myself
        - teq_backlog_get_project_list
        - teq_backlog_get_project
        - teq_backlog_get_users
        - teq_backlog_get_priorities
        - teq_backlog_get_categories
        - teq_backlog_get_document_tree
        - teq_backlog_get_document
        - finatext_backlog_get_myself
        - finatext_backlog_get_project_list
        - finatext_backlog_get_project
        - finatext_backlog_get_priorities
        - finatext_backlog_get_categories
        - mattermost_get_team_info
        - company_offwork_list_rewards
        - company_offwork_get_my_offwork_requests
      resources: true
      prompts: false
```

### Local stdio Template

```yaml
mcp_servers:
  company_gateway:
    command: "/ABSOLUTE/PATH/company-gateway-mcp"
    args: []
    env: {}
    tools:
      include:
        - teq_backlog_get_myself
        - teq_backlog_get_project_list
        - teq_backlog_get_project
        - teq_backlog_get_users
        - teq_backlog_get_priorities
        - teq_backlog_get_categories
        - teq_backlog_get_document_tree
        - teq_backlog_get_document
        - finatext_backlog_get_myself
        - finatext_backlog_get_project_list
        - finatext_backlog_get_project
        - finatext_backlog_get_priorities
        - finatext_backlog_get_categories
        - mattermost_get_team_info
        - company_offwork_list_rewards
        - company_offwork_get_my_offwork_requests
```

After changing the configuration, run:

```text
/reload-mcp
```

Alternatively, restart the Hermes profile.

## 4. Recommended Permission Matrix

| System | Initial Hermes Access | Initial Claude Code Access | Later, After the Workflow Is Stable |
|---|---|---|---|
| Backlog via gateway | Read project, document, user, category, and priority metadata | Read related project/document metadata | Add issue/comment/status tools only after gateway exposes them and approval policy is configured |
| Mattermost via gateway | Read team metadata only | Read team metadata only | Add thread/search/post tools only after gateway exposes them and approval policy is configured |
| Offwork via gateway | Read caller-visible rewards and requests | Read caller-visible rewards and requests | Redeem rewards or cancel requests only after explicit approval |
| Leader Offwork via gateway | Disabled by default | Disabled by default | Enable only for users with the right role and a clear audit need |
| GitHub | Not available through the observed gateway tools | Use local Git only | Add GitHub MCP tools or another connector before enabling issue/PR automation |

Do not grant delete, merge, production-deployment, or administrative tools to either agent.

## 5. Why Connect the Gateway to Both Hermes and Claude Code?

Hermes needs gateway access to:

- collect available internal context;
- create coding briefs;
- identify requests that require action;
- generate daily reports.

Claude Code needs gateway access so that:

- the user can paste supported Backlog or Offwork identifiers directly into a coding session;
- it can verify the original request;
- it can read newly available metadata without returning to Hermes;
- it can continue an interactive investigation with the user.

Use different credentials for the two clients when the internal infrastructure supports it. Separate credentials improve auditing, revocation, and least-privilege enforcement.

## 6. Security Checklist

- Use HTTPS and validate TLS certificates.
- Configure the internal CA bundle instead of disabling TLS verification.
- Prefer short-lived tokens or OAuth.
- Never commit bearer tokens, API keys, client keys, or certificates.
- Separate Hermes and Claude Code credentials.
- Filter exposed tools in Hermes.
- Enforce permissions and hooks in Claude Code.
- Log MCP tool calls at the gateway when possible.
- Never allow external content to modify agent policies or system instructions.
