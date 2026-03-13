import requests
import sys
import os

SERVER_URL = "http://10.0.0.2:8000"

def interactive_select(keyword):
    current_page = 1
    while True:
        try:
            # 使用 params 传参，对应后端的 @app.get("/search")
            resp = requests.get(f"{SERVER_URL}/search", params={"q": keyword, "p": current_page}, timeout=10)
            
            # --- 新增：HTTP 状态码校验，方便排错 ---
            if resp.status_code != 200:
                print(f"\n❌ 服务器返回错误状态码: {resp.status_code}")
                print(f"详情: {resp.text}")
                break
            # ------------------------------------
            
            data = resp.json()
            results = data.get("results", [])

            if not results:
                print("\n   --- 🏜️ 没有更多结果了 ---")
                input("按回车返回上一页...")
                current_page = max(1, current_page - 1)
                continue

            os.system('clear' if os.name == 'posix' else 'cls')
            print(f"🔍 搜索: \033[1;34m{keyword}\033[0m (第 {current_page} 页)")
            print("=" * 60)
            
            for i, item in enumerate(results, 1):
                p_count = item['play']
                p_str = f"{p_count/10000:.1f}万" if isinstance(p_count, int) and p_count >= 10000 else p_count
                print(f" \033[1;32m[{i}]\033[0m {item['title'][:50]}")
                print(f"    📊 播放: {p_str}  |  👤 UP: {item['author']}  |  ⏱️ {item['duration']}")
            
            print("=" * 60)
            print(" \033[1;36m[n]\033[0m 下一页  |  \033[1;33m[p]\033[0m 上一页  |  \033[1;31m[q]\033[0m 退出")

            user_input = input(f"\n选择序号 (1-{len(results)}) 或输入指令: ").strip().lower()

            if user_input == 'n':
                current_page += 1
            elif user_input == 'p':
                current_page = max(1, current_page - 1)
            elif user_input == 'q':
                sys.exit(0)
            elif user_input.isdigit():
                idx = int(user_input) - 1
                if 0 <= idx < len(results):
                    return results[idx]['url']
            elif user_input == "" and current_page == 1:
                return results[0]['url']
        except Exception as e:
            print(f"❌ 交互异常: {e}")
            break

def send_download(q_list):
    """
    统一发送下载请求
    """
    try:
        if len(q_list) == 1:
            # 单任务，必须用 params 传 q
            requests.post(f"{SERVER_URL}/download", params={"q": q_list[0]}, timeout=5)
        else:
            # 批量任务，用 json 传 tasks
            requests.post(f"{SERVER_URL}/batch_download", json={"tasks": q_list}, timeout=5)
        print("🚀 任务已提交至后端队列")
    except Exception as e:
        print(f"❌ 提交失败: {e}")

def main():
    # 获取所有命令行参数
    args = sys.argv[1:]
    
    # 如果没有参数，打印帮助信息
    if not args:
        print("\033[1;34m--- B站音乐下载助手 ---\033[0m")
        print("用法示例:")
        print("  mdl '歌名'             # 直接下载搜索最热的结果")
        print("  mdl -s '歌名'          # 进入交互模式，支持翻页选择")
        print("  mdl BV1xxx [BV2xxx]    # 直接下载一个或多个 BV 号")
        print("  mdl -f list.txt        # 从文件批量读取关键词/URL下载")
        return

    # 场景 1: 交互式搜索模式 (-s)
    if args[0] == "-s":
        if len(args) < 2:
            print("❌ 错误: -s 模式需要输入关键词 (例如: mdl -s '周杰伦')")
            return
        # 将后面的所有参数拼接成一个搜索关键词
        keyword = " ".join(args[1:])
        target_url = interactive_select(keyword)
        if target_url:
            send_download([target_url])

    # 场景 2: 从文件批量读取模式 (-f)
    elif args[0] == "-f":
        if len(args) < 2:
            print("❌ 错误: 请指定文件名 (例如: mdl -f music.txt)")
            return
        
        file_path = args[1]
        if not os.path.exists(file_path):
            print(f"❌ 错误: 找不到文件 '{file_path}'")
            return

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                # 读取非空行，并过滤掉以 # 开头的注释行
                tasks = [line.strip() for line in f if line.strip() and not line.startswith("#")]
            
            if not tasks:
                print("⚠️ 提示: 文件为空，没有可下载的任务。")
                return
            
            print(f"读取到 {len(tasks)} 个任务，正在提交...")
            send_download(tasks)
        except Exception as e:
            print(f"❌ 读取文件失败: {e}")

    # 场景 3: 默认模式 (直接下载关键词或批量 BV 号)
    else:
        # 如果是多个参数 (例如 mdl BV1 BV2)，args 本身就是列表
        # 如果是一个关键词 (例如 mdl 晴天)，args 就是 ['晴天']
        # 统一交给 send_download 处理
        send_download(args)

if __name__ == "__main__":
    main()
