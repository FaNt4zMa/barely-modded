#!/usr/bin/env python3
"""
Check Missing Dependencies
Validates that all required dependencies are present in the modpack
"""

import json
import sys
from pathlib import Path
from collections import defaultdict

OUTPUT_DIR = "reports"

# Exception list: Project IDs to ignore during dependency checking
# Useful for forks, alternatives, or intentionally missing dependencies
EXCEPTIONS = {
    "nfn13YXA",  # REI - using a fork instead
    "mOgUt4GM",  # Mod Menu - not needed for server pack
}

def load_dependency_data(pack_dir):
    """Load the JSON dependency data"""
    json_file = Path(pack_dir) / OUTPUT_DIR / "mod_dependencies.json"
    
    if not json_file.exists():
        print(f"✗ {json_file} not found!")
        print("Run the dependency checker script first to generate this file.")
        sys.exit(1)
    
    with open(json_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def check_missing_dependencies(data, exceptions):
    """Check for missing required dependencies"""
    
    # Build a set of all installed mod project IDs
    installed_mods = set()
    mod_names = {}  # project_id -> name mapping
    
    for mod in data['mods']:
        project_id = mod['project_id']
        installed_mods.add(project_id)
        mod_names[project_id] = mod['name']
    
    # Add exceptions to installed set (treat them as "installed")
    installed_mods.update(exceptions)
    
    # Check each mod's dependencies
    missing_deps = defaultdict(list)
    optional_missing = defaultdict(list)
    excepted_deps = defaultdict(list)
    all_satisfied = True
    
    for mod in data['mods']:
        mod_name = mod['name']
        
        for dep in mod['dependencies']:
            dep_project_id = dep['project_id']
            dep_name = dep['name']
            dep_type = dep['dependency_type']
            
            if dep_project_id not in installed_mods:
                if dep_type == 'required':
                    missing_deps[mod_name].append({
                        'name': dep_name,
                        'project_id': dep_project_id,
                        'type': dep_type
                    })
                    all_satisfied = False
                elif dep_type == 'optional':
                    optional_missing[mod_name].append({
                        'name': dep_name,
                        'project_id': dep_project_id,
                        'type': dep_type
                    })
            elif dep_project_id in exceptions:
                # Track which dependencies were excepted
                excepted_deps[mod_name].append({
                    'name': dep_name,
                    'project_id': dep_project_id,
                    'type': dep_type
                })
    
    return missing_deps, optional_missing, excepted_deps, all_satisfied

def print_results(missing_deps, optional_missing, excepted_deps, all_satisfied, output_lines):
    """Print the results in a nice format"""
    
    def log(text=""):
        print(text)
        output_lines.append(text)
    
    log("\n" + "="*70)
    log("DEPENDENCY CHECK RESULTS")
    log("="*70 + "\n")
    
    # Print excepted dependencies first if any
    if excepted_deps:
        log("ℹ️  EXCEPTED DEPENDENCIES")
        log("-" * 70)
        log("These dependencies are in the exception list:\n")
        
        for mod_name, deps in sorted(excepted_deps.items()):
            log(f"📦 {mod_name}")
            for dep in deps:
                log(f"   ⊘ Excepted: {dep['name']}")
                log(f"     Project ID: {dep['project_id']}")
                log(f"     Type: {dep['type'].upper()}")
            log()
        log()
    
    if all_satisfied and not optional_missing:
        log("✓ All dependencies satisfied!")
        log("  Your modpack has all required and optional dependencies installed.\n")
        return
    
    # Print missing required dependencies
    if missing_deps:
        log("🔴 MISSING REQUIRED DEPENDENCIES")
        log("-" * 70)
        log("These mods will likely crash or fail to load:\n")
        
        for mod_name, deps in sorted(missing_deps.items()):
            log(f"📦 {mod_name}")
            for dep in deps:
                log(f"   ✗ Missing: {dep['name']}")
                log(f"     Project ID: {dep['project_id']}")
                log(f"     Type: {dep['type'].upper()}")
            log()
        
        log("=" * 70)
        log(f"Total mods with missing required dependencies: {len(missing_deps)}")
        log("=" * 70 + "\n")
    else:
        log("✓ All required dependencies are satisfied!\n")
    
    # Print missing optional dependencies
    if optional_missing:
        log("🟡 MISSING OPTIONAL DEPENDENCIES")
        log("-" * 70)
        log("These are optional - mods will work without them:\n")
        
        for mod_name, deps in sorted(optional_missing.items()):
            log(f"📦 {mod_name}")
            for dep in deps:
                log(f"   • {dep['name']}")
                log(f"     Project ID: {dep['project_id']}")
            log()
        
        log("=" * 70)
        log(f"Total mods with missing optional dependencies: {len(optional_missing)}")
        log("=" * 70 + "\n")

def generate_install_list(missing_deps, output_lines):
    """Generate a list of mod IDs to install"""
    if not missing_deps:
        return
    
    def log(text=""):
        print(text)
        output_lines.append(text)
    
    log("\n" + "="*70)
    log("MODRINTH PROJECT IDs TO INSTALL")
    log("="*70)
    log("Add these mods to your pack using packwiz:\n")
    
    # Collect unique missing dependencies
    to_install = set()
    dep_names = {}
    
    for mod_name, deps in missing_deps.items():
        for dep in deps:
            to_install.add(dep['project_id'])
            dep_names[dep['project_id']] = dep['name']
    
    for project_id in sorted(to_install):
        name = dep_names[project_id]
        log(f"  packwiz modrinth add {project_id}")
        log(f"    # {name}")
    
    log("\n" + "="*70 + "\n")

def main():
    """Main entry point"""
    print("Checking modpack dependencies...")
    
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
    
    # Load data
    data = load_dependency_data(pack_path)
    
    if EXCEPTIONS:
        print(f"Using {len(EXCEPTIONS)} exception(s)")
    
    print(f"Loaded data for {len(data['mods'])} mods/datapacks/resourcepacks")
    
    # Check dependencies
    missing_deps, optional_missing, excepted_deps, all_satisfied = check_missing_dependencies(data, EXCEPTIONS)
    
    # Collect output for log file
    output_lines = []
    
    # Print results (and collect output)
    print_results(missing_deps, optional_missing, excepted_deps, all_satisfied, output_lines)
    
    # Generate install commands if needed (and collect output)
    if missing_deps:
        generate_install_list(missing_deps, output_lines)
    
    # Write log file
    output_dir = pack_path / OUTPUT_DIR
    output_dir.mkdir(exist_ok=True)
    log_file = output_dir / "dependency_check.log"
    
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"Dependency Check Report - Generated {timestamp}\n")
        f.write("="*70 + "\n\n")
        f.write('\n'.join(output_lines))
    
    print(f"✓ Report saved to: {log_file.relative_to(pack_path)}")
    
    # Exit with error code if required deps are missing
    if missing_deps:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()