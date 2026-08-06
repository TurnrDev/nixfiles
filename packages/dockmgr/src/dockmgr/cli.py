from __future__ import annotations

import json
import logging
import time
from pathlib import Path
from typing import Annotated

import typer

from dockmgr.adapters import apply_monitor, collect_state, log, monitors, resolve
from dockmgr.matcher import select_profile
from dockmgr.models import Config, Context, Profile

app = typer.Typer(no_args_is_help=True)
logging.basicConfig(level=logging.INFO, format="%(message)s")


def load_config(path: Path) -> Config:
    return Config.model_validate_json(path.read_text())


def selected(path: Path) -> tuple[Config, Profile]:
    config = load_config(path)
    profile = select_profile(config.profiles, collect_state())
    if profile is None:
        typer.echo("dockmgr: no profile matched and no fallback is configured", err=True)
        raise typer.Exit(1)
    return config, profile


def apply(profile: Profile, *, dry_run: bool) -> None:
    active = monitors()
    configured = set()
    commands: list[tuple[str, str | None, tuple[int, int] | None, float | None]] = []
    for selector, output in profile.outputs.items():
        configured |= resolve(selector, active)
        commands.append(
            (
                selector,
                None if output.disabled else output.mode,
                (output.position.x, output.position.y),
                output.scale,
            )
        )
    if profile.disableUnspecifiedOutputs:
        for monitor in active:
            name = monitor.get("name")
            if isinstance(name, str) and name not in configured:
                commands.append((name, None, None, None))
    if dry_run:
        typer.echo(json.dumps({"profile": profile.name, "commands": commands}, indent=2))
        return
    for selector, mode, position, scale in commands:
        apply_monitor(selector, mode, position, scale)
        log("monitor_applied", profile=profile.name, selector=selector, disabled=mode is None)


@app.command()
def status(config: Annotated[Path, typer.Option()] = Path("/etc/dockmgr/config.json")) -> None:
    _, profile = selected(config)
    typer.echo(profile.model_dump_json(indent=2))


@app.command()
def once(
    config: Annotated[Path, typer.Option()] = Path("/etc/dockmgr/config.json"),
    context: Annotated[Context, typer.Option()] = "session",
    dry_run: Annotated[bool, typer.Option()] = False,
) -> None:
    _, profile = selected(config)
    try:
        apply(profile, dry_run=dry_run)
    except RuntimeError as error:
        log("apply_failed", context=context, profile=profile.name, error=str(error))
        raise typer.Exit(1) from error


@app.command()
def watch(
    config: Annotated[Path, typer.Option()] = Path("/etc/dockmgr/config.json"),
    context: Annotated[Context, typer.Option()] = "session",
) -> None:
    last_profile = ""
    while True:
        _, profile = selected(config)
        if profile.id != last_profile:
            try:
                apply(profile, dry_run=False)
                last_profile = profile.id
            except RuntimeError as error:
                log("apply_failed", context=context, profile=profile.name, error=str(error))
        time.sleep(15)


if __name__ == "__main__":
    app()
