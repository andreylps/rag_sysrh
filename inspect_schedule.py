import json

with open("data/qa_schedule.json") as f:
    data = json.load(f)

print(f"Total schedules: {len(data)}")

target_dates = ["2025-11-27", "2025-11-28", "2025-11-29", "2025-11-30"]
found = []

for item in data:
    date_str = item["scheduled_date"][:10]
    if date_str in target_dates:
        found.append(item)

print(f"Found {len(found)} items for target dates.")
for item in sorted(found, key=lambda x: x["scheduled_date"]):
    print(f"{item['scheduled_date']} - {item['audit_type']} - {item['status']}")
