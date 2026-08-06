from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class Position(BaseModel):
    model_config = ConfigDict(extra="forbid")
    x: int = 0
    y: int = 0


class Output(BaseModel):
    model_config = ConfigDict(extra="forbid")
    mode: str = "preferred"
    position: Position = Field(default_factory=Position)
    scale: float = 1.0
    disabled: bool = False


class Phases(BaseModel):
    model_config = ConfigDict(extra="forbid")
    preUp: list[str] = Field(default_factory=list)
    postUp: list[str] = Field(default_factory=list)
    preDown: list[str] = Field(default_factory=list)
    postDown: list[str] = Field(default_factory=list)


class Hooks(BaseModel):
    model_config = ConfigDict(extra="forbid")
    session: Phases = Field(default_factory=Phases)
    greeter: Phases = Field(default_factory=Phases)


def _validate_match(value: Any) -> Any:
    if not isinstance(value, dict) or not value:
        raise ValueError("match expressions must be non-empty objects")
    for key, clause in value.items():
        if key in {"and", "or"}:
            if not isinstance(clause, list):
                raise ValueError(f"{key} must be a list")
            for item in clause:
                _validate_match(item)
        elif key == "not":
            _validate_match(clause)
        elif key == "lid":
            if (
                not isinstance(clause, dict)
                or set(clause) != {"closed"}
                or not isinstance(clause["closed"], bool)
            ):
                raise ValueError("lid must contain only boolean closed")
        elif key == "usb":
            _validate_list_clauses(clause, {"anyOf", "allOf", "noneOf"})
        elif key == "displays":
            _validate_list_clauses(clause, {"connectedAnyOf", "connectedAllOf", "connectedNoneOf"})
        else:
            raise ValueError(f"unsupported match expression key: {key}")
    return value


def _validate_list_clauses(value: Any, allowed: set[str]) -> None:
    if not isinstance(value, dict) or not value or set(value) - allowed:
        raise ValueError("invalid match clause")
    if any(
        not isinstance(item, list) or not all(isinstance(entry, str) for entry in item)
        for item in value.values()
    ):
        raise ValueError("match clause values must be string lists")


class Profile(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: str
    name: str
    match: dict[str, Any] | None = None
    hooks: Hooks = Field(default_factory=Hooks)
    outputs: dict[str, Output] = Field(default_factory=dict)
    disableUnspecifiedOutputs: bool = True
    order: int = 0
    specificity: int = 0
    fallback: bool = False

    @model_validator(mode="after")
    def validate_match(self) -> Profile:
        if self.match is not None:
            _validate_match(self.match)
        return self


class Config(BaseModel):
    model_config = ConfigDict(extra="forbid")
    version: Literal[2]
    profiles: list[Profile]

    @model_validator(mode="after")
    def validate_profiles(self) -> Config:
        if not self.profiles:
            raise ValueError("profiles must not be empty")
        if not any(profile.fallback for profile in self.profiles):
            raise ValueError("a fallback profile is required")
        return self


class State(BaseModel):
    usb: set[str] = Field(default_factory=set)
    displays: set[str] = Field(default_factory=set)
    lid_closed: bool = False


Context = Literal["session", "greeter"]
