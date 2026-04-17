import os

def bundle_godot_project(output_file="godot_project_context.txt"):
    # Common Godot file extensions
    # .gd = logic, .tscn = scene hierarchy/settings
    valid_extensions = ('.gd', '.tscn')
    
    # Files or directories to ignore
    ignore_list = {'.import', 'bin', 'build'}

    with open(output_file, 'w', encoding='utf-8') as outfile:
        for root, dirs, files in os.walk('.'):
            # Skip ignored directories
            dirs[:] = [d for d in dirs if d not in ignore_list]

            for file in files:
                if file.endswith(valid_extensions):
                    file_path = os.path.join(root, file)
                    
                    # Write a clear header for the AI to identify the file
                    outfile.write(f"\n{'='*50}\n")
                    outfile.write(f"FILE: {file_path}\n")
                    outfile.write(f"{'='*50}\n\n")
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as infile:
                            outfile.write(infile.read())
                    except Exception as e:
                        outfile.write(f"[Error reading file: {e}]\n")
                    
                    outfile.write("\n\n")

    print(f"Project bundled successfully into: {output_file}")

if __name__ == "__main__":
    bundle_godot_project()