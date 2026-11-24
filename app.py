from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, StreamingResponse
from pydantic import BaseModel, Field

import asyncio

from bmi import BMI

app = FastAPI(title="Agent 方向 · 任务二", version="0.4.0")


# ---------- ① 无参数 ----------
@app.get("/hello")
async def hello() -> dict[str, str]:
    return {"message": "你好"}


# ---------- ② 路径参数 ----------
@app.get("/greet/{name}")
async def greet(name: str) -> dict[str, str]:
    return {"message": f"你好，{name}！"}


# ---------- ③ 查询参数 ----------
@app.get("/search")
async def search(q: str, limit: int = 5) -> dict[str, object]:
    results = [f"{q}的第{i}条" for i in range(1, limit + 1)]
    return {"query": q, "limit": limit, "results": results}


# ---------- ④ 请求体 + Pydantic 校验 ----------
class BMIRequest(BaseModel):
    height: float = Field(..., gt=0, le=3, description="身高（米）")
    weight: float = Field(..., gt=0, le=500, description="体重（公斤）")


@app.post("/bmi")
async def calc_bmi_api(req: BMIRequest) -> dict[str, object]:
    person = BMI(req.height, req.weight)
    label, tip = person.judge()
    return {"bmi": round(person.value(), 2), "label": label, "tip": tip}


# ---------- ⑤ 健康检查（Docker 用）----------
@app.get("/health")
async def health() -> dict[str, object]:
    return {"status": "ok", "version": app.version}


# ---------- ⑥ 统一错误响应 ----------
@app.get("/error-demo/{code}")
async def error_demo(code: int) -> dict[str, str]:
    if code == 404:
        raise HTTPException(status_code=404, detail="你要找的东西不存在")
    if code == 500:
        raise HTTPException(status_code=500, detail="服务器内部错误（演示）")
    return {"message": "没有触发错误"}


# ---------- ⑦ SSE 流式输出（任务二核心验收项）----------
@app.get("/stream")
async def stream() -> StreamingResponse:
    """逐字推送：浏览器里能看到文字一个个蹦出来"""

    async def event_gen():
        words = ["你好", "，", "这是", "一次", "流式", "输", "出", "。"]
        for w in words:
            yield f"data: {w}\n\n"       # 两个换行 = 一条消息的结束
            await asyncio.sleep(0.4)      # 模拟大模型逐字生成
        yield "data: [DONE]\n\n"          # 自定义结束标记

    return StreamingResponse(event_gen(), media_type="text/event-stream")


@app.get("/stream-page", response_class=HTMLResponse)
async def stream_page() -> str:
    """最小网页：用 EventSource 接收 SSE 并实时显示"""
    return """<!doctype html>
<meta charset="utf-8">
<title>SSE 流式测试</title>
<style>body{font-family:system-ui;margin:40px} #out{font-size:24px;line-height:1.9}</style>
<h3>SSE 流式输出演示</h3>
<p>本页会自动连接 /stream，文字会一个一个出现。</p>
<div id="out"></div>
<script>
const es = new EventSource("/stream");
es.onmessage = (e) => {
  if (e.data === "[DONE]") {
    es.close();
    document.getElementById("out").innerHTML +=
      "<br><b style='color:#2e7d32'>&#10003; 流结束</b>";
    return;
  }
  document.getElementById("out").innerHTML += e.data;
};
</script>"""
