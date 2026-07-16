from fastapi import FastAPI

app = FastAPI(title="DIY L2T Backend")


@app.get("/")
def read_root() -> dict[str, str]:
    return {"status": "ok"}