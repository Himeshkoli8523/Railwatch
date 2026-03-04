# CCTV FastAPI Backend

This backend exposes only the APIs requested:

- `GET /api/videos`
- `GET /api/videos/{video_id}`
- `GET /api/dashboard/summary`

## Run locally

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Flutter integration

Use `API_BASE_URL` when running Flutter:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a real Android device, replace with your PC LAN IP, for example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```
