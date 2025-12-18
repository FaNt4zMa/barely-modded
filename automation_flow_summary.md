# Barely Modded - Automation Flow Summary

This document outlines the complete automation process for the "Barely Modded" project, from local development and release preparation to automated publishing on GitHub and Modrinth.

### Summary of Scripts

*   **`release.ps1`**: The main, interactive PowerShell script that orchestrates the entire release process from a local machine. It handles versioning, changelog generation, file updates, and Git tagging.
*   **`update-mods.ps1`**: A helper script designed to update mods for a specific pack (`client` or `server`). It automatically logs which mods were updated into a staging changelog file (`changelog-staging.md`).
*   **`changelog-generator.ps1`**: This script reads the content from `changelog-staging.md`, prepends it to the main `changelog.md` file with the new version and date, and then clears the staging file for the next release cycle.
*   **`mrpack-export.ps1`**: A script that temporarily injects correct version numbers and metadata into the pack files and then uses `packwiz` to export the `.mrpack` file.
*   **`update-readme.ps1`**: Combines the `readme.md` files from the `client-pack` and `server-pack` directories into the main `README.md` file at the project root.

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
        *   **Performs Local Export**: It calls `mrpack-export.ps1` to create a local `.mrpack` archive. This step primarily serves for validation and local archival.
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
        *   **Builds `.mrpack`**: It re-builds the `.mrpack` file for the specific pack directly from the repository's source code, ensuring consistency.
        *   **Extracts Changelog**: It extracts the most recent changelog entry from the pack's `changelog.md` file.
        *   **Creates Published GitHub Release**: A new, formal **GitHub Release** is created. The `.mrpack` file is uploaded as a downloadable asset, and the extracted changelog entry forms the body of the release notes.

4.  **Modrinth Publication**:
    *   The creation of a *published* GitHub Release (from the previous step) acts as the trigger for the subsequent GitHub Actions workflow (`release-client-modrinth.yml` or `release-server-modrinth.yml`).
    *   This workflow handles the publication to Modrinth:
        *   **Downloads Asset**: It retrieves the `.mrpack` file that was uploaded to the GitHub Release.
        *   **Publishes to Modrinth**: Using the `mc-publish` action, it uploads the `.mrpack` file to your Modrinth project, associating it with the correct version number, loaders, game versions, and the changelog from the GitHub Release.
        *   **Updates Modrinth Project Description**: As a final step, it uses the content of the pack's `readme.md` file (e.g., `client-pack/readme.md`) to update the main description page of your project on Modrinth, keeping your Modrinth page synchronized with your repository.

This comprehensive workflow ensures a streamlined and largely automated process for releasing and publishing your modpacks, minimizing manual steps after the initial local preparation.
