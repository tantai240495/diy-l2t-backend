# Workflow: Offwork Request

## Inputs

One or more direct requests about:

- visible rewards;
- the caller's current Offwork requests;
- canceling one Offwork request;
- redeeming one reward;
- leader-visible request review, only when the user has the right role.

## Procedure

1. Map the request to the `offwork` capability family in
   `integrations/mcp-capabilities.yaml`.
2. Use read tools first:
   - `company_offwork_list_rewards`;
   - `company_offwork_get_my_offwork_requests`.
3. Use `company_offwork_list_leader_o_4ee1d6ce12ef` only when the request
   explicitly requires leader-visible data and the caller is allowed to view it.
4. Summarize the visible choices and identify the exact `reward_id` or
   `request_id` before any mutation.
5. Ask for explicit approval before calling:
   - `company_offwork_redeem_reward`;
   - `company_offwork_cancel_offwork_request`.
6. After an approved mutation, read back the relevant state and summarize the
   result.

## Stop Conditions

Stop when:

- the request requires a reward or request ID that cannot be identified;
- the user is asking to act on another person's request without a clear role;
- the requested tool is outside the allowlist;
- the user has not approved a mutation.

## Output

Return:

1. Current Offwork state used as evidence.
2. Proposed action.
3. Approval status.
4. Mutation result, if any.
