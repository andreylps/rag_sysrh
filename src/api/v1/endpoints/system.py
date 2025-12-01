import shutil

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class DiskStats(BaseModel):
    total_gb: float
    used_gb: float
    percent_used: float
    status: str


class HealthResponse(BaseModel):
    disk: DiskStats


@router.get("/health", response_model=HealthResponse)
def get_system_health():
    total, used, free = shutil.disk_usage("/")

    total_gb = round(total / (2**30), 2)
    used_gb = round(used / (2**30), 2)
    percent_used = round((used / total) * 100, 1)

    if percent_used > 85:
        status = "critical"
    elif percent_used > 70:
        status = "warning"
    else:
        status = "healthy"

    return {
        "disk": {
            "total_gb": total_gb,
            "used_gb": used_gb,
            "percent_used": percent_used,
            "status": status,
        }
    }
