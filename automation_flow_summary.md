# Barely Modded Automation - Technical Deep Dive

This document provides a detailed technical breakdown of the automation scripts and CI/CD pipeline used in the Barely Modded project.

---

## Table of Contents
- [Project Configuration](#project-configuration)
  - [`pack-config.yml`](#pack-configyml)
- [Local Release Scripts (PowerShell)](#local-release-scripts-powershell)
  - [`release.ps1`](#releaseps1---master-release-script)
  - [`mrpack-export.ps1`](#mrpack-exportps1---pack-exporter)
  - [`changelog-generator.ps1`](#changelog-generatorps1---changelog-generator)
  - [`update-readme.ps1`](#update-readmeps1---readme-combiner)
  - [`update-mods.ps1`](#update-modsps1---mod-updater)
- [CI/CD Pipeline (GitHub Actions)](#cicd-pipeline-github-actions)
  - [`release-client.yml` & `release-server.yml`](#release-clientyml--release-serveryml)
- [Helper Scripts](#helper-scripts)
- [End-to-End Release Flow](#end-to-end-release-flow)

---

## Project Configuration

### `pack-config.yml`

This is the central metadata file for the entire project. It contains two main keys, `client` and `server`, each with a set of key-value pairs that define the properties and build parameters for the respective modpack. This file is heavily utilized by both the local PowerShell scripts and the remote GitHub Actions workflows.

**Structure:**

```yaml
server:
  modrinth_id: "MmLJ3gYm"
  modrinth_slug: "fantazs-barely-modded-server"
  pack_name: "Barely Modded Server"
  minecraft_version: "1.21.11"
  loader: "fabric"
  loader_version: "0.18.4"
  custom_datapacks:
    - folder: "DefaultGamerules"
      version: "1.0.1"
  # ... and so on
```

**Keys Explained:**

*   `modrinth_id`: The alphanumeric ID for the project on Modrinth. Used for publishing.
*   `modrinth_slug`: The human-readable slug for the project on Modrinth.
*   `pack_name`: The official name of the modpack. This is used in filenames and release titles.
*   `minecraft_version`: The target Minecraft version.
*   `loader`: The mod loader being used (e.g., "fabric").
*   `loader_version`: The specific version of the mod loader.
*   `custom_datapacks`: A list of custom datapacks to be processed during the export phase. For each item, it specifies a `folder` and `version`. This is used by `mrpack-export.ps1` and the CI pipeline to zip datapack folders before inclusion in the modpack.

## Local Release Scripts (PowerShell)

This section details the scripts intended for local execution by the developer to prepare and initiate a release.

### `release.ps1` - Master Release Script

This is the main entry point for a developer to create a new release. It orchestrates all the necessary steps, from updating versions to tagging the release for the CI/CD pipeline. It has a `-DryRun` mode to preview actions without making changes.

**Execution Flow:**

1.  **Prerequisites Check:** Verifies that `packwiz` and `git` are installed and that the script is run from the root of a git repository.
2.  **User Prompts:**
    *   Asks which pack to release (Client, Server, or Both).
    *   Prompts for the new version number for the selected pack(s). It shows the current version from `version.txt` for reference.
    *   Performs a basic semver format validation on the input.
3.  **Confirmation:** Displays a summary of the planned release and asks for final confirmation to proceed.
4.  **Pack Processing (`Update-Pack` function):** For each selected pack, it performs the following:
    *   **`packwiz refresh`**: Updates the `index.toml` with the latest hashes for all mods.
    *   **Version Update**: Updates the version number in the pack's `version.txt` file.
    *   **MRPack Export**: Calls `mrpack-export.ps1` to handle the actual pack export process.
    *   **Changelog Generation**: Calls `changelog-generator.ps1` to generate a new changelog entry.
5.  **Changelog Preview:** Displays the generated changelog entries for final review.
6.  **Git Operations:**
    *   **README Update**: Calls `update-readme.ps1` to combine the client and server readmes into the root `README.md`.
    *   **Staging**: Stages all changes made to the pack directories, `pack-config.yml`, and `README.md` using `git add`.
    *   **Commit**: Creates a commit with a standardized message (e.g., "Release client vX.X.X").
    *   **Tagging**: Creates Git tags for the new version(s) (e.g., `client/vX.X.X` and/or `server/vX.X.X`).
    *   **Push**: Pushes the commit and all tags to the remote repository. This action is what triggers the GitHub Actions workflows.
7.  **Conclusion:** Informs the user that the process is complete and that the CI/CD pipeline will take over.

### `mrpack-export.ps1` - Pack Exporter

This script is responsible for the complex process of preparing and exporting a single modpack into the `.mrpack` format. It's designed to be called by other scripts (like `release.ps1`) and in the CI environment. It ensures that the exported pack is correctly versioned and contains all necessary components.

**Execution Flow:**

1.  **Parameter Input:** Takes a mandatory `PackName` parameter ("client" or "server").
2.  **Config Parsing:** Reads `pack-config.yml` to retrieve all necessary metadata for the given pack (pack name, Modrinth ID, MC version, loader version).
3.  **Version Reading:** Reads the target version number from the pack's `version.txt` file.
4.  **Placeholder Replacement:**
    *   It creates temporary backups of key configuration files (`pack.toml`, `config/simpleupdatechecker_modpack.json`).
    *   It replaces placeholder strings like `<MODPACKVERSION>`, `<PACKNAME>`, `<MINECRAFTVERSION>`, etc., in these files with the actual values parsed from `pack-config.yml` and `version.txt`.
5.  **Datapack Processing:**
    *   It checks `pack-config.yml` for a `custom_datapacks` list for the specified pack.
    *   If found, it iterates through each datapack entry.
    *   It creates a temporary zip archive of the datapack's folder (e.g., `datapacks/DefaultGamerules` becomes `datapacks/DefaultGamerules-v1.0.1.zip`).
    *   To prevent `packwiz` from exporting the raw datapack *folders*, it temporarily adds the folder paths (e.g., `datapacks/DefaultGamerules/`) to the `.packwizignore` file. This ensures only the newly created zip files are included in the final export.
6.  **Pack Export:**
    *   It creates an export directory for the specific version (e.g., `export/v2.6.0/`).
    *   It calls `packwiz modrinth export` to generate the final `.mrpack` file.
7.  **Cleanup:**
    *   Crucially, it restores the backed-up configuration files (`pack.toml`, etc.) from step 4, removing the temporary files with the hardcoded version numbers.
    *   It deletes the temporary zip archives of the datapacks created in step 5.
    *   It restores the original `.packwizignore` file.
    *   Runs `packwiz refresh` to ensure the index is consistent with the cleaned-up state.
8.  **Output:** Prints the path to the final exported `.mrpack` file.

### `changelog-generator.ps1` - Changelog Generator

This script automates the creation of formatted changelog entries. It works by sourcing content from a temporary "staging" file, which is meant to be edited by the developer as they make changes.

**Execution Flow:**

1.  **Parameter Input:** Takes a mandatory `PackName` ("client" or "server") and an optional `Version`.
2.  **Version Discovery:** If a `Version` is not provided, it reads the version from the pack's `version.txt` file.
3.  **Staging File Check:** It looks for a `changelog-staging.md` file within the pack's directory. If this file is empty or doesn't exist, the script will exit with an error. This enforces the workflow of preparing changelog notes beforehand.
4.  **Entry Generation:**
    *   It reads the content from `changelog-staging.md`.
    *   It creates a new markdown-formatted entry, combining the version, the current date, and the staged content.
    ```markdown
    ## [version] - yyyy-MM-dd

    ... content from changelog-staging.md ...
    ```
5.  **Changelog Update:** It prepends the newly generated entry to the top of the main `changelog.md` file for that pack.
6.  **Staging File Reset:** After successfully generating the entry, it overwrites `changelog-staging.md` with a blank template (`### Added`, `### Changed`, etc.). This prepares it for the next development cycle and prevents old notes from being reused.

### `update-readme.ps1` - README Combiner

This is a simple utility script with a single purpose. It is called by `release.ps1` to ensure the main project README is kept up-to-date with the individual pack descriptions.

**Execution Flow:**

1.  **Read Files:** It reads the entire content of `client-pack/readme.md` and `server-pack/readme.md`.
2.  **Combine Content:** It combines the two files into a single string, separated by a horizontal rule and with "Client Pack" and "Server Pack" headers.
3.  **Write Output:** It overwrites the root `README.md` with the newly combined content.

### `update-mods.ps1` - Mod Updater

This script is a development utility designed to simplify the process of updating mods and preparing the changelog. It is not part of the release process itself but is used during development.

**Execution Flow:**

1.  **Parameter Input:** Takes a mandatory `PackName` ("client" or "server").
2.  **Run Update:** It runs `packwiz update -a -y` which tells `packwiz` to update all mods and automatically say "yes" to the confirmation prompt. The output of this command is saved to a timestamped log file in the `update-logs` directory.
3.  **Parse Log:** It parses the log file to identify which mods and datapacks were successfully updated.
4.  **Generate Changelog Snippet:** It creates a markdown list of the updated mods.
5.  **Update Staging File:** It automatically inserts this list into the `changelog-staging.md` file under the `### Changed` section. This automates the tedious process of documenting which mods were updated, making the `changelog-generator.ps1` script more effective.

## CI/CD Pipeline (GitHub Actions)

The CI/CD pipeline is handled by GitHub Actions and is defined in two almost identical workflow files. This is the "remote" part of the release process, which takes over after the local `release.ps1` script has pushed a new tag.

### `release-client.yml` & `release-server.yml`

These workflows are responsible for building the `.mrpack`, creating a GitHub Release, and publishing the pack to Modrinth.

**Workflow Trigger:**

*   The `release-client.yml` workflow is triggered by a push of a tag matching the pattern `client/v*`.
*   The `release-server.yml` workflow is triggered by a push of a tag matching the pattern `server/v*`.

**Execution Flow:**

1.  **Checkout:** The workflow begins by checking out the repository code.
2.  **Extract Version:** It extracts the version number from the Git tag (e.g., `client/v2.6.0` becomes `2.6.0`).
3.  **Install Tools:** It installs `packwiz` and `yq` (a YAML processor) on the Ubuntu runner.
4.  **Load Config:** It uses `yq` to read all the necessary values for the specific pack (client or server) from `pack-config.yml`. These values (like `modrinth_id`, `pack_name`, etc.) are loaded into output variables for later steps.
5.  **Process Datapacks:** It performs the same custom datapack zipping logic as the local `mrpack-export.ps1` script, ensuring the build is consistent. It zips the folders and temporarily adds the source folders to `.packwizignore`.
6.  **Export Modpack:** This step mirrors the local export script's logic:
    *   It uses `sed` to replace the placeholders (`<MODPACKVERSION>`, `<PACKNAME>`, etc.) in `pack.toml` and other configuration files.
    *   It runs `packwiz refresh` to ensure the index is correct.
    *   It runs `packwiz modrinth export` to create the final `.mrpack` file.
7.  **Extract Changelog:** It uses `awk` to extract the content of the *most recent* entry from the pack's `changelog.md` file. This is used for the body of the GitHub Release and the Modrinth version notes.
8.  **Create GitHub Release:** It uses the `softprops/action-gh-release` action to create a new release on GitHub. The release is titled with the pack name and version, the body contains the extracted changelog, and the generated `.mrpack` file is attached as a release asset.
9.  **Publish to Modrinth:** It uses the `Kir-Antipov/mc-publish` action to publish the new version to Modrinth. It uses secrets (`MODRINTH_TOKEN`) for authentication and passes all the required metadata, including the changelog, game versions, and loaders.
10. **Update Modrinth Description:** As a final step, it uses `curl` to make a `PATCH` request to the Modrinth API, updating the main project page's description with the content from the pack's `readme.md` file. This ensures the Modrinth page always reflects the latest README from the repository.

## Helper Scripts

These are supplementary Python scripts designed for development and maintenance tasks, providing deeper insights and checks for the modpack's content.

### `dependency_checker.py` - Modrinth Dependency Harvester

This script serves as the foundational tool for dependency analysis. It reaches out to the Modrinth API to gather comprehensive dependency information for each mod in the pack.

**Execution Flow:**

1.  **Scan `packwiz` files:** It iterates through all `.pw.toml` files found in the `mods`, `datapacks`, and `resourcepacks` directories.
2.  **Modrinth API Calls:** For each `.pw.toml` file, it extracts the Modrinth project ID and version ID. It then makes API calls to Modrinth to retrieve detailed information about the mod's version, specifically its declared dependencies.
3.  **JSON Output:** It compiles all this information into a structured JSON file named `mod_dependencies.json` within the `reports` directory. This file contains a list of all analyzed mods, their basic info, and their complete list of declared dependencies (name, project ID, type: required/optional/incompatible).
4.  **Log Output:** A human-readable log (`mod_dependencies.log`) is also generated, summarizing the findings.

### `check_missing_deps.py` - Missing Dependency Reporter

This script uses the output from `dependency_checker.py` to identify any required dependencies that are not present in the modpack.

**Execution Flow:**

1.  **Load Data:** It reads the `mod_dependencies.json` file generated by `dependency_checker.py`.
2.  **Identify Installed Mods:** It builds a set of all Modrinth Project IDs corresponding to mods currently included in the pack.
3.  **Check Against Dependencies:** For each mod in the `mod_dependencies.json` data, it checks its declared `required` dependencies against the `installed_mods` set.
4.  **Exceptions:** It includes an `EXCEPTIONS` list where specific Modrinth Project IDs can be ignored (e.g., for forks or intentionally omitted dependencies).
5.  **Report Generation:** It generates a detailed report (`dependency_check.log` in the `reports` directory) listing:
    *   Any mods with missing *required* dependencies.
    *   Any mods with missing *optional* dependencies.
    *   Any dependencies that were explicitly excepted.
6.  **Installation Suggestions:** For missing required dependencies, it even provides `packwiz modrinth add <project-id>` commands to help the user easily add them.
7.  **Exit Code:** The script exits with an error code (1) if any required dependencies are found to be missing, making it suitable for CI checks.

### `check_licenses.py` - License Auditor

This script helps to audit the licenses of all mods, datapacks, and resource packs within the modpack, categorizing them for compliance awareness.

**Execution Flow:**

1.  **Scan `packwiz` files:** Similar to `dependency_checker.py`, it scans all `.pw.toml` files in the configured directories.
2.  **Modrinth API Calls:** For each mod, it fetches its project information from the Modrinth API to retrieve its declared license.
3.  **License Categorization:** It categorizes each license into one of three types:
    *   **Restrictive:** Licenses containing keywords like "All Rights Reserved."
    *   **Copyleft:** Licenses like GPL, LGPL, AGPL.
    *   **Permissive:** More lenient licenses like MIT, Apache, BSD.
4.  **Report Generation:** It generates a comprehensive `license_report.log` in the `reports` directory. This report details each mod's license and categorizes them, providing a summary count for each category.
5.  **Rate Limiting:** Includes a small delay between API calls to respect Modrinth's rate limits.

## End-to-End Release Flow

This section outlines the complete journey of a modpack release, from a developer's local machine to its final publication on Modrinth and GitHub, demonstrating how all the documented scripts and workflows integrate.

1.  **Developer Initiates Release Locally:**
    *   A developer decides to release a new version of the modpack (client, server, or both).
    *   They ensure `changelog-staging.md` for the relevant pack(s) is updated with release notes.
    *   They run `release.ps1`.

2.  **Local Release Script Execution (`release.ps1`):**
    *   `release.ps1` prompts the developer for the new version number(s) and confirms the action.
    *   For each selected pack:
        *   It updates the `version.txt` file in the pack's directory with the new version.
        *   It executes `packwiz refresh` to ensure mod metadata is up-to-date.
        *   It calls `mrpack-export.ps1` to prepare and export the `.mrpack` file. This involves:
            *   Reading pack metadata from `pack-config.yml`.
            *   Temporarily replacing placeholders in `pack.toml` and other config files with actual version and pack information.
            *   Zipping any `custom_datapacks` and temporarily modifying `.packwizignore` to ensure only the zipped versions are included in the export.
            *   Running `packwiz modrinth export` to create the `.mrpack` in a version-specific export folder.
            *   Restoring the original `pack.toml` and `.packwizignore`, and cleaning up temporary datapack zips.
        *   It calls `changelog-generator.ps1` to:
            *   Read the content from `changelog-staging.md`.
            *   Format it with the version and date.
            *   Prepend this new entry to the pack's `changelog.md`.
            *   Reset `changelog-staging.md` for future use.
    *   After processing packs, `release.ps1` calls `update-readme.ps1`, which reads `client-pack/readme.md` and `server-pack/readme.md` and combines them into the root `README.md`.
    *   `release.ps1` then performs Git operations:
        *   It stages all modified files (pack directories, `pack-config.yml`, `README.md`).
        *   It commits these changes with a message like "Release client vX.X.X and server vY.Y.Y".
        *   Crucially, it creates Git tags (e.g., `client/vX.X.X` and `server/vY.Y.Y`).
        *   Finally, it pushes the commit and these new tags to the remote GitHub repository.

3.  **GitHub Actions Workflow Trigger:**
    *   The push of the new Git tag(s) (e.g., `client/v2.6.0`) automatically triggers the corresponding GitHub Actions workflow (`release-client.yml` or `release-server.yml`).

4.  **CI/CD Pipeline Execution (GitHub Actions):**
    *   The workflow starts on a fresh Ubuntu runner.
    *   It extracts the version number from the Git tag.
    *   It installs necessary tools (`packwiz`).
    *   It reads pack-specific metadata (Modrinth IDs, pack names, versions, loaders) from `pack-config.yml` using `yq`.
    *   It performs the same placeholder replacement in `pack.toml` and other configuration files as `mrpack-export.ps1` would have.
    *   It processes `custom_datapacks` (zipping folders and updating `.packwizignore` temporarily) exactly as `mrpack-export.ps1` does, ensuring consistency.
    *   It runs `packwiz refresh` and `packwiz modrinth export` to build the `.mrpack` file.
    *   It extracts the latest changelog entry from the pack's `changelog.md` to use for release notes.
    *   It creates a new GitHub Release, attaching the generated `.mrpack` file and using the extracted changelog as the release body.
    *   It publishes the `.mrpack` to Modrinth using the `Kir-Antipov/mc-publish` action, again using the extracted changelog for version notes and incorporating metadata from `pack-config.yml`.
    *   Finally, it updates the Modrinth project description using the content from the pack's `readme.md`, keeping the Modrinth page synchronized.

5.  **Completion:**
    *   The GitHub Actions workflow finishes, and the new version of the modpack is now available on GitHub Releases and Modrinth.

This entire flow ensures a consistent, automated, and traceable release process for both client and server modpacks.