import asyncio
import time

import httpx

URLS = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
]


async def fetch(client: httpx.AsyncClient, url: str) -> int:
    """请求一个地址，返回状态码；失败返回 -1（超时）或 -2（其他网络错误）"""
    try:
        resp = await client.get(url, timeout=10.0)
        return resp.status_code
    except httpx.TimeoutException:
        return -1
    except httpx.HTTPError:
        return -2


async def serial() -> float:
    """串行：一个一个等"""
    start = time.perf_counter()
    async with httpx.AsyncClient() as client:
        for url in URLS:
            code = await fetch(client, url)
            print(f"  状态码 {code}")
    return time.perf_counter() - start


async def concurrent() -> float:
    """并发：同时发起"""
    start = time.perf_counter()
    async with httpx.AsyncClient() as client:
        tasks = [fetch(client, url) for url in URLS]
        results = await asyncio.gather(*tasks)
        print(f"  状态码 {results}")
    return time.perf_counter() - start


async def main() -> None:
    print("串行开始…")
    s = await serial()
    print("并发开始…")
    c = await concurrent()
    print(f"串行耗时：{s:.2f} 秒")
    print(f"并发耗时：{c:.2f} 秒")
    print(f"快了约 {s / c:.1f} 倍")


if __name__ == "__main__":
    asyncio.run(main())
