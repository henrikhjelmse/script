# --- Mouse click section ---
mouse_click_active = False
mouse_click_type = 'left'
mouse_click_delay = 0.1
mouse_click_mode = 'timer'  # 'timer' eller 'move'
last_mouse_click_time = 0

def do_mouse_click():
    btn = {'left': mouse.Button.left, 'right': mouse.Button.right, 'middle': mouse.Button.middle}.get(mouse_click_type, mouse.Button.left)
    try:
        mouse.Controller().press(btn)
        mouse.Controller().release(btn)
        update_status(f"Mus-klick: {mouse_click_type}")
    except Exception as e:
        print(f"Fel vid musklick: {e}")
        update_status(f"Fel vid musklick: {e}")

def mouse_click_on_move(x, y):
    global last_pos, mouse_click_active, last_mouse_click_time, mouse_click_delay, mouse_click_mode
    if mouse_click_active and mouse_click_mode == 'move':
        now = time.time()
        if last_pos != (x, y) and (now - last_mouse_click_time) >= mouse_click_delay:
            do_mouse_click()
            last_pos = (x, y)
            last_mouse_click_time = now

def mouse_click_on_timer():
    global mouse_click_active, last_mouse_click_time, mouse_click_delay, mouse_click_mode
    while True:
        if mouse_click_active and mouse_click_mode == 'timer':
            now = time.time()
            if (now - last_mouse_click_time) >= mouse_click_delay:
                do_mouse_click()
                last_mouse_click_time = now
        time.sleep(0.01)

def start_mouse_click():
    global mouse_click_active
    mouse_click_active = True
    print("Mus-klick ON")
    update_status("Mus-klick ON")

def stop_mouse_click():
    global mouse_click_active
    mouse_click_active = False
    print("Mus-klick OFF")
    update_status("Mus-klick OFF")

def on_mouse_click_type(event):
    global mouse_click_type
    mouse_click_type = mouse_click_type_var.get()

def on_mouse_click_delay_change(event):
    global mouse_click_delay
    try:
        mouse_click_delay = float(mouse_click_delay_var.get())
    except ValueError:
        mouse_click_delay = 0.1

def on_mouse_click_mode_change():
    global mouse_click_mode
    mouse_click_mode = mouse_click_mode_var.get()
import threading
import time
import os
from pynput import mouse, keyboard
import tkinter as tk
from tkinter import ttk

# Global state
active = False
last_pos = None
last_click_time = 0
listener_thread = None
selected_key = 'space'
delay = 0.1
mouse_required = True

kb_controller = keyboard.Controller()

key_map = {
    'space': keyboard.Key.space,
    'enter': keyboard.Key.enter,
    'tab': keyboard.Key.tab,
    'esc': keyboard.Key.esc,
    'up': keyboard.Key.up,
    'down': keyboard.Key.down,
    'left': keyboard.Key.left,
    'right': keyboard.Key.right,
    'f1': keyboard.Key.f1,
    'f2': keyboard.Key.f2,
    'f3': keyboard.Key.f3,
    'f4': keyboard.Key.f4,
    'f5': keyboard.Key.f5,
    'f6': keyboard.Key.f6,
    'f7': keyboard.Key.f7,
    'f8': keyboard.Key.f8,
    'f9': keyboard.Key.f9,
    'f10': keyboard.Key.f10,
    'f11': keyboard.Key.f11,
    'f12': keyboard.Key.f12,
    'a': 'a', 'b': 'b', 'c': 'c', 'd': 'd', 'e': 'e', 'f': 'f', 'g': 'g', 'h': 'h', 'i': 'i', 'j': 'j', 'k': 'k', 'l': 'l', 'm': 'm', 'n': 'n', 'o': 'o', 'p': 'p', 'q': 'q', 'r': 'r', 's': 's', 't': 't', 'u': 'u', 'v': 'v', 'w': 'w', 'x': 'x', 'y': 'y', 'z': 'z',
    '0': '0', '1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
}

# Modifierare
modifier_keys = {
    '': None,
    'ctrl': keyboard.Key.ctrl,
    'alt': keyboard.Key.alt,
    'shift': keyboard.Key.shift,
    'cmd/win': keyboard.Key.cmd if hasattr(keyboard.Key, 'cmd') else keyboard.Key.cmd_l,
}
selected_modifier = ''

def autoclick_on_move(x, y):
    global last_pos, active, last_click_time, delay, selected_key, mouse_required
    if active and mouse_required:
        now = time.time()
        if last_pos != (x, y) and (now - last_click_time) >= delay:
            send_key()
            last_pos = (x, y)
            last_click_time = now

def autoclick_on_timer():
    global active, last_click_time, delay, selected_key, mouse_required
    while True:
        if active and not mouse_required:
            now = time.time()
            if (now - last_click_time) >= delay:
                send_key()
                last_click_time = now
        time.sleep(0.01)

def send_key():
    key = key_map.get(selected_key, keyboard.Key.space)
    mod = modifier_keys.get(selected_modifier, None)
    try:
        if mod:
            kb_controller.press(mod)
        kb_controller.press(key)
        kb_controller.release(key)
        if mod:
            kb_controller.release(mod)
        update_status(f"Tryckte: {selected_modifier + '+' if selected_modifier else ''}{selected_key}")
    except Exception as e:
        print(f"Fel vid tangenttryck: {e}")
        update_status(f"Fel vid tangenttryck: {e}")

def on_press(key):
    global active, mouse_click_active
    if key == keyboard.Key.f6:
        active = not active
        print(f"Autoclick {'ON' if active else 'OFF'}")
        update_status(f"Tangent {'ON' if active else 'OFF'} (F6)")
    elif key == keyboard.Key.f7:
        mouse_click_active = not mouse_click_active
        print(f"Mus-klick {'ON' if mouse_click_active else 'OFF'}")
        update_status(f"Mus-klick {'ON' if mouse_click_active else 'OFF'} (F7)")
    elif key == keyboard.Key.f8:
        print("Avslutar scriptet...")
        update_status("Avslutar...")
        root.after(500, lambda: os._exit(0))

def start_listeners():
    mouse_listener = mouse.Listener(
        on_move=lambda x, y: [autoclick_on_move(x, y), mouse_click_on_move(x, y)])
    keyboard_listener = keyboard.Listener(on_press=on_press)
    mouse_listener.start()
    keyboard_listener.start()
    mouse_listener.join()
    keyboard_listener.join()

def start_autoclick_thread():
    t = threading.Thread(target=autoclick_on_timer, daemon=True)
    t.start()

def start_all():
    global active
    active = True
    print("Autoclick ON")
    update_status("Tangent ON")

def stop_all():
    global active
    active = False
    print("Autoclick OFF")
    update_status("Tangent OFF")

def on_key_select(event):
    global selected_key
    selected_key = key_var.get()

def on_modifier_select(event):
    global selected_modifier
    selected_modifier = modifier_var.get()

def on_delay_change(event):
    global delay
    try:
        delay = float(delay_var.get())
    except ValueError:
        delay = 0.1

def on_mode_change():
    global mouse_required
    mouse_required = mode_var.get() == 'mouse'

# GUI
root = tk.Tk()
root.title("Autoclicker")

mainframe = ttk.Frame(root, padding="10")
mainframe.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))


# Modifier selection
modifier_var = tk.StringVar(value='')
ttm = ttk.Label(mainframe, text="Modifierare:")
ttm.grid(row=0, column=0, sticky=tk.W)
modifier_combo = ttk.Combobox(mainframe, textvariable=modifier_var, values=list(modifier_keys.keys()), state="readonly")
modifier_combo.grid(row=0, column=1)
modifier_combo.bind('<<ComboboxSelected>>', on_modifier_select)

# Key selection
key_var = tk.StringVar(value='space')
tt = ttk.Label(mainframe, text="Tangent:")
tt.grid(row=1, column=0, sticky=tk.W)
key_combo = ttk.Combobox(mainframe, textvariable=key_var, values=list(key_map.keys()), state="readonly")
key_combo.grid(row=1, column=1)
key_combo.bind('<<ComboboxSelected>>', on_key_select)

# Delay
delay_var = tk.StringVar(value=str(delay))
tt2 = ttk.Label(mainframe, text="Delay (sekunder):")
tt2.grid(row=2, column=0, sticky=tk.W)
delay_entry = ttk.Entry(mainframe, textvariable=delay_var, width=5)
delay_entry.grid(row=2, column=1)
delay_entry.bind('<FocusOut>', on_delay_change)

# Mode
mode_var = tk.StringVar(value='mouse')
tt3 = ttk.Label(mainframe, text="Läge:")
tt3.grid(row=3, column=0, sticky=tk.W)
mode_mouse = ttk.Radiobutton(mainframe, text='Vid musrörelse', variable=mode_var, value='mouse', command=on_mode_change)
mode_mouse.grid(row=3, column=1, sticky=tk.W)
mode_timer = ttk.Radiobutton(mainframe, text='Automatiskt (ingen mus)', variable=mode_var, value='timer', command=on_mode_change)
mode_timer.grid(row=4, column=1, sticky=tk.W)

# Start/Stop
start_btn = ttk.Button(mainframe, text="Starta", command=start_all)
start_btn.grid(row=5, column=0)
stop_btn = ttk.Button(mainframe, text="Stoppa", command=stop_all)
stop_btn.grid(row=5, column=1)

# Info
info = ttk.Label(mainframe, text="F6 = toggle tangent, F7 = toggle mus, F8 = avsluta")
info.grid(row=6, column=0, columnspan=2)

# Statusrad
status_var = tk.StringVar(value="Status: Inaktiv")
status_label = ttk.Label(root, textvariable=status_var, relief=tk.SUNKEN, anchor=tk.W)
status_label.grid(row=2, column=0, sticky=(tk.W, tk.E))

def update_status(msg=None):
    t = "ON" if active else "OFF"
    m = "ON" if mouse_click_active else "OFF"
    text = f"Status: Tangent: {t} | Mus: {m}"
    if msg:
        text += f" | {msg}"
    status_var.set(text)


# Start threads
threading.Thread(target=start_listeners, daemon=True).start()
start_autoclick_thread()
threading.Thread(target=mouse_click_on_timer, daemon=True).start()


# --- Mouse click GUI section ---
mouse_frame = ttk.LabelFrame(root, text="Mus-klick", padding="10")
mouse_frame.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=10, pady=10)

# Typ av klick
mouse_click_type_var = tk.StringVar(value='left')
ttm1 = ttk.Label(mouse_frame, text="Typ av klick:")
ttm1.grid(row=0, column=0, sticky=tk.W)
mouse_click_type_combo = ttk.Combobox(mouse_frame, textvariable=mouse_click_type_var, values=['left', 'right', 'middle'], state="readonly")
mouse_click_type_combo.grid(row=0, column=1)
mouse_click_type_combo.bind('<<ComboboxSelected>>', on_mouse_click_type)

# Delay
mouse_click_delay_var = tk.StringVar(value=str(mouse_click_delay))
ttm2 = ttk.Label(mouse_frame, text="Delay (sekunder):")
ttm2.grid(row=1, column=0, sticky=tk.W)
mouse_click_delay_entry = ttk.Entry(mouse_frame, textvariable=mouse_click_delay_var, width=5)
mouse_click_delay_entry.grid(row=1, column=1)
mouse_click_delay_entry.bind('<FocusOut>', on_mouse_click_delay_change)

# Mode
mouse_click_mode_var = tk.StringVar(value='timer')
ttm3 = ttk.Label(mouse_frame, text="Läge:")
ttm3.grid(row=2, column=0, sticky=tk.W)
mouse_click_mode_timer = ttk.Radiobutton(mouse_frame, text='Automatiskt (timer)', variable=mouse_click_mode_var, value='timer', command=on_mouse_click_mode_change)
mouse_click_mode_timer.grid(row=2, column=1, sticky=tk.W)
mouse_click_mode_move = ttk.Radiobutton(mouse_frame, text='Vid musrörelse', variable=mouse_click_mode_var, value='move', command=on_mouse_click_mode_change)
mouse_click_mode_move.grid(row=3, column=1, sticky=tk.W)

# Start/Stop
mouse_click_start_btn = ttk.Button(mouse_frame, text="Starta mus-klick", command=start_mouse_click)
mouse_click_start_btn.grid(row=4, column=0)
mouse_click_stop_btn = ttk.Button(mouse_frame, text="Stoppa mus-klick", command=stop_mouse_click)
mouse_click_stop_btn.grid(row=4, column=1)

root.mainloop()
