import os, sys, json, time, threading, queue, shutil, random
from datetime import datetime
import tkinter as tk
from tkinter import filedialog, messagebox
import customtkinter as ctk

import changer
from config import BASE_DIR, AVATAR_DIR, DATA_FILE

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

CONFIG_FILE = os.path.join(BASE_DIR, "config.json")

DEFAULT_CONFIG = {
    "threads": 3,
    "delay_min": 10,
    "delay_max": 25,
    "switch_sleep": 5,
    "do_avatar": True,
    "do_name": True,
    "gender": "random",
    "use_proxy": True,
    "headless": False,
}


class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Tudzhub AutoChange Avatar + Name")
        self.geometry("1200x740")
        self.minsize(1100, 700)

        self.cfg = self._load_config()
        self.accounts = self._load_accounts()
        self.avatars = []
        self.running = False
        self.stop_flag = False
        self.log_queue = queue.Queue()

        self._build_ui()
        self._scan_avatars()
        self._refresh_acc_list()
        self._drain_log()

    def _load_config(self):
        if os.path.exists(CONFIG_FILE):
            try:
                c = json.load(open(CONFIG_FILE, encoding="utf-8"))
                for k, v in DEFAULT_CONFIG.items():
                    c.setdefault(k, v)
                return c
            except:
                pass
        return dict(DEFAULT_CONFIG)

    def _save_config(self):
        try:
            json.dump(self.cfg, open(CONFIG_FILE, "w", encoding="utf-8"),
                      ensure_ascii=False, indent=2)
        except:
            pass

    def _load_accounts(self):
        if os.path.exists(DATA_FILE):
            try:
                d = json.load(open(DATA_FILE, encoding="utf-8"))
                return d if isinstance(d, list) else []
            except:
                pass
        return []

    def _save_accounts(self):
        try:
            json.dump(self.accounts, open(DATA_FILE, "w", encoding="utf-8"),
                      ensure_ascii=False, indent=2)
        except:
            pass

    def _build_ui(self):
        header = ctk.CTkFrame(self, height=70, corner_radius=0, fg_color="#0d1326")
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="TUDZHUB AUTOCANGE AVATAR + NAME",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color="#7dd3fc").pack(side="left", padx=20)
        self.status_dot = ctk.CTkLabel(header, text="●  SẴN SÀNG",
                                       font=ctk.CTkFont(size=14, weight="bold"),
                                       text_color="#22c55e")
        self.status_dot.pack(side="right", padx=20)

        body = ctk.CTkFrame(self, fg_color="transparent")
        body.pack(fill="both", expand=True, padx=12, pady=10)

        left = ctk.CTkScrollableFrame(body, width=400, corner_radius=12)
        left.pack(side="left", fill="both", padx=(0, 8))
        self._build_left(left)

        right = ctk.CTkFrame(body, corner_radius=12)
        right.pack(side="left", fill="both", expand=True)
        self._build_right(right)

    def _build_left(self, parent):
        ctk.CTkLabel(parent, text="TÀI KHOẢN", font=ctk.CTkFont(size=14, weight="bold"),
                     text_color="#93c5fd").pack(anchor="w", padx=14, pady=(10, 4))
        self.lbl_acc = ctk.CTkLabel(parent, text="0 acc",
                                    font=ctk.CTkFont(size=12), text_color="#a0a8c0")
        self.lbl_acc.pack(anchor="w", padx=14)
        row1 = ctk.CTkFrame(parent, fg_color="transparent")
        row1.pack(fill="x", padx=14, pady=6)
        ctk.CTkButton(row1, text="Thêm acc", height=32, width=120,
                      command=self._add_acc).pack(side="left", padx=(0, 4))
        ctk.CTkButton(row1, text="Xoá hết acc", height=32, width=120,
                      command=self._clear_acc).pack(side="left")

        self.acc_list = ctk.CTkTextbox(parent, height=140,
                                       font=ctk.CTkFont(family="Consolas", size=11))
        self.acc_list.pack(fill="x", padx=14, pady=4)
        self.acc_list.configure(state="disabled")

        ctk.CTkLabel(parent, text="AVATAR", font=ctk.CTkFont(size=14, weight="bold"),
                     text_color="#93c5fd").pack(anchor="w", padx=14, pady=(14, 4))
        self.lbl_avt = ctk.CTkLabel(parent, text="0 ảnh",
                                    font=ctk.CTkFont(size=12), text_color="#a0a8c0")
        self.lbl_avt.pack(anchor="w", padx=14)
        row2 = ctk.CTkFrame(parent, fg_color="transparent")
        row2.pack(fill="x", padx=14, pady=6)
        ctk.CTkButton(row2, text="Thêm ảnh", height=32, width=120,
                      command=self._add_avatars).pack(side="left", padx=(0, 4))
        ctk.CTkButton(row2, text="Xoá ảnh", height=32, width=120,
                      command=self._clear_avatars).pack(side="left")

        ctk.CTkLabel(parent, text="PROXY", font=ctk.CTkFont(size=14, weight="bold"),
                     text_color="#93c5fd").pack(anchor="w", padx=14, pady=(14, 4))
        self.sw_proxy = ctk.CTkSwitch(parent, text="Dùng proxy từng acc",
                                      command=self._toggle_proxy)
        self.sw_proxy.pack(anchor="w", padx=14, pady=4)
        if self.cfg["use_proxy"]:
            self.sw_proxy.select()
        ctk.CTkLabel(parent, text="Format: ip:port:user:pass",
                     font=ctk.CTkFont(size=11), text_color="#6b7280").pack(anchor="w", padx=14)

        ctk.CTkLabel(parent, text="CẤU HÌNH", font=ctk.CTkFont(size=14, weight="bold"),
                     text_color="#93c5fd").pack(anchor="w", padx=14, pady=(14, 4))
        self._entry_row(parent, "Số luồng:", "threads")
        self._entry_row(parent, "Delay min:", "delay_min")
        self._entry_row(parent, "Delay max:", "delay_max")
        self._entry_row(parent, "Nghỉ giữa acc:", "switch_sleep")

        ctk.CTkLabel(parent, text="HÀNH VI", font=ctk.CTkFont(size=14, weight="bold"),
                     text_color="#93c5fd").pack(anchor="w", padx=14, pady=(14, 4))
        self.sw_avt = ctk.CTkSwitch(parent, text="Đổi avatar")
        self.sw_avt.pack(anchor="w", padx=14, pady=2)
        if self.cfg["do_avatar"]:
            self.sw_avt.select()
        self.sw_name = ctk.CTkSwitch(parent, text="Đổi tên")
        self.sw_name.pack(anchor="w", padx=14, pady=2)
        if self.cfg["do_name"]:
            self.sw_name.select()

        row3 = ctk.CTkFrame(parent, fg_color="transparent")
        row3.pack(fill="x", padx=14, pady=6)
        ctk.CTkLabel(row3, text="Giới tính:").pack(side="left")
        self.cmb_gender = ctk.CTkOptionMenu(row3, values=["random", "nam", "nu"], width=110)
        self.cmb_gender.set(self.cfg["gender"])
        self.cmb_gender.pack(side="right")

        self.sw_headless = ctk.CTkSwitch(parent, text="Chạy ẩn")
        self.sw_headless.pack(anchor="w", padx=14, pady=2)
        if self.cfg["headless"]:
            self.sw_headless.select()

    def _entry_row(self, parent, label, key):
        row = ctk.CTkFrame(parent, fg_color="transparent")
        row.pack(fill="x", padx=14, pady=3)
        ctk.CTkLabel(row, text=label, font=ctk.CTkFont(size=12)).pack(side="left")
        e = ctk.CTkEntry(row, width=80, justify="right")
        e.insert(0, str(self.cfg.get(key, "")))
        e.pack(side="right")
        setattr(self, f"entry_{key}", e)

    def _build_right(self, parent):
        ctrl = ctk.CTkFrame(parent, height=60, corner_radius=10)
        ctrl.pack(fill="x", padx=12, pady=(12, 6))
        ctrl.pack_propagate(False)
        self.btn_start = ctk.CTkButton(ctrl, text="BẮT ĐẦU",
                                       font=ctk.CTkFont(size=14, weight="bold"),
                                       fg_color="#16a34a", hover_color="#15803d",
                                       height=40, width=140, command=self._start)
        self.btn_start.pack(side="left", padx=10, pady=10)
        self.btn_stop = ctk.CTkButton(ctrl, text="DỪNG",
                                      font=ctk.CTkFont(size=14, weight="bold"),
                                      fg_color="#dc2626", hover_color="#b91c1c",
                                      height=40, width=100, command=self._stop)
        self.btn_stop.pack(side="left", padx=4, pady=10)
        self.btn_stop.configure(state="disabled")
        ctk.CTkButton(ctrl, text="Xoá log", height=40, width=100,
                      command=self._clear_log).pack(side="left", padx=4, pady=10)

        prog = ctk.CTkFrame(parent, corner_radius=10)
        prog.pack(fill="x", padx=12, pady=6)
        self.lbl_progress = ctk.CTkLabel(prog, text="Tiến trình: 0 / 0",
                                         font=ctk.CTkFont(size=13, weight="bold"))
        self.lbl_progress.pack(anchor="w", padx=14, pady=(10, 4))
        self.progress = ctk.CTkProgressBar(prog, height=14)
        self.progress.pack(fill="x", padx=14, pady=(0, 12))
        self.progress.set(0)

        ctk.CTkLabel(parent, text="LOG REALTIME",
                     font=ctk.CTkFont(size=13, weight="bold"),
                     text_color="#93c5fd").pack(anchor="w", padx=14, pady=(6, 2))
        self.txt_log = ctk.CTkTextbox(parent, font=ctk.CTkFont(family="Consolas", size=12))
        self.txt_log.pack(fill="both", expand=True, padx=12, pady=(0, 12))
        self.txt_log.configure(state="disabled")

    def _log(self, msg, tag="info"):
        self.log_queue.put(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

    def _drain_log(self):
        while not self.log_queue.empty():
            line = self.log_queue.get()
            self.txt_log.configure(state="normal")
            self.txt_log.insert("end", line + "\n")
            self.txt_log.see("end")
            self.txt_log.configure(state="disabled")
        self.after(200, self._drain_log)

    def _refresh_acc_list(self):
        self.lbl_acc.configure(text=f"{len(self.accounts)} acc")
        self.acc_list.configure(state="normal")
        self.acc_list.delete("1.0", "end")
        for i, a in enumerate(self.accounts, 1):
            self.acc_list.insert("end", f"{i}. {a.get('uid','?')}\n")
        self.acc_list.configure(state="disabled")

    def _scan_avatars(self):
        imgs = [f for f in os.listdir(AVATAR_DIR)
                if f.lower().endswith((".jpg", ".png", ".jpeg", ".webp"))]
        self.avatars = [os.path.join(AVATAR_DIR, f) for f in imgs]
        self.lbl_avt.configure(text=f"{len(imgs)} ảnh")

    def _add_acc(self):
        win = ctk.CTkToplevel(self)
        win.title("Thêm tài khoản")
        win.geometry("560x540")
        win.transient(self)
        win.grab_set()

        ctk.CTkLabel(win, text="Thêm tài khoản Facebook",
                     font=ctk.CTkFont(size=16, weight="bold")).pack(pady=10)

        box = ctk.CTkTextbox(win, height=320, font=ctk.CTkFont(family="Consolas", size=12))
        box.pack(fill="x", padx=14, pady=6)

        ctk.CTkLabel(win,
                     text="Mỗi dòng 1 acc. Format:\n"
                          "uid|password|twofa|proxy|user_agent\n\n"
                          "Ví dụ:\n"
                          "1000123456789|matkhau123||1.2.3.4:8000:user:pass|\n"
                          "email@gmail.com|pass456|||",
                     justify="left", font=ctk.CTkFont(size=11),
                     text_color="#a0a8c0").pack(padx=14, anchor="w")

        def _save():
            text = box.get("1.0", "end").strip()
            lines = [l.strip() for l in text.splitlines() if l.strip() and not l.startswith("#")]
            added = 0
            for line in lines:
                if line.lower().startswith("uid"):
                    continue
                parts = [p.strip() for p in line.split("|")]
                if len(parts) < 2 or not parts[0] or not parts[1]:
                    continue
                acc = {
                    "uid": parts[0],
                    "password": parts[1],
                    "twofa": parts[2] if len(parts) > 2 else "",
                    "proxy": parts[3] if len(parts) > 3 else "",
                    "user_agent": parts[4] if len(parts) > 4 else "",
                }
                self.accounts.append(acc)
                added += 1
            self._save_accounts()
            self._refresh_acc_list()
            self._log(f"Đã thêm {added} acc")
            win.destroy()

        ctk.CTkButton(win, text="LƯU", height=40,
                      command=_save).pack(pady=12, padx=14, fill="x")

    def _clear_acc(self):
        if not messagebox.askyesno("Xác nhận", "Xoá hết danh sách acc?"):
            return
        self.accounts = []
        self._save_accounts()
        self._refresh_acc_list()
        self._log("Đã xoá hết acc")

    def _add_avatars(self):
        files = filedialog.askopenfilenames(title="Chọn ảnh avatar",
                                            filetypes=[("Image", "*.jpg *.jpeg *.png *.webp")])
        if not files:
            return
        for f in files:
            try:
                shutil.copy(f, os.path.join(AVATAR_DIR, os.path.basename(f)))
            except:
                pass
        self._scan_avatars()
        self._log(f"Đã thêm {len(files)} ảnh")

    def _clear_avatars(self):
        if not messagebox.askyesno("Xác nhận", "Xoá hết ảnh trong avatars/?"):
            return
        for f in os.listdir(AVATAR_DIR):
            try:
                os.remove(os.path.join(AVATAR_DIR, f))
            except:
                pass
        self._scan_avatars()
        self._log("Đã xoá hết ảnh")

    def _toggle_proxy(self):
        self.cfg["use_proxy"] = bool(self.sw_proxy.get())
        self._save_config()

    def _collect_cfg(self):
        def _f(e, d):
            try:
                return float(e.get())
            except:
                return d

        def _i(e, d):
            try:
                return int(e.get())
            except:
                return d

        self.cfg["threads"] = _i(self.entry_threads, 3)
        self.cfg["delay_min"] = _f(self.entry_delay_min, 10)
        self.cfg["delay_max"] = _f(self.entry_delay_max, 25)
        self.cfg["switch_sleep"] = _f(self.entry_switch_sleep, 5)
        self.cfg["do_avatar"] = bool(self.sw_avt.get())
        self.cfg["do_name"] = bool(self.sw_name.get())
        self.cfg["gender"] = self.cmb_gender.get()
        self.cfg["headless"] = bool(self.sw_headless.get())
        self.cfg["use_proxy"] = bool(self.sw_proxy.get())
        self._save_config()

    def _clear_log(self):
        self.txt_log.configure(state="normal")
        self.txt_log.delete("1.0", "end")
        self.txt_log.configure(state="disabled")

    def _set_running(self, r):
        self.running = r
        if r:
            self.btn_start.configure(state="disabled")
            self.btn_stop.configure(state="normal")
            self.status_dot.configure(text="●  ĐANG CHẠY", text_color="#f59e0b")
        else:
            self.btn_start.configure(state="normal")
            self.btn_stop.configure(state="disabled")
            self.status_dot.configure(text="●  SẴN SÀNG", text_color="#22c55e")

    def _start(self):
        if self.running:
            return
        self._collect_cfg()
        if not self.accounts:
            messagebox.showwarning("Thiếu acc", "Chưa có acc nào")
            return
        if not self.cfg["do_avatar"] and not self.cfg["do_name"]:
            messagebox.showwarning("Thiếu hành vi", "Bật ít nhất 1 hành vi")
            return
        if self.cfg["do_avatar"] and not self.avatars:
            messagebox.showwarning("Thiếu ảnh", "avatars/ trống")
            return

        self.stop_flag = False
        self._set_running(True)
        self._clear_log()

        n_threads = max(1, min(int(self.cfg["threads"]), 50))
        self._log(f"BẮT ĐẦU: {len(self.accounts)} acc, {n_threads} luồng")
        self._log(f"Delay mỗi luồng: {self.cfg['delay_min']}s - {self.cfg['delay_max']}s")

        threading.Thread(target=self._run_worker, args=(n_threads,), daemon=True).start()

    def _stop(self):
        self.stop_flag = True
        self._log("Đang dừng... chờ acc hiện tại xong")

    def _run_worker(self, n_threads):
        acc_queue = queue.Queue()
        for acc in self.accounts:
            acc_queue.put(acc)

        total = len(self.accounts)
        done_lock = threading.Lock()
        progress = {"done": 0, "ok": 0, "fail": 0}

        def _do(acc, worker_id):
            if self.stop_flag:
                return
            uid = acc.get("uid", "?")
            self._log(f"[Luồng {worker_id}] Bắt đầu acc {uid}")
            try:
                changer.process_account(acc, self.cfg, self._log, lambda: self.stop_flag)
                with done_lock:
                    progress["ok"] += 1
                self._log(f"[Luồng {worker_id}] Xong acc {uid}", "ok")
            except Exception as e:
                with done_lock:
                    progress["fail"] += 1
                self._log(f"[Luồng {worker_id}] Lỗi acc {uid}: {str(e)[:80]}", "err")
            finally:
                with done_lock:
                    progress["done"] += 1
                    d = progress["done"]
                    o = progress["ok"]
                    f = progress["fail"]
                self.after(0, lambda: self._update_progress(d, total, o, f))

        def _worker(worker_id):
            while True:
                if self.stop_flag:
                    return
                try:
                    acc = acc_queue.get_nowait()
                except queue.Empty:
                    return
                try:
                    _do(acc, worker_id)
                finally:
                    acc_queue.task_done()
                if self.stop_flag:
                    return
                sleep_time = random.uniform(self.cfg["delay_min"], self.cfg["delay_max"])
                self._log(f"[Luồng {worker_id}] Nghỉ {sleep_time:.1f}s")
                end = time.time() + sleep_time
                while time.time() < end:
                    if self.stop_flag:
                        return
                    time.sleep(0.3)

        threads = []
        for i in range(1, n_threads + 1):
            t = threading.Thread(target=_worker, args=(i,), daemon=True)
            t.start()
            threads.append(t)
            time.sleep(0.5)

        for t in threads:
            t.join()

        self._log(f"HOÀN TẤT: OK {progress['ok']} / Lỗi {progress['fail']} / Tổng {total}")
        self.after(0, lambda: self._set_running(False))

    def _update_progress(self, d, t, o, f):
        self.lbl_progress.configure(text=f"Tiến trình: {d}/{t}  |  OK: {o}  |  Lỗi: {f}")
        self.progress.set(d / max(1, t))


if __name__ == "__main__":
    app = App()
    app.mainloop()
