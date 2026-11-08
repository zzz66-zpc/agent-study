# agent-study

红岩网校 · AI 开发与应用部 · Agent 方向 · **第一阶段（基础学习）学习仓库**

## 这个仓库是什么

记录第一阶段的完整学习过程：环境搭建 → Git → Python 基础（函数 / 类 / 异常 / 类型提示）→ 异步并发。

每一次学习都留下了三样东西：**能跑的代码**、**截图证据**、**踩坑笔记**——既方便自己复盘，也方便别人照着复现。

## 目录结构

```
agent-study/
├── hello.py              # 第一个程序：输入名字和心情，输出问候
├── bmi.py                # BMI 计算器（类封装版，含异常处理与类型提示）
├── async_demo.py         # 异步入门：串行 vs 并发（asyncio.sleep 模拟耗时）
├── async_fetch.py        # httpx 真实并发请求（三次网络请求）
├── requirements.txt      # 依赖清单
├── docs/
│   ├── git练习.md         # Git 六个场景的操作步骤（自己练手用）
│   ├── 学习日历.ics       # 12 周学习计划（可导入日历）
│   └── task01-env/       # 任务一材料：13 张截图 + 笔记 + 时间线复盘
└── tools/                # 自用脚本
    ├── 拍.ps1            # 一键截图（DPI 感知，2560×1600）
    ├── 取证.ps1          # 环境证据取证
    ├── 提交检查.ps1       # 提交前自检清单
    └── remind.ps1        # 每日提醒
```

## 快速开始

> 环境要求：Windows + Python 3.12 以上 + Git

```powershell
# 1. 拿到代码
git clone https://github.com/zzz66-zpc/agent-study.git
cd agent-study

# 2. 创建虚拟环境（只需一次）
py -3.12 -m venv .venv

# 3. 安装依赖
.venv\Scripts\python.exe -m pip install -r requirements.txt

# 4. 跑第一个程序
.venv\Scripts\python.exe bmi.py
```

输入 `1.75` 和 `70`，预期输出：

```
请输入身高（米）：1.75
请输入体重（公斤）：70
你的 BMI 是：22.86
判断:正常
建议:保持健康的方式。
```

**注意**：所有命令都用 `.venv\Scripts\python.exe`，不要直接敲 `python`——系统里可能装了多个 Python 版本，直接敲会装到别的地方。

## 各个脚本的作用

| 脚本 | 作用 | 运行命令 | 预期输出 |
|---|---|---|---|
| `hello.py` | 第一个程序：问名字和心情，输出问候 | `.venv\Scripts\python.exe hello.py` | 输入名字后打印问候语 |
| `bmi.py` | BMI 计算器（类封装版）：算 BMI、四档判断、给建议；空输入和零值会给出友好提示 | `.venv\Scripts\python.exe bmi.py` | `22.86 / 正常 / 保持健康的方式。` |
| `async_demo.py` | 异步入门：三个各 1 秒的任务，对比串行与并发（`asyncio.sleep` 模拟） | `.venv\Scripts\python.exe async_demo.py` | `串行 3.03 秒 / 并发 1.01 秒` |
| `async_fetch.py` | 真实并发请求：用 httpx 同时请求 3 个接口，含超时与网络异常处理 | `.venv\Scripts\python.exe async_fetch.py` | `串行 5.5 秒 / 并发 2.6 秒` |

## 环境要求

| 项 | 版本 |
|---|---|
| 操作系统 | Windows 11 |
| Python | 3.12.10（`>= 3.12`） |
| Git | 2.56.0 |
| 第三方依赖 | 见 `requirements.txt`（httpx 0.28.1 及其 5 个传递依赖） |

依赖安装：`.venv\Scripts\python.exe -m pip install -r requirements.txt`

## 学习记录

| 材料 | 位置 |
|---|---|
| 详细笔记（每天学了什么、踩了什么坑、收获） | `docs/task01-env/笔记.md` |
| 证据索引（13 张截图分别证明哪条验收标准） | `docs/task01-env/笔记.md` 第七节 |
| 时间线复盘 | `docs/task01-env/时间线复盘.md` |
| 截图目录 | `docs/task01-env/01-env-all.png` … `13-httpx.png` |

## 进度

- [x] 环境搭建：Python 3.12 + 虚拟环境 + Git
- [x] Git：提交 / 撤销 / 分支 / 推送
- [x] Python 基础：变量、条件、函数、类、异常、类型提示
- [x] 异步并发：`async/await`、`asyncio.gather`、httpx 真实请求
- [ ] README 与材料整理（进行中）
- [ ] 任务二：FastAPI + SSE
