{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.codex ];

    file.".codex/AGENTS.md".text = ''
      ## Git safety

      Read-only Git commands are allowed: git status, git diff, git log, git show, and git blame.

      The user exclusively controls Git state. Never infer that a staged or
      unstaged change should be changed, including to comply with these rules.

      Never run a Git command that changes the index, working tree, branches,
      remotes, or history unless I explicitly request that exact operation in
      the current message.

      This includes git add, restore, reset, commit, push, pull, fetch, merge,
      rebase, cherry-pick, checkout, switch, stash, clean, and commands using
      --staged, --cached, or -a.

      Do not stage, unstage, commit, push, pull, fetch, stash, discard, or
      otherwise modify Git state unless explicitly asked.
    '';
  };
}
