import shutil

import psutil
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class DiskStats(BaseModel):
    total_gb: float
    used_gb: float
    percent_used: float
    status: str


class CPUStats(BaseModel):
    percent_used: float
    status: str


class HealthResponse(BaseModel):
    disk: DiskStats
    cpu: CPUStats


DISK_CRITICAL_THRESHOLD = 85
DISK_WARNING_THRESHOLD = 70
CPU_CRITICAL_THRESHOLD = 90
CPU_WARNING_THRESHOLD = 75


@router.get("/health", response_model=HealthResponse)
def get_system_health() -> dict:
    # Disk Usage
    total, used, _ = shutil.disk_usage("/")

    total_gb = round(total / (2**30), 2)
    used_gb = round(used / (2**30), 2)
    disk_percent = round((used / total) * 100, 1)

    if disk_percent > DISK_CRITICAL_THRESHOLD:
        disk_status = "critical"
    elif disk_percent > DISK_WARNING_THRESHOLD:
        disk_status = "warning"
    else:
        disk_status = "healthy"

    # CPU Usage
    # interval=None returns the usage since the last call (non-blocking)
    cpu_percent = psutil.cpu_percent(interval=None)

    if cpu_percent > CPU_CRITICAL_THRESHOLD:
        cpu_status = "critical"
    elif cpu_percent > CPU_WARNING_THRESHOLD:
        cpu_status = "warning"
    else:
        cpu_status = "healthy"

    return {
        "disk": {
            "total_gb": total_gb,
            "used_gb": used_gb,
            "percent_used": disk_percent,
            "status": disk_status,
        },
        "cpu": {
            "percent_used": cpu_percent,
            "status": cpu_status,
        },
    }
