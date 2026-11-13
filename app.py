"""任务二：第一个 FastAPI 服务

启动：
    .venv\\Scripts\\python.exe -m uvicorn app:app --reload

访问：
    http://127.0.0.1:8000/hello      接口本身
    http://127.0.0.1:8000/docs       自动生成的交互文档（重点看这个）
"""
from fastapi import FastAPI

app = FastAPI(title="Agent 方向 · 任务二")


@app.get("/hello")
async def hello() -> dict[str, str]:
    """最简单的接口：访问 /hello 返回一句话"""
    return {"message": "你好，这是我的第一个接口"}
