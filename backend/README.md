# 译声原生 API

这是由 SilentRider 服务端派生的可选自托管版本，用于译声，不包含旧版网页、用户数据库或运行密钥。Python 3.10+，默认只监听 127.0.0.1:8818。应用的本地沟通和内置语音不依赖此服务。

在 backend 目录运行 `python3 server.py`；通过 `/api/health` 查看配置状态。公开服务应通过 HTTPS 反向代理；只在自己的反向代理正确转发客户端地址时启用 YLCT_TRUST_PROXY。关闭或脱敏代理的查询字符串访问日志：兼容接口的 TTS 查询包含用户输入的文字，天气查询可含位置。

- 自定义语音：在服务进程环境中设置 MIMO_API_KEY。MiMo 失败会返回错误，供客户端保留已生成的半对语音并重试，不用其他音色冒充成功。
- 天气：配置 AMAP_KEY。可选 OCR：使用本机 Tesseract（语言包 chi_sim、eng），或在服务环境设置 TENCENT_SECRET_ID、TENCENT_SECRET_KEY。请勿提交环境变量文件、截图或用户数据。
- 文件：使用 YLCT_DATA_DIR 指向源码目录之外的私有目录。该目录仅供服务进程读写，不应由 Web 服务公开。壁纸走单独的 /wallpapers/v2/ 路径，见 wallpaper/README.md。
- 测试：运行 `python3 -B -m unittest -v test_native`。使用临时数据库和模拟合成器，不调用真实上游。
