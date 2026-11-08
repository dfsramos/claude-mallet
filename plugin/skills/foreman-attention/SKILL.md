---
name: foreman-attention
description: Invoke when the user asks what needs their attention in foreman, which foreman tasks are waiting on them, stuck, blocked or failed, or to go through or resolve them, or runs /foreman-attention.
allowed-tools: Bash(foreman status) Bash(gh pr view *) Bash(gh pr diff *)
---
# Foreman Attention

Go through what [foreman](https://github.com/dfsramos/foreman) is waiting on the user for, one task at a time: say what each one needs, offer the ways forward, and carry out the one the user picks.

Foreman's `list_attention` tool decides what needs a person. This skill does not second-guess it: it reads the items, explains them, and acts on the user's choice. It needs a foreman version that has `list_attention`.

---

## 1. Reach foreman

Foreman's tools are reached in one of two ways:

- **MCP tools**, when the session has them: `mcp__foreman__list_attention`, `mcp__foreman__get_task`, `mcp__foreman__comment_task`, `mcp__foreman__update_task`, `mcp__foreman__move_task`.
- **Over HTTP** otherwise, by posting the same tool call to foreman's MCP endpoint. Build the request with `jq` so text is escaped correctly; `<tool>` and the arguments are those of the MCP tool:

  ```sh
  jq -n --arg name '<tool>' --argjson args '<arguments as JSON>' \
    '{jsonrpc: "2.0", id: 1, method: "tools/call", params: {name: $name, arguments: $args}}' \
    | curl -s -m 60 -X POST -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -d @- \
      http://127.0.0.1:4310/mcp \
    | jq -r '.result.content[0].text // .error.message'
  ```

  A result with `isError: true` carries its reason as that text.

When neither answers, run `foreman status`: it prints the console's address, or exits with 3 when foreman is not running. When foreman is not running, say so and stop; do not start it. When `list_attention` is an unknown tool, say that foreman needs updating (`npm install -g @dfsramos/foreman`, then `foreman stop` and `foreman start`) and stop.

---

## 2. List

Call `list_attention`, with `project` when the user named one (`list_projects` gives the ids). Show:

- a numbered list, one line per item: identifier, kind, and the `reason` cut to one line;
- each entry of `notes` as it is, since it says what could not be read.

When `items` is empty, say nothing waits on the user and stop.

Ask which item to start with through the question dialog, recommending `blocked` and `failed` items before `aborted`, `unclaimed`, `handed_over` and `awaiting_approval`, and older runs first.

---

## 3. One item

Present the item so it can be decided without opening anything else:

- the task: identifier, title, state, and its link;
- the `reason`, and the agent's last message summarised in a few lines; for a `blocked` item, the agent's question with its context and options in full, since the user answers it;
- the kept worktree: whether it exists and how many uncommitted files and unpushed commits it has. When it has unpushed commits, list them with `git -C <path> log --oneline @{u}..` or, without an upstream, `git -C <path> log --oneline --not --remotes`;
- for a pull request, its state from `gh pr view <url> --json state,reviewDecision,mergeable,statusCheckRollup`.

Then offer two to four options through the question dialog, the recommended one first, each saying what it does and what it changes:

| Kind | Options |
|---|---|
| `blocked` | **Answer and retry**: write the answer into the task with `update_task` (append it to the description under a `## Answer` heading) or, on a Git branch task, `comment_task`; clear the worktree and branch as below; `move_task` to `todo`. **Use the work**: when the unpushed commits do what the task asks, push the branch and open the pull request with `/mallet:create-pr`, then `move_task` to `in_review`. **Leave it**. |
| `failed`, `aborted` | **Fix and open the pull request**: work in the kept worktree, then push and open it with `/mallet:create-pr`, then `move_task` to `in_review`. **Retry from scratch**: clear the worktree and branch as below, then `move_task` to `todo`. **Leave it**. |
| `unclaimed` | **Retry**: `move_task` to `todo`. **Move it elsewhere**: `move_task` to the state the user names. **Leave it**. |
| `handed_over`, `awaiting_approval` | **Another round**: `comment_task` with what the agent should change; foreman hands it to an agent on its next review check. **Review it now**: summarise the pull request's diff (`gh pr diff <url>`) and its open review comments. **Leave it for the user to merge**. |

For a Linear or Kaneo item (`task.state` is null), foreman's task tools do not apply: name what to change in that tracker and let the user do it there.

---

## 4. Act

Carry out only the option the user picked, and only after their explicit OK for this item. Approval for one item does not carry over to the next.

- **Clearing the worktree and branch.** Show what would be lost first: the uncommitted files (`git -C <path> status --short`) and the unpushed commits. Remove the worktree with `git -C <repository> worktree remove <path>`, which refuses when files are uncommitted; never add `--force` without its own confirmation naming the files. Delete the branch with `git -C <repository> branch -d <branch>`; a branch with unpushed commits needs `-D`, and that needs its own confirmation naming the commits. `<repository>` is the project's `repoPath` from `list_projects`.
- **Pushing and opening a pull request.** Push the branch from the worktree (`git -C <path> push -u origin <branch>`) and open the pull request through `/mallet:create-pr`, which shows the title and body first. Reference the task's identifier in it.
- **Writing to the task.** `comment_task`, `update_task` and `move_task` each push one commit to the project's task branch; say which one is about to run.

Report what was done in one line, with the commit or pull request it made.

---

## 5. Next

Call `list_attention` again for the same project, since acting on one item can change others, and continue with the next item the user picks. Stop when the list is empty or the user says so.

End with a summary: what was done to each item, and what is still waiting.
