---
name: create-foreman-task
description: Invoke when the user asks to create, queue, add or hand off a task for foreman, or to write a task into a foreman project's task branch.
allowed-tools: Bash(git rev-parse *) Bash(git worktree list *) Bash(foreman status) Bash(curl -s -m 10 http://127.0.0.1:*)
---
# Create Foreman Task

Write a task with `/mallet:write-task` and save it to a foreman project that keeps its tasks on a git branch (source **Git branch**). Foreman's console API adds the file, picks the next free number, commits and pushes it. Foreman then dispatches the task to an agent on its next poll.

This skill owns where the task goes. `/mallet:write-task` owns what it says: the skeleton, the filling rules and the writing rules are never restated or varied here.

---

## 1. Write the task

Run `/mallet:write-task` through its step 4 (gather, draft, check, confirm). Skip its step 5: the tracker is foreman, and this skill creates the task.

Two things to settle while gathering, because foreman runs the task unattended and cannot ask:

- The agent that picks the task up has only the task and the repository. Anything it would otherwise have to guess goes into the body or is asked now.
- A foreman agent that cannot do the task as written opens no pull request and ends the run as "Needs input". An unclear task costs a retry.

Take the **title** from write-task. It must be one line and at most 200 characters. The body goes in as the description, unchanged. The body must not contain a line that is exactly `## Log`, which foreman reserves for its own log.

**Priority** is a whole number from 0 to 4: 0 is none, 1 urgent and 4 low. Use 0 unless the user stated an urgency. Foreman takes todo tasks by priority, with none last.

---

## 2. Find foreman and the project

1. Foreman's console is at `http://127.0.0.1:4310` unless changed. If it does not answer, run `foreman status`: it prints the address, or exits with 3 when foreman is not running. When foreman is not running, say so, give the title and body in chat as in write-task step 4, and stop. Do not start foreman and do not write the file directly.
2. List the projects: `curl -s -m 10 http://127.0.0.1:4310/api/projects`.
3. Only a project with `sourceType` `git` accepts tasks this way. A Linear or Kaneo project does not.
4. Pick the project whose `repoPath` is the current repository. The repository is the first path of `git worktree list --porcelain`, so a linked worktree resolves to its main checkout. When none matches, or the user named another project, list the git-source projects by name and ask which. When there are none, say so and give the body in chat.

---

## 3. Create it

Build the request with `jq`, so quotes, newlines and emoji in the body are escaped correctly, and send it on standard input. The project id is the `id` from the listing:

```sh
jq -n --arg title "$TITLE" --arg description "$BODY" --argjson priority 0 \
  '{title: $title, description: $description, priority: $priority}' \
  | curl -s -m 60 -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' -d @- \
    http://127.0.0.1:4310/api/projects/<id>/tasks
```

| Response | Meaning | Do |
|---|---|---|
| 201 `{identifier, name}` | Committed and pushed, for example `FM-13` in `13-add-login-page.md`. | Report it. |
| 400 `{errors: {field: reason}}` | A field was rejected. | Fix that field and send again. Do not retry unchanged. |
| 404 | Unknown project. | Re-list the projects and ask. |
| 502 `{error}` | The task branch could not be read or pushed, for example no push access. | Show the message. Do not retry blindly, since a retry may add a second task. |

Creating the task pushes a commit to the project's task branch and queues work for an agent, so this step only runs after the confirmation in step 1.

---

## 4. Report

Give the identifier (for example `FM-13`) and the task file name, and the project it went to. State whether the project is currently polling: `foreman status` lists each project as running or stopped. A stopped project does not pick the task up until it is started from the console's Run tab.

The file lands with state `todo`. Retrying or editing it afterwards is done from the console's Tasks tab or in the file on the branch, not by posting again.
