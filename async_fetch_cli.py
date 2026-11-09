"""异步并发请求多个 HTTP 接口并汇总结果（命令行版）。

用法：
    # 用默认的 3 个测试地址
    .venv\\Scripts\\python.exe async_fetch_cli.py

    # 指定地址（--url 可重复），每个地址请求 2 次
    .venv\\Scripts\\python.exe async_fetch_cli.py \\
        --url https://httpbin.org/delay/1 \\
        --url https://httpbin.org/delay/2 \\
        --repeat 2

    # 看全部参数
    .venv\\Scripts\\python.exe async_fetch_cli.py --help

环境变量（写在 .env 里，缺省值如下）：
    HTTP_TIMEOUT=10     单次请求超时秒数
    HTTP_REPEAT=1       每个地址重复请求次数
    LOG_LEVEL=INFO      日志级别（DEBUG / INFO / WARNING / ERROR）
"""
from __future__ import annotations

import argparse
import asyncio
import logging
import os
import sys
import time

import httpx
from dotenv import load_dotenv

DEFAULT_URLS: list[str] = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
]

logger = logging.getLogger("async_fetch_cli")


def parse_args() -> argparse.Namespace:
    """解析命令行参数；超时与重复次数的默认值来自环境变量。"""
    parser = argparse.ArgumentParser(
        description="异步并发请求多个 HTTP 接口，并汇总成功/失败与耗时",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "示例：\n"
            "  python async_fetch_cli.py\n"
            "  python async_fetch_cli.py -u https://httpbin.org/delay/1 -r 3\n"
            "  python async_fetch_cli.py --url https://a.com --url https://b.com -t 5 -v"
        ),
    )
    parser.add_argument(
        "-u", "--url", action="append", dest="urls", metavar="URL",
        help="要请求的地址，可重复指定；不传则使用 3 个默认测试地址",
    )
    parser.add_argument(
        "-t", "--timeout", type=float,
        default=float(os.getenv("HTTP_TIMEOUT", "10")),
        help="单次请求超时秒数（默认读 HTTP_TIMEOUT，缺省 10）",
    )
    parser.add_argument(
        "-r", "--repeat", type=int,
        default=int(os.getenv("HTTP_REPEAT", "1")),
        help="每个地址重复请求次数（默认读 HTTP_REPEAT，缺省 1）",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="输出调试日志（等价于 LOG_LEVEL=DEBUG）",
    )
    return parser.parse_args()


async def fetch(client: httpx.AsyncClient, url: str, timeout: float) -> tuple[int, float]:
    """请求一个地址，返回 (状态码, 耗时秒数)。

    状态码约定：-1 表示超时，-2 表示其他网络错误。
    """
    start = time.perf_counter()
    try:
        resp = await client.get(url, timeout=timeout)
        elapsed = time.perf_counter() - start
        logger.info("%s -> %d（%.2f 秒）", url, resp.status_code, elapsed)
        return resp.status_code, elapsed
    except httpx.TimeoutException:
        elapsed = time.perf_counter() - start
        logger.warning("%s 超时（%.2f 秒，timeout=%.1f）", url, elapsed, timeout)
        return -1, elapsed
    except httpx.HTTPError as exc:
        elapsed = time.perf_counter() - start
        logger.error("%s 请求失败：%s", url, exc)
        return -2, elapsed


def summarize(results: list[tuple[int, float]]) -> None:
    """汇总：成功/失败个数、总耗时、最慢一次。"""
    codes = [code for code, _ in results]
    ok = sum(1 for code in codes if code == 200)
    failed = len(codes) - ok
    timeout_count = sum(1 for code in codes if code == -1)
    slowest = max((elapsed for _, elapsed in results), default=0.0)

    logger.info(
        "汇总：共 %d 次请求，成功 %d，失败 %d（其中超时 %d），最慢一次 %.2f 秒",
        len(codes), ok, failed, timeout_count, slowest,
    )
    print("---- 结果汇总 ----")
    print(f"请求总数：{len(codes)}")
    print(f"成功：{ok}　失败：{failed}（超时 {timeout_count}）")
    print(f"最慢一次：{slowest:.2f} 秒")


async def run(urls: list[str], timeout: float, repeat: int) -> float:
    """并发跑完全部请求，返回总耗时秒数。"""
    targets = [url for url in urls for _ in range(repeat)]
    start = time.perf_counter()
    async with httpx.AsyncClient() as client:
        tasks = [fetch(client, url, timeout) for url in targets]
        results = await asyncio.gather(*tasks)
    total = time.perf_counter() - start
    summarize(results)
    return total


async def main() -> None:
    load_dotenv()                                  # 读取 .env（存在才生效）
    args = parse_args()

    level = logging.DEBUG if args.verbose else os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
        stream=sys.stdout,          # 走 stdout：PowerShell 不会把日志染成红色"错误"
    )
    logging.getLogger("httpx").setLevel(logging.WARNING)   # 压掉 httpx 自己的逐条日志

    urls = args.urls or DEFAULT_URLS
    logger.info(
        "开始：%d 个地址 × %d 次 = %d 个请求，timeout=%.1f 秒",
        len(urls), args.repeat, len(urls) * args.repeat, args.timeout,
    )

    total = await run(urls, args.timeout, args.repeat)
    logger.info("全部完成，总耗时 %.2f 秒", total)


if __name__ == "__main__":
    asyncio.run(main())
