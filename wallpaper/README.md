# 通用版城市壁纸

青岛、济南、上海、北京每天各发布 5 个场景。北京时间 04:00 换日；同一天的清单和文件不可变。图库使用有摄影者及来源记录的城市照片（Pexels、Wikimedia Commons），不是 Bing 官方首页图库。每张的作者、原作地址、许可、裁切和文件摘要保存在 library/<city>/catalog.json；App 的「壁纸设置 → 照片来源」可查阅当前照片。改编的 CC 图片沿用原许可。照片许可只适用于对应照片。

每个场景有 1242×2688 竖图和 1440×810 横图，从足够大的同一原片裁出；手机不从小图放大生成竖图。每天从本地素材库排除上一期的 ID 和近似图像指纹，再选出 5 个场景。只有四座城市的 40 个文件全部通过尺寸与摘要校验，才一次性公开当天目录。不足时返回缺图状态，客户端读内置青岛；不会以昨天的日期冒充今天。保留最近三个日期，供请求过渡。当日不依赖第三方图片服务。增加素材时将来源已核对的原片及 meta.json 放入 originals/<city>/<id>/（现有 catalog 包含元数据范例），运行 python3 prepare.py originals 重建完整 library；bundle_qingdao.py 单独管理随包五景。不要直接修改已经发布的派生文件。

## 安装到使用 systemd 与 Nginx 的 Ubuntu 后端

无需改动骑手版 Python 服务。在服务器上把本目录内容（包括 library）放到 /opt/ylct-wallpapers。首次安装以下操作需要服务器管理员权限：

    sudo apt-get install python3-pil
    getent passwd ylct-wallpapers >/dev/null || sudo useradd --system --user-group --no-create-home --shell /usr/sbin/nologin ylct-wallpapers
    cd /opt/ylct-wallpapers
    python3 test_pool.py
    sudo install -m 644 deploy/city-wallpapers.service deploy/city-wallpapers.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl start city-wallpapers.service
    sudo systemctl enable --now city-wallpapers.timer

把 deploy/nginx-location.conf 的两个 location 放入线上域名的 HTTPS server {}，或在该块 include /opt/ylct-wallpapers/deploy/nginx-location.conf; 然后 sudo nginx -t && sudo systemctl reload nginx。首次发布应先通过测试和手动启动，再打开客户端。若当天任务失败会自动重试；可用 journalctl -u city-wallpapers.service 查看原因。通过 systemctl list-timers city-wallpapers.timer 确认下次运行时间；机器关机错过执行时，启动后补发当期。

验收地址：/wallpapers/v2/<北京时间减4小时后的日期>/qingdao/index.json。另三个城市代号为 jinan、shanghai、beijing。每个 id 同目录对应 <id>-portrait.jpg 和 <id>-landscape.jpg。线上返回这批静态文件后，App 自动使用；未上线、离线、未知城市或收到错误文件时显示随包青岛。

## 本地验证

Python 3.9+ 与 Pillow。python3 test_pool.py 会用真实素材验证连续八个发布日、四城数量与尺寸、相邻日期无交集、重复运行、并发与失败时的完整性。也可使用 python3 pool.py --output /tmp/city-preview/wallpapers/v2，在 /tmp/city-preview 用 python3 -m http.server 临时预览。iOS 端仅用于开发联调的模拟器编译条件 WALLPAPER_INTEGRATION 会把后端指向 localhost:18746；常规与发布构建始终使用正式域名。
