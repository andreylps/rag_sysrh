import sys
from pathlib import Path

import guardrails as gd

# Add src to path
SRC_PATH = Path(__file__).resolve().parent.parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.guardrails.rail_specs import rail_spec_topical  # noqa: E402


def inspect_guard():
    guard = gd.Guard.from_rail_string(rail_spec_topical)
    print("Guard methods:", dir(guard))

    try:
        # Try to format the prompt
        formatted_prompt = guard.base_prompt.format(user_input="TEST INPUT")
        print(f"Formatted prompt: {formatted_prompt}")
    except Exception as e:
        print(f"Error formatting prompt: {e}")


if __name__ == "__main__":
    inspect_guard()
