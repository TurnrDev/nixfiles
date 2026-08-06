from __future__ import annotations

from typing import Any

from dockmgr.models import Profile, State


def matches(expression: dict[str, Any], state: State) -> bool:
    for key, value in expression.items():
        if key == "and" and not all(matches(item, state) for item in value):
            return False
        if key == "or" and not any(matches(item, state) for item in value):
            return False
        if key == "not" and matches(value, state):
            return False
        if key == "lid" and state.lid_closed != value["closed"]:
            return False
        if key == "usb" and not _list_clause(value, state.usb, "anyOf", "allOf", "noneOf"):
            return False
        if key == "displays" and not _list_clause(
            value, state.displays, "connectedAnyOf", "connectedAllOf", "connectedNoneOf"
        ):
            return False
    return True


def _list_clause(
    clause: dict[str, list[str]], values: set[str], any_key: str, all_key: str, none_key: str
) -> bool:
    return (
        (any(item in values for item in clause[any_key]) if any_key in clause else True)
        and (all(item in values for item in clause[all_key]) if all_key in clause else True)
        and (all(item not in values for item in clause[none_key]) if none_key in clause else True)
    )


def select_profile(profiles: list[Profile], state: State) -> Profile | None:
    matched = [
        profile
        for profile in profiles
        if profile.match is not None and matches(profile.match, state)
    ]
    fallback = [profile for profile in profiles if profile.fallback]
    candidates = matched or fallback
    return max(candidates, key=lambda profile: (profile.specificity, -profile.order), default=None)
