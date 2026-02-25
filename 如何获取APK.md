# 不装 Flutter，直接拿到 APK 的步骤

用 GitHub 云端帮你把项目打成 APK，你在网页上下载即可。

## 1. 把项目推到 GitHub

1. 打开 [github.com](https://github.com) 并登录。
2. 右上角点 **+** → **New repository**，仓库名随便（例如 `ai-recorder`），**不要**勾选 “Add a README”，点 **Create repository**。
3. 在本机打开**终端**，执行（把 `你的用户名` 和 `ai-recorder` 换成你的仓库信息）：

```bash
cd /Users/mi/LUYINJI
git init
git add .
git commit -m "init"
git branch -M main
git remote add origin https://github.com/你的用户名/ai-recorder.git
git push -u origin main
```

如果提示要登录 GitHub，按提示用浏览器或 Personal Access Token 完成认证。

## 2. 在 GitHub 上构建并下载 APK

1. 打开你的仓库页面，点顶部的 **Actions**。
2. 左侧点 **Build APK**，右侧点 **Run workflow** → 再点绿色的 **Run workflow**。
3. 等几分钟，列表里会出现一条正在跑或已完成的记录，点进去。
4. 跑完后页面下方会出现 **Artifacts**，点 **app-debug-apk** 即可下载到本机。

下载下来的 zip 里就是 **app-debug.apk**，解压后传到手机安装即可。
