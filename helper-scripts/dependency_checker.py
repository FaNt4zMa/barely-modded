#!/usr/bin/env python3
"""
Packwiz Mod Dependency Checker
Analyzes all mods in a packwiz modpack and lists their dependencies
"""

import sys
import time
import json
import requests
from pathlib import Path
from datetime import datetime

# Configuration
API_BASE = "https://api.modrinth.com/v2"
RATE_LIMIT_DELAY = 0.1  # Seconds between API calls (gentle rate limiting)
OUTPUT_DIR = "reports"  # Output directory for reports

# Directories to scan for packwiz files
SCAN_DIRS = ["mods", "datapacks", "resourcepacks"]

def parse_toml_simple(content):
    """Simple TOML parser for packwiz mod files"""
    data = {}
    current_section = []
    
    for line in content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        # Section header
        if line.startswith('[') and line.endswith(']'):
            section = line[1:-1]
            current_section = section.split('.')
            
            # Create nested structure
            d = data
            for part in current_section[:-1]:
                if part not in d:
                    d[part] = {}
                d = d[part]
            if current_section[-1] not in d:
                d[current_section[-1]] = {}
            continue
        
        # Key-value pair
        if '=' in line:
            key, _, value = line.partition('=')
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            
            if current_section:
                # Navigate to correct nested dict
                d = data
                for part in current_section:
                    if part not in d:
                        d[part] = {}
                    d = d[part]
                d[key] = value
            else:
                data[key] = value
    
    return data

def get_mod_version_from_modrinth(project_id, version_id):
    """Fetch mod version details from Modrinth API"""
    try:
        url = f"{API_BASE}/version/{version_id}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 429:
            print(f"  ⚠ Rate limited, waiting longer...")
            time.sleep(5)
            return get_mod_version_from_modrinth(project_id, version_id)
        else:
            print(f"  ⚠ API error {response.status_code} for version {version_id}")
            return None
    except Exception as e:
        print(f"  ✗ Error fetching version {version_id}: {e}")
        return None

def get_mod_info_from_modrinth(project_id):
    """Fetch mod project details from Modrinth API"""
    try:
        url = f"{API_BASE}/project/{project_id}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 429:
            print(f"  ⚠ Rate limited, waiting longer...")
            time.sleep(5)
            return get_mod_info_from_modrinth(project_id)
        else:
            print(f"  ⚠ API error {response.status_code} for project {project_id}")
            return None
    except Exception as e:
        print(f"  ✗ Error fetching project {project_id}: {e}")
        return None

def scan_packwiz_mods(base_dir, scan_dirs):
    """Scan multiple directories for .pw.toml files"""
    all_files = []
    
    for dir_name in scan_dirs:
        dir_path = Path(base_dir) / dir_name
        
        if not dir_path.exists():
            print(f"⚠ Directory not found: {dir_name} (skipping)")
            continue
        
        files = list(dir_path.glob("*.pw.toml"))
        if files:
            print(f"Found {len(files)} files in {dir_name}/")
            all_files.extend([(f, dir_name) for f in files])
    
    print(f"\nTotal files to scan: {len(all_files)}\n")
    return all_files

def analyze_dependencies(mod_files_with_dirs, log_file, json_file):
    """Analyze dependencies for all mods"""
    results = []
    json_data = {"mods": [], "generated": datetime.now().isoformat()}
    
    with open(log_file, 'w', encoding='utf-8') as log:
        log.write(f"Packwiz Mod Dependency Analysis\n")
        log.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        log.write(f"Total files scanned: {len(mod_files_with_dirs)}\n")
        log.write("="*80 + "\n\n")
        
        for idx, (mod_file, source_dir) in enumerate(mod_files_with_dirs, 1):
            print(f"[{idx}/{len(mod_files_with_dirs)}] Analyzing {source_dir}/{mod_file.name}...")
            
            try:
                with open(mod_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                mod_data = parse_toml_simple(content)
                
                # Extract mod info
                mod_name = mod_data.get('name', mod_file.stem)
                
                # Get Modrinth project ID and version
                update_section = mod_data.get('update', {})
                if not isinstance(update_section, dict):
                    update_section = {}
                
                modrinth_section = update_section.get('modrinth', {})
                if not isinstance(modrinth_section, dict):
                    modrinth_section = {}
                    
                project_id = modrinth_section.get('mod-id')
                version_id = modrinth_section.get('version')
                
                if not project_id or not version_id:
                    log.write(f"📦 {mod_name}\n")
                    log.write(f"   File: {source_dir}/{mod_file.name}\n")
                    log.write(f"   ⚠ No Modrinth data found in .pw.toml\n\n")
                    print(f"   ⚠ No Modrinth data found")
                    continue
                
                # Fetch version details from Modrinth
                time.sleep(RATE_LIMIT_DELAY)
                version_data = get_mod_version_from_modrinth(project_id, version_id)
                
                if not version_data:
                    log.write(f"📦 {mod_name}\n")
                    log.write(f"   File: {source_dir}/{mod_file.name}\n")
                    log.write(f"   Project ID: {project_id}\n")
                    log.write(f"   ⚠ Could not fetch version data from Modrinth\n\n")
                    print(f"   ⚠ Could not fetch version data")
                    continue
                
                # Get project info for better naming
                time.sleep(RATE_LIMIT_DELAY)
                project_data = get_mod_info_from_modrinth(project_id)
                project_title = project_data.get('title', mod_name) if project_data else mod_name
                
                # Extract dependencies
                dependencies = version_data.get('dependencies', [])
                
                # Build JSON entry
                mod_entry = {
                    "name": project_title,
                    "file": mod_file.name,
                    "source_dir": source_dir,
                    "project_id": project_id,
                    "version": version_data.get('version_number', version_id),
                    "dependencies": []
                }
                
                log.write(f"📦 {project_title}\n")
                log.write(f"   File: {source_dir}/{mod_file.name}\n")
                log.write(f"   Project ID: {project_id}\n")
                log.write(f"   Version: {version_data.get('version_number', version_id)}\n")
                
                if dependencies:
                    log.write(f"   Dependencies ({len(dependencies)}):\n")
                    
                    for dep in dependencies:
                        dep_type = dep.get('dependency_type', 'unknown')
                        dep_project_id = dep.get('project_id')
                        dep_version_id = dep.get('version_id')
                        
                        # Mark dependency type
                        if dep_type == 'required':
                            marker = "🔴 REQUIRED"
                        elif dep_type == 'optional':
                            marker = "🟡 OPTIONAL"
                        else:
                            marker = f"⚪ {dep_type.upper()}"
                        
                        # Fetch dependency project name
                        if dep_project_id:
                            time.sleep(RATE_LIMIT_DELAY)
                            dep_project = get_mod_info_from_modrinth(dep_project_id)
                            dep_name = dep_project.get('title', dep_project_id) if dep_project else dep_project_id
                            
                            log.write(f"      • {marker}: {dep_name}\n")
                            log.write(f"        Project ID: {dep_project_id}\n")
                            
                            if dep_version_id:
                                log.write(f"        Version ID: {dep_version_id}\n")
                            
                            # Add to JSON
                            mod_entry["dependencies"].append({
                                "name": dep_name,
                                "project_id": dep_project_id,
                                "version_id": dep_version_id,
                                "dependency_type": dep_type
                            })
                        else:
                            log.write(f"      • {marker}: (ID not specified)\n")
                    
                    print(f"   ✓ Found {len(dependencies)} dependencies")
                else:
                    log.write(f"   ✓ No dependencies\n")
                    print(f"   ✓ No dependencies")
                
                log.write("\n")
                json_data["mods"].append(mod_entry)
                results.append({
                    'name': project_title,
                    'file': mod_file.name,
                    'dependencies': len(dependencies)
                })
                
            except Exception as e:
                log.write(f"📦 {mod_file.name}\n")
                log.write(f"   ✗ Error: {str(e)}\n\n")
                print(f"   ✗ Error: {e}")
        
        # Write summary
        log.write("\n" + "="*80 + "\n")
        log.write("SUMMARY\n")
        log.write("="*80 + "\n")
        total_deps = sum(r['dependencies'] for r in results)
        log.write(f"Total mods analyzed: {len(results)}\n")
        log.write(f"Total dependencies found: {total_deps}\n")
        log.write(f"\nMods with dependencies:\n")
        for result in sorted(results, key=lambda x: x['dependencies'], reverse=True):
            if result['dependencies'] > 0:
                log.write(f"  • {result['name']}: {result['dependencies']} dependencies\n")
    
    # Write JSON file
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, indent=2, ensure_ascii=False)
    
    return results

def main():
    """Main entry point"""
    print("Packwiz Mod Dependency Checker")
    print("="*50)
    
    # Get pack directory
    if len(sys.argv) > 1:
        pack_dir = sys.argv[1]
    else:
        pack_dir = input("\nEnter path to your packwiz modpack directory (or '.' for current): ").strip()
        if not pack_dir:
            pack_dir = "."
    
    pack_path = Path(pack_dir).resolve()
    
    if not pack_path.exists():
        print(f"✗ Directory not found: {pack_dir}")
        sys.exit(1)
    
    print(f"\nScanning modpack at: {pack_path}")
    
    # Create output directory
    output_path = pack_path / OUTPUT_DIR
    output_path.mkdir(exist_ok=True)
    
    log_file = output_path / "mod_dependencies.log"
    json_file = output_path / "mod_dependencies.json"
    
    # Scan for files in multiple directories
    mod_files = scan_packwiz_mods(pack_path, SCAN_DIRS)
    
    if not mod_files:
        print("✗ No .pw.toml files found in any directory")
        sys.exit(1)
    
    # Analyze dependencies
    print(f"Analyzing dependencies (rate limited to {RATE_LIMIT_DELAY}s per request)...\n")
    results = analyze_dependencies(mod_files, log_file, json_file)
    
    # Print summary
    print("\n" + "="*50)
    print(f"✓ Analysis complete!")
    print(f"✓ Results written to: {log_file.relative_to(pack_path)}")
    print(f"✓ Machine-readable data: {json_file.relative_to(pack_path)}")
    print(f"✓ Mods analyzed: {len(results)}")
    total_deps = sum(r['dependencies'] for r in results)
    print(f"✓ Total dependencies: {total_deps}")

if __name__ == "__main__":
    main()