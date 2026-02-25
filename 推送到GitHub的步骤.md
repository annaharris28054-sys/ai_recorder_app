# 把代码推送到 GitHub

本地已经完成：`git init`、`git add .`、`git commit`，当前在 `main` 分支。

## 你只需做两步

### 1. 在 GitHub 上新建仓库

1. 打开 https://github.com/new
2. **Repository name** 随便填（例如 `ai-recorder`）
3. 选 **Public**
4. **不要**勾选 "Add a README file"
5. 点 **Create repository**

### 2. 在终端执行（把链接换成你自己的仓库地址）

在终端里执行（替换成你的用户名和仓库名）：

```bash
cd /Users/mi/LUYINJI
git remote add origin https://github.com/你的用户名/你的仓库名.git
git push -u origin main
```

例如仓库是 `https://github.com/zhangsan/ai-recorder`，就执行：

```bash
cd /Users/mi/LUYINJI
git remote add origin https://github.com/zhangsan/ai-recorder.git
git push -u origin main
```

若提示登录，按页面提示用浏览器或 Personal Access Token 完成认证。

---

推送成功后，打开仓库 → **Actions** → 左侧选 **Build APK** → **Run workflow** → 跑完后在 **Artifacts** 里下载 **app-debug-apk** 即得到 APK。
