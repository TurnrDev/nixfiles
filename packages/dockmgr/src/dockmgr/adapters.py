from __future__ import annotations

import json
import logging
import subprocess
from pathlib import Path

from dockmgr.models import State


def command(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=False, capture_output=True, text=True)


def monitors() -> list[dict[str, object]]:
    result = command(["hyprctl", "monitors", "all", "-j"])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "hyprctl monitors failed")
    data = json.loads(result.stdout)
    if not isinstance(data, list):
        raise RuntimeError("hyprctl returned invalid monitor data")
    return [item for item in data if isinstance(item, dict)]


def collect_state() -> State:
    usb = {
        f"{vendor.read_text().strip()}:{(vendor.parent / 'idProduct').read_text().strip()}"
        for vendor in Path("/sys/bus/usb/devices").glob("*/idVendor")
        if (vendor.parent / "idProduct").is_file()
    }
    display_names = {
        status.parent.name.split("-", 1)[1]
        for status in Path("/sys/class/drm").glob("card*-*/status")
        if status.read_text().strip() == "connected"
    }
    descriptions = {
        f"desc:{description}"
        for monitor in monitors()
        if isinstance(description := monitor.get("description"), str) and description
    }
    lid = next(iter(Path("/proc/acpi/button/lid").glob("*/state")), None)
    return State(
        usb=usb,
        displays=display_names | descriptions,
        lid_closed=lid is not None and "closed" in lid.read_text(),
    )


def resolve(selector: str, active_monitors: list[dict[str, object]]) -> set[str]:
    return {
        name
        for monitor in active_monitors
        if isinstance(name := monitor.get("name"), str)
        and (name == selector or selector == f"desc:{monitor.get('description', '')}")
    }


def apply_monitor(
    selector: str, mode: str | None, position: tuple[int, int] | None, scale: float | None
) -> None:
    if mode is None:
        rule = f"{selector},disable"
    else:
        assert position is not None
        assert scale is not None
        rule = f"{selector},{mode},{position[0]}x{position[1]},{scale}"
    result = command(["hyprctl", "keyword", "monitor", rule])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"failed to configure {selector}")


def log(event: str, **fields: object) -> None:
    logging.getLogger("dockmgr").info(json.dumps({"event": event, **fields}, sort_keys=True))
