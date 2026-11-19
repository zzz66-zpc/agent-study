from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from bmi import BMI

app = FastAPI(title="Agent 方向 · 任务二", version="0.3.0")


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
    """请求体的形状：height/weight 必填、都是数字、都必须大于 0"""

    height: float = Field(..., gt=0, le=3, description="身高（米）")
    weight: float = Field(..., gt=0, le=500, description="体重（公斤）")


class BMIResponse(BaseModel):
    """返回值的形状：response_model 会按它过滤输出"""

    bmi: float
    label: str
    tip: str


@app.post("/bmi", response_model=BMIResponse)
async def calc_bmi_api(req: BMIRequest) -> BMIResponse:
    """复用任务一写的 BMI 类：value() 算 BMI，judge() 返回 (标签, 建议)"""
    person = BMI(req.height, req.weight)
    label, tip = person.judge()
    return BMIResponse(bmi=round(person.value(), 2), label=label, tip=tip)


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
