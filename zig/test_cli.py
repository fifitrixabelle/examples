"""Check the compiled CLI with the Zig version selected by mise.

Run: mise exec -- python zig/test_cli.py
"""

import pathlib
import re
import subprocess
import tempfile
import unittest


class ZigCliTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="zig-cli-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.binary = pathlib.Path(cls.temp.name) / "showcase"
        subprocess.run(
            ["zig", "build-exe", "main.zig", f"-femit-bin={cls.binary}"],
            cwd=pathlib.Path(__file__).parent,
            check=True,
        )

    def output(self, *args):
        result = subprocess.run(
            [str(self.binary), *args], check=True, capture_output=True, text=True
        )
        return re.sub(r"\x1b\[[0-9;]*m", "", result.stdout + result.stderr)

    def test_default_showcase(self):
        output = self.output()
        self.assertIn("factorial(10)    -> 3628800", output)
        self.assertIn("Random walk neon track", output)

    def test_help(self):
        self.assertIn("Commands:", self.output("help"))

    def test_collatz(self):
        output = self.output("collatz", "27")
        self.assertIn("Steps to 1: 111", output)
        self.assertIn("Peak value: 9232", output)

    def test_walk(self):
        output = self.output("walk", "4")
        self.assertIn("(4 steps)", output)
        self.assertIn("step 4", output)

    def test_rejects_invalid_walk_length(self):
        self.assertIn("ValueTooSmall", self.output("walk", "0"))


if __name__ == "__main__":
    unittest.main()
