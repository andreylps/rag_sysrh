import asyncio
import os

from src.services.scrum_master_service import scrum_master_service


async def main():
    print("Testing Daily Snapshot...")
    try:
        snapshot = await scrum_master_service.take_daily_snapshot()
        print(f"Snapshot created: {snapshot}")

        # Verify file existence
        sprint_id = snapshot.sprint_id
        file_path = f"data/sprint_history_{sprint_id}.json"

        if os.path.exists(file_path):
            print(f"SUCCESS: Snapshot file found at {file_path}")
        else:
            print(f"FAILURE: Snapshot file not found at {file_path}")

    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    asyncio.run(main())
