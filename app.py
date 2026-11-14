"""任务二：FastAPI 服务（第 2–3 步）

启动：
    .venv\\Scripts\\python.exe -m uvicorn app:app --reload

访问 http://127.0.0.1:8000/docs 可以在网页上直接测试所有接口：

    GET  /hello           最简单的接口
    GET  /greet/{name}    路径参数（参数是 URL 的一段）
    GET  /search?q=...    查询参数（? 后面那串）
    POST /bmi             请求体 + Pydantic 校验（复用任务一的 BMI 类）
    GET  /health          健康检查（后面 Docker 要用）
    GET  /error-demo/{n}  统一错误响应演示
"""
from fastapi import FastAPI, HTTPException, Path, Query
from pydantic import BaseModel, Field

from bmi import BMI                       # 复用任务一写的类

app = FastAPI(title="Agent 方向 · 任务二", version="0.2.0")


# ---------- ① 最简单：无参数 ----------
@app.get("/hello")
async def hello() -> dict[str, str]:
    """访问 /hello 返回一句话"""
    return {"message": "你好，这是我的第一个接口"}


# ---------- ② 路径参数：参数是 URL 的一段 ----------
@app.get("/greet/{name}")
async def greet(
    name: str = Path(..., min_length=1, max_length=20, description="你的名字"),
) -> dict[str, str]:
    """访问 /greet/小明 —— 函数参数名要和 {name} 一致"""
    return {"message": f"你好，{name}！"}


# ---------- ③ 查询参数：? 后面的键值对 ----------
@app.get("/search")
async def search(
    q: str = Query(..., min_length=1, description="搜索关键词"),
    limit: int = Query(5, ge=1, le=50, description="返回条数，1–50"),
) -> dict[str, object]:
    """访问 /search?q=agent&limit=3 —— 没给 limit 就用默认值 5"""
    fake_db = [f"{q} 的第 {i} 条结果" for i in range(1, limit + 1)]
    return {"query": q, "limit": limit, "results": fake_db}


# ---------- ④ 请求体：POST 的 JSON，用 Pydantic 校验 ----------
class BMIRequest(BaseModel):
    """请求体的形状：客户端必须给 height 和 weight，且都要大于 0"""

    height: float = Field(..., gt=0, le=3, description="身高（米）")
    weight: float = Field(..., gt=0, le=500, description="体重（公斤）")


class BMIResponse(BaseModel):
    """返回值的形状：FastAPI 会按这个模型过滤/校验输出"""

    bmi: float
    label: str
    tip: str


@app.post("/bmi", response_model=BMIResponse)
async def calc_bmi_api(req: BMIRequest) -> BMIResponse:
    """POST /bmi  {"height": 1.75, "weight": 70}"""
    person = BMI(req.height, req.weight)   # 任务一的类
    label, tip = person.judge()            # 返回 (标签, 建议)
    return BMIResponse(bmi=round(person.value(), 2), label=label, tip=tip)


# ---------- ⑤ 健康检查：容器/负载均衡靠它判断服务活着 ----------
@app.get("/health")
async def health() -> dict[str, object]:
    """访问 /health 返回 ok —— 后面 Docker 健康检查会用到"""
    return {"status": "ok", "version": app.version}


# ---------- ⑥ 统一错误响应 ----------
@app.get("/error-demo/{code}")
async def error_demo(code: int) -> dict[str, str]:
    """主动抛 HTTPException，FastAPI 会自动转成 {"detail": "..."} + 对应状态码"""
    if code == 404:
        raise HTTPException(status_code=404, detail="你要找的东西不存在")
    if code == 500:
        raise HTTPException(status_code=500, detail="服务器内部错误（演示）")
    return {"message": "没有触发错误"}
