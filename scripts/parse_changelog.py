import re
import os

def main():
    if not os.path.exists("CHANGELOG.md"):
        print("CHANGELOG.md not found")
        return

    with open("CHANGELOG.md", "r", encoding="utf-8") as f:
        content = f.read()

    # Find the first ## vX.Y.Z heading
    match = re.search(r"^##\s+(v\d+\.\d+\.\d+)", content, re.MULTILINE)
    if match:
        version = match.group(1)
        print(f"Detected version: {version}")
        
        # Extract text from this heading until the next heading or end of file
        start_idx = match.end()
        # Find next ## heading
        next_match = re.search(r"^##\s+", content[start_idx:], re.MULTILINE)
        if next_match:
            notes = content[start_idx:start_idx + next_match.start()].strip()
        else:
            notes = content[start_idx:].strip()
            
        with open("release_notes.txt", "w", encoding="utf-8") as out:
            out.write(notes)
        print("Written release_notes.txt")
        
        # Write to GITHUB_OUTPUT
        github_output = os.environ.get("GITHUB_OUTPUT")
        if github_output:
            with open(github_output, "a", encoding="utf-8") as go:
                go.write(f"version={version}\n")
            print("Exported version to GITHUB_OUTPUT")
    else:
        print("No version heading matching '## vX.Y.Z' found in CHANGELOG.md")

if __name__ == "__main__":
    main()
