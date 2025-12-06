file_path = "src/rag_sysrh/app.py"

with open(file_path, "rb") as f:
    lines = f.readlines()

start_marker = b"<<<<<<< HEAD"
mid_marker = b"======="
end_marker = b">>>>>>>"

# Find indices
start_idx = -1
mid_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if line.startswith(start_marker):
        start_idx = i
    elif line.startswith(mid_marker):
        mid_idx = i
    elif line.startswith(end_marker):
        end_idx = i

print(f"Markers found at: Start={start_idx}, Mid={mid_idx}, End={end_idx}")

if start_idx != -1 and mid_idx != -1 and end_idx != -1:
    # We want to keep content AFTER mid_marker and BEFORE end_marker
    # But wait, usually we want to keep one or the other.
    # Based on analysis, the content AFTER mid_marker is the new version we want.

    # If there is content BEFORE start_marker, we keep it.
    # If there is content AFTER end_marker, we keep it.

    new_lines = []

    # Keep pre-conflict
    new_lines.extend(lines[:start_idx])

    # Keep "Theirs" (Incoming) - lines between mid and end
    new_lines.extend(lines[mid_idx + 1 : end_idx])

    # Keep post-conflict
    new_lines.extend(lines[end_idx + 1 :])

    with open(file_path, "wb") as f:
        f.writelines(new_lines)

    print("Successfully resolved conflict by keeping 'theirs' (incoming changes).")
else:
    print("Could not find all conflict markers. Aborting.")
