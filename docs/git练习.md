# Git 实战练习（30 分钟，6 个真实场景）

> 前提：`hello.py` 已提交、工作区干净。**每一步都有存档兜底，改坏了一定能退回。**
> 全部在 `C:\Users\25494\code\agent-study` 目录下做。
> 每个场景做的时候顺手截图，这些图就是任务一「能用 Git 完成提交、分支、推送」的证据。
>
> **练习前先记一个安全点**（练完觉得历史太乱可以退回这里）：
>
> ```powershell
> git log --oneline -1        # 把这一行的哈希抄到便签上
> ```
>
> 想恢复：`git reset --hard <那个哈希>`（会丢弃练习期间所有提交，执行前确认工作区干净）

---

## 场景 1｜改坏了，想一句话退回（最高频，30 秒）

**为什么**：这是 Git 最有价值的能力，比 `commit` 更值钱。

```powershell
# 1. 在 VS Code 里把 hello.py 第 3 行改成：
print("我把它改坏了")

# 2. 看 Git 发现了什么
git status
#    预期： M hello.py        （M = modified，改了但没提交）

# 3. 看具体改了什么（红色是删掉的行，绿色是新增的行）
git diff

# 4. 一句话退回上次提交的版本
git restore hello.py

# 5. 打开文件确认：第 3 行已经变回原样
git status
#    预期：nothing to commit, working tree clean
```

**原理**：`git restore <文件>` = 从"最近一次提交"里把文件取回来，丢弃你在工作区的所有改动。

---

## 场景 2｜改坏了，而且已经 `git add` 了

**为什么**：`add` 之后 `restore` 不管用，这是新手最容易卡住的地方。

```powershell
# 1. 再改坏第 3 行，然后放进暂存区
git add .

# 2. 看状态
git status
#    预期：Changes to be committed:  M hello.py   （已经进暂存区）

# 3. 只跑 git restore 是没用的，先把它从暂存区撤出来
git restore --staged hello.py

# 4. 再丢弃工作区的改动
git restore hello.py

git status
#    预期：clean
```

**原理**：`add` 是把改动放进"待提交区"。要撤销必须两步：先退出待提交区（`--staged`），再丢弃文件改动。

---

## 场景 3｜提交之后才发现写错了

**为什么**：三种情况三种解法，选错会把历史搞乱。

### 3a 只是提交说明写错了（最常见）

```powershell
# 改一下 hello.py 随便一处，然后提交，说明写成 "test"
git add .
git commit -m "test"

# 只改说明，不动内容
git commit --amend -m "hello.py：补充一行说明"
git log --oneline -1
#    预期：哈希变了，说明变成新的
```

### 3b 提交错了，想撤回这次提交但保留改动

```powershell
git reset --soft HEAD~1
git status
#    预期：改动又回到暂存区，文件内容没丢
```

### 3c 已经推送过的提交要撤销（安全做法）

```powershell
# 生成一个"反向提交"来抵消上次提交，历史完整保留
git revert HEAD --no-edit
git log --oneline -3
#    预期：多了一条 "Revert ..." 的提交
```

**原理**：
- `--amend` / `reset` 会**改写历史**，只能在还没推送时用
- `revert` 是**新增一条撤销提交**，适合已推送/多人协作
- 记住这句话：**没推送可以改写历史，推送了只能追加历史**

---

## 场景 4｜想看清楚"到底改了什么"

**为什么**：调试时定位问题靠这个，不靠猜。

```powershell
git diff                    # 工作区 vs 上次提交（还没 add 的改动）
git diff --staged           # 暂存区 vs 上次提交（已 add 但没 commit 的）
git log --oneline -5        # 最近 5 次提交
git show --stat HEAD        # 最近一次提交改了哪些文件、增删多少行
git log -p hello.py         # 只看 hello.py 这个文件的历史改动
```

---

## 场景 5｜怕弄坏主线？开个分支试（**关键体验**）

**为什么**：这一条能让你真正理解"分支"是什么，也是任务一的验收项之一。

```powershell
# 1. 新建并切换到一个分支
git switch -c try-branch
git branch
#    预期：* try-branch
#          main

# 2. 在分支上改 hello.py（随便加一句 print）
git add .
git commit -m "分支上试验：加一句结束语"

# 3. 切回主线 —— 注意看文件内容
git switch main
#    文件变回没有那句 print 的样子！这就是分支的意义

# 4. 切回分支，那句又出现了
git switch try-branch

# 5. 满意了就合并进主线
git switch main
git merge try-branch
git log --oneline -3

# 6. 删掉临时分支（历史已合并，删了不丢东西）
git branch -d try-branch
```

**原理**：分支就是一个"指向某次提交的指针"。切换分支，Git 会把文件换成那个指针指向的版本。所以你可以随便试，试坏了大不了切回 `main`。

---

## 场景 6｜推送到 GitHub（今晚做，需要先注册账号）

```powershell
# 1. 在 github.com 上新建一个空仓库，名字 agent-study，不要勾任何初始化文件
# 2. 把本地仓库连到远程
git remote add origin https://github.com/<你的用户名>/agent-study.git
git branch -M main
git push -u origin main

# 3. 推送一个分支（展示分支也能推）
git switch -c week1
git push -u origin week1
git switch main

# 4. 确认
git remote -v
git status -sb
```

**原理**：`origin` 只是"远程仓库地址"的别名。`push` = 把本地提交上传，`-u` = 记住这个对应关系，以后直接 `git push` 就行。

---

## 做完的自检

```powershell
git log --oneline -8        # 应能看到练习产生的提交
git branch                  # 只剩 main（临时分支已删）
git remote -v               # 场景 6 之后才有输出
git status                  # 应该是 clean
```

**掌握标准**：不看这份文档，能独立完成 场景 1、2、5，就算会用了。
