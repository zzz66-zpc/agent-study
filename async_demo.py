import asyncio
import time
async def task(name: str, sec: float) -> str:
    """模拟一个耗时 sec 秒的请求"""
    await asyncio.sleep(sec)
    return f"{name}完成"
async def sequential() -> float:
    """串行：一个一个等"""
    start = time.perf_counter()
    for name in ("A", "B", "C"):
        await task(name, 1.0)
    return time.perf_counter() - start
async def concurrent() -> float:
    """并发：同时发起"""
    start = time.perf_counter()
    results = await asyncio.gather(
        task("A", 1.0),
        task("B", 1.0),
        task("C", 1.0),
    )
    print(f"结果：{results}")
    return time.perf_counter() - start
async def main() -> None:
    s = await sequential()
    c = await concurrent()
    print(f"串行耗时：{s:.2f} 秒")
    print(f"并发耗时：{c:.2f} 秒")
    print(f"快了约 {s / c:.1f} 倍")
if __name__ == "__main__":
    asyncio.run(main())
