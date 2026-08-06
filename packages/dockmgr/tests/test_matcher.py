from dockmgr.matcher import select_profile
from dockmgr.models import Profile, State


def test_prefers_the_most_specific_matching_profile() -> None:
    fallback = Profile(id="fallback", name="Fallback", fallback=True)
    docked = Profile(id="docked", name="Docked", match={"usb": {"allOf": ["a:b"]}}, specificity=1)
    assert select_profile([fallback, docked], State(usb={"a:b"})) == docked
