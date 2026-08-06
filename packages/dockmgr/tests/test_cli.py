from typer.testing import CliRunner

from dockmgr.cli import app


def test_version() -> None:
    result = CliRunner().invoke(app, ["--version"])

    assert result.exit_code == 0
    assert result.stdout == "3.0.0\n"
