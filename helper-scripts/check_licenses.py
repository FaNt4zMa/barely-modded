#!/usr/bin/env python3
"""
Packwiz License Checker
Scans all mods/datapacks/resourcepacks and reports their licenses
"""

import sys
import time
import requests
from pathlib import Path
from collections import defaultdict
from datetime import datetime

# Configuration
API_BASE = "https://api.modrinth.com/v2"
RATE_LIMIT_DELAY = 0.1  # Seconds between API calls
OUTPUT_DIR = "reports"  # Output directory for reports

# Directories to scan
SCAN_DIRS = ["mods", "datapacks", "resourcepacks"]

# License categories
RESTRICTIVE_KEYWORDS = ['arr', 'all rights reserved', 'all-rights-reserved']
COPYLEFT_LICENSES = ['gpl-3.0', 'gpl-2.0', 'lgpl-3.0', 'lgpl-2.1', 'agpl-3.0']

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

def get_modrinth_project_info(project_id):
    """Fetch project information from Modrinth API"""
    try:
        url = f"{API_BASE}/project/{project_id}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 429:
            print(f"  ⚠ Rate limited, waiting longer...")
            time.sleep(5)
            return get_modrinth_project_info(project_id)
        else:
            return None
    except Exception as e:
        print(f"  ✗ Error fetching {project_id}: {e}")
        return None

def scan_directories(base_dir, directories):
    """Scan multiple directories for packwiz files"""
    all_projects = []
    
    for directory in directories:
        dir_path = Path(base_dir) / directory
        
        if not dir_path.exists():
            print(f"⚠ Directory not found: {directory} (skipping)")
            continue
        
        projects = []
        for toml_file in dir_path.glob("*.pw.toml"):
            try:
                with open(toml_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                data = parse_toml_simple(content)
                
                # Extract Modrinth info
                update_section = data.get('update', {})
                modrinth_section = update_section.get('modrinth', {})
                project_id = modrinth_section.get('mod-id')
                
                if project_id:
                    projects.append({
                        'name': data.get('name', toml_file.stem),
                        'filename': data.get('filename', 'Unknown'),
                        'project_id': project_id,
                        'file_path': f"{directory}/{toml_file.name}",
                        'source_dir': directory
                    })
            except Exception as e:
                print(f"  ⚠ Error parsing {toml_file.name}: {e}")
        
        if projects:
            print(f"Found {len(projects)} projects in {directory}/")
            all_projects.extend(projects)
        else:
            print(f"No projects found in {directory}/")
    
    return all_projects

def categorize_license(license_id, license_name):
    """Categorize a license as restrictive, copyleft, or permissive"""
    license_id_lower = license_id.lower()
    
    # Check for restrictive
    if any(keyword in license_id_lower for keyword in RESTRICTIVE_KEYWORDS):
        return 'restrictive'
    
    # Check for copyleft
    if license_id_lower in COPYLEFT_LICENSES:
        return 'copyleft'
    
    # Default to permissive
    return 'permissive'

def check_licenses(pack_dir):
    """Main license checking function"""
    print("Packwiz License Checker")
    print("="*70)
    print()
    
    pack_path = Path(pack_dir).resolve()
    
    # Scan directories
    print("Scanning for packwiz files...\n")
    all_projects = scan_directories(pack_path, SCAN_DIRS)
    
    if not all_projects:
        print("\n✗ No projects found with Modrinth IDs!")
        sys.exit(1)
    
    print(f"\nTotal projects found: {len(all_projects)}")
    print(f"Fetching license info (rate limited to {RATE_LIMIT_DELAY}s per request)...\n")
    
    # Fetch license info
    licenses_by_category = {
        'restrictive': defaultdict(list),
        'copyleft': defaultdict(list),
        'permissive': defaultdict(list),
        'unknown': []
    }
    
    for idx, project in enumerate(all_projects, 1):
        print(f"[{idx}/{len(all_projects)}] Checking {project['name']}...")
        
        time.sleep(RATE_LIMIT_DELAY)
        project_info = get_modrinth_project_info(project['project_id'])
        
        if project_info:
            license_data = project_info.get('license', {})
            license_id = license_data.get('id', 'Unknown')
            license_name = license_data.get('name', 'Unknown')
            
            project['license_id'] = license_id
            project['license_name'] = license_name
            project['project_url'] = f"https://modrinth.com/{project_info.get('project_type', 'mod')}/{project['project_id']}"
            
            if license_id != 'Unknown':
                category = categorize_license(license_id, license_name)
                licenses_by_category[category][license_id].append(project)
            else:
                licenses_by_category['unknown'].append(project)
        else:
            project['license_id'] = 'API_ERROR'
            project['license_name'] = 'Could not fetch'
            project['project_url'] = f"https://modrinth.com/mod/{project['project_id']}"
            licenses_by_category['unknown'].append(project)
    
    # Generate report
    generate_report(licenses_by_category, all_projects, pack_path)

def generate_report(licenses_by_category, all_projects, pack_path):
    """Generate and save the license report"""
    output_lines = []
    
    def log(text=""):
        print(text)
        output_lines.append(text)
    
    print("\n" + "="*70)
    
    # Restrictive licenses section
    log("="*70)
    log("⚠️  RESTRICTIVE LICENSES (ARR or similar)")
    log("="*70)
    
    restrictive = licenses_by_category['restrictive']
    if restrictive:
        for license_id in sorted(restrictive.keys()):
            projects = restrictive[license_id]
            log(f"\n[{license_id}] - {projects[0]['license_name']}")
            log("-"*70)
            for project in projects:
                log(f"  📦 {project['name']}")
                log(f"     URL: {project['project_url']}")
                log(f"     File: {project['file_path']}")
                log()
    else:
        log("\n✓ None found!")
    
    # Copyleft licenses section
    log("\n" + "="*70)
    log("🔄 COPYLEFT LICENSES (GPL, LGPL, AGPL)")
    log("="*70)
    
    copyleft = licenses_by_category['copyleft']
    if copyleft:
        for license_id in sorted(copyleft.keys()):
            projects = copyleft[license_id]
            log(f"\n[{license_id}] - {projects[0]['license_name']}")
            log(f"  Count: {len(projects)} project(s)")
            for project in projects:
                log(f"    • {project['name']}")
    else:
        log("\n✓ None found!")
    
    # Permissive licenses section
    log("\n" + "="*70)
    log("✅ PERMISSIVE LICENSES (MIT, Apache, BSD, etc.)")
    log("="*70)
    
    permissive = licenses_by_category['permissive']
    if permissive:
        for license_id in sorted(permissive.keys()):
            projects = permissive[license_id]
            log(f"\n[{license_id}] - {projects[0]['license_name']}")
            log(f"  Count: {len(projects)} project(s)")
            for project in projects:
                log(f"    • {project['name']}")
    else:
        log("\n✓ None found!")
    
    # Unknown/Error section
    unknown = licenses_by_category['unknown']
    if unknown:
        log("\n" + "="*70)
        log("❓ UNKNOWN/ERROR")
        log("="*70)
        for project in unknown:
            log(f"\n  • {project['name']}")
            log(f"    License: {project['license_id']}")
            log(f"    File: {project['file_path']}")
    
    # Summary
    restrictive_count = sum(len(projects) for projects in restrictive.values())
    copyleft_count = sum(len(projects) for projects in copyleft.values())
    permissive_count = sum(len(projects) for projects in permissive.values())
    unknown_count = len(unknown)
    
    log("\n" + "="*70)
    log("SUMMARY")
    log("="*70)
    log(f"Total projects: {len(all_projects)}")
    log(f"  ⚠️  Restrictive (ARR): {restrictive_count}")
    log(f"  🔄 Copyleft (GPL etc): {copyleft_count}")
    log(f"  ✅ Permissive: {permissive_count}")
    log(f"  ❓ Unknown/Error: {unknown_count}")
    
    total_license_types = len(restrictive) + len(copyleft) + len(permissive)
    log(f"\nUnique license types: {total_license_types}")
    
    # Create output directory and write file
    output_dir = pack_path / OUTPUT_DIR
    output_dir.mkdir(exist_ok=True)
    output_file = output_dir / "license_report.log"
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"License Report - Generated {timestamp}\n")
        f.write("="*70 + "\n\n")
        f.write('\n'.join(output_lines))
    
    print(f"\n✓ Report saved to: {output_file.relative_to(pack_path)}")

def main():
    """Main entry point"""
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
    
    print(f"Scanning modpack at: {pack_path}\n")
    
    try:
        check_licenses(pack_dir)
    except KeyboardInterrupt:
        print("\n\n⚠ Interrupted by user")
        sys.exit(1)

if __name__ == "__main__":
    main()