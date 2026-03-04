from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


class VideoOut(BaseModel):
    id: str
    camera_id: str
    wagon_id: str
    train_id: str
    timestamp: str
    duration: str
    thumbnail_url: str
    ai_tags: List[str]
    severity: str
    s3_signed_url_status: str
    zone_id: str
    zone_name: str
    division: str
    stream_url: str


class DashboardSummaryOut(BaseModel):
    total_videos_today: int
    total_trains_monitored: int
    alerts_generated: int
    storage_usage_gb: float


app = FastAPI(title="CCTV FastAPI", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _generate_videos() -> List[dict]:
    zones = [
        ("zone-A", "Zone A", "North Division"),
        ("zone-B", "Zone B", "South Division"),
        ("zone-C", "Zone C", "East Division"),
        ("zone-D", "Zone D", "West Division"),
    ]
    severities = ["low", "medium", "high", "critical"]
    tags = ["DoorOpen", "Smoke", "BearingHeat", "Motion", "PersonDetected"]

    now = datetime.utcnow()
    videos: List[dict] = []

    for zone_index, (zone_id, zone_name, division) in enumerate(zones):
        for cam_no in range(1, 4):
            camera_id = f"{zone_id}-cam{cam_no:02d}"
            for sample in range(1, 16):
                ts = now - timedelta(minutes=(zone_index * 120) + (cam_no * 20) + sample * 4)
                videos.append(
                    {
                        "id": f"{camera_id}-v{sample:03d}",
                        "camera_id": camera_id,
                        "wagon_id": f"W{(sample % 20) + 1}",
                        "train_id": f"T{(sample + cam_no + zone_index) % 10 + 1}",
                        "timestamp": ts.isoformat(),
                        "duration": f"{2 + (sample % 6)}:{(sample * 7) % 60:02d}",
                        "thumbnail_url": f"https://picsum.photos/seed/{camera_id}-{sample}/320/180",
                        "ai_tags": [tags[(sample + zone_index) % len(tags)]],
                        "severity": severities[(sample + cam_no) % len(severities)],
                        "s3_signed_url_status": "valid",
                        "zone_id": zone_id,
                        "zone_name": zone_name,
                        "division": division,
                        "stream_url": f"https://stream.example.local/{camera_id}/{sample}",
                    }
                )

    videos.sort(key=lambda item: item["timestamp"], reverse=True)
    return videos


VIDEOS = _generate_videos()


@app.get("/api/videos", response_model=List[VideoOut])
def get_videos(
    train_number: Optional[str] = Query(default=None),
    from_date: Optional[date] = Query(default=None),
    to_date: Optional[date] = Query(default=None),
    camera_id: Optional[str] = Query(default=None),
):
    filtered = VIDEOS

    if train_number:
        train_q = train_number.strip().lower()
        filtered = [item for item in filtered if train_q in item["train_id"].lower()]

    if camera_id:
        camera_q = camera_id.strip().lower()
        filtered = [item for item in filtered if item["camera_id"].lower() == camera_q]

    if from_date:
        filtered = [
            item
            for item in filtered
            if datetime.fromisoformat(item["timestamp"]).date() >= from_date
        ]

    if to_date:
        filtered = [
            item
            for item in filtered
            if datetime.fromisoformat(item["timestamp"]).date() <= to_date
        ]

    return filtered


@app.get("/api/videos/{video_id}", response_model=VideoOut)
def get_video_details(video_id: str):
    for item in VIDEOS:
        if item["id"] == video_id:
            return item
    raise HTTPException(status_code=404, detail="Video not found")


@app.get("/api/dashboard/summary", response_model=DashboardSummaryOut)
def get_dashboard_summary():
    today = datetime.utcnow().date()
    videos_today = [item for item in VIDEOS if datetime.fromisoformat(item["timestamp"]).date() == today]
    trains = {item["train_id"] for item in VIDEOS}
    alerts = [item for item in VIDEOS if item["severity"] in {"high", "critical"}]

    return DashboardSummaryOut(
        total_videos_today=len(videos_today),
        total_trains_monitored=len(trains),
        alerts_generated=len(alerts),
        storage_usage_gb=round(len(VIDEOS) * 0.08, 2),
    )
