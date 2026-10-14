# 健康饮食助手 V1.5 — 手机云端构建工程

## 已实现
- 本地 SQLite 数据库
- 内置食物营养库（热量、蛋白质、碳水、脂肪）
- 搜索食物、按分类筛选
- 按餐次和克数记录饮食，并估算营养
- 首页今日热量与宏量营养素汇总
- 饮水记录
- 体重记录
- 今日营养报告
- GitHub Actions 云端构建 APK

## 手机上构建 APK
1. 下载 ZIP 并解压。
2. 在 GitHub 网站创建一个新仓库（建议命名 `HealthDietApp`）。
3. 进入仓库，选择 Add file → Upload files。
4. 上传解压后文件夹中的所有内容（包含隐藏的 `.github` 文件夹），不要只上传 ZIP。
5. 点击 Commit changes。
6. 打开仓库的 Actions 标签页，选择 `Build Android APK`，点击 `Run workflow`。
7. 等待绿色成功状态，进入该次运行详情页，在 Artifacts 中下载 `health-diet-v1.5-apk`。
8. 解压下载的 artifact ZIP，里面的 `app-release.apk` 即为安装包。

## 重要说明
- 此 ZIP 是 Flutter 源码工程，不是已经编译好的 APK。
- 工作流会在 GitHub 云端生成 Android 平台文件并尝试编译 APK。
- GitHub Actions 运行受账号、仓库权限和服务可用性限制；若失败，请把红色错误页面截图发给助手。
- 当前版本的热量目标是示例值；食物营养数据是估算值。
- 数据默认保存在本机 SQLite 数据库。卸载应用可能会删除本地数据；此版本没有云同步或自动备份。
- 当前没有真正的 AI 云端服务或食物照片识别功能；相应功能需要后续开发。
