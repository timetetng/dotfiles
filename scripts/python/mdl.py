# B站音乐下载
import requests
import sys
import os

# --- 配置 ---
# 音乐服务器
SERVER_URL = "http://10.8.0.2:8000"

def send_download_request(tasks):
    """
    核心请求函数：判断单任务还是多任务并发送
    """
    if not tasks:
        print("❌ 错误：任务列表为空")
        return

    try:
        if len(tasks) == 1:
            # 单任务：使用 /download 接口
            endpoint = f"{SERVER_URL}/download"
            params = {"q": tasks[0]}
            response = requests.post(endpoint, params=params, timeout=10)
        else:
            # 多任务：使用 /batch_download 接口
            endpoint = f"{SERVER_URL}/batch_download"
            payload = {"tasks": tasks}
            response = requests.post(endpoint, json=payload, timeout=10)

        if response.status_code == 202 or response.status_code == 200:
            data = response.json()
            print(f"✅ 已成功提交 {len(tasks)} 个任务到后端。")
            print(f"📩 后端消息: {data.get('message', '任务已加入队列')}")
        else:
            print(f"⚠️ 服务器返回异常 ({response.status_code}): {response.text}")

    except requests.exceptions.ConnectionError:
        print(f"❌ 无法连接到服务器 {SERVER_URL}，请检查网络或 Fedora IP 设置。")
    except Exception as e:
        print(f"❌ 发生意外错误: {e}")

def main():
    if len(sys.argv) < 2:
        print("用法示例:")
        print("  mdl '周杰伦 晴天'          # 下载单曲")
        print("  mdl BV1xxx BV2xxx        # 批量下载多个 BV 号")
        print("  mdl -f list.txt          # 从文件读取关键词批量下载")
        return

    if sys.argv[1] == "-f":
        # 处理文件读取
        if len(sys.argv) < 3:
            print("❌ 请指定文件名: mdl -f music_list.txt")
            return
        
        file_path = sys.argv[2]
        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {file_path}")
            return

        with open(file_path, 'r', encoding='utf-8') as f:
            tasks = [line.strip() for line in f if line.strip() and not line.startswith("#")]
            send_download_request(tasks)
    else:
        # 直接从命令行参数获取
        tasks = sys.argv[1:]
        send_download_request(tasks)

if __name__ == "__main__":
    main()
