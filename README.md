# LEGACY / DEPRECATED — DO NOT EXECUTE

This repository is a historical record of an old, poorly engineered configuration experiment. **Nothing in this repository should be executed, downloaded, or copied as-is.** It is not a supported installer, configuration source, or security baseline.

New work belongs in [DotNaos/systems](https://github.com/DotNaos/systems) and user-level configuration belongs in [DotNaos/dotfiles](https://github.com/DotNaos/dotfiles). Those repositories are the migration destinations; this repository is retained only long enough to review the intent captured below.

## Migration inventory

Every tracked file at the start of this migration is listed here. The classification describes where the useful intent belongs, not a recommendation to port the old implementation.

| Historical file | Classification | Intent worth preserving / disposition |
| --- | --- | --- |
| `README.md` | rewrite in systems | Keep the distinction between machine setup, user configuration, and platform-specific notes, but replace the old install walkthrough with maintained documentation and safe, reviewed entry points. |
| `Linux/install.sh` | discard | This was only a `WIP` placeholder with no executable implementation. It provided no migration value. |
| `Windows/config.bak.json` | discard | Backup of a duplicated configuration definition. It adds no authoritative intent and should not be revived. |
| `Windows/config.json` | split between systems and dotfiles | Rewrite the debloat policy, HKLM settings, and optional Windows features in systems after review. Rewrite HKCU preferences and the PowerShell/Windows Terminal, VS Code, Neovim, Git, theme, and cursor user preferences in dotfiles after review. Do not preserve the old repository split or treat every listed preference as wanted. |
| `Windows/configure.ps1` | split between systems and dotfiles | Rewrite the provisioning orchestration, machine-wide changes, feature enablement, debloat behavior, and system font installation in systems after review. Rewrite the user-level PowerShell/Windows Terminal, VS Code, Neovim, Git, theme, and cursor configuration in dotfiles after review. Use reviewed inputs, safe defaults, validation, idempotence, and explicit confirmation for destructive changes; do not reproduce its remote-fetch or command-execution behavior. |
| `Windows/install.ps1` | rewrite in systems | Preserve the idea of profile-aware software provisioning and package categories. Rebuild it around a reviewed profile manifest and a single controlled package source; do not port the interactive manager selection, remote execution, or direct-download behavior. |
| `Windows/packages.json` | rewrite in systems | Preserve only the historical category/intent signal: development tools, CLI tools, design tools, games, and miscellaneous applications. Packages require per-profile review; this list is not an approved current package set and must not be copied wholesale. |
| `res/dotfiles/.gitconfig` | discard | Empty placeholder with no configuration to migrate. Git identity and other user settings belong in the reviewed dotfiles repository. |

The split is by ownership and blast radius: systems should own reviewed machine-wide state and provisioning, while dotfiles should own reviewed per-user preferences and application configuration. These are migration boundaries, not a reason to keep multiple legacy configuration repositories or to copy the old layout.

### Package categories are historical intent only

The old package list groups applications into `dev`, `CLI`, `design`, `games`, and `misc`. These labels may help start a profile discussion, but they do not establish that any old package is still wanted, current, safe, licensed, or compatible. Review each package per user profile, platform, and purpose before adding it to [DotNaos/systems](https://github.com/DotNaos/systems); remove anything without a current decision.

## Security and maintenance rejection list

The following historical choices are explicitly rejected and must not be migrated literally:

- `EnableLUA = 0` disables User Account Control. It weakens Windows security and must not be reproduced.
- The old README and scripts download-and-execute arbitrary remote content, including `Invoke-Expression`, `ScriptBlock::Create`, and unpinned raw URLs. Remote scripts must never be executed as an installation shortcut.
- Downloads are not pinned to reviewed versions, hashes, signatures, or immutable sources. Any replacement must establish an auditable trust and update process.
- Interactive package-manager and category selection makes automation non-repeatable and difficult to review. Profile choices belong in reviewed, versioned data rather than prompts with implicit defaults.
- This repository duplicated configuration that belongs in separate systems and dotfiles repositories. Do not create another competing source of truth.
- `config.bak.json` was a backup tracked beside the active config; backup files do not belong in the maintained configuration source.
- `Linux/install.sh` and `res/dotfiles/.gitconfig` were empty or placeholder artifacts and are discarded rather than treated as migration targets.

We have not run the historical scripts and must not mutate system settings while reviewing them.

## Archive criteria

Archive this repository only after all of the following are true:

1. Replacement decisions for each inventory item have been reviewed in the destination repository.
2. Wanted intent has been reimplemented and tested through the maintained systems and dotfiles workflows.
3. Historical references are no longer needed for execution, onboarding, or migration verification.
4. The destination repositories document any intentional omissions and the review is complete.

Until then, keep the remaining historical scripts and package list available as inventory evidence, but treat them as deprecated source material only.
