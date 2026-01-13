# Barely Modded - Automation Flow Summary

This document outlines the complete automation process for the "Barely Modded" project, from local development and release preparation to automated publishing on GitHub and Modrinth.

### Summary of Scripts & Configs

*   **`pack-config.yml`**: A centralized configuration file that stores essential metadata for both the client and server packs. This includes the Minecraft version, Fabric loader version, Modrinth project ID, and the public-facing pack name. It also contains a `custom_datapacks` section for each pack that defines which datapack folders should be automatically zipped with version numbers during export. It is the single source of truth for this data, ensuring consistency across all automation scripts.
*   **`release.ps1`**: The main, interactive PowerShell script that orchestrates the entire release process from a local machine. It handles versioning, changelog generation, file updates, and Git tagging.
*   **`update-mods.ps1`**: A helper script designed to update mods for a specific pack (`client` or `server`). It automatically logs which mods were updated into a staging changelog file (`changelog-staging.md`).
*   **`changelog-generator.ps1`**: This script reads the content from `changelog-staging.md`, prepends it to the main `changelog.md` file with the new version and date, and then clears the staging file for the next release cycle.
*   **`mrpack-export.ps1`**: A script that reads metadata from `pack-config.yml` (like Minecraft and loader versions) and temporarily injects these values into the pack's files (e.g., `pack.toml`). It also handles automatic zipping of custom datapacks as defined in `pack-config.yml`, temporarily modifying `.packwizignore` to ensure only the zipped versions are included in the final export. It then uses `packwiz` to export the `.mrpack` file with the correct, up-to-date information, and cleans up temporary files afterward.
*   **`update-readme.ps1`**: Combines the `readme.md` files from the `client-pack` and `server-pack` directories into the main `README.md` file at the project root.

### Custom Datapack Handling

To maintain code visibility and ease of editing in the repository while ensuring launcher compatibility, custom datapacks follow a special workflow:

*   **Repository Storage**: Custom datapacks are stored as unzipped folders in the repository (e.g., `server-pack/datapacks/my-datapack/`). This allows for easy version control, code review, and direct editing.
*   **Export-Time Zipping**: During the export process (both local and GitHub Actions), custom datapacks defined in `pack-config.yml` are automatically zipped with their version numbers appended (e.g., `my-datapack-v1.0.0.zip`).
*   **Temporary Ignore**: The original folders are temporarily added to `.packwizignore` during export so that packwiz only includes the zipped versions in the final `.mrpack` file. After export, the `.packwizignore` is restored to its original state.
*   **Launcher Compatibility**: The zipped datapacks in the exported `.mrpack` ensure proper detection by launchers like Modrinth Launcher, which require datapacks to be in `.zip` format.

### The Complete Automation Flow

The automation is divided into two primary stages: a local, interactive release preparation stage, and a fully automated publication stage driven by GitHub Actions.

---

### Stage 1: Local Release Preparation (Semi-Automated)

This stage describes the steps you would take on your local development machine to initiate a new release.

1.  **Update Mods & Prepare Changelog**:
    *   You can run `.\update-mods.ps1 -PackName client` (or `-PackName server`) to download the latest versions of your mods. This script automatically appends a list of updated mods to the `### Changed` section of the relevant `client-pack\changelog-staging.md` (or `server-pack\changelog-staging.md`) file.
    *   You are responsible for manually editing the `changelog-staging.md` file to add any other relevant changes, such as new mods, removed mods, or configuration adjustments, in the appropriate sections.

2.  **Execute the Master Release Script**:
    *   To begin the release, you run the main interactive script: `.\release.ps1`.
    *   The script will prompt you to select:
        *   Which pack(s) to release: **Client**, **Server**, or **Both**.
        *   The **new version number** for each selected pack (e.g., `1.2.3`).
    *   Upon your confirmation, the script performs the following critical actions for each chosen pack:
        *   **Generates Changelog**: It executes `changelog-generator.ps1`, which processes the content of `changelog-staging.md` and integrates it into the primary `changelog.md` file, marking the new version.
        *   **Updates Version Files**: It updates the `version.txt` file within the respective pack directory to reflect the new release version.
        *   **Performs Local Export**: It calls `mrpack-export.ps1` to create a local `.mrpack` archive. During this process, custom datapacks are automatically zipped with version numbers and the original folders are temporarily excluded from the export. This step primarily serves for validation and local archival.
        *   **Updates Project README**: It calls `update-readme.ps1` to consolidate the individual `readme.md` files from the pack directories into the project's root `README.md`.
    *   After these preparatory steps, and a final confirmation from you, the script proceeds with Git operations:
        *   **Commits Changes**: All changes made during the preparation phase (updated changelogs, version files, README) are staged and committed to your Git repository with an appropriate message (e.g., "Release client v2.5.0").
        *   **Creates Git Tags**: It generates and applies a Git tag formatted as `client/vX.X.X` (for client releases) or `server/vX.X.X` (for server releases).
        *   **Pushes to GitHub**: The new commit and its associated tag(s) are then pushed to your remote GitHub repository.

---

### Stage 2: Automated Publishing (GitHub Actions)

The `git push --tags` command, executed at the end of Stage 1, triggers the fully automated CI/CD pipeline on GitHub Actions.

3.  **GitHub Release Creation**:
    *   The newly pushed tag (e.g., `client/v2.5.0`) automatically activates the corresponding GitHub Actions workflow (`release-client-github.yml` or `release-server-github.yml`).
    *   This workflow, running in a GitHub Actions environment, performs these steps:
        *   **Processes Custom Datapacks**: Custom datapacks defined in `pack-config.yml` are zipped with their version numbers, and the original folders are temporarily added to `.packwizignore` to exclude them from the packwiz export.
        *   **Builds `.mrpack`**: It re-builds the `.mrpack` file for the specific pack directly from the repository's source code, ensuring consistency. The export includes the zipped datapacks rather than the folder versions.
        *   **Extracts Changelog**: It extracts the most recent changelog entry from the pack's `changelog.md` file.
        *   **Creates Published GitHub Release**: A new, formal **GitHub Release** is created. The `.mrpack` file is uploaded as a downloadable asset, and the extracted changelog entry forms the body of the release notes.

4.  **Modrinth Publication**:
    *   The creation of a *published* GitHub Release (from the previous step) acts as the trigger for the subsequent GitHub Actions workflow (`release-client-modrinth.yml` or `release-server-modrinth.yml`).
    *   This workflow handles the publication to Modrinth:
        *   **Downloads Asset**: It retrieves the `.mrpack` file that was uploaded to the GitHub Release.
        *   **Publishes to Modrinth**: Using the `mc-publish` action, it uploads the `.mrpack` file to your Modrinth project, associating it with the correct version number, loaders, game versions, and the changelog from the GitHub Release.
        *   **Updates Modrinth Project Description**: As a final step, it uses the content of the pack's `readme.md` file (e.g., `client-pack/readme.md`) to update the main description page of your project on Modrinth, keeping your Modrinth page synchronized with your repository.

This comprehensive workflow ensures a streamlined and largely automated process for releasing and publishing your modpacks, minimizing manual steps after the initial local preparation.
